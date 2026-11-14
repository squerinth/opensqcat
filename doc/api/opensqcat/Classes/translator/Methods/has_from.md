# has_from

`bool translator::has_from(const string&in catalog_name, const string&in key) const;`

## Arguments:
* `const string&in catalog_name`: registered name passed through without case normalization, or empty to select the default catalog.
* `const string&in key`: exact message key to check.

## Returns:
`true` if the selected catalog contains the key; otherwise `false`.

## Remarks:
Unknown catalog names produce `false`. An empty template still counts as present. This raw membership query does not change `error`.
