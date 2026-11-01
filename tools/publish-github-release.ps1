[CmdletBinding()]
param([Parameter(Mandatory = $true)][string]$BundleDirectory)
$ErrorActionPreference = 'Stop'
$bundle = [IO.Path]::GetFullPath($BundleDirectory)
$manifest = Get-Content -LiteralPath (Join-Path $bundle 'manifest.json') -Raw | ConvertFrom-Json
if ($manifest.tag -notmatch '^(v\d+\.\d+\.\d+|nightly-\d{8}T\d{6}Z-[a-f0-9]{12})$' -or $manifest.commit -notmatch '^[a-f0-9]{40}$' -or $manifest.asset -notmatch '^opensqcat-[a-zA-Z0-9.\-]+\.zip$' -or $manifest.prerelease -isnot [bool]) {
	throw 'Invalid publication manifest.'
}
$archive = Join-Path $bundle $manifest.asset
$checksum = "$archive.sha256"
$hash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
if ($hash -cne $manifest.sha256 -or (Get-Content -LiteralPath $checksum -Raw).Trim() -cne "$hash  $($manifest.asset)") { throw 'Publication checksum mismatch.' }
$notes = Join-Path $bundle 'notes.md'
if (-not (Test-Path -LiteralPath $notes -PathType Leaf)) { throw 'Missing release notes.' }
# Listing must succeed: a network/authentication error is not a missing release.
$releases = @(& gh release list --limit 1000 --json tagName,isDraft)
if ($LASTEXITCODE -ne 0) { throw 'Cannot query GitHub releases.' }
$releaseList = $releases -join "`n" | ConvertFrom-Json
$existing = @($releaseList | Where-Object { $_.tagName -ceq $manifest.tag })
if ($existing.Count -gt 0 -and -not $existing[0].isDraft) {
	Write-Output "Release $($manifest.tag) is already published; leaving its assets unchanged."
	return
}
if ($existing.Count -eq 0) {
	$createArguments = @('release', 'create', $manifest.tag, '--target', $manifest.commit, '--title', $manifest.title, '--notes-file', $notes, '--draft', '--latest=false')
	if ($manifest.prerelease) { $createArguments += '--prerelease' } else { $createArguments += '--verify-tag' }
	& gh @createArguments
	if ($LASTEXITCODE -ne 0) { throw 'Cannot create GitHub draft release.' }
}
& gh release upload $manifest.tag $archive $checksum --clobber
if ($LASTEXITCODE -ne 0) { throw 'Asset upload failed; release remains a draft.' }
$latest = if ($manifest.prerelease) { '--latest=false' } else { '--latest' }
$prerelease = if ($manifest.prerelease) { '--prerelease=true' } else { '--prerelease=false' }
& gh release edit $manifest.tag --title $manifest.title --notes-file $notes --draft=false $prerelease $latest
if ($LASTEXITCODE -ne 0) { throw 'Cannot publish GitHub release.' }
