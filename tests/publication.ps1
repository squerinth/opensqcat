[CmdletBinding()]
param(
	[Parameter(Mandatory = $true)][string]$FixtureRoot,
	[Parameter(Mandatory = $true)][string]$VerificationLog
)
$ErrorActionPreference = 'Stop'
$prepare = Join-Path $FixtureRoot 'tools/prepare-publication.ps1'
$publish = Join-Path $FixtureRoot 'tools/publish-github-release.ps1'
$output = Join-Path $FixtureRoot 'build/publication'
$version = (Get-Content -LiteralPath (Join-Path $FixtureRoot 'VERSION') -Raw).Trim()
$null = & $prepare -Kind Nightly -RefName main -VerificationLog $VerificationLog
$nightly = Get-Content -LiteralPath (Join-Path $output 'manifest.json') -Raw | ConvertFrom-Json
if (-not $nightly.prerelease -or $nightly.tag -notmatch '^nightly-\d{8}T\d{6}Z-[a-f0-9]{12}$' -or -not $nightly.asset.Contains($nightly.tag)) { throw 'Nightly identity is invalid.' }
$notes = Get-Content -LiteralPath (Join-Path $output 'notes.md') -Raw
if ($notes -notmatch 'Stability is not guaranteed' -or -not $notes.Contains($nightly.commit) -or $notes -notmatch 'NVGT .+ commit [a-f0-9]{40}') { throw 'Nightly notes lack stability or provenance information.' }
$firstManifest = Get-Content -LiteralPath (Join-Path $output 'manifest.json') -Raw
$null = & $prepare -Kind Nightly -RefName main -VerificationLog $VerificationLog
if ((Get-Content -LiteralPath (Join-Path $output 'manifest.json') -Raw) -cne $firstManifest) { throw 'Nightly identity changes on retry.' }

# Replace GitHub CLI only in this test scope; no network or releases are created.
$publicationTestState = @{ calls = @(); existing = '[]'; failOperation = '' }
function gh {
	$publicationTestState.calls += ,@($args)
	$global:LASTEXITCODE = 0
	if ($args[1] -eq $publicationTestState.failOperation) { $global:LASTEXITCODE = 1; return }
	if ($args[1] -eq 'list') { return $publicationTestState.existing }
}
$null = & $publish -BundleDirectory $output
if (($publicationTestState.calls | ForEach-Object { $_[1] }) -join ',' -cne 'list,create,upload,edit') { throw 'Publication must upload to a draft before publishing.' }
if ('--prerelease' -notin $publicationTestState.calls[1] -or '--latest=false' -notin $publicationTestState.calls[3]) { throw 'Nightly must be a prerelease and never Latest.' }
$publicationTestState.existing = ConvertTo-Json -InputObject @(@{tagName = 'unrelated'; isDraft = $true}, @{tagName = $nightly.tag; isDraft = $false})
$publicationTestState.calls = @()
$null = & $publish -BundleDirectory $output
if ($publicationTestState.calls.Count -ne 1) { throw 'Retry modified a published release.' }
$publicationTestState.existing = @(@{tagName = $nightly.tag; isDraft = $true}) | ConvertTo-Json
$publicationTestState.calls = @()
$null = & $publish -BundleDirectory $output
if (($publicationTestState.calls | ForEach-Object { $_[1] }) -join ',' -cne 'list,upload,edit') { throw 'Retry did not resume a draft.' }
$publicationTestState.existing = '[]'
foreach ($operation in @('list', 'create', 'upload')) {
	$publicationTestState.failOperation = $operation
	$publicationTestState.calls = @()
	$failed = $false
	try { $null = & $publish -BundleDirectory $output } catch { $failed = $true }
	if (-not $failed -or @($publicationTestState.calls | Where-Object { $_[1] -eq 'edit' }).Count -gt 0) { throw "Failure in $operation did not stop publication." }
}
$publicationTestState.failOperation = ''
$null = & $prepare -Kind Stable -RefName "v$version" -VerificationLog $VerificationLog
$stable = Get-Content -LiteralPath (Join-Path $output 'manifest.json') -Raw | ConvertFrom-Json
if ($stable.prerelease -or $stable.tag -cne "v$version" -or $stable.asset -cne "opensqcat-$version.zip") { throw 'Stable identity is invalid.' }
$publicationTestState.calls = @()
$null = & $publish -BundleDirectory $output
if ('--verify-tag' -notin $publicationTestState.calls[1] -or '--latest' -notin $publicationTestState.calls[3] -or '--prerelease=false' -notin $publicationTestState.calls[3]) { throw 'Stable publication flags are incorrect.' }
$failed = $false
try { $null = & $prepare -Kind Stable -RefName 'v999.0.0' -VerificationLog $VerificationLog } catch { $failed = $true }
if (-not $failed) { throw 'Mismatched stable tag was accepted.' }
$publicationTestState.calls = @()
Add-Content -LiteralPath (Join-Path $output $stable.asset) -Value 'corruption'
$failed = $false
try { $null = & $publish -BundleDirectory $output } catch { $failed = $true }
if (-not $failed -or $publicationTestState.calls.Count -ne 0) { throw 'Corrupt archive reached GitHub.' }
Write-Output 'PASS: nightly/stable identity, notes, checksums, publication flags, retries and failed uploads'
