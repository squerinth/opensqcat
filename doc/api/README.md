# API reference

OpenSQCat implements [SQCat 1](../advanced/format.md). The library entry point is
`opensqcat/opensqcat.nvgt` for a project installation, or `opensqcat.nvgt` through
the global wrapper. This reference covers symbols in the `opensqcat` namespace.
The `opensqcat::detail` namespace is implementation-only. Two publicly exposed
catalog hooks are documented for transparency but are not compatibility-guaranteed.

This section documents contracts. Step-by-step examples belong to the
[tutorials](../tutorials/README.md); design and integration guidance belongs to
the [advanced documentation](../advanced/README.md). Browse the [namespace
index](opensqcat/README.md) or the [cross-cutting concepts](concepts/README.md).

| Category | Type | Reference |
| --- | --- | --- |
| Class | `catalog` | [Class and members](opensqcat/Classes/catalog/!catalog.md) |
| Class | `translator` | [Class and members](opensqcat/Classes/translator/!translator.md) |
| Class | `evaluation_budget` | [Class and members](opensqcat/Classes/evaluation_budget/!evaluation_budget.md) |
| Class | `diagnostic` | [Class and members](opensqcat/Classes/diagnostic/!diagnostic.md) |
| Interface | `field_provider` | [Interface and method](opensqcat/Classes/field_provider/!field_provider.md) |
| Callback | `field_resolver` | [Function definition](opensqcat/Funcdefs/field_resolver.md) |
| Concept | Field values and dictionaries | [Value and conversion rules](concepts/field-values.md) |
| Concept | Diagnostic codes and resource limits | [Diagnostics and limits](concepts/diagnostics.md#diagnostic) |

Each class/interface page links to an individual page for every member. Constructors
are described with their type, following the reference documentation's layout.
Instances are intended for sequential use. Providers may replace configuration
during formatting: that operation retains its selected templates, copied fields
and provider handle; later operations see configuration changes. Application
state read by a provider is not snapshotted. Callbacks must return promptly and
manage their external state and lifetime.
