# translator

Combines a default and named catalogs, copied general fields and an optional dynamic field provider. It returns formatted text; it does not deliver it to an output service.

## Constructor:

`translator(catalog@ messages = null);`

The translator retains a supplied catalog and treats it as the anonymous,
explicitly installed default. A null argument creates an empty anonymous
catalog. The first successful named load or registration selects a default
automatically only if no explicit default is currently installed. A successful
`load_text` with an empty `catalog_name` explicitly installs or replaces the
default. Catalog names supplied through the translator are passed through
without case normalization; names inferred by `load` preserve filename spelling
apart from removal of the final `.sqcat` suffix.

## Properties
- [default_catalog](Properties/default_catalog.md)
- [error](Properties/error.md)

## Methods

### Configuration and fields
- [clear_variables](Methods/clear_variables.md)
- [remove_variable](Methods/remove_variable.md)
- [set_provider](Methods/set_provider.md)
- [set_resolver](Methods/set_resolver.md)
- [set_variable](Methods/set_variable.md)
- [set_variables](Methods/set_variables.md)

### Catalog registry
- [has_catalog](Methods/has_catalog.md)
- [remove_catalog](Methods/remove_catalog.md)
- [set_catalog](Methods/set_catalog.md)
- [set_default_catalog](Methods/set_default_catalog.md)

### Loading and raw lookup
- [has](Methods/has.md)
- [has_from](Methods/has_from.md)
- [load](Methods/load.md)
- [load_text](Methods/load_text.md)
- [lookup](Methods/lookup.md)
- [lookup_from](Methods/lookup_from.md)

### Message retrieval
- [get](Methods/get.md)
- [get_from](Methods/get_from.md)
- [try_get](Methods/try_get.md)
- [try_get_from](Methods/try_get_from.md)

### Inline formatting
- [format](Methods/format.md)
- [format_from](Methods/format_from.md)
- [try_format](Methods/try_format.md)
- [try_format_from](Methods/try_format_from.md)

Rendering calls capture catalogs and field configuration before callbacks run. See [field values](../../../concepts/field-values.md), [SQCat format](../../../../advanced/format.md) and [integration guidance](../../../../advanced/integration.md).
