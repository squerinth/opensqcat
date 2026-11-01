[CmdletBinding()]
param(
	[string]$NvgtPath = $env:NVGT_EXE,
	[string]$BuildDirectory,
	[string]$DistributionPath,
	[switch]$CheckGlobalInstallation,
	[switch]$KeepArtifacts
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'temporary.ps1')
$projectRoot = Split-Path $PSScriptRoot -Parent
if ([string]::IsNullOrWhiteSpace($NvgtPath)) {
	$NvgtPath = 'nvgt.exe'
}
if (Test-Path -LiteralPath $NvgtPath -PathType Leaf) {
	$NvgtPath = (Resolve-Path -LiteralPath $NvgtPath).Path
} else {
	$NvgtPath = (Get-Command $NvgtPath -ErrorAction Stop).Source
}
if ([string]::IsNullOrWhiteSpace($BuildDirectory)) {
	$BuildDirectory = Join-Path $projectRoot 'build'
}
$buildRoot = [IO.Path]::GetFullPath($BuildDirectory)
$runRoot = Join-Path $buildRoot ([guid]::NewGuid().ToString('N'))
$packageRoot = Join-Path $runRoot 'standalone'
$tempRoot = Join-Path $runRoot 'tmp'
$previousTemp = $env:TEMP
$previousTmp = $env:TMP
try {
	New-Item -ItemType Directory -Force -Path $packageRoot, $tempRoot | Out-Null
	$inputRoot = if ([string]::IsNullOrWhiteSpace($DistributionPath)) { $projectRoot } else { [IO.Path]::GetFullPath($DistributionPath) }
	$libraryDirectory = if (Test-Path -LiteralPath (Join-Path $inputRoot 'src/opensqcat.nvgt') -PathType Leaf) { 'src' } else { 'opensqcat' }
	if (-not (Test-Path -LiteralPath (Join-Path $inputRoot "$libraryDirectory/opensqcat.nvgt") -PathType Leaf)) {
		throw 'Cannot find repository source or release library folder.'
	}
	# Execute a standalone copy. Every include and fixture must travel with it.
	foreach ($directory in @($libraryDirectory, 'examples', 'doc')) {
		Copy-Item -LiteralPath (Join-Path $inputRoot $directory) -Destination $packageRoot -Recurse
	}
	foreach ($directory in @('tests', 'tools')) {
		Copy-Item -LiteralPath (Join-Path $projectRoot $directory) -Destination $packageRoot -Recurse
	}
	foreach ($file in @('README.md', 'LICENSE')) {
		Copy-Item -LiteralPath (Join-Path $inputRoot $file) -Destination $packageRoot
	}
	foreach ($file in @('CONTRIBUTING.md', 'CHANGELOG.md', 'VERSION', '.gitignore')) {
		Copy-Item -LiteralPath (Join-Path $projectRoot $file) -Destination $packageRoot
	}
	$contractPath = Join-Path $packageRoot 'tests/contracts.nvgt'
	$contract = [IO.File]::ReadAllText($contractPath).Replace('#include "../src/opensqcat.nvgt"', "#include `"../$libraryDirectory/opensqcat.nvgt`"")
	[IO.File]::WriteAllText($contractPath, $contract, [Text.UTF8Encoding]::new($false))
	$fixtures = Join-Path $packageRoot 'tests/fixtures'
	New-Item -ItemType Directory -Force -Path $fixtures | Out-Null
	[IO.File]::WriteAllBytes((Join-Path $fixtures 'invalid_utf8.sqcat'), [byte[]](107, 61, 255, 10))

	function Test-DocumentationProgram([string]$DocumentPath, [string]$WorkingDirectory, [string]$Compiler, [switch]$GlobalInclude) {
		$document = Get-Content -LiteralPath $DocumentPath -Raw -Encoding UTF8
		$catalogs = [regex]::Matches($document, '(?s)```properties\r?\n(.*?)```')
		$programs = @([regex]::Matches($document, '(?s)```nvgt\r?\n(.*?)```') | Where-Object { $_.Groups[1].Value -match 'void main\(' })
		$outputs = [regex]::Matches($document, '(?s)```text\r?\n(.*?)```')
		if ($catalogs.Count -ne 1 -or $programs.Count -ne 1 -or $outputs.Count -ne 1) {
			throw "Expected one catalog, complete program and output in $DocumentPath"
		}
		$locales = Join-Path $WorkingDirectory 'locales'
		New-Item -ItemType Directory -Force -Path $locales | Out-Null
		$utf8 = [Text.UTF8Encoding]::new($false)
		[IO.File]::WriteAllText((Join-Path $locales 'en.sqcat'), $catalogs[0].Groups[1].Value, $utf8)
		$program = $programs[0].Groups[1].Value
		if ($GlobalInclude) {
			$program = $program.Replace('#include "opensqcat/opensqcat.nvgt"', '#include "opensqcat.nvgt"')
		} else {
			Copy-Item -LiteralPath (Join-Path $inputRoot $libraryDirectory) -Destination (Join-Path $WorkingDirectory 'opensqcat') -Recurse
		}
		$programPath = Join-Path $WorkingDirectory 'main.nvgt'
		[IO.File]::WriteAllText($programPath, $program, $utf8)
		$actualOutput = @(& $Compiler -w 2 $programPath)
		if ($LASTEXITCODE -ne 0) { throw "Documentation program failed: $DocumentPath. Rerun with -KeepArtifacts to retain diagnostics." }
		$expectedOutput = ($outputs[0].Groups[1].Value -replace '\r\n', "`n").TrimEnd("`n")
		if (($actualOutput -join "`n") -cne $expectedOutput) {
			throw "Documentation program output differs from its documented result: $DocumentPath. Rerun with -KeepArtifacts to retain diagnostics."
		}
		$actualOutput | Write-Output
	}
	$env:TEMP = $tempRoot
	$env:TMP = $tempRoot
	& $NvgtPath -w 2 (Join-Path $packageRoot 'tests/contracts.nvgt')
	if ($LASTEXITCODE -ne 0) {
		throw "OpenSQCat contracts failed (exit $LASTEXITCODE). Rerun with -KeepArtifacts to retain diagnostics."
	}
	# These programs must not compile: snapshots cannot expose parsed records,
	# and an evaluator subclass must not intercept their rendering.
	$isolationProbes = @(
		'void main() { opensqcat::catalog source; dictionary@ exposed = source.snapshot(); }',
		'void main() { opensqcat::catalog source; opensqcat::catalog@ captured = source.snapshot(); dictionary exposed = captured.entries; }',
		'class interceptor : opensqcat::detail::evaluation {} void main() {}'
	)
	for ($probeIndex = 0; $probeIndex -lt $isolationProbes.Count; $probeIndex++) {
		$probePath = Join-Path $packageRoot "tests/isolation-$probeIndex.nvgt"
		$probeSource = "#pragma console`n#include `"../$libraryDirectory/opensqcat.nvgt`"`n" + $isolationProbes[$probeIndex]
		[IO.File]::WriteAllText($probePath, $probeSource, [Text.UTF8Encoding]::new($false))
		$probeOutput = @(& $NvgtPath -w 2 $probePath)
		if ($LASTEXITCODE -eq 0 -or ($probeOutput -join "`n") -notmatch 'ERROR:') {
			throw "Catalog isolation probe $probeIndex was not rejected by the compiler. Rerun with -KeepArtifacts to retain diagnostics."
		}
	}
	Write-Output 'PASS: mutable snapshot access and evaluator interception rejected'
	$exampleOutput = @(& $NvgtPath -w 2 (Join-Path $packageRoot 'examples/messages.nvgt'))
	if ($LASTEXITCODE -ne 0) {
		throw "OpenSQCat example failed (exit $LASTEXITCODE). Rerun with -KeepArtifacts to retain diagnostics."
	}
	$exampleOutput | Write-Output
	$liveTutorial = Get-Content -LiteralPath (Join-Path $packageRoot 'doc/tutorials/live-values.md') -Raw -Encoding UTF8
	$liveExpected = [regex]::Match($liveTutorial, '(?s)```text\r?\n(.*?)```')
	if (-not $liveExpected.Success -or ($exampleOutput -join "`n") -cne ($liveExpected.Groups[1].Value -replace '\r\n', "`n").TrimEnd("`n")) {
		throw 'Console example output differs from the live-values tutorial.'
	}
	# Test the README's catalog and program together, without example fixtures.
	$readme = Get-Content -LiteralPath (Join-Path $packageRoot 'README.md') -Raw -Encoding UTF8
	$version = (Get-Content -LiteralPath (Join-Path $packageRoot 'VERSION') -Raw -Encoding UTF8).Trim()
	$changelog = Get-Content -LiteralPath (Join-Path $packageRoot 'CHANGELOG.md') -Raw -Encoding UTF8
	if ($version -notmatch '^\d+\.\d+\.\d+$' -or -not $readme.Contains("Version **$version**") -or $changelog -notmatch "(?m)^## $([regex]::Escape($version))\r?$") {
		throw 'VERSION, README version and changelog release heading must agree.'
	}
	Test-DocumentationProgram (Join-Path $packageRoot 'README.md') (Join-Path $packageRoot 'readme-project') $NvgtPath
	Test-DocumentationProgram (Join-Path $packageRoot 'doc/tutorials/first-catalog.md') (Join-Path $packageRoot 'tutorial-project') $NvgtPath

	Write-Output 'PASS: project installation; README and tutorial outputs'
	if ($CheckGlobalInstallation) {
		# Check conventional global includes from an unrelated project, without
		# changing the caller's NVGT installation or include configuration.
		$engineRoot = Join-Path $runRoot 'nvgt'
		$engineIncludes = Join-Path $engineRoot 'include'
		New-Item -ItemType Directory -Force -Path $engineIncludes | Out-Null
		Copy-Item -LiteralPath $NvgtPath -Destination (Join-Path $engineRoot 'nvgt.exe')
		Copy-Item -LiteralPath (Join-Path (Split-Path $NvgtPath -Parent) 'lib') -Destination $engineRoot -Recurse
		Copy-Item -LiteralPath (Join-Path $inputRoot $libraryDirectory) -Destination (Join-Path $engineIncludes 'opensqcat') -Recurse
		$releaseWrapper = Join-Path $inputRoot 'opensqcat.nvgt'
		$globalWrapper = Join-Path $engineIncludes 'opensqcat.nvgt'
		if (Test-Path -LiteralPath $releaseWrapper -PathType Leaf) {
			Copy-Item -LiteralPath $releaseWrapper -Destination $globalWrapper
		} else {
			[IO.File]::WriteAllText($globalWrapper, "#include `"opensqcat/opensqcat.nvgt`"`n", [Text.UTF8Encoding]::new($false))
		}
		Test-DocumentationProgram (Join-Path $packageRoot 'README.md') (Join-Path $runRoot 'global-project') (Join-Path $engineRoot 'nvgt.exe') -GlobalInclude
		Write-Output 'PASS: global installation'
	}
	$documentationRoot = if ([string]::IsNullOrWhiteSpace($DistributionPath)) { $packageRoot } else { $inputRoot }
	$documentationPrefix = [IO.Path]::GetFullPath($documentationRoot).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
	$linkCount = 0
	foreach ($document in Get-ChildItem -LiteralPath $documentationRoot -Filter '*.md' -File -Recurse) {
		$content = Get-Content -LiteralPath $document.FullName -Raw -Encoding UTF8
		foreach ($link in [regex]::Matches($content, '\[[^\]]*\]\(([^)]+)\)')) {
			$target = $link.Groups[1].Value
			if ($target -match '^https?://') {
				continue
			}
			$parts = $target.Split('#', 2)
			$targetPath = if ($parts[0].Length -eq 0) {
				$document.FullName
			} else {
				[IO.Path]::GetFullPath((Join-Path $document.DirectoryName $parts[0]))
			}
			if (-not $targetPath.StartsWith($documentationPrefix, [StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $targetPath -PathType Leaf)) {
				throw "Broken or nonlocal documentation link in $($document.FullName): $target"
			}
			if ($parts.Length -gt 1) {
				$targetText = Get-Content -LiteralPath $targetPath -Raw -Encoding UTF8
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
	$packagePrefix = [IO.Path]::GetFullPath($packageRoot).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
	foreach ($script in Get-ChildItem -LiteralPath $packageRoot -Filter '*.nvgt' -File -Recurse) {
		$content = Get-Content -LiteralPath $script.FullName -Raw -Encoding UTF8
		foreach ($include in [regex]::Matches($content, '(?m)^\s*#include "([^"]+)"')) {
			$targetPath = [IO.Path]::GetFullPath((Join-Path $script.DirectoryName $include.Groups[1].Value))
			if (-not $targetPath.StartsWith($packagePrefix, [StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $targetPath -PathType Leaf)) {
				throw "Nonlocal or missing include in $($script.FullName): $($include.Groups[1].Value)"
			}
			$includeCount++
		}
	}
	Write-Output "PASS: $linkCount documentation links and $includeCount local includes"
	Write-Output 'Standalone package verified.'
} finally {
	$env:TEMP = $previousTemp
	$env:TMP = $previousTmp
	if ($KeepArtifacts) { Write-Output "Artifacts retained: $runRoot" } else { Remove-TemporaryDirectory $runRoot $buildRoot }
}
