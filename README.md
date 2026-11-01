# OpenSQCat

An implementation of the open SQCat text-localization format for NVGT and
AngelScript. OpenSQCat reads
UTF-8 `.sqcat` catalogs, looks up messages and evaluates bounded text templates,
including conditionals, references and `join` for optional fragments.
It has no input, display, speech, network or application-framework dependencies.

## Quick start

Copy the complete `src/` directory into your project and include
`src/opensqcat.nvgt`. The entry point includes the `src/opensqcat/` implementation
directory; keep them together. Paths passed to the library are used as supplied.

Create `locales/es.sqcat`:

```properties
!sqcat_format_version 1

welcome = Hola, {playername}.
balance = Tienes {money} monedas.
access = {"Puedes editar" if logged_in and (owner or admin) else "Solo lectura"}
```

```nvgt
#pragma console
#include "src/opensqcat.nvgt"

void main() {
    opensqcat::translator messages;
    if (!messages.load("locales/es.sqcat")) {
        println(messages.error.message);
        exit(1);
    }
    println(messages.get("welcome", {{"playername", "Ana"}}));
    println(messages.get("balance", {{"money", 25}}));
    messages.set_variable("logged_in", true);
    messages.set_variable("owner", false);
    messages.set_variable("admin", true);
    println(messages.get("access"));
}
```

`get(key)` finds and evaluates a catalog message. `format(text)` evaluates an
inline template; `lookup(key, output)` retrieves the raw template. `get` returns
the key on failure and records `error`; use `try_get(key, output)` when you need
an explicit success flag. Neither operation sends text to speech or a display.
`load("locales/es.sqcat")` registers `es` and selects it as the default if it is
the first catalog. Later loads add catalogs without changing that selection. Use
`get_from("common", "hint")` for an explicit catalog, and `{$common/hint}` inside
a template. See [catalog management](doc/api/translator.md#catalog-management).

You can pass the returned string to your own console or screen-reader service.

An argument dictionary belongs to one operation. For shared values, use typed
`set_variable(name, value)` calls or replace the general dictionary with
`set_variables()`. These store copies; update them when your game state changes.
For live values, optionally install a provider or resolver function, as shown in
the runnable [example](examples/messages.nvgt). Temporary arguments override
general values; general values override the provider.

Dictionary strings are text; plain numeric and boolean entries use NVGT's
numeric dictionary conversion to double precision (false/true become 0/1).
Typed setters preserve booleans and 64-bit integers. For exact types in temporary
dictionaries, use native NVGT `var`, for example `{{"logged_in", var(true)}}`.
There is no library-specific scalar wrapper. See [field values](doc/api/values.md).

## Documentation

- [The `.sqcat` format and expression grammar](doc/format.md)
- [API index](doc/api/README.md)
- [Catalogs](doc/api/catalog.md)
- [Translation and formatting](doc/api/translator.md)
- [Values and providers](doc/api/values.md)
- [Diagnostics and limits](doc/api/diagnostics.md)

SQCat versions describe the file format independently of library releases.
OpenSQCat currently supports SQCat 1; an absent version declaration means version
1. Version declarations may appear anywhere on their own line. Unsupported or
malformed declarations fail loading. Unknown optional directives (`!?name value`)
are ignored; unknown required directives (`!name value`) fail loading. OpenSQCat
currently implements only `!sqcat_format_version`, with no user directive registry.
See [declarations and directives](doc/format.md#version-declarations).

OpenSQCat does not choose languages, reserve catalog names, infer directory
layouts or install an automatic fallback language. Applications choose files
and handle a missing message according to their needs.

## Verification

Run the independent contract suite and console example with Windows PowerShell:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/test.ps1 -NvgtPath C:/nvgt/nvgt.exe
```

The runner uses `NVGT_EXE`, then `nvgt.exe` on `PATH` when `-NvgtPath` is omitted.
It copies only this project's source, tests, examples and documentation to a unique
directory under `build/`, then executes that standalone copy. It also executes
the complete README program and checks local documentation links, fragments and
source includes. `-BuildDirectory` selects
another output directory. TEMP and TMP are changed only for the runner's process
and restored afterward. Test fixtures and compiler artifacts stay in the build
directory, which is retained for inspection. The tests do not access physical
input or speech services.

The implementation is verified with NVGT 0.90.0-dev, commit
`2fc57173a1044c7ec64c71e4bad30369dd15e47b`. Other builds require validation.

## License

[zlib](LICENSE).
