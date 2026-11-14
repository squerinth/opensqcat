# error

`diagnostic@ catalog::get_error() const property;`

## Returns:
A detached copy of the diagnostic from the catalog's latest load or mutation. Empty `code` means success. Reading this property does not change the stored diagnostic, and editing the returned object does not affect the catalog.

See [diagnostic](../../diagnostic/!diagnostic.md) and the [diagnostic code table](../../../../concepts/diagnostics.md#diagnostic).
