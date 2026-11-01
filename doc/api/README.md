# API reference

OpenSQCat implements [SQCat 1](../advanced/format.md). The library entry point is
`opensqcat/opensqcat.nvgt` for a project installation, or `opensqcat.nvgt` through
the global wrapper. Supported types and members are documented here in the
`opensqcat` namespace. Undocumented members and the `opensqcat::detail` namespace
are implementation details and are not covered by public compatibility guarantees.

This section documents public contracts. Step-by-step examples belong to the
[tutorials](../tutorials/README.md); design and integration guidance belongs to
the [advanced documentation](../advanced/README.md).

| Type | Purpose |
| --- | --- |
| [catalog](catalog.md) | Load, validate and store message templates. |
| [translator](translator.md) | Look up and format messages with supplied fields. |
| [Native values](values.md#native-values) | Strings, numbers, booleans and NVGT `var`. |
| [field_provider](values.md#field_provider) | Resolve fields dynamically. |
| [field_resolver](values.md#field_resolver) | Function/delegate alternative to a provider object. |
| [evaluation_budget](budget.md) | Share work and generated-text limits between evaluations. |
| [diagnostic](diagnostics.md#diagnostic) | Error code and source location for a completed operation. |

Instances are intended for sequential use, not concurrent mutation. Providers may
replace configuration during a format operation: the current operation retains
the selected templates, copied fields and provider handle; later operations see
configuration changes. Application state read by a provider is not snapshotted.
Callbacks must return promptly and manage their own external state and lifetime.
