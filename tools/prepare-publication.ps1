[CmdletBinding()]
param(
	[Parameter(Mandatory = $true)][ValidateSet('Nightly', 'Stable')][string]$Kind,
	[Parameter(Mandatory = $true)][string]$RefName,
	[Parameter(Mandatory = $true)][string]$VerificationLog,
	[string]$OutputDirectory
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'versioning.ps1')
$root = Split-Path $PSScriptRoot -Parent
$version = Get-SourceVersion $root
if ($Kind -eq 'Stable' -and $RefName -cne "v$version") { throw 'Stable tag must match VERSION exactly.' }
if ($Kind -eq 'Nightly' -and $RefName -cne 'main') { throw 'Nightlies must come from main.' }
$stableNotes = if ($Kind -eq 'Stable') { Get-StableReleaseNotes $root $version } else { '' }
$commit = & git -C $root rev-parse HEAD
if ($LASTEXITCODE -ne 0) { throw 'Cannot resolve publication commit.' }
$commit = $commit.Trim()
$commitTime = & git -C $root show -s --format=%cI HEAD
if ($LASTEXITCODE -ne 0) { throw 'Cannot read commit date.' }
$stamp = [DateTimeOffset]::Parse($commitTime.Trim()).ToUniversalTime().ToString("yyyyMMdd'T'HHmmss'Z'")
$log = Get-Content -LiteralPath $VerificationLog -Raw
if ($log -notmatch '(?m)^NVGT ([^\r\n]+) commit ([a-fA-F0-9]{40})\r?$') { throw 'Verification log must identify the tested NVGT build.' }
$compiler = "NVGT $($Matches[1]) commit $($Matches[2])"
if (-not $log.Contains("Verified OpenSQCat $version from commit $commit")) { throw 'Verification log does not confirm this source commit.' }
if ($log -notmatch "(?m)^Package kind: $([regex]::Escape($Kind))\r?$") { throw 'Verified package kind does not match the publication channel.' }
$nightly = $Kind -eq 'Nightly'
$tag = if ($nightly) { "nightly-$stamp-$($commit.Substring(0, 12))" } else { "v$version" }
$title = if ($nightly) { "OpenSQCat $tag" } else { "OpenSQCat $version" }
$assetName = if ($nightly) { "opensqcat-$version-$tag.zip" } else { "opensqcat-$version.zip" }
$archive = Join-Path $root "release/opensqcat-$version.zip"
$hash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
if ($log -notmatch "(?m)^SHA256: $hash\r?$") { throw 'Verification log does not identify this archive checksum.' }
$sidecar = (Get-Content -LiteralPath "$archive.sha256" -Raw).Trim()
if ($sidecar -cne "$hash  opensqcat-$version.zip") { throw 'Verified archive checksum does not match.' }
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) { $OutputDirectory = Join-Path $root 'build/publication' }
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$utf8 = [Text.UTF8Encoding]::new($false)
Copy-Item -LiteralPath $archive -Destination (Join-Path $OutputDirectory $assetName) -Force
[IO.File]::WriteAllText((Join-Path $OutputDirectory "$assetName.sha256"), "$hash  $assetName`n", $utf8)
$description = if ($nightly) {
	"Automated development build from main targeting $version. This target is not an announcement of a stable release. Stability is not guaranteed."
} else {
	$stableNotes
}
$notes = "$description`n`nSource commit: $commit`n`nVerified with $compiler (Latest/Bleeding Edge Development Version at build time).`n`nDownload the ZIP asset and its SHA-256 checksum below. The ZIP is ready to install; GitHub's source archives contain the repository layout.`n"
[IO.File]::WriteAllText((Join-Path $OutputDirectory 'notes.md'), $notes, $utf8)
$manifest = [ordered]@{ tag = $tag; title = $title; commit = $commit; prerelease = $nightly; asset = $assetName; sha256 = $hash }
[IO.File]::WriteAllText((Join-Path $OutputDirectory 'manifest.json'), ($manifest | ConvertTo-Json), $utf8)
Write-Output "Prepared $tag in $OutputDirectory"
