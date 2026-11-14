# error

`diagnostic@ translator::get_error() const property;`

## Returns:
A detached copy of the diagnostic from the most recent operation that updates errors. Empty `code` means success. Editing the copy does not change the translator.

Successful configuration changes and rendering operations clear the diagnostic. Raw lookup and membership queries do not change it. See [diagnostic](../../diagnostic/!diagnostic.md).
