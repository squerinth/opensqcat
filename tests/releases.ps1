[CmdletBinding()]
param([string]$NvgtPath = $env:NVGT_EXE, [switch]$KeepArtifacts)
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($NvgtPath)) { $NvgtPath = 'nvgt.exe' }
if (Test-Path -LiteralPath $NvgtPath -PathType Leaf) {
	$NvgtPath = (Resolve-Path -LiteralPath $NvgtPath).Path
} else { $NvgtPath = (Get-Command $NvgtPath -ErrorAction Stop).Source }
$root = Split-Path $PSScriptRoot -Parent
. (Join-Path $root 'tools/temporary.ps1')
$probe = Join-Path $root ('build/r-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
$retentionOptions = @{}
$retentionArguments = @()
if ($KeepArtifacts) { $retentionOptions.KeepArtifacts = $true; $retentionArguments = @('-KeepArtifacts') }
try {
	New-Item -ItemType Directory -Path $probe | Out-Null
	foreach ($item in @('src', 'tests', 'examples', 'doc', 'tools', '.github', 'README.md', 'CONTRIBUTING.md', 'CHANGELOG.md', 'VERSION', 'LICENSE', 'AGENTS.md', '.gitignore')) {
		Copy-Item -LiteralPath (Join-Path $root $item) -Destination $probe -Recurse
	}
	$utf8 = [Text.UTF8Encoding]::new($false)
	foreach ($workspace in @('build', 'release', '.agent-work')) {
		New-Item -ItemType Directory -Path (Join-Path $probe $workspace) | Out-Null
		[IO.File]::WriteAllText((Join-Path $probe "$workspace/.gitkeep"), '', $utf8)
		[IO.File]::WriteAllText((Join-Path $probe "$workspace/internal-note.md"), 'Must never enter Git or a release.', $utf8)
	}
	[IO.File]::WriteAllText((Join-Path $probe 'development-only.txt'), 'Must never enter a release.', $utf8)
	& git -C $probe init --quiet
	& git -C $probe -c core.autocrlf=false add .
	& git -C $probe -c user.name='Release verification' -c user.email='verification@example.invalid' -c commit.gpgsign=false commit --quiet -m 'Release tool fixture'
	if ($LASTEXITCODE -ne 0) { throw 'Cannot create disposable verification commit.' }
	$buildDirectory = Join-Path $probe 'build/release-tests'
	$tool = Join-Path $probe 'tools/release.ps1'
	$results = @(& $tool @retentionOptions -SkipGlobalInstallationCheck -NvgtPath $NvgtPath -Revision HEAD -BuildDirectory $buildDirectory)
	$results | Write-Output
	if (@($results | Where-Object { $_ -ceq 'PASS: global installation' }).Count -ne 0) { throw 'Packaging regression repeated the global installation check.' }
	if (-not $KeepArtifacts -and @(Get-ChildItem -LiteralPath $buildDirectory -Directory).Count -ne 0) { throw 'Successful release retained temporary directories.' }
	$version = (Get-Content -LiteralPath (Join-Path $probe 'VERSION') -Raw).Trim()
	$archive = Join-Path $probe "release/opensqcat-$version.zip"
	if (-not (Test-Path -LiteralPath $archive -PathType Leaf)) { throw 'Finished ZIP is not in release/.' }
	$firstHash = (Get-FileHash -LiteralPath $archive).Hash
	$null = & $tool @retentionOptions -SkipGlobalInstallationCheck -NvgtPath $NvgtPath -Revision HEAD -BuildDirectory $buildDirectory
	if ((Get-FileHash -LiteralPath $archive).Hash -cne $firstHash) { throw 'Repeated releases of the same commit differ.' }
	$sidecar = Get-Content -LiteralPath "$archive.sha256" -Raw
	if (-not $sidecar.StartsWith($firstHash.ToLowerInvariant())) { throw 'Release checksum does not match.' }
	Add-Type -AssemblyName System.IO.Compression.FileSystem
	$zip = [IO.Compression.ZipFile]::OpenRead($archive)
	try {
		$entries = @($zip.Entries.FullName)
		foreach ($entry in $entries) {
			if ($entry -notmatch '^(opensqcat/(docs/|opensqcat/|opensqcat\.nvgt$|LICENSE$)|examples/|opensqcat\.nvgt$|README\.md$)') {
				throw "Forbidden release content or intermediate directory: $entry"
			}
		}
		$roots = @($entries | ForEach-Object { $_.Split('/')[0] } | Sort-Object -Unique)
		if ($roots.Count -ne 4 -or @($roots | Where-Object { $_ -notin @('opensqcat', 'examples', 'opensqcat.nvgt', 'README.md') }).Count) { throw 'ZIP must contain exactly the four distribution entries.' }
		foreach ($required in @('opensqcat/opensqcat.nvgt', 'opensqcat.nvgt', 'README.md', 'opensqcat/LICENSE', 'examples/messages.nvgt', 'opensqcat/docs/README.md', 'opensqcat/docs/api/README.md', 'opensqcat/docs/tutorials/README.md', 'opensqcat/docs/advanced/README.md')) {
			if ($required -notin $entries) { throw "Release omits root content: $required" }
		}
	} finally { $zip.Dispose() }
	$trackedOutputs = @(& git -C $probe ls-files -- build release .agent-work)
	$placeholders = @('.agent-work/.gitkeep', 'build/.gitkeep', 'release/.gitkeep')
	if ($trackedOutputs.Count -ne 3 -or @($trackedOutputs | Where-Object { $_ -notin $placeholders }).Count -ne 0) { throw 'Workspace directories must track only their empty placeholders.' }
	& git -C $probe check-ignore --quiet 'build/temporary.txt'
	if ($LASTEXITCODE -ne 0) { throw 'build/ is not ignored.' }
	& git -C $probe check-ignore --quiet "release/opensqcat-$version.zip"
	if ($LASTEXITCODE -ne 0) { throw 'release/ is not ignored.' }
	foreach ($workspace in @('build', 'release', '.agent-work')) {
		& git -C $probe check-ignore --no-index --quiet "$workspace/.gitkeep"
		if ($LASTEXITCODE -ne 1) { throw "Workspace placeholder is ignored: $workspace" }
		& git -C $probe check-ignore --quiet "$workspace/internal-note.md"
		if ($LASTEXITCODE -ne 0) { throw "Workspace contents are not ignored: $workspace" }
	}
	Write-Output 'PASS: release/ output, exact allowlist, checksums, repeatability and Git ignores'
	& (Join-Path $PSScriptRoot 'publication.ps1') -FixtureRoot $probe -NvgtPath $NvgtPath

	# A failed release must not replace a previously verified artifact.
	[IO.File]::WriteAllText((Join-Path $probe '.gitattributes'), "/doc/tutorials/first-catalog.md export-ignore`n", $utf8)
	& git -C $probe add .gitattributes
	& git -C $probe -c user.name='Release verification' -c user.email='verification@example.invalid' -c commit.gpgsign=false commit --quiet -m 'Probe omitted documentation'
	if ($LASTEXITCODE -ne 0) { throw 'Cannot prepare omitted-documentation test.' }
	$ErrorActionPreference = 'Continue'
	$failure = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $tool @retentionArguments -SkipGlobalInstallationCheck -NvgtPath $NvgtPath -Revision HEAD -BuildDirectory $buildDirectory 2>&1)
	$failedExit = $LASTEXITCODE
	$ErrorActionPreference = 'Stop'
	if ($failedExit -eq 0 -or ($failure -join "`n") -notmatch 'Release omits documentation') { throw 'Incomplete documentation was not rejected.' }
	if ((Get-FileHash -LiteralPath $archive).Hash -cne $firstHash) { throw 'Failed run replaced a verified release.' }
	Write-Output 'PASS: omitted documentation rejected; previous release preserved'
	if (-not $KeepArtifacts -and @(Get-ChildItem -LiteralPath $buildDirectory -Directory).Count -ne 0) { throw 'Failed release retained temporary directories.' }

	[IO.File]::WriteAllText((Join-Path $probe '.gitattributes'), "/LICENSE export-ignore`n", $utf8)
	& git -C $probe add .gitattributes
	& git -C $probe -c user.name='Release verification' -c user.email='verification@example.invalid' -c commit.gpgsign=false commit --quiet -m 'Probe omitted license'
	if ($LASTEXITCODE -ne 0) { throw 'Cannot prepare omitted-license test.' }
	$ErrorActionPreference = 'Continue'
	$failure = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $tool @retentionArguments -SkipGlobalInstallationCheck -NvgtPath $NvgtPath -Revision HEAD -BuildDirectory $buildDirectory 2>&1)
	$failedExit = $LASTEXITCODE
	$ErrorActionPreference = 'Stop'
	if ($failedExit -eq 0 -or ($failure -join "`n") -notmatch 'Release omits license') { throw 'Missing license was not rejected.' }
	if ((Get-FileHash -LiteralPath $archive).Hash -cne $firstHash) { throw 'License failure replaced a verified release.' }
	Write-Output 'PASS: omitted license rejected; previous release preserved'

	# Default mode must include local documentation changes without requiring a commit.
	$workingDocument = Join-Path $probe 'doc/advanced/README.md'
	[IO.File]::AppendAllText($workingDocument, "`nWorking-tree release fixture.`n", $utf8)
	$null = & powershell -NoProfile -ExecutionPolicy Bypass -File $tool @retentionArguments -SkipGlobalInstallationCheck -NvgtPath $NvgtPath -BuildDirectory $buildDirectory
	if ($LASTEXITCODE -ne 0) { throw 'Default release failed in a fresh PowerShell process.' }
	$zip = [IO.Compression.ZipFile]::OpenRead($archive)
	try {
		$entry = $zip.GetEntry('opensqcat/docs/advanced/README.md')
		$reader = [IO.StreamReader]::new($entry.Open())
		try { $workingText = $reader.ReadToEnd() } finally { $reader.Dispose() }
		if (-not $workingText.Contains('Working-tree release fixture.')) { throw 'Default release omitted local changes.' }
	} finally { $zip.Dispose() }
	Write-Output 'PASS: default release includes current working-tree documentation'
	if (-not $KeepArtifacts -and @(Get-ChildItem -LiteralPath $buildDirectory -Directory).Count -ne 0) { throw 'Repeated releases accumulated temporary directories.' }
	Write-Output 'PASS: successful and failed release staging cleaned automatically'
	if ($KeepArtifacts) { Write-Output "Verified archive retained: $archive" }
} finally {
	if ($KeepArtifacts) { Write-Output "Artifacts retained: $probe" } else { Remove-TemporaryDirectory $probe (Join-Path $root 'build') }
}
