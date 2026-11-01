# Your first catalog

This tutorial builds a small console program that loads a catalog, supplies
shared values and checks for a missing message. It assumes NVGT is installed.

## 1. Install the library

Follow the [project installation](../../README.md#project-installation). Your
working directory should contain an `opensqcat/` folder with `opensqcat.nvgt`
inside it. Create a `locales/` directory beside that folder.

## 2. Write the catalog

Save this UTF-8 text as `locales/en.sqcat`:

```properties
!sqcat_format_version 1

welcome = Hello, {playername}.
balance = You have {money} coins.
```

Each entry has a key and a template. The field inside braces is filled from
application data when the message is requested.

## 3. Write the program

Save this as `first_catalog.nvgt` beside `opensqcat/` and `locales/`:

```nvgt
#pragma console
#include "opensqcat/opensqcat.nvgt"

void main() {
	opensqcat::translator messages;
	if (!messages.load("locales/en.sqcat")) {
		println(messages.error.message);
		exit(1);
	}
	if (!messages.set_variable("playername", "Alex")) {
		println(messages.error.message);
		exit(1);
	}
	println(messages.get("welcome"));
	println(messages.get("balance", {{"money", 3}}));

	string text;
	if (!messages.try_get("missing", text)) {
		println("Missing message: " + messages.error.key);
	}
}
```

The shared player name is available to each call. The `money` dictionary belongs
only to the `balance` call. `try_get` lets the application handle a failure
explicitly instead of treating the returned key as translated text.

## 4. Run it

Run the program with your NVGT executable:

```powershell
C:/nvgt/nvgt.exe -w 2 first_catalog.nvgt
```

Expected output:

```text
Hello, Alex.
You have 3 coins.
Missing message: missing
```

Change the player name or coin count and run it again. Then add a `missing`
entry to the catalog: the final error line will disappear.

Continue with [live application values](live-values.md). For the exact retrieval
contract, see [message retrieval](../api/translator.md#getting-translated-messages).
