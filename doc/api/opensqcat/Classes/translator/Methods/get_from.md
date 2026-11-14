# get_from

`string translator::get_from(const string&in catalog_name, const string&in key, dictionary@ arguments = null, evaluation_budget@ budget = null);`

## Arguments:
* `const string&in catalog_name`: registered catalog name passed through without case normalization; empty selects the default.
* `const string&in key`: literal message key in the selected catalog.
* `dictionary@ arguments = null`: optional per-call fields, validated and copied.
* `evaluation_budget@ budget = null`: optional shared allowance; null creates a fresh budget.

## Returns:
The evaluated message on success, including empty text. On any failure, returns the supplied `key` and records a diagnostic in `error`.

## Remarks:
No automatic language or template fallback occurs.
Fields resolve by priority: per-call arguments, general fields, then the provider. A present empty, false or zero blocks lower priorities. Provider values and absence are cached once by name during the operation. The selected catalog, registry and field configuration are captured before callbacks. No partial text is returned. Use [try_get_from](try_get_from.md) to distinguish failure from valid text.
