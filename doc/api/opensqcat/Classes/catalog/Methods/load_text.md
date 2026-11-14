# load_text

`bool catalog::load_text(const string&in source, const string&in origin = "");`

## Arguments:
* `const string&in source`: complete SQCat document.
* `const string&in origin = ""`: diagnostic path and successful `loaded_path` provenance; no file is opened.

## Returns:
`true` after validation and installation; `false` on invalid encoding or line endings, invalid/unsupported declarations, malformed entries, template errors or a supported limit.

## Remarks:
The operation is transactional. Success replaces the whole catalog and clears `error`; failure updates `error` while preserving prior entries and `loaded_path`. Empty source is valid. SQCat 1 is used when the version declaration is absent. Only `!sqcat_format_version` is recognized; an unsupported required directive fails, while an unknown optional directive is skipped. Declarations are not messages. See the [format reference](../../../../../advanced/format.md#loading-stages).
