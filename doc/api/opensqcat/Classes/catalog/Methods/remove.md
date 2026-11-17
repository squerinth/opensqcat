# remove

`bool catalog::remove(const string&in key);`

## Arguments:
* `const string&in key`: exact, case-sensitive key to remove.

## Returns:
`true` if an entry was removed; otherwise `false`.

## Remarks:
Clears `error` whether or not a key existed. Clears `loaded_path` only if an entry was removed.
