# Getting started

OpenSQCat loads UTF-8 `.sqcat` catalogs and formats their messages with values
from your NVGT program. It returns text; your program chooses when and where to
display or speak it. Your program also chooses catalog paths, languages and
fallback behavior.

## Requirements

Install NVGT from the
[official releases](https://github.com/samtupy/nvgt/releases). OpenSQCat has
been verified with NVGT `0.90.0-dev` on Windows; other builds and platforms
have not been verified.

## Install OpenSQCat

Download the [latest OpenSQCat release](https://github.com/squerinth/opensqcat/releases/latest)
and extract its ZIP. The four top-level entries are:

```tree
opensqcat/              installable library folder
examples/               example programs and catalogs
opensqcat.nvgt          wrapper for a global installation
README.md
```

The complete installable folder contains the library entry point, implementation
files, this documentation and the license:

```tree
opensqcat/
    opensqcat.nvgt
    opensqcat/
    docs/
    LICENSE
```

### Install into one project

Copy the release's complete `opensqcat/` folder beside your program. Keep its
contents together, including `docs/` and `LICENSE`. No separate library build
is needed. Include the library with:

```nvgt
#include "opensqcat/opensqcat.nvgt"
```

### Install globally

Copy the same `opensqcat/` folder into your NVGT include directory, such as
`C:/nvgt/include`. Copy the release's top-level `opensqcat.nvgt` wrapper into
that directory too. A program can then use:

```nvgt
#include "opensqcat.nvgt"
```

### Install from a source checkout

Copy `src/` as `opensqcat/`, `doc/` as `opensqcat/docs/`, and the root
`LICENSE` into `opensqcat/`. For a global installation, create the same
`opensqcat.nvgt` wrapper beside that folder with this contents:

```nvgt
#include "opensqcat/opensqcat.nvgt"
```

The release ZIP already assembles this layout.

## Run your first translation

Create a project with this layout. The `opensqcat/` folder is the one copied
from the release:

```tree
hello-project/
    hello.nvgt
    opensqcat/
    locales/
        en.sqcat
```

Save this UTF-8 catalog as `locales/en.sqcat`:

```properties
!sqcat_format_version 1

welcome = Hello, {name}.
```

Save this program as `hello.nvgt`:

```nvgt
#include "opensqcat/opensqcat.nvgt"

void main() {
	opensqcat::translator messages;
	if (!messages.load("locales/en.sqcat")) {
		alert("OpenSQCat", messages.error.message);
		exit(1);
	}
	if (!messages.set_variable("name", "Alex")) {
		alert("OpenSQCat", messages.error.message);
		exit(1);
	}

	string greeting;
	if (!messages.try_get("welcome", greeting)) {
		alert("OpenSQCat", messages.error.message);
		exit(1);
	}
	alert("Welcome", greeting);
}
```

From `hello-project/`, run it with your NVGT executable:

```powershell
C:/nvgt/nvgt.exe hello.nvgt
```

The program opens a dialog titled **Welcome** with this text:

```text
Hello, Alex.
```

This guide is complete as written; a copy of the program and catalog is also included under `examples/getting-started/`.

`try_get` returns `false` and sets `messages.error` when the message is missing
or formatting fails. The convenience method `get` returns the requested key on
failure; use `try_get` when the program should handle failure separately.

The translator copies general values when you set them. For changing
application state, install a resolver callback.

## Next steps

- [Supply per-call fields and handle missing messages](tutorials/first-catalog.md)
  shows field dictionaries and explicit error handling in a complete program.
- [Resolve changing values with a callback](tutorials/live-values.md) shows how
  to read live application state while formatting a message.
- [Reuse messages across catalogs](tutorials/catalog-references.md) shows
  local and named references, plus explicit lookups from a named catalog.
- [SQCat 1 format](advanced/format.md) specifies catalog syntax and template
  expressions; [application integration](advanced/integration.md) explains
  catalog selection, values and failure handling.
- [API reference](api/README.md) is the direct index of public types and members.

The complete [license](../LICENSE) is included in each release.
