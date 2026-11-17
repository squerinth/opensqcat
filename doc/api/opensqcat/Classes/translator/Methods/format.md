# format

`string translator::format(const string&in source, dictionary@ arguments = null, evaluation_budget@ budget = null);`

## Arguments:
* `const string&in source`: inline template source to parse and evaluate.
* `dictionary@ arguments = null`: optional validated and copied per-call fields.
* `evaluation_budget@ budget = null`: optional shared allowance; null creates a fresh budget.

## Returns:
Complete formatted text on success. Empty text on failure; inspect `error` to distinguish failure from a valid empty result.

## Remarks:
Unlike `get`, this parses `source` as a template rather than looking up a key. A literal template with no references can succeed with the anonymous default catalog; each local reference must resolve to an existing message in the default catalog. Fields resolve by per-call arguments, general fields, then provider; present empty/false/zero values block lower priorities. No partial output is returned. Inline syntax errors have a one-based UTF-8 byte column and no catalog path, key or line. Returned field text is not reparsed.
