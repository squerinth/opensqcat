# Resolve changing values with a callback

`set_variable` stores a copy of a value. Use a resolver when a message should
read changing application state each time it is requested. This tutorial shows
one complete program with a resolver and no shared-catalog setup.

Create this project beside the complete `opensqcat/` folder from the release:

```tree
live-values/
    live_values.nvgt
    opensqcat/
    locales/
        en.sqcat
```

Save this UTF-8 catalog as `locales/en.sqcat`:

```properties
!sqcat_format_version 1

status = Current player: {playername}.
```

Save this program as `live_values.nvgt`:

```nvgt
#include "opensqcat/opensqcat.nvgt"

string player_name = "Sam";

bool resolve_player(const string&in name, var@&out result) {
	if (name != "playername") {
		return false;
	}
	@result = var(player_name);
	return true;
}

void main() {
	opensqcat::translator messages;
	if (!messages.load("locales/en.sqcat")) {
		alert("OpenSQCat", messages.error.message);
		return;
	}
	messages.set_resolver(resolve_player);

	alert("Live values", messages.get("status"));
	player_name = "Alex";
	alert("Live values", messages.get("status"));
}
```

## How the resolver works

The template asks for `playername`. The translator first checks values supplied
for this request and values stored on the translator. If neither contains that
field, it calls `resolve_player` with the field name. The callback writes a
scalar value to the output handle and returns `true`; returning `false` says it
does not provide that field. In this example, all other field names are
unhandled.

`var@&out result` is the callback's output parameter. `@result = var(player_name)`
wraps the current string in a `var` and returns it to the translator. The
callback reads `player_name` when OpenSQCat asks for the field, so the first
request produces `Sam`. After the program changes that variable, the next
request produces `Alex` without reloading the catalog or calling
`set_variable`.

Resolver results are cached by field name during one formatting operation. If
one message uses the same dynamic field more than once, its callback result is
reused for that operation. A later `get` is a new operation and asks the
resolver again. A supplied per-call or stored value takes precedence, so the
resolver is not called for a field already provided by the program.

Use `set_variable` for a value that should remain a stored copy until the
program updates it. Use a resolver for a value that should be read from live
application state when a message is formatted.

## Run it

On Windows, select `live_values.nvgt` in File Explorer and press Enter. You can
also run it from a command prompt opened in `live-values/`:

```powershell
nvgt.exe live_values.nvgt
```

The message texts are:

```text
Current player: Sam.
Current player: Alex.
```

The tutorial is complete as written; a copy of the program and catalog is also included under `examples/live-values/`.
