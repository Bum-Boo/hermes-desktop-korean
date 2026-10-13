[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [string]$HermesRepo
)

$ErrorActionPreference = 'Stop'
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$resolvedRepo = (Resolve-Path -LiteralPath $HermesRepo).Path
$i18nDir = Join-Path $resolvedRepo 'apps\desktop\src\i18n'
$sourceKo = Join-Path $PSScriptRoot '..\src\i18n\ko.ts'
$sourceKo = [System.IO.Path]::GetFullPath($sourceKo)

$paths = @{
    Catalog = Join-Path $i18nDir 'catalog.ts'
    Languages = Join-Path $i18nDir 'languages.ts'
    LanguageTests = Join-Path $i18nDir 'languages.test.ts'
    Locale = Join-Path $i18nDir 'ko.ts'
    Types = Join-Path $i18nDir 'types.ts'
}

foreach ($requiredPath in @($paths.Catalog, $paths.Languages, $paths.Types, $sourceKo)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Required file was not found: $requiredPath"
    }
}

function Read-Utf8File([string]$Path) {
    return [System.IO.File]::ReadAllText($Path, $utf8NoBom).Replace("`r`n", "`n")
}

function Install-LocaleFiles([array]$Updates) {
    $backupDirectory = [IO.Path]::GetFullPath((Join-Path $i18nDir ('.ko-install-' + [guid]::NewGuid().ToString('N'))))
    $targetDirectory = [IO.Path]::GetFullPath($i18nDir)
    if (-not $backupDirectory.StartsWith($targetDirectory + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Backup directory is outside the localization target.'
    }
    [IO.Directory]::CreateDirectory($backupDirectory) | Out-Null
    $attempted = [Collections.Generic.List[object]]::new()
    $keepBackup = $false
    try {
        # Capture every previous file before writing any registration file.
        for ($index = 0; $index -lt $Updates.Count; $index++) {
            $update = $Updates[$index]
            $update | Add-Member -NotePropertyName Backup -NotePropertyValue (Join-Path $backupDirectory "$index.bin")
            $exists = Test-Path -LiteralPath $update.Path
            if ($exists -and -not (Test-Path -LiteralPath $update.Path -PathType Leaf)) {
                throw "Destination is not a regular file: $($update.Path)"
            }
            $update | Add-Member -NotePropertyName HadPrevious -NotePropertyValue $exists
            if ($exists) { [IO.File]::WriteAllBytes($update.Backup, [IO.File]::ReadAllBytes($update.Path)) }
        }
        $Updates | Select-Object Path, Backup, HadPrevious | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $backupDirectory 'recovery.json') -Encoding UTF8
        try {
            foreach ($update in $Updates) {
                # A failed write can be partial, so include the attempted file.
                $attempted.Add($update)
                [IO.File]::WriteAllBytes($update.Path, $update.Bytes)
            }
        } catch {
            $installError = $_
            $restoreFailures = [Collections.Generic.List[string]]::new()
            for ($index = $attempted.Count - 1; $index -ge 0; $index--) {
                $update = $attempted[$index]
                try {
                    if ($update.HadPrevious) {
                        $previous = [IO.File]::ReadAllBytes($update.Backup)
                        $unchanged = [IO.File]::Exists($update.Path) -and ([Convert]::ToBase64String([IO.File]::ReadAllBytes($update.Path)) -eq [Convert]::ToBase64String($previous))
                        if (-not $unchanged) { [IO.File]::WriteAllBytes($update.Path, $previous) }
                    } else {
                        [IO.File]::Delete($update.Path)
                    }
                } catch { $restoreFailures.Add($update.Path) }
            }
            if ($restoreFailures.Count) {
                $keepBackup = $true
                throw "Installation failed and restoration was incomplete. Previous files and recovery.json are preserved at: $backupDirectory"
            }
            throw $installError
        }
    } finally {
        if (-not $keepBackup) {
            if (-not $backupDirectory.StartsWith($targetDirectory + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe backup cleanup.' }
            Remove-Item -LiteralPath $backupDirectory -Recurse -Force
        }
    }
}

function Replace-ExactOnce {
    param(
        [string]$Content,
        [string]$Old,
        [string]$New,
        [string]$Label
    )

    if ($Content.Contains($New)) {
        return $Content
    }

    $first = $Content.IndexOf($Old, [System.StringComparison]::Ordinal)
    if ($first -lt 0) {
        throw "Could not find the expected $Label block (needle length: $($Old.Length), content length: $($Content.Length)). The upstream source may have changed."
    }

    $second = $Content.IndexOf($Old, $first + $Old.Length, [System.StringComparison]::Ordinal)
    if ($second -ge 0) {
        throw "Found more than one $Label block; refusing an ambiguous edit."
    }

    return $Content.Substring(0, $first) + $New + $Content.Substring($first + $Old.Length)
}

$types = Read-Utf8File $paths.Types
$types = Replace-ExactOnce $types `
    "export type Locale = 'en' | 'zh' | 'zh-hant' | 'ja' | 'ar'" `
    "export type Locale = 'en' | 'zh' | 'zh-hant' | 'ja' | 'ko' | 'ar'" `
    'Locale union'

$catalog = Read-Utf8File $paths.Catalog
$catalog = Replace-ExactOnce $catalog `
    "import { ja } from './ja'" `
    "import { ja } from './ja'`nimport { ko } from './ko'" `
    'Korean catalog import'
$catalog = Replace-ExactOnce $catalog `
    "  ja,`n  ar" `
    "  ja,`n  ko,`n  ar" `
    'Korean catalog entry'

$languages = Read-Utf8File $paths.Languages
$japaneseName = -join [char[]]@(0x65E5, 0x672C, 0x8A9E)
$koreanName = -join [char[]]@(0xD55C, 0xAD6D, 0xC5B4)
$japaneseOption = "  {`n    id: 'ja',`n    name: '$japaneseName',`n    englishName: 'Japanese',`n    configValue: 'ja'`n  },"
$koreanOption = $japaneseOption + "`n  {`n    id: 'ko',`n    name: '$koreanName',`n    englishName: 'Korean',`n    configValue: 'ko'`n  },"
$languages = Replace-ExactOnce -Content $languages -Old $japaneseOption -New $koreanOption -Label 'Korean locale option'
$languages = Replace-ExactOnce $languages `
    "  ja_jp: 'ja',`n  ar: 'ar'," `
    "  ja_jp: 'ja',`n  ko: 'ko',`n  'ko-kr': 'ko',`n  ko_kr: 'ko',`n  korean: 'ko',`n  ${koreanName}: 'ko',`n  ar: 'ar'," `
    'Korean locale aliases'

$tests = $null
if (Test-Path -LiteralPath $paths.LanguageTests -PathType Leaf) {
    $tests = Read-Utf8File $paths.LanguageTests
    $tests = Replace-ExactOnce $tests `
        "    expect(normalizeLocale('ja-JP')).toBe('ja')" `
        "    expect(normalizeLocale('ja-JP')).toBe('ja')`n    expect(normalizeLocale('ko')).toBe('ko')`n    expect(normalizeLocale('KO-KR')).toBe('ko')`n    expect(normalizeLocale(' $koreanName ')).toBe('ko')" `
        'Korean normalization tests'
    $tests = Replace-ExactOnce $tests `
        "    expect(isSupportedLocaleValue('ja-JP')).toBe(true)" `
        "    expect(isSupportedLocaleValue('ja-JP')).toBe(true)`n    expect(isSupportedLocaleValue('ko-KR')).toBe(true)" `
        'Korean supported-locale test'
    $tests = Replace-ExactOnce $tests `
        "    expect(isLocale('ja')).toBe(true)" `
        "    expect(isLocale('ja')).toBe(true)`n    expect(isLocale('ko')).toBe(true)" `
        'Korean exact-locale test'
    $tests = Replace-ExactOnce $tests `
        "    expect(localeConfigValue('ja')).toBe('ja')" `
        "    expect(localeConfigValue('ja')).toBe('ja')`n    expect(localeConfigValue('ko')).toBe('ko')" `
        'Korean config-value test'
}

$applied = $false
if ($PSCmdlet.ShouldProcess($i18nDir, 'Install the Korean locale and register it with Hermes Desktop')) {
    $updates = @(
        [pscustomobject]@{ Path = $paths.Types; Bytes = $utf8NoBom.GetBytes($types) }
        [pscustomobject]@{ Path = $paths.Catalog; Bytes = $utf8NoBom.GetBytes($catalog) }
        [pscustomobject]@{ Path = $paths.Languages; Bytes = $utf8NoBom.GetBytes($languages) }
        [pscustomobject]@{ Path = $paths.Locale; Bytes = [IO.File]::ReadAllBytes($sourceKo) }
    )
    if ($null -ne $tests) {
        $updates += [pscustomobject]@{ Path = $paths.LanguageTests; Bytes = $utf8NoBom.GetBytes($tests) }
    }
    Install-LocaleFiles $updates
    $applied = $true
}

if ($applied) {
    Write-Host 'Hermes Desktop Korean localization was applied.' -ForegroundColor Green
    Write-Host "Target: $resolvedRepo"
    Write-Host 'Next: install dependencies and run the Hermes Desktop typecheck/build from the upstream repository.'
}
