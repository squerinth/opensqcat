# try_get_from

`bool translator::try_get_from(const string&in catalog_name, const string&in key, string&out text, dictionary@ arguments = null, evaluation_budget@ budget = null);`

## Arguments:
* `const string&in catalog_name`: registered catalog name passed through without case normalization; empty selects the default.
* `const string&in key`: literal message key.
* `string&out text`: receives the full evaluated message.
* `dictionary@ arguments = null`: optional validated and copied per-call fields.
* `evaluation_budget@ budget = null`: shared allowance, or null for a fresh one.

## Returns:
`true` on success, including an empty message. On failure, returns `false`, clears `text` and records the diagnostic in `error`.

## Remarks:
No automatic language or template fallback occurs.
Fields resolve in order: temporary arguments, general fields, provider. Present empty/false/zero values block lower priorities. Provider results and absence are cached by name for this entire operation. Catalogs and field configuration are captured before callbacks run. Failure returns no partial output; causes include absent catalog/message, invalid arguments, missing required fields, provider errors, cycles and limit exhaustion.
