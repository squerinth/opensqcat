[CmdletBinding()]
param(
    [string]$NvgtPath = $env:NVGT_EXE,
    [string]$BuildDirectory
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
if ([string]::IsNullOrWhiteSpace($NvgtPath)) {
    $NvgtPath = 'nvgt.exe'
}
if (Test-Path -LiteralPath $NvgtPath -PathType Leaf) {
    $NvgtPath = (Resolve-Path -LiteralPath $NvgtPath).Path
}
else {
    $NvgtPath = (Get-Command $NvgtPath -ErrorAction Stop).Source
}
if ([string]::IsNullOrWhiteSpace($BuildDirectory)) {
    $BuildDirectory = Join-Path $projectRoot 'build'
}
$buildRoot = [IO.Path]::GetFullPath($BuildDirectory)
$runRoot = Join-Path $buildRoot ([guid]::NewGuid().ToString('N'))
$packageRoot = Join-Path $runRoot 'standalone'
$tempRoot = Join-Path $runRoot 'tmp'
New-Item -ItemType Directory -Force -Path $packageRoot, $tempRoot | Out-Null
# Execute a standalone copy. Every include and fixture must travel with it.
foreach ($directory in @('src', 'tests', 'examples', 'doc', 'tools')) {
    Copy-Item -LiteralPath (Join-Path $projectRoot $directory) -Destination $packageRoot -Recurse
}
foreach ($file in @('README.md', 'LICENSE', '.gitignore')) {
    Copy-Item -LiteralPath (Join-Path $projectRoot $file) -Destination $packageRoot
}
$fixtures = Join-Path $packageRoot 'tests/fixtures'
New-Item -ItemType Directory -Force -Path $fixtures | Out-Null
[IO.File]::WriteAllBytes((Join-Path $fixtures 'invalid_utf8.sqcat'), [byte[]](107, 61, 255, 10))
$previousTemp = $env:TEMP
$previousTmp = $env:TMP
try {
    $env:TEMP = $tempRoot
    $env:TMP = $tempRoot
    & $NvgtPath -w 2 (Join-Path $packageRoot 'tests/contracts.nvgt')
    if ($LASTEXITCODE -ne 0) {
        throw "OpenSQCat contracts failed (exit $LASTEXITCODE). Artifacts: $runRoot"
    }
    & $NvgtPath -w 2 (Join-Path $packageRoot 'examples/messages.nvgt')
    if ($LASTEXITCODE -ne 0) {
        throw "OpenSQCat example failed (exit $LASTEXITCODE). Artifacts: $runRoot"
    }
    # The README's complete program is an executable documentation contract.
    Copy-Item -LiteralPath (Join-Path $packageRoot 'examples/locales') -Destination $packageRoot -Recurse
    $readme = Get-Content -LiteralPath (Join-Path $packageRoot 'README.md') -Raw
    $blocks = [regex]::Matches($readme, '(?s)```nvgt\r?\n(.*?)```')
    $programCount = 0
    foreach ($block in $blocks) {
        if ($block.Groups[1].Value -notmatch 'void main\(') {
            continue
        }
        $programCount++
        $programPath = Join-Path $packageRoot "readme_example_$programCount.nvgt"
        [IO.File]::WriteAllText($programPath, $block.Groups[1].Value, [Text.UTF8Encoding]::new($false))
        & $NvgtPath -w 2 $programPath
        if ($LASTEXITCODE -ne 0) {
            throw "OpenSQCat README example failed (exit $LASTEXITCODE). Artifacts: $runRoot"
        }
    }
    if ($programCount -eq 0) {
        throw 'No complete README example was found.'
    }
    $packagePrefix = [IO.Path]::GetFullPath($packageRoot).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    $linkCount = 0
    foreach ($document in Get-ChildItem -LiteralPath $packageRoot -Filter '*.md' -File -Recurse) {
        $content = Get-Content -LiteralPath $document.FullName -Raw
        foreach ($link in [regex]::Matches($content, '\[[^\]]*\]\(([^)]+)\)')) {
            $target = $link.Groups[1].Value
            if ($target -match '^https?://') {
                continue
            }
            $parts = $target.Split('#', 2)
            $targetPath = if ($parts[0].Length -eq 0) {
                $document.FullName
            }
            else {
                [IO.Path]::GetFullPath((Join-Path $document.DirectoryName $parts[0]))
            }
            if (-not $targetPath.StartsWith($packagePrefix, [StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $targetPath -PathType Leaf)) {
                throw "Broken or nonlocal documentation link in $($document.FullName): $target"
            }
            if ($parts.Length -gt 1) {
                $targetText = Get-Content -LiteralPath $targetPath -Raw
                $anchors = @([regex]::Matches($targetText, '(?m)^#{1,6} +([^\r\n]+)') | ForEach-Object {
                    $heading = $_.Groups[1].Value.ToLowerInvariant() -replace '[^\p{L}\p{N}_\-\s]', ''
                    $heading.Trim() -replace '\s+', '-'
                })
                if ($parts[1] -notin $anchors) {
                    throw "Broken documentation fragment in $($document.FullName): $target"
                }
            }
            $linkCount++
        }
    }
    $includeCount = 0
    foreach ($script in Get-ChildItem -LiteralPath $packageRoot -Filter '*.nvgt' -File -Recurse) {
        $content = Get-Content -LiteralPath $script.FullName -Raw
        foreach ($include in [regex]::Matches($content, '(?m)^\s*#include "([^"]+)"')) {
            $targetPath = [IO.Path]::GetFullPath((Join-Path $script.DirectoryName $include.Groups[1].Value))
            if (-not $targetPath.StartsWith($packagePrefix, [StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $targetPath -PathType Leaf)) {
                throw "Nonlocal or missing include in $($script.FullName): $($include.Groups[1].Value)"
            }
            $includeCount++
        }
    }
    Write-Output "PASS: $linkCount documentation links and $includeCount local includes"
    Write-Output "Standalone package verified. Artifacts: $runRoot"
}
finally {
    $env:TEMP = $previousTemp
    $env:TMP = $previousTmp
}
