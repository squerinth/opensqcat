# API reference

OpenSQCat implements [SQCat 1](../advanced/format.md). This reference covers
symbols in the `opensqcat` namespace.
The `opensqcat::detail` namespace is implementation-only. Two publicly exposed
catalog hooks are documented for transparency but are not compatibility-guaranteed.

| Category | Type | Reference |
| --- | --- | --- |
| Class | `catalog` | [Class and members](opensqcat/Classes/catalog/!catalog.md) |
| Class | `translator` | [Class and members](opensqcat/Classes/translator/!translator.md) |
| Class | `evaluation_budget` | [Class and members](opensqcat/Classes/evaluation_budget/!evaluation_budget.md) |
| Class | `diagnostic` | [Class and members](opensqcat/Classes/diagnostic/!diagnostic.md) |
| Interface | `field_provider` | [Interface and method](opensqcat/Classes/field_provider/!field_provider.md) |
| Callback | `field_resolver` | [Function definition](opensqcat/Funcdefs/field_resolver.md) |

Each class page documents its constructor where applicable and links to each
individual member page.

## Cross-cutting contracts

| Topic | Reference |
| --- | --- |
| Field values and dictionaries | [Conversion, validation and copying](concepts/field-values.md) |
| Shared evaluation budgets | [Counters and limits across operations](concepts/evaluation-budgets.md) |
| Diagnostics and resource limits | [Codes, source locations and bounds](concepts/diagnostics.md) |
