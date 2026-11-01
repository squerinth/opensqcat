[CmdletBinding()]
param(
	[string]$NvgtPath = $env:NVGT_EXE,
	[string]$Revision,
	[string]$BuildDirectory,
	[switch]$SkipGlobalInstallationCheck,
	[switch]$KeepArtifacts
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'temporary.ps1')
$projectRoot = Split-Path $PSScriptRoot -Parent
if ([string]::IsNullOrWhiteSpace($BuildDirectory)) {
	$BuildDirectory = Join-Path $projectRoot 'build'
}
$buildRoot = [IO.Path]::GetFullPath($BuildDirectory)
$runRoot = Join-Path $buildRoot ('release-' + [guid]::NewGuid().ToString('N'))
$staging = Join-Path $runRoot 'staging'
$retentionOptions = @{}
if ($KeepArtifacts) { $retentionOptions.KeepArtifacts = $true }
if (-not $SkipGlobalInstallationCheck) { $retentionOptions.CheckGlobalInstallation = $true }
try {
	New-Item -ItemType Directory -Force -Path $staging | Out-Null
	$snapshotRoot = Join-Path $runRoot 'source'
	if ([string]::IsNullOrWhiteSpace($Revision)) {
		New-Item -ItemType Directory -Path $snapshotRoot | Out-Null
		foreach ($item in @('src', 'examples', 'doc', 'tests', 'tools', 'README.md', 'CONTRIBUTING.md', 'CHANGELOG.md', 'VERSION', 'LICENSE', '.gitignore')) {
			Copy-Item -LiteralPath (Join-Path $projectRoot $item) -Destination $snapshotRoot -Recurse
		}
		$sourceDescription = 'working-tree snapshot (local changes included)'
		$documentPrefix = [IO.Path]::GetFullPath((Join-Path $snapshotRoot 'doc')).TrimEnd('\') + '\'
		$documents = @(Get-ChildItem -LiteralPath (Join-Path $snapshotRoot 'doc') -File -Recurse -Force | ForEach-Object { 'doc/' + $_.FullName.Substring($documentPrefix.Length).Replace('\', '/') })
		$archiveTime = [DateTimeOffset]::Parse('1980-01-01T00:00:00Z')
	} else {
		$commit = & git -C $projectRoot rev-parse --verify "${Revision}^{commit}"
		if ($LASTEXITCODE -ne 0) { throw 'Cannot resolve release commit.' }
		$commit = $commit.Trim()
		$sourceArchive = Join-Path $staging 'source.zip'
		& git -C $projectRoot archive --format=zip "--output=$sourceArchive" $commit
		if ($LASTEXITCODE -ne 0) { throw 'Cannot archive release commit.' }
		Expand-Archive -LiteralPath $sourceArchive -DestinationPath $snapshotRoot
		$documents = @(& git -C $projectRoot ls-tree -r --name-only $commit -- doc)
		if ($LASTEXITCODE -ne 0) { throw 'Cannot enumerate release documentation.' }
		$commitTime = & git -C $projectRoot show -s --format=%cI $commit
		if ($LASTEXITCODE -ne 0) { throw 'Cannot read release commit timestamp.' }
		$archiveTime = [DateTimeOffset]::Parse($commitTime.Trim()).ToUniversalTime()
		$sourceDescription = "commit $commit"
	}
	$version = (Get-Content -LiteralPath (Join-Path $snapshotRoot 'VERSION') -Raw -Encoding UTF8).Trim()
	if ($version -notmatch '^\d+\.\d+\.\d+$') { throw 'VERSION must contain major.minor.patch.' }
	$releaseName = "opensqcat-$version"
	$releaseRoot = Join-Path $staging $releaseName
	New-Item -ItemType Directory -Path $releaseRoot | Out-Null

	# A release exposes the installable folder promised by the README.
	$sourcePrefix = [IO.Path]::GetFullPath($releaseRoot).TrimEnd('\') + '\'
	Copy-Item -LiteralPath (Join-Path $snapshotRoot 'src') -Destination (Join-Path $releaseRoot 'opensqcat') -Recurse
	foreach ($directory in @('examples', 'doc')) {
		Copy-Item -LiteralPath (Join-Path $snapshotRoot $directory) -Destination $releaseRoot -Recurse
	}
	foreach ($file in @('README.md', 'LICENSE')) {
		Copy-Item -LiteralPath (Join-Path $snapshotRoot $file) -Destination $releaseRoot
	}
	$utf8 = [Text.UTF8Encoding]::new($false)
	foreach ($script in @('examples/messages.nvgt')) {
		$path = Join-Path $releaseRoot $script
		$content = [IO.File]::ReadAllText($path)
		if (-not $content.Contains('#include "../src/opensqcat.nvgt"')) {
			throw "Expected repository include missing in $script"
		}
		[IO.File]::WriteAllText($path, $content.Replace('#include "../src/opensqcat.nvgt"', '#include "../opensqcat/opensqcat.nvgt"'), $utf8)
	}
	[IO.File]::WriteAllText((Join-Path $releaseRoot 'opensqcat.nvgt'), "#include `"opensqcat/opensqcat.nvgt`"`n", $utf8)

	if ($documents.Count -eq 0) { throw 'Release must contain documentation.' }
	foreach ($required in @('doc/README.md', 'doc/api/README.md', 'doc/tutorials/README.md', 'doc/advanced/README.md') + $documents) {
		if (-not (Test-Path -LiteralPath (Join-Path $releaseRoot $required) -PathType Leaf)) {
			throw "Release omits documentation: $required"
		}
	}

	# Stable entry order and timestamps make identical inputs repeatable.
	$archive = Join-Path $runRoot "$releaseName.zip"
	Add-Type -AssemblyName System.IO.Compression.FileSystem
	Add-Type -AssemblyName System.IO.Compression
	$paths = [string[]]@(Get-ChildItem -LiteralPath $releaseRoot -File -Recurse -Force | ForEach-Object { $_.FullName.Substring($sourcePrefix.Length) })
	[Array]::Sort($paths, [StringComparer]::Ordinal)
	$stream = [IO.File]::Open($archive, [IO.FileMode]::CreateNew)
	$zip = [IO.Compression.ZipArchive]::new($stream, [IO.Compression.ZipArchiveMode]::Create)
	try {
		foreach ($relativePath in $paths) {
			$entry = $zip.CreateEntry($relativePath.Replace('\', '/'), [IO.Compression.CompressionLevel]::Optimal)
			$entry.LastWriteTime = $archiveTime
			$entryInput = [IO.File]::OpenRead((Join-Path $releaseRoot $relativePath))
			$entryOutput = $entry.Open()
			try { $entryInput.CopyTo($entryOutput) } finally { $entryOutput.Dispose(); $entryInput.Dispose() }
		}
	} finally {
		$zip.Dispose()
		$stream.Dispose()
	}
	$extracted = Join-Path $runRoot 'extracted'
	Expand-Archive -LiteralPath $archive -DestinationPath $extracted
	$sourceRoot = $extracted
	foreach ($document in $documents) {
		$original = Join-Path $releaseRoot $document
		$packaged = Join-Path $sourceRoot $document
		if (-not (Test-Path -LiteralPath $packaged -PathType Leaf) -or (Get-FileHash -LiteralPath $original).Hash -cne (Get-FileHash -LiteralPath $packaged).Hash) {
			throw "Packaged documentation differs: $document"
		}
	}
	if ([string]::IsNullOrWhiteSpace($NvgtPath)) {
		$NvgtPath = & (Join-Path $snapshotRoot 'tools/get-nvgt.ps1') -BuildDirectory (Join-Path $buildRoot 'toolchain')
	}
	# Keep tests and tools in staging; run them against the actual extracted release.
	& (Join-Path $snapshotRoot 'tools/test.ps1') @retentionOptions -NvgtPath $NvgtPath -BuildDirectory (Join-Path $runRoot 'verify') -DistributionPath $sourceRoot
	$checksum = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
	$releaseDirectory = Join-Path $projectRoot 'release'
	New-Item -ItemType Directory -Force -Path $releaseDirectory | Out-Null
	$finishedArchive = Join-Path $releaseDirectory "$releaseName.zip"
	Copy-Item -LiteralPath $archive -Destination $finishedArchive -Force
	[IO.File]::WriteAllText("$finishedArchive.sha256", "$checksum  $([IO.Path]::GetFileName($finishedArchive))`n", $utf8)
	Write-Output "Verified OpenSQCat $version from $sourceDescription"
	Write-Output "Archive: $finishedArchive"
	Write-Output "SHA256: $checksum"
} finally {
	if ($KeepArtifacts) { Write-Output "Artifacts retained: $runRoot" } else { Remove-TemporaryDirectory $runRoot $buildRoot }
}
