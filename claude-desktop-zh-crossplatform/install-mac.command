#!/bin/bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
PYTHON="/usr/bin/python3"
PATCHER="$DIR/scripts/apply_macos.py"

if [ ! -x "$PYTHON" ]; then
  PYTHON="$(command -v python3)"
fi

echo "Claude Desktop 中文语言包"
echo
echo "请选择操作："
echo "  [1] 安装中文语言包（默认安全模式，不修改 app.asar）"
echo "  [2] 安装中文语言包 + Advanced app.asar 补丁"
echo "  [3] 恢复最近备份 / 卸载补丁"
read -rp "请输入选项 [1/2/3，默认 1]: " action_choice

ADVANCED_ARG=""
ACTION="install"
case "${action_choice:-1}" in
  2) ADVANCED_ARG="--advanced-asar-patch" ;;
  3) ACTION="restore" ;;
esac

LANG_CODE="zh-CN"
if [ "$ACTION" = "install" ]; then
  echo
  echo "请选择语言："
  echo "  [1] 简体中文"
  echo "  [2] 繁体中文（中国台湾）"
  echo "  [3] 繁体中文（中国香港）"
  read -rp "请输入选项 [1/2/3，默认 1]: " lang_choice
  case "${lang_choice:-1}" in
    2) LANG_CODE="zh-TW" ;;
    3) LANG_CODE="zh-HK" ;;
  esac
fi

USER_HOME="$HOME"
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
  USER_HOME="$("$PYTHON" -c 'import pwd, sys; print(pwd.getpwnam(sys.argv[1]).pw_dir)' "$SUDO_USER" 2>/dev/null || true)"
fi

if [ "$(id -u)" -ne 0 ]; then
  echo "需要管理员权限来替换 /Applications/Claude.app。"
  if [ "$ACTION" = "restore" ]; then
    sudo "$PYTHON" "$DIR/scripts/rollback_macos.py" --user-home "$HOME" --backup latest --launch
  else
    sudo "$PYTHON" "$PATCHER" --user-home "$HOME" --lang "$LANG_CODE" --launch ${ADVANCED_ARG:+"$ADVANCED_ARG"}
  fi
else
  if [ "$ACTION" = "restore" ]; then
    "$PYTHON" "$DIR/scripts/rollback_macos.py" --user-home "$USER_HOME" --backup latest --launch
  else
    "$PYTHON" "$PATCHER" --user-home "$USER_HOME" --lang "$LANG_CODE" --launch ${ADVANCED_ARG:+"$ADVANCED_ARG"}
  fi
fi

echo
echo "完成。按回车退出。"
read -r _
