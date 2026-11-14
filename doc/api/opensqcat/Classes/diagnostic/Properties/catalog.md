# catalog

`string diagnostic::catalog;`

Catalog name associated with the error when available. Evaluation failures identify the containing catalog; missing roots identify the requested catalog. For `translator.load`, an open failure or rejection for the catalog byte limit or returned content records the name only after a valid, nonempty name has been selected. An invalid UTF-8 name or empty inferred name fails before loading and leaves this field empty. For `translator.load_text`, failure to process or parse the supplied text records the valid supplied `catalog_name`, or the selected `default_catalog_name` when the argument is empty; an invalid UTF-8 `catalog_name` fails before loading and leaves this field empty. Interpret an empty value with `code` and `message` to distinguish anonymous from unavailable.
