# set_variables

`bool translator::set_variables(dictionary@ fields);`

## Arguments:
* `dictionary@ fields`: dictionary of general fields to validate and copy; null means an empty dictionary.

## Returns:
`true` when every entry is valid and the complete copied dictionary replaces the previous general fields. `false` if any field name or value is unsupported or invalid; the old fields remain unchanged and `error` reports `argument`.

## Remarks:
The input dictionary and native `var` payloads are copied, so later mutations do not change the translator's fields. Plain numeric dictionary values use NVGT's double conversion; use `var` entries or typed [set_variable](set_variable.md) calls when preserving signedness or 64-bit integer precision matters. Input integer width and `float`-versus-`double` distinctions are not retained. Success clears `error`.
