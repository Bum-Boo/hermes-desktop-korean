$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$apply = Join-Path $repoRoot 'scripts/apply-localization.ps1'
$fixtureRoot = Join-Path $repoRoot ('.verification/apply-tests-' + [guid]::NewGuid().ToString('N'))
$fixtureRoot = [IO.Path]::GetFullPath($fixtureRoot)
$verificationRoot = [IO.Path]::GetFullPath((Join-Path $repoRoot '.verification'))
if (-not $fixtureRoot.StartsWith($verificationRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Fixture outside verification root' }
[IO.Directory]::CreateDirectory($fixtureRoot) | Out-Null
$encoding = [Text.UTF8Encoding]::new($false)
function Assert($condition, $message) { if (-not $condition) { throw $message } }
function New-Fixture($name) {
    $target = Join-Path $fixtureRoot $name
    $i18n = Join-Path $target 'apps/desktop/src/i18n'
    [IO.Directory]::CreateDirectory($i18n) | Out-Null
    $ja = -join [char[]]@(0x65E5, 0x672C, 0x8A9E)
    $data = @{
        'types.ts' = "export type Locale = 'en' | 'zh' | 'zh-hant' | 'ja' | 'ar'`n"
        'catalog.ts' = "import { ja } from './ja'`nconst catalog = {`n  ja,`n  ar`n}`n"
        'languages.ts' = "  {`n    id: 'ja',`n    name: '$ja',`n    englishName: 'Japanese',`n    configValue: 'ja'`n  },`n  ja_jp: 'ja',`n  ar: 'ar',`n"
        'ko.ts' = 'previous Korean source'
        'languages.test.ts' = "    expect(normalizeLocale('ja-JP')).toBe('ja')`n    expect(isSupportedLocaleValue('ja-JP')).toBe(true)`n    expect(isLocale('ja')).toBe(true)`n    expect(localeConfigValue('ja')).toBe('ja')`n"
    }
    foreach ($name in $data.Keys) { [IO.File]::WriteAllText((Join-Path $i18n $name), $data[$name], $encoding) }
    return $target
}
function Snapshot($target) {
    $result = @{}
    Get-ChildItem -LiteralPath (Join-Path $target 'apps/desktop/src/i18n') -File | ForEach-Object { $result[$_.Name] = [Convert]::ToBase64String([IO.File]::ReadAllBytes($_.FullName)) }
    return $result
}
function Assert-Unchanged($target, $before) {
    $after = Snapshot $target
    Assert ($before.Count -eq $after.Count) 'Fixture file count changed'
    foreach ($name in $before.Keys) { Assert ($before[$name] -eq $after[$name]) "Original bytes changed: $name" }
}
try {
    $target = New-Fixture 'readonly failure'
    $before = Snapshot $target
    $locale = Join-Path $target 'apps/desktop/src/i18n/ko.ts'
    [IO.File]::SetAttributes($locale, [IO.FileAttributes]::ReadOnly)
    $failed = $false
    try { & $apply -HermesRepo $target } catch { $failed = $true }
    finally { [IO.File]::SetAttributes($locale, [IO.FileAttributes]::Normal) }
    Assert $failed 'Read-only destination should fail'
    Assert-Unchanged $target $before
    Write-Host 'PASS: late write failure preserves all previous bytes'

    $target = New-Fixture 'what if'
    $before = Snapshot $target
    & $apply -HermesRepo $target -WhatIf
    Assert-Unchanged $target $before
    Write-Host 'PASS: WhatIf preserves all files'

    $target = New-Fixture 'successful install'
    & $apply -HermesRepo $target
    $first = Snapshot $target
    $sourceLocale = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $repoRoot 'src/i18n/ko.ts')))
    Assert ($first['ko.ts'] -eq $sourceLocale) 'Installed Korean source differs'
    Assert ([IO.File]::ReadAllText((Join-Path $target 'apps/desktop/src/i18n/types.ts')).Contains("'ja' | 'ko' | 'ar'")) 'Locale type not registered'
    & $apply -HermesRepo $target
    Assert-Unchanged $target $first
    Write-Host 'PASS: successful install is complete and repeatable'

    $target = New-Fixture 'upstream mismatch'
    $types = Join-Path $target 'apps/desktop/src/i18n/types.ts'
    [IO.File]::WriteAllText($types, 'incompatible upstream source', $encoding)
    $before = Snapshot $target
    $failed = $false
    try { & $apply -HermesRepo $target } catch { $failed = $true }
    Assert $failed 'Upstream mismatch should fail'
    Assert-Unchanged $target $before
    Write-Host 'PASS: incompatible upstream rejected before writes'
} finally {
    if (-not $fixtureRoot.StartsWith($verificationRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe fixture cleanup' }
    Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
}
