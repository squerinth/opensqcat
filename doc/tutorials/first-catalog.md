# Per-call fields and missing-message handling

This tutorial shows how to store a value on a translator, provide values for
one message request, and handle a missing message. It includes its own catalog
and program.

Create this project beside the complete `opensqcat/` folder from the release:

```tree
first-catalog/
    first_catalog.nvgt
    opensqcat/
    locales/
        en.sqcat
```

## Catalog

Save this UTF-8 file as `locales/en.sqcat`:

```properties
!sqcat_format_version 1

welcome = Hello, {playername}.
balance = {playername}, you have {money} coins.
```

Each line maps a message key to a template. `{playername}` and `{money}` are
fields whose values come from the program when it requests a message.

## Program

Save this as `first_catalog.nvgt`:

```nvgt
#include "opensqcat/opensqcat.nvgt"

void main() {
	opensqcat::translator messages;
	if (!messages.load("locales/en.sqcat")) {
		alert("OpenSQCat", messages.error.message);
		return;
	}
	if (!messages.set_variable("playername", "Alex")) {
		alert("OpenSQCat", messages.error.message);
		return;
	}

	alert("Welcome", messages.get("welcome"));
	alert("Balance", messages.get("balance", {{"money", 3}, {"playername", "Sam"}}));
	alert("Welcome", messages.get("welcome"));

	string missing;
	if (messages.try_get("missing", missing)) {
		alert("Missing message", missing);
	} else {
		alert("Missing message", "Missing message: " + messages.error.key);
	}
}
```

`set_variable` stores `playername = Alex` on this translator, so ordinary
requests can use it. The second argument to `get` is a dictionary for that
request only. Its outer braces enclose field/value pairs, each written as
`{"field", value}`. In
`{{"money", 3}, {"playername", "Sam"}}`, the message receives `money = 3` and
`playername = Sam`. Per-call values take priority over the translator's stored
values, so that one `balance` request says “Sam”; the following `welcome`
request still says “Alex”.

`try_get` lets the program distinguish missing messages from successful text.
It writes the formatted message to its second argument and returns `true` on
success. If the key is missing or formatting fails, it returns `false`, clears
the output and sets `messages.error`. Here the program uses `messages.error.key`
to report the missing key. If you add a `missing = ...` entry to the catalog,
the `try_get` call succeeds and the dialog shows that message instead.

## Run it

On Windows, select `first_catalog.nvgt` in File Explorer and press Enter. You
can also open a command prompt in `first-catalog/` and run:

```powershell
nvgt.exe first_catalog.nvgt
```

If `nvgt.exe` is not on your `PATH`, use its full path. The message texts are:

```text
Hello, Alex.
Sam, you have 3 coins.
Hello, Alex.
Missing message: missing
```

The tutorial is complete as written; a copy of the program and catalog is also included under `examples/per-call-fields/`.
