# set

`bool catalog::set(const string&in key, const string&in text);`

## Arguments:
* `const string&in key`: nonempty UTF-8 message key.
* `const string&in text`: UTF-8 template to compile and store.

## Returns:
`true` when the template compiles and is installed. `false` when the key or template is invalid; the existing entry remains unchanged and `error` is updated.

## Remarks:
Success inserts or replaces the entry, clears `loaded_path` and clears `error`. In-memory keys need not be representable in an SQCat file. See the [template grammar and compile limits](../../../../../advanced/format.md).
