# API reference

OpenSQCat implements [SQCat 1](../format.md). Include `src/opensqcat.nvgt`. All supported symbols are in the `opensqcat`
namespace. The `opensqcat::detail` namespace and `catalog.snapshot()` are
implementation details, not application API.

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
its catalog, dictionaries and provider snapshot; later operations see the change.
Callbacks must return promptly and manage their own external state and lifetime.

No type in this API owns application data such as players, accounts or documents.
