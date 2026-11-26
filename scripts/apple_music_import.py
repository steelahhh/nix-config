#!/usr/bin/env python3
"""Import an exported Apple Music library into the homeserver music stack.

Phase 1 (artists): dedupe artists from Library.xml (XML/binary plist, or a
JSON conversion with the same top-level structure), resolve them through
Lidarr's MusicBrainz-backed lookup, and add them monitored with
search-on-add. Resumable via a state file; --dry-run prints counts without
adding anything.

Phase 2 (playlists): match playlist tracks against the actual Navidrome
library via its Subsonic API and write .m3u8 files locally. Copy them to the
server afterwards:
    scp playlists/*.m3u8 homeserver:/srv/music/playlists/
Re-run once the library fills; only matched tracks are written.

Phase 3 (loved-track sync) is deferred — see docs/navidrome-music-stack-plan.md.

Stdlib only. Runs on the laptop against the LAN endpoints. Examples:
    LIDARR_API_KEY=... python3 apple_music_import.py artists \\
        --library Library.xml --dry-run
    LIDARR_API_KEY=... python3 apple_music_import.py artists --library Library.xml
    NAVIDROME_PASSWORD=... python3 apple_music_import.py playlists \\
        --library Library.xml --navidrome-user sasha

DRM'd Apple Music streaming downloads are unusable; this imports metadata
only, and Lidarr/soularr/TorBox acquire the actual files.
"""

import argparse
import getpass
import hashlib
import json
import os
import plistlib
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

DEFAULT_LIDARR_URL = "http://homeserver:8686"
DEFAULT_NAVIDROME_URL = "http://homeserver:4533"
USER_AGENT = "apple-music-import/1.0"


def norm(s):
    return " ".join((s or "").casefold().split())


class ApiError(Exception):
    def __init__(self, status, message):
        super().__init__(f"HTTP {status}: {message}" if status else message)
        self.status = status
        self.message = message


class Throttle:
    def __init__(self, rate):
        self.interval = 1.0 / rate if rate > 0 else 0.0
        self.last = 0.0

    def wait(self):
        if self.interval:
            delay = self.last + self.interval - time.monotonic()
            if delay > 0:
                time.sleep(delay)
        self.last = time.monotonic()


def http_json(url, throttle, headers=None, method="GET", payload=None):
    last_err = None
    for attempt in range(3):
        throttle.wait()
        req = urllib.request.Request(url, method=method)
        req.add_header("User-Agent", USER_AGENT)
        for key, value in (headers or {}).items():
            req.add_header(key, value)
        data = None
        if payload is not None:
            data = json.dumps(payload).encode("utf-8")
            req.add_header("Content-Type", "application/json")
        try:
            with urllib.request.urlopen(req, data=data, timeout=30) as resp:
                return json.loads(resp.read().decode("utf-8"))
        except urllib.error.HTTPError as err:
            body = err.read().decode("utf-8", errors="replace")[:500]
            if err.code == 429 or 500 <= err.code < 600:
                last_err = ApiError(err.code, body)
                time.sleep(2 ** (attempt + 1))
                continue
            raise ApiError(err.code, body) from None
        except (urllib.error.URLError, TimeoutError, OSError) as err:
            last_err = ApiError(0, str(err))
            time.sleep(2 ** (attempt + 1))
    raise last_err


class Lidarr:
    def __init__(self, base_url, api_key, throttle):
        self.base = base_url.rstrip("/")
        self.headers = {"X-Api-Key": api_key}
        self.throttle = throttle

    def get(self, path, **params):
        url = self.base + path
        if params:
            url += "?" + urllib.parse.urlencode(params)
        return http_json(url, self.throttle, headers=self.headers)

    def post(self, path, payload):
        return http_json(
            self.base + path, self.throttle, headers=self.headers,
            method="POST", payload=payload,
        )


class Navidrome:
    def __init__(self, base_url, user, password, throttle):
        self.base = base_url.rstrip("/")
        self.throttle = throttle
        self.salt = os.urandom(8).hex()
        self.auth = {
            "u": user,
            "t": hashlib.md5((password + self.salt).encode("utf-8")).hexdigest(),
            "s": self.salt,
            "v": "1.16.1",
            "c": "apple-music-import",
            "f": "json",
        }

    def search_songs(self, query, count=20):
        params = dict(self.auth, query=query, songCount=count,
                      artistCount=0, albumCount=0)
        url = self.base + "/rest/search3.view?" + urllib.parse.urlencode(params)
        resp = http_json(url, self.throttle).get("subsonic-response", {})
        if resp.get("status") != "ok":
            raise ApiError(0, resp.get("error", {}).get("message", "unknown error"))
        songs = resp.get("searchResult3", {}).get("song", [])
        return [songs] if isinstance(songs, dict) else songs


def load_library(path):
    p = Path(path)
    if p.suffix.lower() == ".json":
        data = json.loads(p.read_text(encoding="utf-8"))
    else:
        with p.open("rb") as fh:
            data = plistlib.load(fh)
    if not isinstance(data, dict) or not isinstance(data.get("Tracks"), dict):
        sys.exit(f"error: {p} is not an Apple Music export "
                 "(expected a top-level 'Tracks' dict)")
    return data


def track_artist(track):
    return (track.get("Album Artist") or track.get("Artist") or "").strip()


def extract_artists(tracks):
    artists = {}
    pairs = set()
    for track in tracks.values():
        if not isinstance(track, dict):
            continue
        artist = track_artist(track)
        if not artist:
            continue
        artists.setdefault(norm(artist), artist)
        album = (track.get("Album") or "").strip()
        if album:
            pairs.add((norm(artist), album))
    return artists, pairs


def user_playlists(library):
    for pl in library.get("Playlists", []):
        if not isinstance(pl, dict):
            continue
        if pl.get("Folder") or pl.get("Distinguished Kind") is not None:
            continue
        items = pl.get("Playlist Items") or []
        name = (pl.get("Name") or "").strip()
        if not items or not name:
            continue
        ids = [it.get("Track ID") for it in items if isinstance(it, dict)]
        yield name, [tid for tid in ids if tid is not None]


def choose_lookup_match(results, name):
    if not results:
        return None
    for result in results:
        if norm(result.get("artistName")) == norm(name):
            return result
    return results[0]


def load_state(path):
    p = Path(path)
    if p.exists():
        return json.loads(p.read_text(encoding="utf-8"))
    return {"artists": {}}


def save_state(path, state):
    p = Path(path)
    tmp = p.with_suffix(p.suffix + ".tmp")
    tmp.write_text(json.dumps(state, indent=1, ensure_ascii=False),
                   encoding="utf-8")
    os.replace(tmp, p)


def cmd_artists(args):
    if not args.api_key:
        sys.exit("error: no Lidarr API key (--api-key or LIDARR_API_KEY); "
                 "Lidarr -> Settings -> General -> Security")
    library = load_library(args.library)
    artists, pairs = extract_artists(library["Tracks"])
    print(f"library: {len(library['Tracks'])} tracks, "
          f"{len(pairs)} (artist, album) pairs, {len(artists)} unique artists")

    lidarr = Lidarr(args.lidarr_url, args.api_key, Throttle(args.rate))
    existing = {norm(a.get("artistName")) for a in lidarr.get("/api/v1/artist")}
    quality = lidarr.get("/api/v1/qualityprofile")
    metadata = lidarr.get("/api/v1/metadataprofile")
    roots = lidarr.get("/api/v1/rootfolder")
    if not quality or not metadata or not roots:
        sys.exit("error: Lidarr has no quality/metadata profile or root folder; "
                 "finish its initial setup first")
    quality_id, metadata_id = quality[0]["id"], metadata[0]["id"]
    root = roots[0]["path"]
    print(f"lidarr: {len(existing)} artists already present; "
          f"using quality profile {quality[0]['name']!r}, "
          f"metadata profile {metadata[0]['name']!r}, root {root!r}")

    todo = sorted(n for n in artists if n not in existing)
    state = load_state(args.state)
    counts = {"added": 0, "skipped": 0, "failed": 0, "not-found": 0,
              "already-done": 0, "would-add": 0}

    for key in todo:
        record = state["artists"].get(key)
        if record and record["status"] in ("added", "skipped"):
            counts["already-done"] += 1
            continue
        if args.dry_run:
            counts["would-add"] += 1
            continue
        name = artists[key]
        try:
            results = lidarr.get("/api/v1/artist/lookup", term=name)
        except ApiError as err:
            state["artists"][key] = {"status": "failed", "error": str(err)}
            save_state(args.state, state)
            counts["failed"] += 1
            print(f"  FAIL lookup {name}: {err}")
            continue
        match = choose_lookup_match(results, name)
        if match is None:
            state["artists"][key] = {"status": "not-found"}
            save_state(args.state, state)
            counts["not-found"] += 1
            print(f"  MISS {name}: no MusicBrainz match")
            continue
        payload = dict(match)
        payload.update(
            monitored=True,
            qualityProfileId=quality_id,
            metadataProfileId=metadata_id,
            rootFolderPath=root,
            addOptions={"searchForMissingAlbums": True},
        )
        try:
            lidarr.post("/api/v1/artist", payload)
        except ApiError as err:
            if err.status == 400 and "exist" in err.message.lower():
                state["artists"][key] = {"status": "skipped"}
                counts["skipped"] += 1
            else:
                state["artists"][key] = {"status": "failed", "error": str(err)}
                counts["failed"] += 1
                print(f"  FAIL add {name}: {err}")
            save_state(args.state, state)
            continue
        state["artists"][key] = {
            "status": "added",
            "foreignArtistId": match.get("foreignArtistId"),
        }
        save_state(args.state, state)
        counts["added"] += 1
        print(f"  ADD  {name}")

    print("\nsummary:")
    if args.dry_run:
        print(f"  would add: {counts['would-add']} "
              f"(already in Lidarr: {len(existing & artists.keys())})")
        print("dry run — nothing was added; re-run without --dry-run")
        return 0
    for label in ("added", "skipped", "already-done", "not-found", "failed"):
        print(f"  {label}: {counts[label]}")
    if counts["failed"] or counts["not-found"]:
        print(f"state saved to {args.state}; re-run to retry failures "
              "(not-found artists are skipped unless you delete their entries)")
    return 1 if counts["failed"] else 0


def match_track(navidrome, track, cache):
    title = (track.get("Name") or "").strip()
    artist = (track.get("Artist") or track_artist(track) or "").strip()
    album = (track.get("Album") or "").strip()
    if not title:
        return None
    key = (norm(artist), norm(album), norm(title))
    if key in cache:
        return cache[key]
    best, best_score = None, 0
    try:
        candidates = navidrome.search_songs(f"{title} {artist}")
    except ApiError as err:
        print(f"  WARN search failed for {title!r}: {err}")
        candidates = []
    for song in candidates:
        if norm(song.get("title")) != norm(title):
            continue
        s_artist, t_artist = norm(song.get("artist")), norm(artist)
        if s_artist == t_artist:
            score = 4
        elif t_artist and (t_artist in s_artist or s_artist in t_artist):
            score = 3
        else:
            continue
        if album and norm(song.get("album")) == norm(album):
            score += 1
        if score > best_score:
            best, best_score = song, score
    cache[key] = best
    return best


def render_m3u8(songs, music_folder):
    lines = ["#EXTM3U"]
    for song in songs:
        duration = int(song.get("duration") or 0)
        lines.append(f"#EXTINF:{duration},{song.get('artist', '')} - "
                     f"{song.get('title', '')}")
        path = (song.get("path") or "").lstrip("/")
        lines.append(music_folder.rstrip("/") + "/" + path)
    return "\n".join(lines) + "\n"


def safe_filename(name, used):
    base = re.sub(r"[^\w\-. ]+", "_", name).strip() or "playlist"
    candidate, n = base, 1
    while candidate.lower() in used:
        n += 1
        candidate = f"{base}-{n}"
    used.add(candidate.lower())
    return candidate + ".m3u8"


def cmd_playlists(args):
    password = args.navidrome_password
    if not password:
        password = getpass.getpass(f"Navidrome password for {args.navidrome_user}: ")
    library = load_library(args.library)
    tracks = library["Tracks"]
    navidrome = Navidrome(args.navidrome_url, args.navidrome_user, password,
                          Throttle(args.rate))
    playlists = list(user_playlists(library))
    if not playlists:
        sys.exit("error: no user playlists with track items found in the export")

    out_dir = Path(args.out)
    if not args.dry_run:
        out_dir.mkdir(parents=True, exist_ok=True)
    used_names = set()
    cache = {}
    total_tracks = total_matched = 0

    for name, ids in playlists:
        songs, seen = [], set()
        for tid in ids:
            track = tracks.get(str(tid)) or tracks.get(tid)
            if not isinstance(track, dict):
                continue
            song = match_track(navidrome, track, cache)
            if song is None:
                continue
            path = song.get("path")
            if path in seen:
                continue
            seen.add(path)
            songs.append(song)
        total_tracks += len(ids)
        total_matched += len(songs)
        rate = f"{len(songs)}/{len(ids)}"
        if args.dry_run:
            print(f"  {name}: {rate} matched")
            continue
        filename = safe_filename(name, used_names)
        (out_dir / filename).write_text(
            render_m3u8(songs, args.music_folder), encoding="utf-8")
        print(f"  {name}: {rate} matched -> {out_dir / filename}")

    print(f"\nmatched {total_matched}/{total_tracks} playlist tracks overall")
    if args.dry_run:
        print("dry run — no files written; re-run without --dry-run")
        return 0
    print("copy to the server, then Navidrome auto-imports them:")
    print(f"  scp {out_dir}/*.m3u8 homeserver:/srv/music/playlists/")
    return 0


def main():
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)

    p1 = sub.add_parser("artists", help="phase 1: add library artists to Lidarr")
    p1.add_argument("--library", required=True,
                    help="Library.xml (plist) or JSON conversion")
    p1.add_argument("--lidarr-url", default=DEFAULT_LIDARR_URL)
    p1.add_argument("--api-key", default=os.environ.get("LIDARR_API_KEY"),
                    help="Lidarr API key (default: LIDARR_API_KEY)")
    p1.add_argument("--state", default="apple-import-state.json",
                    help="resumable progress file")
    p1.add_argument("--dry-run", action="store_true",
                    help="print counts without adding artists")
    p1.add_argument("--rate", type=float, default=1.0,
                    help="max requests/second (default: 1)")
    p1.set_defaults(func=cmd_artists)

    p2 = sub.add_parser("playlists",
                        help="phase 2: match playlists against Navidrome")
    p2.add_argument("--library", required=True)
    p2.add_argument("--navidrome-url", default=DEFAULT_NAVIDROME_URL)
    p2.add_argument("--navidrome-user", required=True)
    p2.add_argument("--navidrome-password",
                    default=os.environ.get("NAVIDROME_PASSWORD"),
                    help="default: NAVIDROME_PASSWORD, else prompt")
    p2.add_argument("--music-folder", default="/srv/music",
                    help="library root as seen by Navidrome")
    p2.add_argument("--out", default="playlists",
                    help="local output directory for .m3u8 files")
    p2.add_argument("--dry-run", action="store_true",
                    help="report match rates without writing files")
    p2.add_argument("--rate", type=float, default=1.0)
    p2.set_defaults(func=cmd_playlists)

    args = parser.parse_args()
    sys.exit(args.func(args))


if __name__ == "__main__":
    main()