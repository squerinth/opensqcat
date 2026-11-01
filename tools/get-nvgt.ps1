[CmdletBinding()]
param([string]$BuildDirectory)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'temporary.ps1')
$projectRoot = Split-Path $PSScriptRoot -Parent
if ([string]::IsNullOrWhiteSpace($BuildDirectory)) {
	$BuildDirectory = Join-Path $projectRoot 'build/toolchain'
}
$toolRoot = [IO.Path]::GetFullPath($BuildDirectory)
New-Item -ItemType Directory -Force -Path $toolRoot | Out-Null
# Serialize cache updates so another setup never observes a partial extraction.
$hasher = [Security.Cryptography.SHA256]::Create()
try { $cacheKey = [BitConverter]::ToString($hasher.ComputeHash([Text.Encoding]::UTF8.GetBytes($toolRoot.ToLowerInvariant()))).Replace('-', '') } finally { $hasher.Dispose() }
$mutex = [Threading.Mutex]::new($false, "Local\OpenSQCat-NVGT-$cacheKey")
$locked = $false
$runRoot = Join-Path $toolRoot ('setup-' + [guid]::NewGuid().ToString('N'))
$installer = $null
$previousTemp = $env:TEMP
$previousTmp = $env:TMP
try {
	try { $locked = $mutex.WaitOne(60000) } catch [Threading.AbandonedMutexException] { $locked = $true }
	if (-not $locked) { throw 'Another NVGT setup is still using this cache.' }
	# Always resolve latest, including on a warm cache. No compiler commit is pinned.
	$release = Invoke-RestMethod -Uri 'https://api.github.com/repos/samtupy/nvgt/releases/tags/latest'
	$assets = @($release.assets | Where-Object { $_.name -match '^nvgt_.*\.exe$' })
	if ($assets.Count -ne 1 -or $assets[0].digest -notmatch '^sha256:([a-f0-9]{64})$') {
		throw 'Latest NVGT development release must identify one Windows installer and its SHA-256.'
	}
	$digest = $assets[0].digest.Substring(7)
	$cacheRoot = Join-Path $toolRoot 'current'
	$manifestPath = Join-Path $cacheRoot 'cache.json'
	$cached = $null
	if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
		try { $cached = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json } catch { $cached = $null }
	}
	$reuse = $null -ne $cached -and $cached.schema -eq 1 -and $cached.installer_sha256 -ceq $digest
	foreach ($required in @('app/nvgt.exe', 'app/lib', 'app/include')) {
		$reuse = $reuse -and (Test-Path -LiteralPath (Join-Path $cacheRoot $required))
	}
	New-Item -ItemType Directory -Path $runRoot | Out-Null
	$tempRoot = Join-Path $runRoot 'tmp'
	New-Item -ItemType Directory -Path $tempRoot | Out-Null
	$env:TEMP = $tempRoot
	$env:TMP = $tempRoot
	if (-not $reuse) {
		$installer = Join-Path $toolRoot "$digest.exe"
		if (-not (Test-Path -LiteralPath $installer -PathType Leaf)) {
			Write-Host 'Downloading latest NVGT development installer'
			Invoke-WebRequest -UseBasicParsing -Uri $assets[0].url -Headers @{Accept = 'application/octet-stream'} -OutFile $installer
		}
		if ((Get-FileHash -LiteralPath $installer -Algorithm SHA256).Hash -ine $digest) { throw 'NVGT installer checksum mismatch.' }
		$extractorHash = '79b69b9b1fcd98f42ccd4b245efdf6a03bcfb674ba6af482f5a46891c9ed4d14'
		$extractorArchive = Join-Path $toolRoot 'innoextract.zip'
		if (-not (Test-Path -LiteralPath $extractorArchive -PathType Leaf)) {
			Invoke-WebRequest -UseBasicParsing -Uri 'https://github.com/UserUnknownFactor/innoextract_win/releases/download/670/innoextract670.zip' -OutFile $extractorArchive
		}
		if ((Get-FileHash -LiteralPath $extractorArchive -Algorithm SHA256).Hash -ine $extractorHash) {
			Remove-Item -LiteralPath $extractorArchive -Force
			throw 'Extraction utility checksum mismatch.'
		}
		$extractorRoot = Join-Path $runRoot 'extractor'
		Expand-Archive -LiteralPath $extractorArchive -DestinationPath $extractorRoot
		$selectedRoot = Join-Path $runRoot 'cache'
		# Verification runs scripts; application-packaging stubs are unnecessary.
		& (Join-Path $extractorRoot 'innoextract.exe') --silent --include 'app\nvgt.exe' --include 'app\lib' --include 'app\include' --output-dir $selectedRoot $installer
		if ($LASTEXITCODE -ne 0) { throw 'NVGT extraction failed.' }
	} else {
		$selectedRoot = $cacheRoot
	}
	$nvgtPath = Join-Path $selectedRoot 'app/nvgt.exe'
	$probe = Join-Path $runRoot 'version.nvgt'
	[IO.File]::WriteAllText($probe, "#pragma console`nvoid main() { println(NVGT_VERSION); println(NVGT_VERSION_COMMIT_HASH); }`n", [Text.UTF8Encoding]::new($false))
	$identity = @(& $nvgtPath -w 2 $probe)
	if ($LASTEXITCODE -ne 0 -or $identity.Count -ne 2 -or [string]::IsNullOrWhiteSpace($identity[0]) -or $identity[1] -notmatch '^[a-fA-F0-9]{40}$') {
		throw "The extracted NVGT did not report a valid version and commit: $identity"
	}
	if (-not $reuse) {
		$manifest = @{schema = 1; installer_sha256 = $digest}
		[IO.File]::WriteAllText((Join-Path $selectedRoot 'cache.json'), ($manifest | ConvertTo-Json), [Text.UTF8Encoding]::new($false))
		Remove-TemporaryDirectory $cacheRoot $toolRoot
		$parentPrefix = $toolRoot.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
		if (-not ([IO.Path]::GetFullPath($selectedRoot).StartsWith($parentPrefix, [StringComparison]::OrdinalIgnoreCase)) -or -not ([IO.Path]::GetFullPath($cacheRoot).StartsWith($parentPrefix, [StringComparison]::OrdinalIgnoreCase))) { throw 'Cache move is outside the tool directory.' }
		Move-Item -LiteralPath $selectedRoot -Destination $cacheRoot
		$nvgtPath = Join-Path $cacheRoot 'app/nvgt.exe'
	}
	Write-Host "Verified NVGT $($identity[0]) commit $($identity[1])"
	# The only success-stream output is the compiler path.
	Write-Output $nvgtPath
} finally {
	$env:TEMP = $previousTemp
	$env:TMP = $previousTmp
	try {
		if ($null -ne $installer -and (Test-Path -LiteralPath $installer)) { Remove-Item -LiteralPath $installer -Force }
		Remove-TemporaryDirectory $runRoot $toolRoot
	} finally {
		if ($locked) { $mutex.ReleaseMutex() }
		$mutex.Dispose()
	}
}
