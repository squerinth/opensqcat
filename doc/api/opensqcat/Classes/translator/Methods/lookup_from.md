# lookup_from

`bool translator::lookup_from(const string&in catalog_name, const string&in key, string&out text) const;`

## Arguments:
* `const string&in catalog_name`: registered catalog name passed through without case normalization, or empty to select the default.
* `const string&in key`: exact message key.
* `string&out text`: receives the raw template.

## Returns:
`true` if the selected catalog contains the key. If the catalog or key is absent, returns `false` and clears `text`.

## Remarks:
Returns raw template text without interpolation and does not change `error`.
