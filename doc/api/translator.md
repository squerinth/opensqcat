# opensqcat::translator

Combines catalogs, copied general fields and an optional dynamic field provider.
It returns text and never delivers it to an output service. The usual operation
is `get(key)`; `format(source)` is for inline templates.

## Construction and configuration

```nvgt
translator(catalog@ messages = null);
void set_catalog(catalog@ source);
void set_provider(field_provider@ source);
void set_resolver(field_resolver@ callback);
diagnostic@ get_error() const property;
```

Construction retains the supplied catalog; null creates a new empty catalog.
`set_catalog(source)` replaces the current default; null installs a new empty
one. If the default is named, the registration is replaced too.
Neither operation changes general fields or the provider. A supplied constructor
catalog counts as an installed anonymous default. Calling `set_catalog(source)`,
including with null, also installs a default. A translator constructed without a
catalog selects the first successful load or named registration automatically
unless a default has already been installed explicitly.

`set_provider` retains the supplied provider; null removes it. `set_resolver`
installs a function or delegate through an internal provider, replacing any
previous provider. Null removes the provider. These configuration changes clear
`error` and apply to the next formatting operation.

## General variables

```nvgt
bool set_variables(dictionary@ fields);
bool set_variable(const string&in name, const string&in text);
bool set_variable(const string&in name, bool flag);
bool set_variable(const string&in name, int number);
bool set_variable(const string&in name, uint number);
bool set_variable(const string&in name, int64 number);
bool set_variable(const string&in name, uint64 number);
bool set_variable(const string&in name, float number);
bool set_variable(const string&in name, double number);
bool set_variable(const string&in name, var@ source);
bool remove_variable(const string&in name);
void clear_variables();
```

`set_variable` adds or replaces one copied field, preserving the supplied scalar
type. Names must be nonempty UTF-8. Invalid names or values return false with an
`argument` diagnostic and preserve existing fields. Booleans remain booleans;
integers retain their full signed/unsigned 64-bit value. Real values must be
finite; text must be UTF-8. Empty/null variants and nonscalar variants are rejected.

`set_variables` validates and copies every entry, replacing the entire general
dictionary only on success. Null clears all general fields. Changing the original
dictionary or native variants afterward does not change the copy. Invalid input
returns false with an `argument` diagnostic and preserves previous fields.
See [dictionary values](values.md#dictionary-arguments) for numeric conversion
when using plain dictionary entries instead of typed setters or `var`.

`remove_variable` removes one general field and returns whether it was present.
`clear_variables` removes all general fields. These operations and successful
setters clear `error`. They never modify temporary arguments or the provider.
General variables are data, not catalog entries or live application bindings.

## Catalog management

```nvgt
bool set_catalog(const string&in name, catalog@ source);
bool remove_catalog(const string&in name);
bool has_catalog(const string&in name) const;
string get_default_catalog() const property;
bool set_default_catalog(const string&in name);
```

Named `set_catalog` retains a catalog under a nonempty UTF-8 name; null installs
an empty catalog. Existing registrations are replaced without changing load
order. If no default has been installed, this becomes the default. Replacing the
current named default updates ordinary `get` and `format` too. Invalid names
return false with `argument`, preserving the registry.

`default_catalog` reports the selected name, or empty text for an anonymous
in-memory default. `set_default_catalog(name)` selects an existing named catalog;
absence returns false with `catalog` and preserves the current selection.

`remove_catalog(name)` returns whether a named registration was removed. Removing
the default selects the earliest remaining registration in incorporation order.
If none remain, the translator has an empty anonymous default until the next
successful installation. Removing and registering a name again appends it to the
order. The anonymous default is not removable by `remove_catalog("")`.

`has_catalog(name)` checks registration; empty selects the always-available
anonymous/default view. It does not change `error`. Successful configuration and
removal operations clear `error`. Registry changes do not affect an operation
already evaluating messages.

## Loading and raw lookup

```nvgt
bool load(const string&in path, const string&in name = "");
bool load_text(const string&in source, const string&in origin = "", const string&in catalog_name = "");
bool has(const string&in key) const;
bool has_from(const string&in catalog_name, const string&in key) const;
bool lookup(const string&in key, string&out text) const;
bool lookup_from(const string&in catalog_name, const string&in key, string&out text) const;
```

`load` installs/reloads one named catalog transactionally. When `name` is omitted,
it uses the final filename component, removing a final `.sqcat` suffix
case-insensitively. Both slash styles are recognized; the remaining spelling and
case are retained. An empty inferred name is an `argument` error. Loading a second
file leaves the first default selected; reloading an existing name preserves its
position in incorporation order.

Named `load_text` installs/reloads that name. Without a name, it replaces the
current default, creating an anonymous in-memory default if none was installed.
`origin` supplies diagnostic provenance only; it is not used for naming.

A failed load preserves messages, registry, default and order; a failed new name
is not registered. Successful loads clear `error`. They do not change general
fields or the provider. Other translators retaining the same catalog object see
successful reloads on their next operation. See [catalog loading](catalog.md#loading).

`has` and `lookup` use the default; `_from` selects a name explicitly. Empty
`catalog_name` selects the default. Keys are always literal, including slashes.
`lookup` retrieves the raw template and a presence flag, clearing `text` if the
catalog or key is absent. These queries do not change `error`.

## Getting translated messages

```nvgt
string get(const string&in key, dictionary@ arguments = null, evaluation_budget@ budget = null);
bool try_get(const string&in key, string&out text, dictionary@ arguments = null, evaluation_budget@ budget = null);
string get_from(const string&in catalog_name, const string&in key, dictionary@ arguments = null, evaluation_budget@ budget = null);
bool try_get_from(const string&in catalog_name, const string&in key, string&out text, dictionary@ arguments = null, evaluation_budget@ budget = null);
```

`get` and `try_get` use the default catalog; `_from` selects a named catalog.
An empty name selects the default. `key` is always literal, never an expression
or a catalog/key path. The selected template
and referenced messages are evaluated with these field priorities:

1. Temporary `arguments` supplied for this call.
2. General fields installed with the setters.
3. The dynamic provider, if present.

A present empty/false/zero field blocks lower priorities. Arguments are validated
and copied for the operation. The default selection, every registered catalog, general fields and provider
are captured before callbacks run. Provider results, including absence, are resolved
once per field name per operation and shared across included messages, even
when references cross catalog boundaries. The next
operation resolves them again.

`get` returns the evaluated message, including valid empty text. On any failure,
it returns the supplied key and records a diagnostic. It does not emit a partially
formatted message. `try_get` returns true on success; on failure it returns false,
clears `text` and records a diagnostic. Use it when missing messages, invalid
arguments or evaluation errors must be distinguished from valid text. Successful
operations clear `error`. There is no automatic fallback language or template.

## Formatting supplied text

```nvgt
string format(const string&in source, dictionary@ arguments = null, evaluation_budget@ budget = null);
bool try_format(const string&in source, string&out text, dictionary@ arguments = null, evaluation_budget@ budget = null);
string format_from(const string&in catalog_name, const string&in source, dictionary@ arguments = null, evaluation_budget@ budget = null);
bool try_format_from(const string&in catalog_name, const string&in source, string&out text, dictionary@ arguments = null, evaluation_budget@ budget = null);
```

These operations parse and evaluate `source` directly instead of looking it up as
a message key. Local references inside the source use the default catalog, or
the catalog selected by `_from`. The selected catalog must exist even if the
inline template contains no references. They share
the same field rules and budgets as message retrieval.

The strict form returns false and clears output on failure. `format` returns
empty text on failure. Both update `error`; inline syntax diagnostics have no
catalog path, key or line, and report a one-based UTF-8 byte column in `source`.
Successful operations clear `error`.

Returned field text is never reparsed as an expression or catalog reference.

## Shared evaluation budgets

Every rendering method accepts an optional final `evaluation_budget@ budget`.
Null creates a fresh budget for that operation. Passing the same budget to several
calls accumulates their evaluation steps and generated bytes; it does not share
catalog snapshots, argument dictionaries or provider-result caches between calls.
See [evaluation_budget](budget.md).
