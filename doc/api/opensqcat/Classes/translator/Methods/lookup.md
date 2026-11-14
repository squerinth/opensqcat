# lookup

`bool translator::lookup(const string&in key, string&out text) const;`

## Arguments:
* `const string&in key`: exact key to retrieve from the default catalog.
* `string&out text`: receives the raw template.

## Returns:
`true` if the key is present. If the catalog or key is absent, returns `false` and clears `text`.

## Remarks:
Returns the raw stored template without evaluation. Does not change `error`.
