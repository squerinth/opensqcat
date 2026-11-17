# remove_catalog

`bool translator::remove_catalog(const string&in name);`

## Arguments:
* `const string&in name`: name of a registered catalog, passed through without case normalization.

## Returns:
`true` if the named registration was removed; otherwise `false`.

## Remarks:
Every call clears `error`. Removing the selected named default selects the earliest remaining registration in incorporation order. If none remain, the translator has an empty anonymous default until another catalog is successfully installed. Removing then registering a name again appends it to the order. The anonymous default is not removable through this method; an empty name matches no registration.
