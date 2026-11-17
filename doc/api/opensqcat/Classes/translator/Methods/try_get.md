# try_get

`bool translator::try_get(const string&in key, string&out text, dictionary@ arguments = null, evaluation_budget@ budget = null);`

## Arguments:
* `const string&in key`: literal key in the selected default catalog.
* `string&out text`: receives the complete evaluated message.
* `dictionary@ arguments = null`: optional validated and copied per-call fields.
* `evaluation_budget@ budget = null`: shared allowance, or null for a fresh one.

## Returns:
`true` on success, including when the message is empty. On failure, returns `false`, clears `text` and records the diagnostic in `error`.

## Remarks:
No automatic language or template fallback occurs.
The key is literal. Fields resolve in this order: per-call arguments, general fields, then provider. Present empty, false or zero values block lower-priority sources. Provider results and missing fields are cached once per field name during the operation. The operation captures its catalog and field configuration before provider callbacks. It never returns partial formatted text. Evaluation failures include a missing catalog/message, missing required field, provider failure, reference cycle, invalid argument or exhausted budget.
