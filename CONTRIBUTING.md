# Contributing to OpenSQCat

Thanks for your interest in contributing! Bug reports, suggestions, documentation improvements, examples, and code contributions are welcome.

## Issues

Before opening an issue, check whether the problem or suggestion has already been reported.

When reporting a bug, describe what happened, what you expected to happen, and how to reproduce it. Include a minimal NVGT example when possible, along with the relevant OpenSQCat and NVGT versions.
Feature requests are welcome. Explain the use case and the problem you want to solve rather than only proposing a particular implementation. Keep discussions constructive and focused on the issue.

## Pull requests

Target `main` when opening a pull request, including contributions from forks.
The GitHub Actions `verify` check must pass before merging.

Small fixes, documentation improvements, and focused changes can be submitted directly. Please discuss substantial API changes, architectural changes, new dependencies, or major features in an issue before investing significant work in them.

When preparing a pull request:

- Keep the change focused. Use tabs for indentation and K&R braces in NVGT/AngelScript and PowerShell, including code examples. Keep YAML indentation as spaces, and preserve meaningful whitespace in Markdown and literal data.
- Prefer existing facilities over introducing duplicate solutions or unnecessary dependencies.
- Include appropriate tests for behavioral changes, and update examples or public documentation when the change affects them.
- Explain what changed and why, how you verified it, and any known limitations. Be clear about checks you could not perform.
- Make sure you have the right to submit the code and other material under the project's license.

OpenSQCat is still evolving, so backward-incompatible changes are not automatically ruled out. They should nevertheless be deliberate, justified, and clearly documented.

For verification and local package checks, see [the development guide](doc/advanced/development.md).

## AI-assisted contributions

Contributions developed with AI tools or coding agents are welcome. The person submitting a contribution remains responsible for understanding the changes, reviewing their correctness, and responding to feedback. AI-generated output is not a substitute for testing or for checking that a change fits the project.

Contributions are evaluated on their quality and suitability, not on whether the code was written manually or with AI assistance.
