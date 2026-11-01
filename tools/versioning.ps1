function Get-SourceVersion([string]$Root) {
	$version = (Get-Content -LiteralPath (Join-Path $Root 'VERSION') -Raw -Encoding UTF8).Trim()
	if ($version -notmatch '^\d+\.\d+\.\d+$') { throw 'VERSION must contain the target major.minor.patch.' }
	return $version
}

function Get-StableReleaseNotes([string]$Root, [string]$Version) {
	$changelog = Get-Content -LiteralPath (Join-Path $Root 'CHANGELOG.md') -Raw -Encoding UTF8
	$sections = [regex]::Matches($changelog, "(?ms)^## $([regex]::Escape($Version))\r?\n(.*?)(?=^## |\z)")
	if ($sections.Count -ne 1 -or [string]::IsNullOrWhiteSpace($sections[0].Groups[1].Value)) {
		throw "Stable release $Version requires exactly one nonempty changelog section."
	}
	return $sections[0].Groups[1].Value.Trim()
}
