# Application integration

This guide explains catalog selection, field resolution and error-handling
decisions for applications. For a guided first program, start with the
[tutorials](../tutorials/README.md). Exact signatures are in the
[API reference](../api/README.md).

## Load and select catalogs

`load("locales/en.sqcat")` registers a catalog as `en`. The first successfully
loaded named catalog becomes the default only if no default was installed
explicitly earlier; later named loads leave that selection unchanged. A
non-null `translator(catalog@)` argument, `set_catalog(catalog@)`,
`set_default_catalog(name)` or successful `load_text` with an empty
`catalog_name` explicitly installs or replaces the default. Paths are used as
supplied. Applications choose their own directory layout and language policy.

Use `set_default_catalog("en")` to select a loaded catalog. Use
`get_from("common", "hint")` to retrieve from another catalog explicitly. Inside
a template, `{$hint}` references the containing catalog and `{$common/hint}`
references a loaded catalog named `common`. These references do not load files.

Check the boolean return from loading and selection operations. A failed load
preserves the previous catalog and default selection. For naming, replacement
and removal rules, see [catalog management](../api/opensqcat/Classes/translator/Methods/set_catalog.md)
and [loading](../api/opensqcat/Classes/translator/Methods/load.md).

## Supply application values

Fields are resolved in this order:

1. Temporary arguments passed to a single formatting call.
2. General values stored with `set_variable` or `set_variables`.
3. An optional dynamic provider or resolver.

A present empty string, zero or false value stops the search. General setters
store copies; update them when application state changes. For live values, use
the provider or resolver pattern in the [live-values tutorial](../tutorials/live-values.md).
Provider results are cached for one formatting operation, including references.

Dictionary strings are text. Plain dictionary numbers and booleans use NVGT's
double-precision conversion; false/true become 0/1, and large integers can lose
precision. Typed setters preserve booleans and 64-bit integers. Use native `var`
for exact types in temporary dictionaries, such as `{{"logged_in", var(true)}}`.
See [values and providers](../api/concepts/field-values.md) for validation and lifetime rules.

## Retrieve text and handle failures

`get(key)` looks up and evaluates a catalog message. `format(text)` evaluates an
inline template. `lookup(key, output)` retrieves a raw template without evaluation.

On failure, `get` returns the supplied key and `format` returns empty text. For
an explicit result, use `try_get` or `try_format`: they return false, clear the
output and set `error`. Successful evaluations clear `error`. Valid messages can
produce empty text, so output length alone does not establish success.

Inspect `error.code`, `message`, `path`, `catalog`, `key`, `line` and `column` as
needed. See [diagnostics](../api/concepts/diagnostics.md). The library returns diagnostics
without logging them. Applications decide whether to display an error, choose a
fallback language or supply alternative text; no automatic fallback is installed.

## Write templates

Catalogs contain one `key = template` per line. Templates support fields,
references, comparisons, short-circuit conditions and `join` for optional parts.
Field values are inserted as data and are never parsed again as templates.

Read the [SQCat specification](format.md) for syntax, version declarations,
directives and numeric behavior. OpenSQCat supports SQCat 1 and recognizes only
`!sqcat_format_version`. Unknown optional directives are ignored; unknown required
directives fail loading. There is no application directive registry.

Evaluation has [resource limits](../api/concepts/diagnostics.md#limits). An optional
[shared budget](../api/opensqcat/Classes/evaluation_budget/!evaluation_budget.md) bounds work across several rendering calls.
