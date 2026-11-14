# lookup

`bool catalog::lookup(const string&in key, string&out text) const;`

## Arguments:
* `const string&in key`: exact, case-sensitive key to retrieve.
* `string&out text`: receives the raw stored template.

## Returns:
`true` if the key exists. If absent, returns `false` and clears `text`.

## Remarks:
No interpolation occurs. This read operation does not change the catalog diagnostic.
