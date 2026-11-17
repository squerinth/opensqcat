# load

`bool translator::load(const string&in path, const string&in name = "");`

## Arguments:
* `const string&in path`: file path of the SQCat catalog to read.
* `const string&in name = ""`: registration name passed through as supplied. Empty text infers the name from the final filename component, preserving its spelling apart from removal of a final `.sqcat` suffix.

## Returns:
`true` when the file loads and the named catalog is installed/reloaded. `false` if the inferred or supplied name is invalid/empty or catalog loading fails; registry, selection and existing messages are preserved.

## Remarks:
Name inference recognizes both slash styles and removes a final `.sqcat` suffix case-insensitively, preserving the remaining spelling and case. A new named load does not change an already installed default. Reloading an existing name preserves its position in incorporation order. Loading does not modify general fields or the provider. After a valid, nonempty name is selected, an open failure or rejection for the catalog byte limit or returned content identifies it in `error.catalog`. An invalid UTF-8 name or empty inferred name fails validation before loading, so `error.catalog` remains empty. See [catalog.load](../../catalog/Methods/load.md).
