# load

`bool catalog::load(const string&in path);`

## Arguments:
* `const string&in path`: path to read as UTF-8 SQCat text.

## Returns:
`true` when the content returned by the file read is validated and installed. Returns `false` if opening fails, the catalog byte limit is exceeded, or the returned content fails decoding, parsing, compilation or another supported validation limit.

## Remarks:
Success replaces all entries and records `path` in `loaded_path`. Failure updates `error` but preserves previous entries and provenance. The input byte limit includes BOM and comments. The method makes one `read()` call and closes the file without querying a `fail` or `good` status afterward; it does not independently report a short or failed read if the returned content passes validation. See [load_text](load_text.md) and [loading stages](../../../../../advanced/format.md#loading-stages).
