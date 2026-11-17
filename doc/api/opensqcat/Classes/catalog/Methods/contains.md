# contains

`bool catalog::contains(const string&in key) const;`

## Arguments:
* `const string&in key`: exact, case-sensitive key to test.

## Returns:
`true` if the key is present, including if its template is empty; otherwise `false`.

## Remarks:
This is a membership check only. It does not evaluate the template or change the catalog diagnostic.
