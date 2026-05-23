$ErrorActionPreference = "Stop"

$scriptPath = Join-Path $PSScriptRoot "apply_windows.ps1"
& $scriptPath uninstall zh-CN
exit $LASTEXITCODE
