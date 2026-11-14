# Field values and dictionaries

Applications provide fields as UTF-8 strings, booleans, signed or unsigned integers, and finite real numbers. Signed integers are stored as `int64`, unsigned integers as `uint64`, and real numbers as `double`; field names must be nonempty UTF-8 strings.

## Native scalar values

Use typed [translator.set_variable](../opensqcat/Classes/translator/Methods/set_variable.md) overloads to preserve the distinction between text, booleans, signed integers, unsigned integers and real numbers. Numeric values are normalized to `int64`, `uint64` or `double`: the original `int`/`uint` width and `float`/`double` distinction are not retained. General fields are copied when installed; they are not bindings to application variables.

```nvgt
messages.set_variable("playername", "Alex");
messages.set_variable("logged_in", true);
messages.set_variable("money", int64(9007199254740993));
```

Native `var()` is empty and is rejected as supplied data. It differs from `var("")`, `var(false)` and `var(0)`, which are valid. Null handles, arbitrary objects, arrays, invalid UTF-8 and nonfinite numbers are rejected. A provider indicates absence by returning false, not by returning an empty variant.

Missing fields, empty text, numeric zero and false are false in conditions; other scalar values are true. Boolean output is `true` or `false`. Numbers follow the [numeric semantics](../../advanced/format.md#numeric-values) of the format.

## Dictionary arguments

Native `dictionary` values may contain:
- UTF-8 strings, imported as text.
- Plain native numbers and booleans, imported through NVGT's numeric dictionary conversion as double-precision numbers. False/true become 0/1 and large integers can lose precision.
- Native `var` objects or handles, converted to boolean, signed `int64`, unsigned `uint64`, double-precision real or text categories. Integer width and `float`/`double` distinction are not retained.

```nvgt
dictionary fields = {
	{"playername", "Alex"},
	{"money", 25},
	{"logged_in", var(true)},
	{"account_id", var(uint64(18446744073709551615))}
};
```

Use typed setters for general fields, or `var` entries in per-message arguments when signedness or full 64-bit integer precision matters. Plain numeric dictionary entries are converted to `double` and suit ordinary amounts and conditions.

The translator validates and copies general dictionaries and per-call argument dictionaries, including `var` payloads. Later mutations do not change captured values. Use a [field provider](../opensqcat/Classes/field_provider/!field_provider.md) or [field resolver](../opensqcat/Funcdefs/field_resolver.md) for values that should be obtained dynamically.

Field names need not be catalog keys. Templates can reference only names allowed by the format's [identifier grammar](../../advanced/format.md#grammar), excluding reserved words.
