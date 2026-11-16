# OpenSQCat

**UTF-8 localization catalogs and bounded message templates for NVGT.**

OpenSQCat loads message catalogs and formats their text with values from your NVGT program. Your application chooses the language, catalog files and how to present the result.

## Features

- Keep player-facing text in editable UTF-8 `.sqcat` files.
- Insert values from your program into messages.
- Select text with conditions and combine optional parts.
- Get diagnostics when a catalog cannot load or a message cannot be formatted.
- Bound template work and generated text.

## Quick start

Download and install NVGT from the [NVGT Releases page](https://github.com/samtupy/nvgt/releases) and download the [Latest OpenSQCat release](https://github.com/squerinth/opensqcat/releases/latest).
Extract the release ZIP and copy its complete `opensqcat/` folder beside your program. There is no library build step.

OpenSQCat has been tested with NVGT `0.90.0-dev` on Windows. Other builds and platforms have not been probed yet.

### Catalog syntax

Each message is written on its own line as `key = template`. This example declares the catalog format and defines one message:

```properties
!sqcat_format_version 1

welcome = Hello, {player}!
```

`!sqcat_format_version 1` identifies the SQCat syntax version, independently of the OpenSQCat library version. OpenSQCat checks the declaration when loading the file. If omitted, the file is read as SQCat 1.

In `welcome = Hello, {player}!`, `welcome` is the key your program uses to request the message. The text after `=` is its template. Text outside braces is literal. Braces mark an expression; `{player}` names a field whose value your program supplies. A text literal inside an expression uses double quotes, as in `{"hello"}`.

### Show your first translation

Create this project and save the catalog above as `locales/en.sqcat`:

```tree
my-game/
    main.nvgt
    opensqcat/          folder from the release ZIP
    locales/
        en.sqcat
```

Save this program as `main.nvgt`:

```nvgt
#include "opensqcat/opensqcat.nvgt"

void main() {
	opensqcat::translator messages;
	if (!messages.load("locales/en.sqcat")) {
		alert("OpenSQCat", messages.error.message);
		return;
	}
	if (!messages.set_variable("player", "Alex")) {
		alert("OpenSQCat", messages.error.message);
		return;
	}

	string greeting = messages.get("welcome");
	alert("Welcome", greeting);
}
```

`#include` loads the library entry point into this script. `void main()` is where the program starts. `opensqcat::translator messages;` creates a translator named `messages`, and `string` declares a text value. You can also call get directly, such as:

```nvgt
alert("Welcome", messages.get("welcome"));
```

`load` reads the catalog. Since this new translator has no other catalog, the loaded file is the one used by `get`.
The `if` statements check whether an operation failed: `!` means “not,” and `return` ends the execution.
When loading or setting a field fails, `messages.error.message` contains the diagnostic.

`set_variable("player", "Alex")` stores the text `Alex` under the field name `player`, matching `{player}` in the catalog. The value stays on this translator until it is changed.
`get("welcome")` looks up the key and returns the formatted message. If the key is missing or formatting fails, `get` returns the key itself.
`try_get("welcome", greeting)` puts the formatted message into `greeting` and returns `true` or `false`, so a program can handle failure separately.

`alert(title, text)` is an NVGT function that opens a dialog. On Windows, select `main.nvgt` in File Explorer and press Enter to run it. The context menu's **Compile Script (Release)** action compiles a release build; its output format depends on NVGT's packaging settings.

You can also run the script from a command prompt opened in `my-game/`:

```powershell
nvgt.exe main.nvgt
```

If `nvgt.exe` is not on your `PATH`, use its full path, for example `C:/nvgt/nvgt.exe main.nvgt`.

The dialog should display:

```text
Hello, Alex!
```

This example is complete as written; a copy of the program and catalog is also included under `examples/quick-start/`.


### More expressive messages

SQCat templates can choose text with a condition or combine pieces of text. Replace the earlier catalog with this complete version:

```properties
!sqcat_format_version 1

welcome = Hello, {player}!
access = {"Manage settings" if can_manage else "Read only"}
summary = {join(", ", player, "administrator" if admin else "")}
```

The `if ... else` expression chooses one of two results based on a boolean field (`true` or `false`). The built-in `join` combines text using the separator `, ` and omits empty pieces. When `admin` is false, the empty piece is omitted and `summary` has no extra comma.

This program sets the fields and displays both messages:

```nvgt
#include "opensqcat/opensqcat.nvgt"

void main() {
	opensqcat::translator messages;
	if (!messages.load("locales/en.sqcat")) {
		alert("OpenSQCat", messages.error.message);
		return;
	}
	if (!messages.set_variable("player", "Alex")
		|| !messages.set_variable("can_manage", true)
		|| !messages.set_variable("admin", true)) {
		alert("OpenSQCat", messages.error.message);
		return;
	}

	alert("Access", messages.get("access"));
	alert("Summary", messages.get("summary"));
}
```

Here `||` means “or,” so the error block runs if any field could not be set. With both boolean fields set to `true`, the alerts show:

```text
Manage settings
Alex, administrator
```

Set `can_manage` to `false` to display `Read only`.
Set `admin` to `false` and the summary becomes `Alex`.
This keeps message wording and simple presentation choices in the catalog, rather than scattering them throughout your application code.
This example is complete as written; a copy of the program and catalog is also included under `examples/expressive-messages/`.


## Other installation methods

### Install globally

Copy the release's complete `opensqcat/` folder into your NVGT include directory, such as `C:/nvgt/include`. Copy the release's top-level `opensqcat.nvgt` wrapper into that same directory. Programs can then include the library with:

```nvgt
#include "opensqcat.nvgt"
```

### Install from a source checkout

Copy `src/` as `opensqcat/`, `doc/` as `opensqcat/docs/`, and the root `LICENSE` into `opensqcat/`. For a project installation, place that folder beside your program and use the include shown in the quick start. For a global installation, put the `opensqcat/` folder in the NVGT include directory and create a wrapper named `opensqcat.nvgt` beside it with this content:

```nvgt
#include "opensqcat/opensqcat.nvgt"
```

## Learn more

The tutorials build on the quick start, with one complete example per topic:

- [Per-call fields and missing messages](doc/tutorials/first-catalog.md)
- [Live values with a resolver](doc/tutorials/live-values.md)
- [Reuse messages across catalogs](doc/tutorials/catalog-references.md)

For reference details, see:

- [SQCat 1 syntax](doc/advanced/format.md)
- [Application integration](doc/advanced/integration.md)
- [API reference](doc/api/README.md)
- [zlib license](LICENSE)
