@echo off
chcp 65001 >nul 2>&1

if "%CLAUDE_ZH_ELEVATED%"=="1" goto elevated

echo 正在请求管理员权限...
set "CLAUDE_ZH_DIR=%~dp0"
set "CLAUDE_ZH_BAT=%~nx0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $q=[char]34; $dir=$env:CLAUDE_ZH_DIR; $bat=$env:CLAUDE_ZH_BAT; $cmd='/k set ' + $q + 'CLAUDE_ZH_ELEVATED=1' + $q + ' && pushd ' + $q + $dir + $q + ' && call ' + $q + $bat + $q; Start-Process -FilePath 'cmd.exe' -ArgumentList $cmd -Verb RunAs -ErrorAction Stop; exit 0 } catch { Write-Host $_.Exception.Message; exit 1 }"
if errorlevel 1 (
    echo 请求管理员权限失败。
    pause
    exit /b 1
)
exit /b

:elevated
set "CLAUDE_ZH_ELEVATED="
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\apply_windows.ps1" -Interactive
set EXITCODE=%ERRORLEVEL%
echo.
pause
exit /b %EXITCODE%
