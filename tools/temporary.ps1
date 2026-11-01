# Delete only a verified child of the caller's artifact directory.
function Remove-TemporaryDirectory([string]$Path, [string]$ParentDirectory) {
	$parent = [IO.Path]::GetFullPath($ParentDirectory).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
	$target = [IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
	if (-not $target.StartsWith($parent, [StringComparison]::OrdinalIgnoreCase)) {
		throw "Refusing to remove a directory outside its artifact parent: $target"
	}
	if (-not (Test-Path -LiteralPath $target)) { return }
	$resolved = (Resolve-Path -LiteralPath $target).ProviderPath.TrimEnd('\', '/')
	if (-not $resolved.StartsWith($parent, [StringComparison]::OrdinalIgnoreCase)) {
		throw "Resolved artifact path is outside its parent: $resolved"
	}
	if ((Get-Item -LiteralPath $resolved -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {
		throw "Refusing to recursively remove an artifact link: $resolved"
	}
	$links = @(Get-ChildItem -LiteralPath $resolved -Force -Recurse | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint })
	if ($links.Count -gt 0) { throw "Artifact directory contains links; refusing recursive removal: $resolved" }
	Remove-Item -LiteralPath $resolved -Recurse -Force
}
