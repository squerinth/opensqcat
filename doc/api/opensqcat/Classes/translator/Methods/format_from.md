# format_from

`string translator::format_from(const string&in catalog_name, const string&in source, dictionary@ arguments = null, evaluation_budget@ budget = null);`

## Arguments:
* `const string&in catalog_name`: registered catalog name passed through without case normalization; empty selects the default.
* `const string&in source`: inline template source.
* `dictionary@ arguments = null`: optional validated and copied per-call fields.
* `evaluation_budget@ budget = null`: shared allowance, or null for a fresh budget.

## Returns:
Complete formatted text on success; empty text on failure. Inspect `error` to distinguish an error from valid empty text.

## Remarks:
A nonempty `catalog_name` must name a registered catalog even if the inline source has no references; an empty name selects the default, which may be anonymous. Each local reference must resolve to an existing message in the selected catalog. Fields resolve from per-call arguments, then general fields, then provider; empty/false/zero values block lower priorities. Provider values and absence are cached by name during the operation. Inline syntax errors report a one-based UTF-8 byte column and have no catalog path, key or line. No partial result is returned and field text is not reparsed.
