#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path

import apply_macos


def main() -> int:
    parser = argparse.ArgumentParser(description="Restore a Claude Desktop macOS backup.")
    parser.add_argument("--app", type=Path, default=apply_macos.APP_DEFAULT, help="Path to Claude.app")
    parser.add_argument("--user-home", type=Path, default=Path.home(), help="Home directory whose Claude config should be reset")
    parser.add_argument("--backup", default="latest", help="Backup to restore: latest or an explicit .app path")
    parser.add_argument("--dry-run", action="store_true", help="Print restore actions without modifying the installed app")
    parser.add_argument("--launch", action="store_true", help="Launch Claude after restore")
    args = parser.parse_args()

    if args.dry_run:
        print("[dry-run] Claude will not be quit.")
    else:
        apply_macos.quit_claude()

    restored = apply_macos.restore_backup(args.app.expanduser(), args.backup, args.dry_run)
    if args.dry_run:
        print(f"[dry-run] Would set Claude config locale under: {args.user_home} to en-US")
        return 0

    apply_macos.set_user_locale(args.user_home.expanduser(), "en-US")
    print(f"Restored from backup: {restored}")
    if args.launch:
        apply_macos.run(["open", "-a", str(args.app.expanduser())], check=False)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
