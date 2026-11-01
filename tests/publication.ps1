[CmdletBinding()]
param(
	[Parameter(Mandatory = $true)][string]$FixtureRoot,
	[Parameter(Mandatory = $true)][string]$NvgtPath
)
$ErrorActionPreference = 'Stop'
$caseRoot = Join-Path $FixtureRoot 'build/version-cases'
New-Item -ItemType Directory -Force -Path $caseRoot | Out-Null
foreach ($item in @('src', 'examples', 'doc', 'tests', 'tools', 'README.md', 'CONTRIBUTING.md', 'CHANGELOG.md', 'VERSION', 'LICENSE', '.gitignore')) {
	Copy-Item -LiteralPath (Join-Path $FixtureRoot $item) -Destination $caseRoot -Recurse
}
$FixtureRoot = $caseRoot
$utf8 = [Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllText((Join-Path $FixtureRoot 'VERSION'), '0.2.0', $utf8)
[IO.File]::WriteAllText((Join-Path $FixtureRoot 'CHANGELOG.md'), "# Changelog`n`n## Unreleased`n`nChanges for the next version.`n`n## 0.1.0`n`nPrevious stable release.`n", $utf8)
& git -C $FixtureRoot init --quiet
& git -C $FixtureRoot -c core.autocrlf=false add .
& git -C $FixtureRoot -c user.name='Version verification' -c user.email='verification@example.invalid' -c commit.gpgsign=false commit --quiet -m 'Development ahead of stable'
if ($LASTEXITCODE -ne 0) { throw 'Cannot create version test fixture.' }
$VerificationLog = Join-Path $FixtureRoot 'build/verification.log'
function Build-PublicationFixture([string]$Kind) {
	$results = @(& (Join-Path $FixtureRoot 'tools/release.ps1') -NvgtPath $NvgtPath -Revision HEAD -Kind $Kind -SkipGlobalInstallationCheck)
	New-Item -ItemType Directory -Force -Path (Split-Path $VerificationLog -Parent) | Out-Null
	[IO.File]::WriteAllText($VerificationLog, ($results -join "`n"), $utf8)
}
function Get-PackageReadme() {
	Add-Type -AssemblyName System.IO.Compression.FileSystem
	$zip = [IO.Compression.ZipFile]::OpenRead((Join-Path $FixtureRoot 'release/opensqcat-0.2.0.zip'))
	try {
		$reader = [IO.StreamReader]::new($zip.GetEntry('README.md').Open())
		try { return $reader.ReadToEnd() } finally { $reader.Dispose() }
	} finally { $zip.Dispose() }
}
Build-PublicationFixture 'Nightly'
if (-not (Get-PackageReadme).Contains('Nightly build targeting **0.2.0**')) { throw 'Nightly README does not distinguish target from stable.' }
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
$staleLog = Join-Path $FixtureRoot 'build/stale-verification.log'
$wrongChecksumLog = [regex]::Replace([IO.File]::ReadAllText($VerificationLog), '(?m)^SHA256: [a-f0-9]{64}', ('SHA256: ' + ('f' * 64)))
[IO.File]::WriteAllText($staleLog, $wrongChecksumLog, $utf8)
$failed = $false
try { $null = & $prepare -Kind Nightly -RefName main -VerificationLog $staleLog } catch { $failed = $_.Exception.Message -match 'archive checksum' }
if (-not $failed) { throw 'Publication accepted a log for different archive bytes.' }
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
$failed = $false
try { $null = & $prepare -Kind Stable -RefName "v$version" -VerificationLog $VerificationLog } catch { $failed = $_.Exception.Message -match 'changelog section' }
if (-not $failed) { throw 'Stable publication accepted an unreleased target without release notes.' }
$beforeFailedStable = (Get-FileHash (Join-Path $FixtureRoot "release/opensqcat-$version.zip")).Hash
$failed = $false
try { $null = & (Join-Path $FixtureRoot 'tools/release.ps1') -NvgtPath $NvgtPath -Revision HEAD -Kind Stable -SkipGlobalInstallationCheck } catch { $failed = $_.Exception.Message -match 'changelog section' }
if (-not $failed -or (Get-FileHash (Join-Path $FixtureRoot "release/opensqcat-$version.zip")).Hash -cne $beforeFailedStable) { throw 'Stable package gate accepted missing notes or replaced the verified nightly.' }
[IO.File]::WriteAllText((Join-Path $FixtureRoot 'CHANGELOG.md'), "# Changelog`n`n## Unreleased`n`n## 0.2.0`n`nCompleted new release.`n`n## 0.1.0`n`nPrevious stable release.`n", $utf8)
& git -C $FixtureRoot add CHANGELOG.md
& git -C $FixtureRoot -c user.name='Version verification' -c user.email='verification@example.invalid' -c commit.gpgsign=false commit --quiet -m 'Prepare stable release notes'
if ($LASTEXITCODE -ne 0) { throw 'Cannot prepare stable test notes.' }
Build-PublicationFixture 'Nightly'
$failed = $false
try { $null = & $prepare -Kind Stable -RefName "v$version" -VerificationLog $VerificationLog } catch { $failed = $_.Exception.Message -match 'package kind' }
if (-not $failed) { throw 'A verified nightly was promoted to stable without stable verification.' }
Build-PublicationFixture 'Stable'
if (-not (Get-PackageReadme).Contains('Stable release **0.2.0**')) { throw 'Stable README does not identify its actual version.' }
$failed = $false
try { $null = & $prepare -Kind Nightly -RefName main -VerificationLog $VerificationLog } catch { $failed = $_.Exception.Message -match 'package kind' }
if (-not $failed) { throw 'A verified stable package was relabeled as nightly.' }
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
Write-Output 'PASS: development ahead of stable, channel-specific README/notes, package provenance, publication flags, retries and failures'
