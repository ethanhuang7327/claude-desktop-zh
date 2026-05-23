# Claude Desktop 中文化跨平台稳定方案

这个工具为 Claude Desktop macOS / Windows 安装中文语言资源，默认只做低侵入语言包汉化。`app.asar` 相关补丁需要显式选择 Advanced 模式。

## 支持内容

- 语言：`zh-CN`、`zh-TW`、`zh-HK`
- 资源：前端 i18n、桌面壳层 i18n、statsig i18n、macOS `Localizable.strings`
- 默认安全模式：写入 locale、注册语言白名单、替换前端硬编码 UI 文案
- Advanced 模式：额外 patch `app.asar`，用于 3P gateway 模型名校验修复和主进程菜单文案

## macOS

```bash
chmod +x ./install-mac.command
./install-mac.command
```

命令行：

```bash
sudo /usr/bin/python3 scripts/diagnose_macos.py --app /Applications/Claude.app --lang zh-CN
sudo /usr/bin/python3 scripts/apply_macos.py --lang zh-CN --user-home "$HOME" --dry-run
sudo /usr/bin/python3 scripts/apply_macos.py --lang zh-CN --user-home "$HOME" --launch
sudo /usr/bin/python3 scripts/apply_macos.py --lang zh-CN --advanced-asar-patch --user-home "$HOME" --launch
sudo /usr/bin/python3 scripts/rollback_macos.py --backup latest --user-home "$HOME" --launch
```

macOS 安装会复制 `/Applications/Claude.app` 到临时目录后修改，重签名并校验，再替换原 app。替换前会保留完整备份，回滚默认恢复最近备份，不删除其他备份。

## Windows

右键管理员运行：

```text
install-windows.bat
```

命令行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\diagnose_windows.ps1 -Language zh-CN
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\apply_windows.ps1 install zh-CN
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\apply_windows.ps1 -AdvancedAsarPatch install zh-CN
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\rollback_windows.ps1
```

Windows 安装会扫描 `WindowsApps\Claude_*`，选择可用安装目录。修改 JS/CSS 后会将对应 `.zst` 改名为 `.bak`，避免 Claude 加载压缩缓存覆盖补丁。

## 更新后的维护流程

1. Claude Desktop 更新后先运行 diagnose。
2. 如果显示 `APPLY_OK`，重新运行安装。
3. 如果显示 `NEEDS_MAINTENANCE`，不要强行安装；需要更新补丁匹配或翻译资源。
4. 用 `scan_missing.py` 扫描新版本英文候选：

```bash
python3 scripts/scan_missing.py --assets "/path/to/ion-dist/assets/v1" --output locales/missing.json
```

`missing.json` 只作为人工确认清单，不应全量自动替换。

## 设计原则

- 默认目标是稳定中文语言包汉化，不默认修改 Claude 业务逻辑。
- `app.asar` patch 属于高风险 Advanced 功能，必须显式开启。
- 不能保证未来任意 Claude 版本无需维护；稳定性来自诊断、停止、备份、回滚和快速更新。
