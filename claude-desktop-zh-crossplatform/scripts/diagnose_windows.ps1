param(
    [ValidateSet("zh-CN", "zh-TW", "zh-HK")]
    [string]$Language = "zh-CN"
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$baseLanguageList = '["en-US","de-DE","fr-FR","ko-KR","ja-JP","es-419","es-ES","it-IT","hi-IN","pt-BR","id-ID"'
$languageListPattern = [System.Text.RegularExpressions.Regex]::Escape($baseLanguageList) + '(?:(?:,"zh-CN")|(?:,"zh-TW")|(?:,"zh-HK"))*\]'

function Find-ClaudePath {
    $packages = @(Get-AppxPackage -Name "Claude" -ErrorAction SilentlyContinue)
    foreach ($package in $packages) {
        if ($package.InstallLocation -and (Test-Path $package.InstallLocation)) {
            return $package.InstallLocation
        }
    }

    $fallback = Get-ChildItem "C:\Program Files\WindowsApps\Claude_*" -Directory -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if ($fallback) { return $fallback.FullName }
    return $null
}

function Get-ProjectRoot {
    return [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
}

try {
    $claudePath = Find-ClaudePath
    $resourcesPath = if ($claudePath) { Join-Path $claudePath "app\resources" } else { $null }
    $assetsDir = if ($resourcesPath) { Join-Path $resourcesPath "ion-dist\assets\v1" } else { $null }
    $i18nDir = if ($resourcesPath) { Join-Path $resourcesPath "ion-dist\i18n" } else { $null }
    $projectResources = Join-Path (Get-ProjectRoot) "resources"

    $indexFiles = @()
    if ($assetsDir -and (Test-Path $assetsDir -PathType Container)) {
        $indexFiles = @(Get-ChildItem (Join-Path $assetsDir "index-*.js") -File -ErrorAction SilentlyContinue)
    }

    $patchable = 0
    $registered = 0
    $regex = [regex]::new($languageListPattern)
    foreach ($file in $indexFiles) {
        $text = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
        if ($text.Contains("`"$Language`"")) {
            $registered += 1
        }
        elseif ($regex.IsMatch($text)) {
            $patchable += 1
        }
    }

    $resourceFiles = [ordered]@{
        frontend = Test-Path (Join-Path $projectResources "frontend-$Language.json") -PathType Leaf
        hardcoded = Test-Path (Join-Path $projectResources "frontend-hardcoded-$Language.json") -PathType Leaf
        desktop = Test-Path (Join-Path $projectResources "desktop-$Language.json") -PathType Leaf
        statsig = Test-Path (Join-Path $projectResources "statsig-$Language.json") -PathType Leaf
    }

    $ok = (
        $claudePath -and
        (Test-Path $resourcesPath -PathType Container) -and
        (Test-Path $i18nDir -PathType Container) -and
        (Test-Path $assetsDir -PathType Container) -and
        (Test-Path (Join-Path $i18nDir "en-US.json") -PathType Leaf) -and
        (Test-Path (Join-Path $resourcesPath "en-US.json") -PathType Leaf) -and
        (($patchable + $registered) -gt 0) -and
        (-not ($resourceFiles.Values -contains $false))
    )

    $report = [ordered]@{
        language = $Language
        claudePath = $claudePath
        resourcesPath = $resourcesPath
        resourcesFound = [bool]($resourcesPath -and (Test-Path $resourcesPath -PathType Container))
        i18nFound = [bool]($i18nDir -and (Test-Path $i18nDir -PathType Container))
        assetsFound = [bool]($assetsDir -and (Test-Path $assetsDir -PathType Container))
        assetIndexFiles = $indexFiles.Count
        whitelistPatchable = $patchable
        languageAlreadyRegistered = $registered
        resourceFilesFound = $resourceFiles
        recommendation = if ($ok) { "APPLY_OK" } else { "NEEDS_MAINTENANCE" }
    }

    $report | ConvertTo-Json -Depth 8
    if ($ok) { exit 0 }
    exit 1
}
catch {
    Write-Host "Diagnose failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
