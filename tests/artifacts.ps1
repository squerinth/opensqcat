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
} finally {
	Remove-TemporaryDirectory $probe (Join-Path $root 'build')
}
