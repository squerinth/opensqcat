# try_format

`bool translator::try_format(const string&in source, string&out text, dictionary@ arguments = null, evaluation_budget@ budget = null);`

## Arguments:
* `const string&in source`: inline template to parse and evaluate.
* `string&out text`: receives the complete result.
* `dictionary@ arguments = null`: optional validated and copied per-call fields.
* `evaluation_budget@ budget = null`: shared allowance, or null for a fresh one.

## Returns:
`true` on success (including empty text). On failure returns `false`, clears `text` and stores a diagnostic in `error`.

## Remarks:
A literal template with no references can succeed with the anonymous default catalog; each local reference must resolve to an existing message in the default catalog. Fields resolve from arguments, then general fields, then provider. Provider results and absence are cached by name for this operation. Inline syntax errors report a one-based UTF-8 byte column without catalog path, key or line. Field text is not reparsed, and no partial result is returned.
