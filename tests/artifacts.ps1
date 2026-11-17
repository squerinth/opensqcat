[CmdletBinding()]
param([string]$NvgtPath = $env:NVGT_EXE)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
. (Join-Path $root 'tools/temporary.ps1')
if ([string]::IsNullOrWhiteSpace($NvgtPath)) { $NvgtPath = 'nvgt.exe' }
if (Test-Path -LiteralPath $NvgtPath -PathType Leaf) { $NvgtPath = (Resolve-Path -LiteralPath $NvgtPath).Path } else { $NvgtPath = (Get-Command $NvgtPath).Source }
$probe = Join-Path $root ('build/artifacts-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $probe | Out-Null
try {
	$workspace = Join-Path $probe 'runs'
	New-Item -ItemType Directory -Path $workspace | Out-Null
	$sentinel = Join-Path $workspace 'unrelated.txt'
	Set-Content -LiteralPath $sentinel -Value 'preserve'
	foreach ($keep in @($false, $true)) {
		$failed = $false
		try { $null = & (Join-Path $root 'tools/test.ps1') -NvgtPath $NvgtPath -BuildDirectory $workspace -DistributionPath (Join-Path $probe 'missing') -KeepArtifacts:$keep } catch { $failed = $true }
		if (-not $failed) { throw 'Invalid distribution unexpectedly passed.' }
		$remaining = @(Get-ChildItem -LiteralPath $workspace -Directory)
		if ($remaining.Count -ne [int]$keep) { throw 'Failed verification did not respect artifact retention.' }
		foreach ($directory in $remaining) { Remove-TemporaryDirectory $directory.FullName $workspace }
	}
	foreach ($path in @($workspace, (Join-Path $probe 'outside'))) {
		$refused = $false
		try { Remove-TemporaryDirectory $path $workspace } catch { $refused = $true }
		if (-not $refused) { throw 'Cleanup accepted a parent or outside path.' }
	}
	if (-not (Test-Path -LiteralPath $sentinel)) { throw 'Cleanup removed an unrelated file.' }
	Write-Output 'PASS: failure cleanup, explicit retention and deletion boundaries'

	# Use a real compiler with synthetic release metadata; never access the network.
	$cache = Join-Path $probe 'toolchain'
	$current = Join-Path $cache 'current'
	$app = Join-Path $current 'app'
	New-Item -ItemType Directory -Force -Path (Join-Path $app 'include') | Out-Null
	Copy-Item -LiteralPath $NvgtPath -Destination (Join-Path $app 'nvgt.exe')
	Copy-Item -LiteralPath (Join-Path (Split-Path $NvgtPath -Parent) 'lib') -Destination $app -Recurse
	$manifest = Join-Path $current 'cache.json'
	$digest = 'a' * 64
	@{schema = 1; installer_sha256 = $digest} | ConvertTo-Json | Set-Content -LiteralPath $manifest
	$toolchainTestState = @{digest = $digest; lookups = 0; downloads = 0; checksumFailure = $false}
	function Invoke-RestMethod {
		$toolchainTestState.lookups++
		return @{assets = @(@{name = 'nvgt_dev.exe'; digest = 'sha256:' + $toolchainTestState.digest; url = 'https://example.invalid/nvgt'})}
	}
	function Invoke-WebRequest {
		param($Uri, $Headers, $OutFile, [switch]$UseBasicParsing)
		$toolchainTestState.downloads++
		Set-Content -LiteralPath $OutFile -Value 'incomplete download'
		if (-not $toolchainTestState.checksumFailure) { throw 'Synthetic download failure' }
	}
	$beforeBytes = (Get-ChildItem -LiteralPath $cache -File -Recurse | Measure-Object Length -Sum).Sum
	$previousTemp = $env:TEMP
	$previousTmp = $env:TMP
	for ($iteration = 0; $iteration -lt 2; $iteration++) {
		$compiler = & (Join-Path $root 'tools/get-nvgt.ps1') -BuildDirectory $cache
		if ($compiler -cne (Join-Path $app 'nvgt.exe')) { throw 'Warm cache returned a different compiler path.' }
	}
	$afterBytes = (Get-ChildItem -LiteralPath $cache -File -Recurse | Measure-Object Length -Sum).Sum
	if ($toolchainTestState.lookups -ne 2 -or $toolchainTestState.downloads -ne 0 -or $beforeBytes -ne $afterBytes) { throw 'Warm cache did not resolve latest and reuse the same extraction without growth.' }
	foreach ($checksumFailure in @($false, $true)) {
		$toolchainTestState.digest = 'b' * 64
		$toolchainTestState.checksumFailure = $checksumFailure
		$failed = $false
		try { $null = & (Join-Path $root 'tools/get-nvgt.ps1') -BuildDirectory $cache } catch { $failed = $true }
		if (-not $failed -or (Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json).installer_sha256 -cne $digest) { throw 'Failed cache refresh replaced the working compiler.' }
		if (@(Get-ChildItem -LiteralPath $cache -Force).Count -ne 1) { throw 'Failed cache refresh retained a download or extraction.' }
	}
	if ($toolchainTestState.downloads -ne 2 -or $env:TEMP -cne $previousTemp -or $env:TMP -cne $previousTmp) { throw 'Cache invalidation or environment restoration failed.' }
	Write-Output "PASS: latest lookup, warm cache reuse ($afterBytes bytes before and after), invalidation and failed-download cleanup"

	& {
		# Use a disposable extractor shim and a real compiler to verify that
		# cold setup extracts and probes the installation at its final path.
		$cold = Join-Path $probe 'cold-toolchain'
		$destination = Join-Path $cold 'current'
		$fakeInstaller = Join-Path $probe 'installer-fixture'
		$shim = Join-Path $probe 'extractor-fixture.ps1'
		[IO.File]::WriteAllText($fakeInstaller, 'verified installer fixture')
		$toolchainTestState.digest = (Get-FileHash -LiteralPath $fakeInstaller).Hash.ToLowerInvariant()
		$toolchainTestState.extractFailure = $true
		[IO.File]::WriteAllText($shim, @'
$output = $args[([Array]::IndexOf($args, '--output-dir') + 1)]
if ($output -cne $destination) { throw 'Cold extraction must use the final compiler path.' }
$appRoot = Join-Path $output 'app'
New-Item -ItemType Directory -Force -Path (Join-Path $appRoot 'include') | Out-Null
if ($toolchainTestState.extractFailure) {
	$global:LASTEXITCODE = 1
	return
}
Copy-Item -LiteralPath $NvgtPath -Destination (Join-Path $appRoot 'nvgt.exe')
Copy-Item -LiteralPath (Join-Path (Split-Path $NvgtPath -Parent) 'lib') -Destination $appRoot -Recurse
$global:LASTEXITCODE = 0
'@)
		New-Item -ItemType Directory -Path $cold | Out-Null
		[IO.File]::WriteAllText((Join-Path $cold 'innoextract.zip'), 'extractor fixture')
		function Invoke-WebRequest {
			param($Uri, $Headers, $OutFile, [switch]$UseBasicParsing)
			Copy-Item -LiteralPath $fakeInstaller -Destination $OutFile
		}
		function Get-FileHash {
			param($LiteralPath, $Algorithm)
			if ($LiteralPath -ceq (Join-Path $cold 'innoextract.zip')) {
				return @{Hash = '79b69b9b1fcd98f42ccd4b245efdf6a03bcfb674ba6af482f5a46891c9ed4d14'}
			}
			Microsoft.PowerShell.Utility\Get-FileHash -LiteralPath $LiteralPath -Algorithm $Algorithm
		}
		function Expand-Archive {
			param($LiteralPath, $DestinationPath)
		}
		function Join-Path {
			param($Path, $ChildPath)
			if ($ChildPath -ceq 'innoextract.exe') { return $shim }
			Microsoft.PowerShell.Management\Join-Path -Path $Path -ChildPath $ChildPath
		}
		$failed = $false
		try { $null = & (Join-Path $root 'tools/get-nvgt.ps1') -BuildDirectory $cold } catch {
			if ($_.Exception.Message -cne 'NVGT extraction failed.') { throw }
			$failed = $true
		}
		if (-not $failed -or @(Get-ChildItem -LiteralPath $cold -Force).Count -ne 1) { throw 'Failed extraction retained cache artifacts.' }
		$toolchainTestState.extractFailure = $false
		$compiler = & (Join-Path $root 'tools/get-nvgt.ps1') -BuildDirectory $cold
		if ($compiler -cne (Join-Path $destination 'app/nvgt.exe') -or @(Get-ChildItem -LiteralPath $cold -Force).Count -ne 2) { throw 'Cold setup returned an unexpected path or retained artifacts.' }
		if ((Get-Content -LiteralPath (Join-Path $destination 'cache.json') -Raw | ConvertFrom-Json).installer_sha256 -cne $toolchainTestState.digest) {
			throw 'Cold setup did not record the verified installer.'
		}
		Write-Output 'PASS: cold setup probes NVGT in place and removes incomplete extractions'
	}
} finally {
	Remove-TemporaryDirectory $probe (Join-Path $root 'build')
}
