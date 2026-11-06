#!/usr/bin/env python3
"""Validate Signal Scout URLs offline; --submit sends one IndexNow notification."""
import argparse
from datetime import datetime, timezone
from http.client import HTTPException
from html.parser import HTMLParser
import json
from pathlib import Path
import re
import sys
from urllib.error import HTTPError, URLError
from urllib.parse import urlsplit
from urllib.request import HTTPRedirectHandler, Request, build_opener
import xml.etree.ElementTree as ET

WEB = Path(__file__).resolve().parents[1] / "Web"
BASE = "https://nickvan23-lang.github.io/signal-scout/"
HOST = "nickvan23-lang.github.io"
PREFIX = "/signal-scout/"
ENDPOINT = "https://api.indexnow.org/indexnow"
NS = "{http://www.sitemaps.org/schemas/sitemap/0.9}"
LIMIT = 8192


def now():
    return datetime.now(timezone.utc).isoformat()


class Page(HTMLParser):
    def __init__(self):
        super().__init__()
        self.noindex = False
        self.canonicals = []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        name = attrs.get("name", "").lower()
        if tag == "meta" and (name == "robots" or "bot" in name):
            tokens = re.split(r"[\s,;]+", attrs.get("content", "").lower())
            self.noindex |= bool({"noindex", "none"}.intersection(tokens))
        if tag == "link" and "canonical" in attrs.get("rel", "").lower().split():
            self.canonicals.append(attrs.get("href"))


def source_path(url):
    parsed = urlsplit(url)
    if (parsed.scheme != "https" or parsed.netloc != HOST
            or not parsed.path.startswith(PREFIX) or parsed.query or parsed.fragment
            or any(ord(c) <= 32 for c in url) or "\\" in url or "%" in url
            or any(p in (".", "..") for p in parsed.path.split("/"))):
        raise ValueError(f"URL outside the supported host/path or noncanonical: {url}")
    relative = parsed.path[len(PREFIX):]
    path = (WEB / relative / "index.html" if url.endswith("/") else WEB / relative).resolve()
    if not path.is_relative_to(WEB.resolve()) or path.suffix != ".html" or not path.is_file():
        raise ValueError(f"URL has no matching local HTML source: {url}")
    return path, relative


def prepare(requested):
    keys = [p for p in WEB.glob("*.txt") if re.fullmatch(r"[A-Za-z0-9-]{8,128}", p.stem)
            and p.read_text(encoding="utf-8").strip() == p.stem]
    if len(keys) != 1:
        raise ValueError("Expected exactly one public IndexNow key file in Web/.")
    raw = (WEB / "sitemap.xml").read_bytes()
    if len(raw) > 1_048_576 or b"<!DOCTYPE" in raw or b"<!ENTITY" in raw:
        raise ValueError("Sitemap too large or contains unsupported declarations.")
    root = ET.fromstring(raw)
    if root.tag != NS + "urlset":
        raise ValueError("Expected a sitemap urlset, not a sitemap index.")
    urls = []
    for entry in root:
        locations = entry.findall(NS + "loc")
        if entry.tag != NS + "url" or len(locations) != 1 or not locations[0].text:
            raise ValueError("Invalid sitemap URL entry.")
        urls.append(locations[0].text.strip())
    if not 1 <= len(urls) <= 10_000 or len(set(urls)) != len(urls):
        raise ValueError("Sitemap must contain 1–10,000 unique URLs.")
    eligible, excluded = [], []
    for url in urls:
        path, relative = source_path(url)
        page = Page()
        page.feed(path.read_text(encoding="utf-8"))
        if page.noindex or relative.startswith("review/"):
            excluded.append(url)
        elif page.canonicals != [url]:
            raise ValueError(f"Local canonical does not match sitemap URL: {url}")
        else:
            eligible.append(url)
    if requested and any(url not in eligible for url in requested):
        raise ValueError("Every --url must be an eligible URL in the local sitemap.")
    selected = list(dict.fromkeys(requested)) if requested else eligible
    if not selected:
        raise ValueError("No indexable URLs to submit.")
    key = keys[0].stem
    return {"host": HOST, "key": key, "keyLocation": BASE + keys[0].name,
            "urlList": selected}, excluded


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def request(url, data=None):
    headers = {"User-Agent": "SignalScout-IndexNow/1.0"}
    if data is not None:
        headers["Content-Type"] = "application/json; charset=utf-8"
    req = Request(url, data=data, headers=headers)
    try:
        response = build_opener(NoRedirect()).open(req, timeout=30)
    except HTTPError as error:
        response = error
    with response:
        body = response.read(LIMIT + 1)
        header_text = str(response.headers)
        return {"status": response.code, "headers": header_text[:LIMIT],
                "headers_truncated": len(header_text) > LIMIT,
                "body": body[:LIMIT].decode("utf-8", errors="replace"),
                "body_truncated": len(body) > LIMIT}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--submit", action="store_true", help="Verify the live key, then POST once.")
    parser.add_argument("--url", action="append", help="Select an eligible sitemap URL; repeatable.")
    parser.add_argument("--output", type=Path, help="Also write the JSON receipt to this path.")
    args = parser.parse_args()
    receipt = {"started_at": now(), "mode": "submit" if args.submit else "dry-run",
               "endpoint": ENDPOINT, "outcome": "validation-failed", "post_attempted": False,
               "indexed": "not determined by IndexNow notification"}
    code = 1
    try:
        payload, excluded = prepare(args.url)
        receipt.update({"payload": payload, "excluded_urls": excluded})
        if not args.submit:
            receipt["outcome"], code = "dry-run-valid", 0
        else:
            receipt["key_preflight"] = request(payload["keyLocation"])
            check = receipt["key_preflight"]
            if check["status"] != 200 or check["body"].strip() != payload["key"] or check["body_truncated"]:
                raise ValueError("Live key preflight failed; deploy the matching key file before submission.")
            receipt["post_attempted"] = True
            receipt["response"] = request(ENDPOINT, json.dumps(payload).encode("utf-8"))
            status = receipt["response"]["status"]
            receipt["outcome"] = {200: "accepted", 202: "key-validation-pending"}.get(status, "http-error")
            code = 0 if status in (200, 202) else 1
    except (ValueError, OSError, URLError, HTTPException, ET.ParseError) as error:
        receipt["error"] = str(error)[:LIMIT]
        if receipt["post_attempted"]:
            receipt["outcome"] = "transport-error-delivery-unknown"
    receipt["completed_at"] = now()
    rendered = json.dumps(receipt, indent=2, ensure_ascii=False) + "\n"
    if args.output:
        try:
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(rendered, encoding="utf-8")
        except OSError as error:
            print(f"Could not write receipt: {error}", file=sys.stderr)
            code = 1
    print(rendered, end="")
    return code


if __name__ == "__main__":
    raise SystemExit(main())
