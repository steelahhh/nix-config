import importlib.util
import json
import plistlib
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location(
    "ami", REPO / "scripts/apple_music_import.py")
ami = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ami)

tmp = Path(tempfile.mkdtemp())

tracks = {
    "101": {"Artist": "Aphex Twin", "Album Artist": "Aphex Twin",
            "Album": "Selected Ambient Works 85-92", "Name": "Xtal",
            "Total Time": 294000},
    "102": {"Artist": "Aphex Twin", "Album Artist": "Aphex Twin",
            "Album": "Selected Ambient Works 85-92", "Name": "Tha"},
    "103": {"Artist": "Boards of Canada", "Album Artist": "Boards of Canada",
            "Album": "Music Has the Right to Children", "Name": "Roygbiv"},
    "104": {"Artist": "Some Guest", "Album Artist": "Boards of Canada",
            "Album": "Music Has the Right to Children",
            "Name": "Turquoise Hexagon Sun"},
    "105": {"Name": "No Artist Track"},
    "106": {"Artist": "Aphex Twin", "Album": "", "Name": "Loose Track"},
}
playlists = [
    {"Name": "My Mix", "Playlist Items": [
        {"Track ID": 101}, {"Track ID": 103}, {"Track ID": 999}]},
    {"Name": "Music", "Distinguished Kind": 4,
     "Playlist Items": [{"Track ID": 101}]},
    {"Name": "A Folder", "Folder": True},
    {"Name": "Smart One", "Smart Criteria": {"rules": []}},
]
lib = {"Tracks": tracks, "Playlists": playlists}

xml_path = tmp / "Library.xml"
with xml_path.open("wb") as fh:
    plistlib.dump(lib, fh)
json_path = tmp / "Library.json"
json_path.write_text(json.dumps(lib), encoding="utf-8")

for p in (xml_path, json_path):
    loaded = ami.load_library(p)
    assert loaded["Tracks"]["101"]["Name"] == "Xtal", p
print("ok: load_library (plist + json)")

artists, pairs = ami.extract_artists(tracks)
assert set(artists) == {"aphex twin", "boards of canada"}, artists
assert artists["boards of canada"] == "Boards of Canada"
assert pairs == {("aphex twin", "Selected Ambient Works 85-92"),
                 ("boards of canada", "Music Has the Right to Children")}, pairs
print("ok: extract_artists dedupe/fallback")

pls = list(ami.user_playlists(lib))
assert pls == [("My Mix", [101, 103, 999])], pls
print("ok: user_playlists filtering")

results = [{"artistName": "Aphex Twin Tribute"}, {"artistName": "Aphex Twin"}]
assert ami.choose_lookup_match(results, "aphex twin")["artistName"] == "Aphex Twin"
assert ami.choose_lookup_match(results[:1], "Aphex Twin") is results[0]
assert ami.choose_lookup_match([], "X") is None
print("ok: choose_lookup_match")

class FakeND:
    def __init__(self, songs):
        self.songs = songs
        self.queries = []
    def search_songs(self, query, count=20):
        self.queries.append(query)
        return self.songs

song_exact = {"title": "Xtal", "artist": "Aphex Twin",
              "album": "Selected Ambient Works 85-92",
              "path": "Aphex Twin/SAW/01 Xtal.flac", "duration": 294}
song_other_album = dict(song_exact, album="Other Album",
                        path="Aphex Twin/Other/01 Xtal.flac")
song_wrong_artist = dict(song_exact, artist="Someone Else")
song_cover = dict(song_exact, title="Xtal (Cover)")

nd = FakeND([song_other_album, song_exact, song_wrong_artist, song_cover])
m = ami.match_track(nd, tracks["101"], {})
assert m is song_exact, m
assert ami.match_track(FakeND([song_wrong_artist]), tracks["101"], {}) is None
assert ami.match_track(FakeND([song_cover]), tracks["101"], {}) is None
partial = dict(song_exact, title="Roygbiv", artist="Boards of Canada Ltd")
m2 = ami.match_track(FakeND([partial]), tracks["103"], {})
assert m2 is partial
cache = {}
nd2 = FakeND([song_exact])
ami.match_track(nd2, tracks["101"], cache)
ami.match_track(nd2, tracks["101"], cache)
assert len(nd2.queries) == 1, nd2.queries
print("ok: match_track scoring + cache")

text = ami.render_m3u8([song_exact], "/srv/music")
lines = text.splitlines()
assert lines[0] == "#EXTM3U"
assert lines[1] == "#EXTINF:294,Aphex Twin - Xtal"
assert lines[2] == "/srv/music/Aphex Twin/SAW/01 Xtal.flac"
assert text.endswith("\n")
print("ok: render_m3u8")

used = set()
assert ami.safe_filename("My/Mix: Vol 2", used) == "My_Mix_ Vol 2.m3u8"
assert ami.safe_filename("My/Mix: Vol 2", used) == "My_Mix_ Vol 2-2.m3u8"
assert ami.safe_filename("", used) == "playlist.m3u8"
print("ok: safe_filename")

state_path = tmp / "state.json"
state = {"artists": {"aphex twin": {"status": "added"}}}
ami.save_state(state_path, state)
assert ami.load_state(state_path) == state
assert ami.load_state(tmp / "missing.json") == {"artists": {}}
print("ok: state save/load")

help_out = subprocess.run(
    [sys.executable, str(REPO / "scripts/apple_music_import.py"), "--help"],
    capture_output=True, text=True)
assert help_out.returncode == 0 and "artists" in help_out.stdout
no_key = subprocess.run(
    [sys.executable, str(REPO / "scripts/apple_music_import.py"),
     "artists", "--library", str(xml_path), "--dry-run"],
    capture_output=True, text=True, env={"PATH": "/usr/bin:/bin"})
assert no_key.returncode != 0 and "LIDARR_API_KEY" in no_key.stderr
print("ok: CLI --help / missing-key error")

print("\nALL TESTS PASSED")