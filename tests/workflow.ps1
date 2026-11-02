[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
. (Join-Path $root 'tools/temporary.ps1')
. (Join-Path $root 'tools/ci-changes.ps1')
$probe = Join-Path $root ('build/workflow-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
$utf8 = [Text.UTF8Encoding]::new($false)
try {
	New-Item -ItemType Directory -Path $probe | Out-Null
	& git -C $probe init --quiet
	function Write-FixtureFile([string]$Path, [string]$Text) {
		$destination = Join-Path $probe $Path
		New-Item -ItemType Directory -Force -Path (Split-Path $destination -Parent) | Out-Null
		[IO.File]::WriteAllText($destination, $Text, $utf8)
	}
	function Commit-Fixture() {
		& git -C $probe -c core.autocrlf=false add -A
		& git -C $probe -c user.name='Workflow verification' -c user.email='verification@example.invalid' -c commit.gpgsign=false commit --quiet -m 'Workflow fixture'
		if ($LASTEXITCODE -ne 0) { throw 'Cannot commit workflow fixture.' }
		return (& git -C $probe rev-parse HEAD).Trim()
	}
	function Expect-Selection([string]$EventName, [string]$RefType, [string]$Base, [string]$Head, [bool]$Expected) {
		$actual = Test-ToolingChanges -RepositoryRoot $probe -EventName $EventName -RefType $RefType -Base $Base -Head $Head
		if ($actual -isnot [bool] -or $actual -ne $Expected) { throw "Incorrect tool selection: $EventName $RefType $Base $Head; expected $Expected, got $actual" }
	}
	foreach ($path in @('README.md', 'src/library.nvgt', 'tools/probe.ps1', 'tests/probe.ps1', '.github/workflows/probe.yml', '.gitignore', '.gitattributes', '.editorconfig')) {
		Write-FixtureFile $path ''
	}
	$initial = Commit-Fixture
	Expect-Selection push branch $initial $initial $false
	$previous = $initial
	foreach ($path in @('README.md', 'doc/more notes.md', 'src/library.nvgt', 'examples/messages.nvgt')) {
		Write-FixtureFile $path 'Library or documentation change.'
		$head = Commit-Fixture
		Expect-Selection push branch $previous $head $false
		Expect-Selection pull_request branch $previous $head $false
		$previous = $head
	}
	$beforeTools = $previous
	foreach ($path in @('tools/probe.ps1', 'tests/probe.ps1', '.github/workflows/probe.yml', '.gitignore', '.gitattributes', '.editorconfig')) {
		Write-FixtureFile $path 'Tooling change.'
		$head = Commit-Fixture
		Expect-Selection push branch $previous $head $true
		Expect-Selection pull_request branch $previous $head $true
		$previous = $head
	}
	Write-FixtureFile 'src/library.nvgt' 'Last commit of a multi-commit push.'
	$head = Commit-Fixture
	Expect-Selection push branch $beforeTools $head $true
	Move-Item -LiteralPath (Join-Path $probe 'tools/probe.ps1') -Destination (Join-Path $probe 'src/retired-tool.ps1')
	$renamed = Commit-Fixture
	Expect-Selection push branch $head $renamed $true
	Remove-Item -LiteralPath (Join-Path $probe 'tests/probe.ps1')
	$deleted = Commit-Fixture
	Expect-Selection push branch $renamed $deleted $true
	foreach ($base in @('', ('0' * 40), ('f' * 40), 'invalid')) {
		Expect-Selection push branch $base $deleted $true
	}
	Expect-Selection push branch $deleted ('f' * 40) $true
	Expect-Selection push tag $deleted $deleted $true
	Expect-Selection workflow_dispatch branch $deleted $deleted $true
	Expect-Selection workflow_dispatch tag $deleted $deleted $true
	Expect-Selection unknown branch $deleted $deleted $true

	# PR comparisons must include only changes since the common ancestor,
	# not unrelated tooling changes made on the target branch.
	& git -C $probe switch --quiet -c target $initial
	Write-FixtureFile 'tools/probe.ps1' 'Target-only change.'
	$target = Commit-Fixture
	& git -C $probe switch --quiet -c contribution $initial
	Write-FixtureFile 'src/library.nvgt' 'Contribution-only change.'
	$contribution = Commit-Fixture
	Expect-Selection pull_request branch $target $contribution $false
	Write-FixtureFile 'tools/new.ps1' 'Contribution tooling change.'
	$contribution = Commit-Fixture
	Expect-Selection pull_request branch $target $contribution $true
	& git -C $probe switch --quiet --orphan unrelated
	Write-FixtureFile 'README.md' 'Unrelated history.'
	$unrelated = Commit-Fixture
	Expect-Selection pull_request branch $initial $unrelated $true
	Write-Output 'PASS: CI selection for source/docs, tools/config, multi-commit pushes, renames, deletions, PR merge bases, tags, manual runs and missing history'
} finally {
	Remove-TemporaryDirectory $probe (Join-Path $root 'build')
}
