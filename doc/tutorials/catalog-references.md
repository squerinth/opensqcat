# Reuse messages across catalogs

Catalog references let one message include text stored in another message.
This is useful for shared controls, menu labels or repeated instructions. This
tutorial loads two catalogs, uses both local and cross-catalog references, and
retrieves one message from a named catalog.

Create this project beside the complete `opensqcat/` folder from the release:

```tree
catalog-references/
    catalog_references.nvgt
    opensqcat/
    locales/
        en.sqcat
        common.sqcat
```

## Catalogs

Save this UTF-8 file as `locales/en.sqcat`:

```properties
!sqcat_format_version 1

welcome = Welcome, {playername}!
local_help = {playername}: {$hint}
shared_help = {playername}: {$common/controls}
hint = Press Enter to continue.
```

Save this UTF-8 file as `locales/common.sqcat`:

```properties
!sqcat_format_version 1

controls = Use the arrow keys to move. {$confirm}
confirm = Press Enter to continue.
```

The file names register these catalogs as `en` and `common`. A reference like
`{$hint}` looks for `hint` in the catalog containing the message. A reference
like `{$common/controls}` names both the catalog and message key. In the
`common` catalog, `{$confirm}` resolves in `common`, because that is where the
referencing message lives.

## Program

Save this as `catalog_references.nvgt`:

```nvgt
#include "opensqcat/opensqcat.nvgt"

void main() {
	opensqcat::translator messages;
	if (!messages.load("locales/en.sqcat")
		|| !messages.load("locales/common.sqcat")) {
		alert("OpenSQCat", messages.error.message);
		return;
	}
	if (!messages.set_variable("playername", "Alex")) {
		alert("OpenSQCat", messages.error.message);
		return;
	}

	alert("Welcome", messages.get("welcome"));
	alert("Local help", messages.get("local_help"));
	alert("Shared help", messages.get("shared_help"));
	alert("Shared controls", messages.get_from("common", "controls"));
}
```

`load` registers a catalog using its file name without `.sqcat`. The first
successfully loaded catalog becomes the default, so `get("welcome")` reads
from `en`. Loading `common` makes its messages available to references; it
does not change the default catalog. `get_from("common", "controls")` selects
that named catalog for one lookup.

References only use catalogs that the program has already loaded. They do not
load files, search other catalogs for a missing key or choose a language. Keep
the reference chain acyclic: a cycle between messages makes formatting fail.

## Run it

On Windows, select `catalog_references.nvgt` in File Explorer and press Enter.
You can also run it from a command prompt opened in `catalog-references/`:

```powershell
nvgt.exe catalog_references.nvgt
```

The message texts are:

```text
Welcome, Alex!
Alex: Press Enter to continue.
Alex: Use the arrow keys to move. Press Enter to continue.
Use the arrow keys to move. Press Enter to continue.
```

The tutorial is complete as written; a copy of the program and catalogs is also included under `examples/catalog-references/`.
