# opensqcat::catalog

Stores raw templates and their parsed representation. All keys are exact,
case-sensitive UTF-8 strings. Templates are validated before installation.

## Construction and properties

```nvgt
catalog(); // Implicit default construction.
diagnostic@ get_error() const property;
string get_loaded_path() const property;
uint get_size() const property;
```

- `error`: detached diagnostic from the latest load or mutation. An empty code
  means success. Read operations do not change it.
- `loaded_path`: origin of the latest successful complete load. Successful
  in-memory mutations clear it. Failed operations preserve it.
- `size`: number of messages, including empty messages.

## Loading

```nvgt
bool load(const string&in path);
bool load_text(const string&in source, const string&in origin = "");
```

`load` reads the supplied path as UTF-8 `.sqcat` text. `load_text` parses supplied
text, using `origin` only as its diagnostic path and successful `loaded_path`.
They return true after replacing the entire catalog. An encoding, structural,
version, directive, syntax, limit or I/O error returns false, updates `error` and preserves all
previous messages and their provenance. Successful loads clear the error.

Version selection and preprocessing happen before message compilation; see
[loading stages](../advanced/format.md#loading-stages). OpenSQCat supports SQCat 1, using
that version when no declaration exists. Unsupported/malformed versions and
required unknown directives fail loading. Unknown optional directives are skipped.
Only `!sqcat_format_version` is recognized; no user directive registration or
dynamic directive mutation is provided. Declarations do not contribute to `size`,
`keys()` or lookups. Reload the whole catalog to change preprocessing decisions.

An empty file is valid. Missing fields or references do not fail loading; only
an evaluated use can require them. See the [format](../advanced/format.md).

## Reading

```nvgt
bool contains(const string&in key) const;
bool lookup(const string&in key, string&out text) const;
string[]@ keys() const;
```

- `contains`: true for a present key, including an empty template.
- `lookup`: returns the raw template, with true for presence. A missing key
  returns false and clears `text`. No interpolation occurs.
- `keys`: returns a separate array of all keys, with unspecified order.

## Editing

```nvgt
bool set(const string&in key, const string&in text);
bool remove(const string&in key);
void clear();
```

`set` validates a nonempty UTF-8 key and a UTF-8 template, then installs or
replaces that entry. It returns false on error without changing the old entry.
In-memory keys need not be representable in a `.sqcat` file. A successful set
clears `loaded_path` and `error`.

`remove` returns whether a key was removed. It clears `error`; it clears
`loaded_path` only when a key was actually removed. `clear` removes all entries
and clears provenance and errors.

Catalog objects may be shared by translators. Each rendering operation retains
the templates selected at its start. Changes made during a provider callback
apply to later operations, including calls through other translators that share
the catalog.
