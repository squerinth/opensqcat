# load_text

`bool translator::load_text(const string&in source, const string&in origin = "", const string&in catalog_name = "");`

## Arguments:
* `const string&in source`: complete SQCat text.
* `const string&in origin = ""`: diagnostic provenance passed to the catalog loader, not used as a catalog name.
* `const string&in catalog_name = ""`: registration name passed through without case normalization; empty replaces the selected default.

## Returns:
`true` when the text loads and its catalog is installed/replaced. `false` for an invalid name or catalog parse/load failure. Failure leaves the old messages, registry, default selection and incorporation order unchanged.

## Remarks:
A nonempty `catalog_name` creates or reloads that registration. Empty `catalog_name` replaces the current default and creates an anonymous default when needed. The first successful installation becomes the default only if no default has already been explicitly installed. If processing or parsing the supplied text fails, `error.catalog` is the supplied name, or the current `default_catalog_name` when the argument is empty. An invalid UTF-8 `catalog_name` fails before loading and leaves `error.catalog` empty. Does not change general fields or provider. See [catalog.load_text](../../catalog/Methods/load_text.md).
