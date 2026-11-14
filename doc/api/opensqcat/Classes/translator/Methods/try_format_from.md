# try_format_from

`bool translator::try_format_from(const string&in catalog_name, const string&in source, string&out text, dictionary@ arguments = null, evaluation_budget@ budget = null);`

## Arguments:
* `const string&in catalog_name`: registered catalog name passed through without case normalization; empty selects the default.
* `const string&in source`: inline template source to parse and evaluate.
* `string&out text`: receives the full result.
* `dictionary@ arguments = null`: optional validated and copied per-call fields.
* `evaluation_budget@ budget = null`: shared allowance, or null for a fresh one.

## Returns:
`true` on success, including empty text. On failure returns `false`, clears `text` and records the diagnostic in `error`.

## Remarks:
A nonempty `catalog_name` must name a registered catalog even if the source contains no references; an empty name selects the default, which may be anonymous. Each local reference must resolve to an existing message in the selected catalog. Fields resolve in priority order: arguments, general fields, provider. Present empty/false/zero values block lower sources. Provider values and absence are cached once per field name for this call. Inline syntax errors report a one-based UTF-8 byte column without catalog path, key or line. Returned field text is not parsed again; failures never return partial output.
