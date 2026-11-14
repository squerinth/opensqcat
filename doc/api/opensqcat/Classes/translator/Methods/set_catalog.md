# set_catalog

Updates the selected default catalog or registers a named catalog.

1. `void translator::set_catalog(catalog@ source);`
2. `bool translator::set_catalog(const string&in name, catalog@ source);`

## Arguments (1):
* `catalog@ source`: catalog to install as the default; null installs a new empty catalog.

## Arguments (2):
* `const string&in name`: nonempty valid UTF-8 name for the registration, passed through without case normalization.
* `catalog@ source`: catalog to register; null installs a new empty catalog.

## Returns (2):
`true` when registration succeeds. `false` for an empty or invalid UTF-8 name; the registry is preserved and `error` reports `argument`.

## Remarks:
Both overloads retain a non-null `source` handle rather than copying its catalog; a null handle is replaced with a new empty catalog. Mutations through a retained handle are visible to operations that start afterward. Each evaluation snapshots its catalogs at the start, so later mutations do not affect an operation already in progress. The first overload marks the default as explicitly installed, so automatic selection will not replace it. If the current default is named, its registry entry is also replaced. General variables and provider configuration are unchanged. The second overload preserves a replaced registration's place in incorporation order and appends a new registration. If no default has been explicitly installed, the first successful named registration becomes the default; replacing the named default updates the selected catalog. Successful calls clear `error`.
