# Development guide

This guide covers verification and local package checks for contributors.
The development tools are available in a repository checkout; they are not
required to use the library and are not included in release ZIPs.

## Repository layout

| Path | Contents |
| --- | --- |
| `src/opensqcat.nvgt` | Library include entry point. |
| `src/opensqcat/` | Implementation modules, kept beside the entry point. |
| `tests/contracts.nvgt` | Behavioral contract suite. |
| `examples/` | Runnable example and sample catalogs. |
| `doc/` | Tutorials, API contracts and advanced documentation. |
| `tools/` | Compiler setup, verification and packaging scripts. |
| `build/` | Temporary fixtures, compiler cache and package staging. |
| `release/` | Generated ZIPs and checksums. |

Generated files are ignored by Git. Empty `.gitkeep` files preserve the workspace
folders in a checkout; those placeholders are not part of the library package.

## Verification

Development and testing use NVGT's Latest/Bleeding Edge Development Version.
The verification tools require Windows PowerShell. From the repository root, run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/test.ps1 -NvgtPath C:/nvgt/nvgt.exe
```

Omit `-NvgtPath` to use `NVGT_EXE`, then `nvgt.exe` on `PATH`.
`-BuildDirectory <path>` changes the temporary workspace location. The runner
reports the compiler version and commit used for the check.

Verification runs the contracts, console example, README program and tutorial
program in a standalone copy. It compares their outputs with the documented
results and checks version consistency, local documentation links, heading
fragments and source includes. External URLs are not checked.

Project installation is checked on every run. After changing includes, the global
wrapper or the distribution layout, add `-CheckGlobalInstallation` to test an
isolated global installation. The release packager runs that check once for the
candidate ZIP; routine verification does not copy the compiler.

Temporary workspaces are removed on success and failure. Use `-KeepArtifacts`
when debugging to retain the run and print its location, then remove it manually.
The runner restores `TEMP` and `TMP` before cleanup.

## Compiler setup

To obtain the current development compiler without changing an existing NVGT
installation, use this Windows PowerShell session:

```powershell
$nvgt = & ./tools/get-nvgt.ps1
& ./tools/test.ps1 -NvgtPath $nvgt
```

The helper queries the official `latest` development release, verifies the
installer checksum and extracts the executable, runtime libraries and includes.
It reports the compiler identity and returns only its path on the success stream.
No NVGT version or commit is pinned in the repository. Internet access is required.

One extraction is cached under `build/toolchain/current/` and reused while the
upstream installer checksum is unchanged. A verified replacement supersedes the
old extraction; failed setup preserves the previous one. Temporary downloads and
extraction files are removed. `-BuildDirectory <path>` changes the cache location.
Keep paths short to avoid NVGT's Windows path-length limitations. Do not refresh
a shared cache while another process is using its compiler.

## Make changes

Use tabs and K&R braces in NVGT/AngelScript and PowerShell: opening braces stay
on declaration or control-statement lines, with `else`, `catch` and `finally`
after the preceding closing brace. YAML uses spaces. Preserve Markdown structure
and literal data. The repository provides `.editorconfig`; no formatter or linter
is configured.

Use `snake_case` for AngelScript classes, functions and variables. Keep supported
APIs in `opensqcat` and implementation helpers in `opensqcat::detail`. Preserve
explicit handles and parameter directions, such as `const string&in`.

Add regression cases to `tests/contracts.nvgt` with `check()` and `expect()`.
Group them in `test_<behavior>()` functions called from `main()`. Cover failures
and boundary conditions. Update the [API reference](../api/README.md) or
[format specification](format.md) when behavior changes, then run verification.
Contribution guidance is in `CONTRIBUTING.md` at the repository root.

Library and format versions are independent. During the `0.x` series, minor
library releases may change public APIs; patch releases preserve their contracts.

## Local package checks

When changing the distribution layout or packaging tools, verify a package with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/release.ps1 -NvgtPath C:/nvgt/nvgt.exe
```

The default packages the current working files. `-Revision <ref>` selects a Git
commit or tag instead. Keep `VERSION`, the README version and `CHANGELOG.md`
aligned. Without a supplied compiler, the packager obtains the current NVGT
development build automatically.

The resulting `release/opensqcat-<version>.zip` has exactly four top-level
entries: `opensqcat/`, `examples/`, `opensqcat.nvgt` and `README.md`. The installable
`opensqcat/` folder contains the entry point, the inner implementation folder,
`docs/` and `LICENSE`, so copying it preserves the license and documentation.
The repository's `doc/` and root license remain the packaging sources. Tests,
tools, workspace folders and repository metadata are excluded. README links and
the example's include are adjusted for the distribution layout.

The packager extracts and verifies the ZIP, including global installation, before
writing it and its SHA-256 sidecar to `release/`. Failed verification leaves any
previous finished output intact. Entry order and timestamps are fixed so the same
source and toolchain produce repeatable archives within each packaging mode.
Staging is cleaned unless `-KeepArtifacts` is supplied.

For changes to the development tools, run their additional regression suites:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/artifacts.ps1 -NvgtPath C:/nvgt/nvgt.exe
powershell -NoProfile -ExecutionPolicy Bypass -File tests/releases.ps1 -NvgtPath C:/nvgt/nvgt.exe
```

These check temporary cleanup, compiler-cache reuse, package contents,
repeatability, checksums and preservation of an earlier ZIP on failure. Packaging
regressions skip repeated global-installation checks; the candidate package keeps
that check enabled. Test workspaces are removed by default.

## Continuous integration

The GitHub Actions workflow runs on pull requests, pushes to `main`, version-tag
pushes and manual requests. It uses Windows and the latest NVGT development build
to run the verification and tool regression suites against an extracted package.
Consult the run's logs for compiler identity and failure diagnostics.

Successful pushes to `main` publish development prereleases without a stability
guarantee. Stable releases use version tags matching `VERSION`. Pull requests and
manual verification runs do not publish. Downloadable packages include the ZIP
and checksum; GitHub's source archives use the repository layout instead.
