# get

`string translator::get(const string&in key, dictionary@ arguments = null, evaluation_budget@ budget = null);`

## Arguments:
* `const string&in key`: literal message key in the default catalog.
* `dictionary@ arguments = null`: optional per-call fields; the input is validated and copied.
* `evaluation_budget@ budget = null`: optional shared evaluation allowance; null creates a fresh one.

## Returns:
The evaluated message on success, including valid empty text. On any failure, returns the supplied `key` and records a diagnostic in `error`.

## Remarks:
No automatic language or template fallback occurs.
The key is never parsed as an expression or catalog/key path. Fields resolve by priority: per-call `arguments`, then fields installed with `set_variable` / `set_variables`, then the provider. A present empty, false or zero value blocks lower priorities. Provider results and absence are cached by field name for the operation. No partial output is returned on failure. Use [try_get](try_get.md) when the fallback key must be distinguished from successful text.
