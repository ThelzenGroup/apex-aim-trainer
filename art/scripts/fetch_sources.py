"""Download the CC0 source packs the dummies are built from.

Quaternius publishes the Universal Animation Library on itch.io as a free
(pay-what-you-want, $0 minimum) download. This script follows the same flow as
clicking "No thanks, just take me to the downloads" and extracts the one .glb
we need from each pack into art/sources/ (git-ignored).

    python art/scripts/fetch_sources.py
"""
import http.cookiejar
import io
import json
import re
import sys
import urllib.parse
import urllib.request
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCES = ROOT / "art" / "sources"

# itch.io game page -> file inside the zip to keep (non-root-motion glTF build).
PACKS = {
    "https://quaternius.itch.io/universal-animation-library": "Unreal-Godot/UAL1_Standard.glb",
    "https://quaternius.itch.io/universal-animation-library-2": "Unreal-Godot/UAL2_Standard.glb",
}

opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))
opener.addheaders = [("User-Agent", "apex-aim-trainer-asset-fetch")]


def get(url):
    with opener.open(url, timeout=60) as r:
        return r.read()


def post_json(url, token):
    data = urllib.parse.urlencode({"csrf_token": token}).encode()
    with opener.open(urllib.request.Request(url, data=data), timeout=60) as r:
        return json.loads(r.read())


def csrf(html):
    return re.search(r'name="csrf_token" value="([^"]+)"', html).group(1)


def fetch(game_url, member):
    target = SOURCES / Path(member).name
    if target.exists():
        print(f"have {target.relative_to(ROOT)}")
        return
    page = get(game_url).decode()
    download_page = get(post_json(f"{game_url}/download_url", csrf(page))["url"]).decode()
    upload_ids = sorted(set(re.findall(r'data-upload_id="(\d+)"', download_page)))
    if len(upload_ids) != 1:
        sys.exit(f"{game_url}: expected one free upload, found {upload_ids}")
    file_url = f"{game_url}/file/{upload_ids[0]}?source=view_game&as_props=1&after_download_lightbox=true"
    archive = zipfile.ZipFile(io.BytesIO(get(post_json(file_url, csrf(download_page))["url"])))
    name = next(n for n in archive.namelist() if n.endswith(member))
    target.write_bytes(archive.read(name))
    print(f"wrote {target.relative_to(ROOT)}")


if __name__ == "__main__":
    SOURCES.mkdir(parents=True, exist_ok=True)
    for game_url, member in PACKS.items():
        fetch(game_url, member)
