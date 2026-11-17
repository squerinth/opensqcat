# Application integration

OpenSQCat loads catalogs, resolves template fields and returns text. The
application controls which files to load, which catalog to use for a language,
how to handle failures, and how to display or speak the result.

## Load and select catalogs

`translator.load(path)` registers a catalog using the file name without its
final `.sqcat` suffix. For example, loading `locales/en.sqcat` registers `en`.
The first successfully loaded named catalog becomes the default unless the
program has already explicitly selected one. Loading later named catalogs does
not change that selection.

Call `set_default_catalog("fr")` after loading `fr.sqcat` to switch languages.
Use `get_from("common", "controls")` when a particular operation should use a
different loaded catalog. In templates, `{$hint}` references the catalog
containing the current message and `{$common/hint}` references the loaded
catalog named `common`. A reference never loads a file or searches other
catalogs for a missing key.

The named overload of `set_catalog(name, catalog)` registers or replaces a
catalog; the unnamed overload installs a catalog as the default. Registering
the first named catalog selects it only if no default was explicitly selected.
The unnamed overload also replaces the registered object when the current
default is named. Removing the selected named catalog selects the earliest
remaining registration, or an empty anonymous catalog if none remain. Failed
file loads preserve the previous catalog and selection.

## Supply application values

Fields are resolved in this order:

1. Arguments passed to the current formatting call.
2. General values stored with `set_variable` or `set_variables`.
3. A dynamic provider or resolver, if installed.

A value that exists stops the search even if it is empty text, zero or false.
General values and dictionary arguments are copied; changing their source later
does not update a stored value. A provider or resolver is called for fields not
found in those sources. Results and absence are cached by name for one formatting
operation, including messages referenced during that operation.

Typed `set_variable` calls preserve text, boolean, signed integer, unsigned
integer and real categories (integers retain 64-bit precision). In dictionaries,
strings remain text, while plain numbers and booleans are converted through
NVGT's double-precision numeric representation: false/true become 0/1 and large
integers can lose precision. Use `var(true)` or `var(int64(...))` in dictionary
arguments when the original category or full integer precision matters.

## Retrieve text and handle failures

- `get(key)` formats a message from the selected default catalog. It returns
  `key` on failure.
- `get_from(catalog, key)` does the same using a named catalog; an empty catalog
  name selects the default.
- `format(template)` formats an inline template. It returns empty text on
  failure.
- `lookup(key, output)` retrieves the raw template without evaluating it.
- `try_get`, `try_get_from`, `try_format` and `try_format_from` return `false`
  on failure, clear the output and leave a diagnostic in `error`. They return
  `true` for valid empty text.

Check the return value when failure must be distinguished from valid text. The
diagnostic provides a machine-readable `code` and a human-readable `message`,
with `path`, `catalog`, `key`, `line` and `column` when available. Common codes
include `io`, `encoding`, `syntax`, `catalog`, `message`, `field`, `provider`,
`cycle` and `limit`. The library does not log diagnostics. The application
decides whether to show an error, supply fallback text or select another
language; no automatic fallback is installed.

## Write templates

Catalogs contain one `key = template` entry per line. Templates can insert
fields, include messages from loaded catalogs, select text with comparisons and
conditions, and combine optional fragments with `join`. Inserted values are
data; they are not parsed again as templates. OpenSQCat implements SQCat 1 and
recognizes only the `!sqcat_format_version` declaration. Unknown optional
directives are ignored and unknown required directives fail loading. The
[format specification](format.md) defines the complete file and expression
grammar.

## Evaluation limits

OpenSQCat applies these limits:

| Resource | Limit |
| --- | --- |
| Catalog input | 16 MiB of UTF-8 bytes. |
| One template source | 1 MiB. |
| Parsed nodes per template | 32,768. |
| Expression nesting | 64 depth units. |
| Active referenced messages | 32, including the root message. |
| Evaluation steps | 65,536 per formatting operation. |
| Cumulative generated text | 1 MiB per formatting operation. |

Generated-text accounting includes intermediate reference and `join` results,
not only the final text. Passing the same `evaluation_budget` to several calls
shares the step and generated-text allowances across those calls; depth and
active-reference limits remain per operation. These are fixed library limits,
not controls for application code or provider execution.
