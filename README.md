# OpenSQCat

**Text localization and bounded templates for NVGT.**

Version **0.1.0** · SQCat **1** · zlib license

OpenSQCat reads UTF-8 `.sqcat` catalogs and formats messages using values from
your application. It supports named catalogs, message references, conditional
expressions, optional text fragments with `join`, and dynamic field providers.
Catalog format and template syntax are validated before installation, and evaluation has resource limits
and structured error diagnostics.

## Requirements

Install NVGT from its [official releases](https://github.com/samtupy/nvgt/releases).
Development and testing use NVGT's Latest/Bleeding Edge Development Version.
OpenSQCat has been tested with NVGT `0.90.0-dev` on Windows; other builds and
platforms have not been verified. Repository verification tools require Windows
PowerShell; using the library does not require those tools.

## Installation

Download an OpenSQCat ZIP from the
[releases page](https://github.com/squerinth/opensqcat/releases) and extract it.
The archive includes the library, examples and complete documentation.

Stable releases use version tags such as `v0.1.0`. Automatic nightly prereleases
identify a date and commit; they are development builds with no stability
guarantee. Choose a stable release for normal use.

### Project installation

Copy the archive's `opensqcat/` folder into your project. With that folder beside
your program, include the library with:

```nvgt
#include "opensqcat/opensqcat.nvgt"
```

Keep the whole folder together. No separate build step is required.

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

The repository keeps the library in `src/`. Copy that directory into your
project or NVGT include directory and rename the copy to `opensqcat/`, then follow
the corresponding installation instructions above. The library is written
entirely in NVGT and requires no compilation before use.

## Quick start

After a project installation, create `locales/en.sqcat` beside your program:

```properties
!sqcat_format_version 1

welcome = Hello, {playername}.
balance = You have {money} coins.
access = {"You can edit" if logged_in and (owner or admin) else "Read only"}
```

Save this program as `hello.nvgt` beside `opensqcat/` and `locales/`:

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
