# has

`bool translator::has(const string&in key) const;`

## Arguments:
* `const string&in key`: exact message key to check in the selected default catalog.

## Returns:
`true` if the default catalog contains the key; otherwise `false`.

## Remarks:
An empty template still counts as present. This raw membership query does not change `error`.
