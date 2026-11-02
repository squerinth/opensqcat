function Test-ToolingChanges([string]$RepositoryRoot, [string]$EventName, [string]$RefType, [string]$Base, [string]$Head) {
	if ($EventName -notin @('push', 'pull_request') -or $RefType -eq 'tag') { return $true }
	if ($Base -notmatch '^[a-fA-F0-9]{40}$' -or $Base -eq ('0' * 40) -or $Head -notmatch '^[a-fA-F0-9]{40}$') { return $true }
	foreach ($revision in @($Base, $Head)) {
		$null = & git -C $RepositoryRoot rev-parse --verify --quiet "${revision}^{commit}"
		if ($LASTEXITCODE -ne 0) { $global:LASTEXITCODE = 0; return $true }
	}
	if ($EventName -eq 'pull_request') {
		$ancestor = & git -C $RepositoryRoot merge-base $Base $Head
		if ($LASTEXITCODE -ne 0) { $global:LASTEXITCODE = 0; return $true }
		$Base = $ancestor.Trim()
	}
	$range = "$Base..$Head"
	$paths = @(& git -C $RepositoryRoot -c core.quotepath=false diff --name-only --no-renames $range --)
	if ($LASTEXITCODE -ne 0) { $global:LASTEXITCODE = 0; return $true }
	return @($paths | Where-Object { $_ -match '^(tools/|tests/|\.github/|\.gitignore$|\.gitattributes$|\.editorconfig$)' }).Count -gt 0
}
