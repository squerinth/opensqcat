# set_default_catalog

`bool translator::set_default_catalog(const string&in name);`

## Arguments:
* `const string&in name`: name of a currently registered catalog, passed through without case normalization.

## Returns:
`true` when an existing named catalog becomes the selected default. `false` if that name is not registered; the current selection is preserved and `error` reports `catalog`.

## Remarks:
The selected name becomes the value of `default_catalog`. Success clears `error`. The anonymous default cannot be selected by name.
