# has_catalog

`bool translator::has_catalog(const string&in name) const;`

## Arguments:
* `const string&in name`: registered catalog name, passed through without case normalization, or empty text to select the default view.

## Returns:
`true` if the name is registered. Empty `name` always returns `true` because the translator always has a default view, which may be anonymous.

## Remarks:
Does not change `error`.
