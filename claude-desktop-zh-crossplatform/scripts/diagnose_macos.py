#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path

import apply_macos


def analyze_language_whitelist(app: Path, lang_code: str) -> dict[str, object]:
    assets_dir = app / apply_macos.FRONTEND_ASSETS_REL
    files = sorted(assets_dir.glob("index-*.js")) if assets_dir.is_dir() else []
    matched = 0
    already = 0
    for path in files:
        text = path.read_text(encoding="utf-8")
        if f'"{lang_code}"' in text:
            already += 1
        elif apply_macos.LANG_LIST_RE.search(text):
            matched += 1
    return {
        "assetIndexFiles": len(files),
        "whitelistPatchable": matched,
        "languageAlreadyRegistered": already,
        "ok": bool(matched or already),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Diagnose Claude Desktop macOS localization compatibility.")
    parser.add_argument("--app", type=Path, default=apply_macos.APP_DEFAULT, help="Path to Claude.app")
    parser.add_argument("--lang", choices=["zh-CN", "zh-TW", "zh-HK"], default="zh-CN", help="Language code to diagnose")
    args = parser.parse_args()

    app = args.app.expanduser()
    config = apply_macos.get_language_config(args.lang)
    report = {
        "app": str(app),
        "language": args.lang,
        "appFound": app.is_dir(),
        "frontendI18nFound": (app / apply_macos.FRONTEND_I18N_REL).is_dir(),
        "frontendEnUsFound": (app / apply_macos.FRONTEND_I18N_REL / "en-US.json").is_file(),
        "desktopEnUsFound": (app / apply_macos.DESKTOP_RESOURCES_REL / "en-US.json").is_file(),
        "assetsFound": (app / apply_macos.FRONTEND_ASSETS_REL).is_dir(),
        "appAsarFound": (app / apply_macos.APP_ASAR_REL).is_file(),
        "resourceFilesFound": {
            "frontend": config["frontend_translation"].is_file(),
            "hardcoded": config["frontend_hardcoded"].is_file(),
            "desktop": config["desktop_translation"].is_file(),
            "localizable": config["localizable_strings"].is_file(),
            "statsig": config["statsig_translation"].is_file(),
        },
    }
    report["languageWhitelist"] = analyze_language_whitelist(app, args.lang) if app.is_dir() else {"ok": False}
    report["recommendation"] = "APPLY_OK" if (
        report["appFound"]
        and report["frontendI18nFound"]
        and report["frontendEnUsFound"]
        and report["desktopEnUsFound"]
        and report["assetsFound"]
        and all(report["resourceFilesFound"].values())
        and report["languageWhitelist"]["ok"]
    ) else "NEEDS_MAINTENANCE"

    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0 if report["recommendation"] == "APPLY_OK" else 1


if __name__ == "__main__":
    raise SystemExit(main())
