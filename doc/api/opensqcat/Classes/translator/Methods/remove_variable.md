# remove_variable

`bool translator::remove_variable(const string&in name);`

## Arguments:
* `const string&in name`: name of a general field.

## Returns:
`true` if a general field with that name was present; otherwise `false`.

## Remarks:
Clears `error`. It does not alter temporary arguments or the provider.
