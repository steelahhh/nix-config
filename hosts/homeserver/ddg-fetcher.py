import asyncio
import os
import re
import time
from contextlib import asynccontextmanager

from fastapi import FastAPI
from pydantic import BaseModel, Field
from invisible_playwright.async_api import InvisiblePlaywright

PORT = int(os.environ.get("PORT", "8191"))
WARM_URL = os.environ.get("WARM_URL", "https://annas-archive.gl/")
MAX_WAIT_S = float(os.environ.get("MAX_WAIT", "60"))

CHALLENGE_MARKERS = (
    "<title>ddos-guard</title>",
    "/.well-known/ddos-guard/",
    "checking your browser before accessing",
    "could not verify your browser automatically",
    "complete the manual check",
    "just a moment",
    "/cdn-cgi/challenge-platform",
    "<title>redirecting...</title>",
)
ANNAS_MARKERS = ("/md5/", "aarecord", "/dyn/", "/datasets", "/fast_download", "/slow_download")
ERROR_TITLE = re.compile(r"<title>\s*5\d\d", re.I)


def classify(html: str) -> str:
    lowered = html.lower()
    if "no files found." in lowered or any(marker in lowered for marker in ANNAS_MARKERS):
        return "done"
    if any(marker in lowered for marker in CHALLENGE_MARKERS):
        return "challenge"
    if ERROR_TITLE.search(html):
        return "error"
    return "waiting"


class LinkRequest(BaseModel):
    cmd: str = "request.get"
    url: str
    max_timeout: int = Field(default=60_000, alias="maxTimeout")


state = {"page": None, "context": None, "browser_cm": None, "pending": None}
lock = asyncio.Lock()


async def poll(page, deadline: float) -> tuple[str, str]:
    html = ""
    while time.monotonic() < deadline:
        try:
            html = await page.content()
        except Exception:
            html = ""  # navigation in flight; context destroyed, retry
        verdict = classify(html)
        if verdict in ("done", "error"):
            return verdict, html
        await asyncio.sleep(0.5)
    return "challenge", html


async def navigate(url: str, budget_s: float) -> tuple[str, str]:
    page = state["page"]
    deadline = time.monotonic() + budget_s
    try:
        await page.goto(url, timeout=max(1000, budget_s * 1000), wait_until="domcontentloaded")
    except Exception as exc:
        return "error", f"navigation failed: {exc}"
    return await poll(page, deadline)


async def solve(url: str, budget_s: float) -> dict:
    async with lock:
        pending = state["pending"]
        if pending is not None and not pending.done():
            await asyncio.wait([pending], timeout=budget_s)
        verdict, html = await navigate(url, budget_s)
        if verdict == "challenge":
            state["pending"] = asyncio.create_task(poll(state["page"], time.monotonic() + MAX_WAIT_S))
            return {"status": "error", "message": "DDoS-Guard check did not complete within the request budget"}
        state["pending"] = None
        if verdict == "error":
            return {"status": "error", "message": html[:200] if html else "page did not load"}
        page = state["page"]
        cookies = await state["context"].cookies()
        user_agent = await page.evaluate("navigator.userAgent")
        return {
            "status": "ok",
            "message": "Success",
            "solution": {
                "url": page.url,
                "status": 200,
                "cookies": [{"name": c["name"], "value": c["value"]} for c in cookies],
                "userAgent": user_agent,
                "response": html,
            },
        }


async def warm() -> None:
    try:
        async with lock:
            verdict, _ = await navigate(WARM_URL, MAX_WAIT_S)
            print(f"[ddg-fetcher] warm-up {WARM_URL}: {verdict}", flush=True)
    except Exception as exc:
        print(f"[ddg-fetcher] warm-up failed (first request will solve): {exc}", flush=True)


@asynccontextmanager
async def lifespan(app: FastAPI):
    cm = InvisiblePlaywright(
        headless=True,
        humanize=True,
        extra_prefs={
            "devtools.jsonview.enabled": False,
            "browser.tabs.remote.useCrossOriginOpenerPolicy": False,
            "browser.tabs.remote.useCrossOriginEmbedderPolicy": False,
            "dom.security.https_first": False,
        },
    )
    browser = await cm.__aenter__()
    context = await browser.new_context()
    state.update(browser_cm=cm, context=context, page=await context.new_page())
    asyncio.create_task(warm())
    yield
    await cm.__aexit__(None, None, None)


app = FastAPI(lifespan=lifespan)


@app.get("/health")
async def health():
    return {"status": "ok", "browser": state["page"] is not None}


@app.post("/v1")
async def v1(request: LinkRequest):
    started = int(time.time() * 1000)
    if request.cmd != "request.get":
        return {"status": "error", "message": f"unsupported cmd: {request.cmd}"}
    budget_s = min(MAX_WAIT_S, max(1.0, request.max_timeout / 1000))
    result = await solve(request.url, budget_s)
    result["startTimestamp"] = started
    result["endTimestamp"] = int(time.time() * 1000)
    return result


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=PORT)