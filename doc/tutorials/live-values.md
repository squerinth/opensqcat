# Live application values

The [console example](../../examples/messages.nvgt) shows how a resolver reads
current application state without copying it into the translator for each call.
It also demonstrates local and cross-catalog references.

## 1. Run the example

Extract a release archive or use a repository checkout. From its root, run:

```powershell
C:/nvgt/nvgt.exe -w 2 examples/messages.nvgt
```

The example loads `examples/locales/en.sqcat` and `common.sqcat`. NVGT resolves
the relative catalog paths from the script directory.

Expected output:

```text
Hello, Sam.
You have 25 coins.
You can edit
Sam: Use the arrow keys.
Sam, administrator
Press Enter to continue.
Sam: Press Enter to continue.
Hello, Alex.
```

## 2. Follow the changing value

Open `examples/messages.nvgt`. The `resolve_player` function returns the current
`player_name` as a native `var`. `set_resolver` installs it on the translator.
The first greeting uses `Sam`; the program then assigns `Alex` and requests the
same greeting again. The new formatting operation resolves the field again.

Change the second assignment and run the program to see the final greeting
change without replacing the catalog or calling `set_variable` for that field.

## 3. Follow the references

In `en.sqcat`, `help` includes `{$hint}`, which stays in that catalog. The program
also requests `get_from("common", "help")` and formats `{$common/help}`. Both
select the explicitly loaded `common` catalog.

For field precedence and caching decisions, read
[application integration](../advanced/integration.md). For the callback signature
and failure behavior, consult [field_resolver](../api/values.md#field_resolver).
