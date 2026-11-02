# OpenSQCat

**Text localization and bounded templates for NVGT.**

SQCat **1** · zlib license

OpenSQCat reads UTF-8 `.sqcat` catalogs and formats messages using values from
your application. It supports named catalogs, message references, conditional
expressions, optional text fragments with `join`, and dynamic field providers.
Catalog format and template syntax are validated before installation, and evaluation has resource limits
and structured error diagnostics.

## Requirements

Install NVGT from its [official releases](https://github.com/samtupy/nvgt/releases).
Development and testing use NVGT's Latest/Bleeding Edge Development Version.
OpenSQCat has been tested with NVGT `0.90.0-dev` on Windows; other builds and
platforms have not been verified.
Repository verification tools require Windows PowerShell; using the library does not require those tools.

## Installation

Download the OpenSQCat ZIP from the
[latest release](https://github.com/squerinth/opensqcat/releases/latest) and extract it.
The archive has four top-level entries:

```
opensqcat/
    docs/
    LICENSE
    opensqcat/
    opensqcat.nvgt
examples/
opensqcat.nvgt
README.md
```

The redistributable `opensqcat/` folder includes the library source, complete
documentation and license notice.

### Project installation

Copy the archive's `opensqcat/` folder into your project. With that folder beside
your program, include the library with:

```nvgt
#include "opensqcat/opensqcat.nvgt"
```

Keep the whole folder together, including `LICENSE` and `docs/`, when copying or
redistributing the library. No separate build step is required.

### Global installation

Copy the same `opensqcat/` folder into your NVGT include directory, such as
`C:/nvgt/include`. Then create `opensqcat.nvgt` directly in that include directory,
outside the folder, containing:

```nvgt
#include "opensqcat/opensqcat.nvgt"
```

The release also includes this wrapper file, ready to copy. Programs can then
use `#include "opensqcat.nvgt"` from any project directory. NVGT resolves the
wrapper's relative include without changes to its include configuration.

### Using the source repository

The repository keeps the library source in `src/`, documentation in `doc/` and
the license at the root. Copy `src/` to the destination as `opensqcat/`, copy
`LICENSE` into that folder, and copy `doc/` into it as `docs/`. Then follow the
corresponding project or global installation instructions above. The release ZIP
already assembles this layout. No separate library compilation is required.

## Quick start

After a project installation, create `locales/en.sqcat` beside your program:

```properties
!sqcat_format_version 1

welcome = Hello, {playername}.
balance = You have {money} coins.
access = {"You can edit" if logged_in and (owner or admin) else "Read only"}
```

then, save this program as `hello.nvgt` beside `opensqcat/` and `locales/`:

```nvgt
#pragma console
#include "opensqcat/opensqcat.nvgt"

void main() {
	opensqcat::translator messages;
	if (!messages.load("locales/en.sqcat")) {
		println(messages.error.message);
		exit(1);
	}
	println(messages.get("welcome", {{"playername", "Alex"}}));
	println(messages.get("balance", {{"money", 25}}));
	messages.set_variable("logged_in", true);
	messages.set_variable("owner", false);
	messages.set_variable("admin", true);
	println(messages.get("access"));
}
```

Run it with your NVGT executable:

```powershell
C:/nvgt/nvgt.exe -w 2 hello.nvgt
```

Expected output:

```text
Hello, Alex.
You have 25 coins.
You can edit
```

Temporary dictionary arguments use NVGT's numeric conversion for plain numbers
and booleans. Use `var(true)` to preserve a boolean and `var(int64(...))` or
`var(uint64(...))` for exact 64-bit integers. See [field values](doc/api/values.md#dictionary-arguments).

## Documentation

Read the [detailed documentation](doc/README.md) for tutorials, the API reference
and advanced developer documentation. It is included in every release.

## License

OpenSQCat is distributed under the zlib license. See [LICENSE](LICENSE).
The installable library folder carries the complete notice; retain it when
redistributing the library source.
