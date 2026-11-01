# Repository Guidelines

## Project Structure & Module Organization

OpenSQCat is an NVGT/AngelScript library for UTF-8 `.sqcat` localization catalogs and bounded text templates.

- `src/opensqcat.nvgt` is the public entry point; keep it together with `src/opensqcat/`, which contains values, budgets, parsing, catalogs, and translation modules.
- `tests/contracts.nvgt` contains the standalone contract suite.
- `examples/messages.nvgt` and `examples/locales/` demonstrate catalog loading and live field resolution.
- `doc/api/` is the public API reference, `doc/tutorials/` contains guided examples, and `doc/advanced/` contains format and developer documentation. Keep these three sections distinct. All official documentation and examples are in English and ship in every release.
- `tools/test.ps1` runs verification. `build/` is temporary space for compiler artifacts, fixtures and release staging. Finished ZIPs and checksums belong in `release/`. Keep a tracked empty `.gitkeep` in each directory to preserve the repository layout; all generated contents must remain ignored and outside source commits.
- `tools/get-nvgt.ps1` always resolves and extracts NVGT's Latest/Bleeding Edge Development Version; do not pin an NVGT version or commit. `tools/release.ps1` automatically stages and verifies the current files, or a Git commit selected with `-Revision`, then writes the finished archive under `release/`. A release contains only the library, examples, documentation and license. Tests, tools, agent files and repository metadata are excluded. `.github/workflows/verify.yml` runs this workflow in CI.
- `.agent-work/` holds session-specific agent work and private maintainer guides. Only its empty `.gitkeep` is tracked to preserve the directory; every other file is ignored. Neither the library nor repository tools may require pre-existing artifacts in `build/`, `.agent-work/` or `release/`; required artifacts must be generated from source or downloaded tools. None of these directories or their placeholders belongs in release ZIPs.
- Test and release scripts remove their temporary workspaces on success and failure. Retaining artifacts requires explicit `-KeepArtifacts`. NVGT setup maintains one reusable latest extraction and removes obsolete installer/extraction files; do not reintroduce unbounded per-run compiler copies on disk.
- `.github/workflows/verify.yml` publishes one nightly prerelease for the final commit of each successful push to `main`, and a stable release for a pushed `v<version>` tag matching `VERSION`. Pull requests and manual runs only verify. Keep publication permissions in the separate publication job; nightlies must never be marked Latest.

## Internal Work and Official Documentation

Store internal notes, session state, audit reports, research, plans, and other agent development artifacts in `.agent-work/`. Never put them in the official project documentation.

Only publish information that library users or developers need: supported behavior, public contracts, usage, compatibility, contribution guidance, and verified development procedures. Keep audit progress, agent decisions, and release-preparation status in `.agent-work/`.
Personal GitHub setup, account instructions, maintainer-only publication walkthroughs and session notes also belong in `.agent-work/`, with no links from public documentation. Contributor documentation may explain verification and local packaging without including personal publishing instructions.

## Build, Test, and Development Commands

Run the full verification workflow from the repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/test.ps1 -NvgtPath C:/nvgt/nvgt.exe
```

Omit `-NvgtPath` to use `NVGT_EXE`, then `nvgt.exe` on `PATH`. Use `-BuildDirectory <path>` to select another artifact directory. The runner executes the contract suite, console example, README and tutorial programs in a standalone copy, tests project installation, then checks documentation links and source includes. Add `-CheckGlobalInstallation` when changing includes, the global wrapper or distribution layout. Normal release packaging runs the global installation check once for the actual candidate; packaging regression tests use `-SkipGlobalInstallationCheck` to avoid repeating it. Packaging must preserve the complete documentation tree.

There is no separate library build step. The repository keeps library source in `src/`; releases distribute it as `opensqcat/` and include a global wrapper. Development and testing use NVGT's Latest/Bleeding Edge Development Version. Record the verified compiler version and commit as test provenance, without pinning future runs to that build.

ZIP entries start directly at the distribution root; do not add a versioned containing directory. The four top-level entries are `opensqcat/`, `examples/`, `opensqcat.nvgt` and `README.md`. The installable `opensqcat/` folder contains its entry point, inner implementation directory, `docs/` and the complete `LICENSE`; project and global installation must preserve them. The source repository retains `doc/` and root `LICENSE`; packaging copies them into the installable folder and adjusts README links. Keep contribution guidance in the repository-root `CONTRIBUTING.md` rather than duplicating it under advanced documentation.

## Coding Style & Naming Conventions

Use tabs for indentation and K&R braces in NVGT/AngelScript and PowerShell: opening braces stay on the declaration or control-statement line, and `else`, `catch`, and `finally` follow the closing brace on the same line. Use `snake_case` names for AngelScript classes, functions, and variables. Keep public APIs in `opensqcat` and implementation helpers in `opensqcat::detail`. Preserve explicit handle and parameter-direction syntax, such as `translator@` and `const string&in`. Code examples follow the same style. YAML keeps space indentation as required by its syntax; preserve Markdown structure and literal data. Editor settings are in `.editorconfig`; no formatter or linter is configured.

## Testing Guidelines

Use the suite's `check()` and `expect()` helpers; group cases in `test_<behavior>()` functions and invoke new groups from `main()`. Add regression cases for changed behavior, including failure diagnostics and boundary conditions. No numeric coverage threshold is configured. Update API or format documentation alongside contract changes and run the full verification command.

## Commit & Pull Request Guidelines

History currently contains only the initial commit, so no established commit convention exists. Use concise, imperative subjects describing the change. Pull requests should explain behavior changes, link relevant issues, and report the verification command and result, including the NVGT version used.

## Architecture Boundaries

Keep the library independent of input, display, speech, networking, and application frameworks. Applications choose catalog paths, languages, and fallback behavior. Preserve bounded evaluation and structured diagnostics when extending template features.
