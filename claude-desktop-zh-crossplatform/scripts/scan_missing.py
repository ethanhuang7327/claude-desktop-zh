#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


PATTERNS = [
    ("defaultMessage", re.compile(r'defaultMessage:"([^"]+)"')),
    ("label", re.compile(r'label:"([^"]+)"')),
    ("title", re.compile(r'title:"([^"]+)"')),
    ("placeholder", re.compile(r'placeholder:"([^"]+)"')),
    ("string", re.compile(r'"([A-Za-z][A-Za-z ]{2,80})"')),
]


def looks_visible(value: str, kind: str) -> bool:
    if not value.strip() or re.search(r"[\u4e00-\u9fff]", value):
        return False
    if "{" in value or "}" in value or "<" in value or ">" in value:
        return False
    if "/" in value or "\\" in value or value.startswith("http"):
        return False
    if re.fullmatch(r"[A-Z0-9_./:-]+", value):
        return False
    if kind == "string" and " " not in value:
        return False
    return bool(re.search(r"[A-Za-z]", value))


def main() -> int:
    parser = argparse.ArgumentParser(description="Scan Claude Desktop JS/CSS assets for untranslated visible English candidates.")
    parser.add_argument("--assets", type=Path, required=True, help="Path to ion-dist/assets/v1")
    parser.add_argument("--known", type=Path, action="append", default=[], help="Known runtime translation JSON files")
    parser.add_argument("--output", type=Path, default=Path("locales/missing.json"), help="Output JSON path")
    args = parser.parse_args()

    known: set[str] = set()
    for path in args.known:
        if not path.is_file():
            continue
        data = json.load(path.open(encoding="utf-8"))
        if isinstance(data, dict):
            known.update(str(key) for key in data.keys())

    seen: set[str] = set()
    items: list[dict[str, str]] = []
    for path in sorted(list(args.assets.glob("*.js")) + list(args.assets.glob("*.css"))):
        text = path.read_text(encoding="utf-8", errors="ignore")
        for kind, pattern in PATTERNS:
            for match in pattern.finditer(text):
                value = bytes(match.group(1), "utf-8").decode("unicode_escape")
                if value in seen or value in known or not looks_visible(value, kind):
                    continue
                seen.add(value)
                items.append({"text": value, "translation": "", "kind": kind, "file": str(path)})

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8") as handle:
        json.dump(items, handle, ensure_ascii=False, indent=2)
        handle.write("\n")
    print(f"Wrote {len(items)} candidates to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
