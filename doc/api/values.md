# Values and field providers

## Native values

Applications supply UTF-8 strings, signed/unsigned 64-bit integers, finite real
numbers and booleans. Use ordinary typed arguments with `set_variable` and native
NVGT `var` in dictionaries or providers when exact type matters. OpenSQCat does
not require its own scalar type.

```nvgt
messages.set_variable("playername", "Ana");
messages.set_variable("logged_in", true);
messages.set_variable("money", int64(9007199254740993));
```

Typed setters copy their values; they do not bind to application variables.
Missing fields, empty text, numeric zero and false are false in conditions;
other scalar values are true. Boolean output is `true` or `false`. Numbers use
the [numeric semantics](../format.md#numeric-values) of the format.

Native `var()` is empty and is rejected as supplied data. It differs from
`var("")`, `var(false)` and `var(0)`, which are valid. Null handles, arbitrary
objects, arrays, invalid UTF-8 and nonfinite numbers are rejected. A provider
indicates absence by returning false, not by returning an empty variant.

## Dictionary arguments

Native `dictionary` values may contain:

- UTF-8 strings, imported as text.
- Plain native numbers and booleans, imported through NVGT's numeric dictionary
  conversion as double-precision numbers. Raw false/true become 0/1, and large
  integers can lose precision.
- Native `var` objects or handles, preserving boolean/integer/real/text type.

```nvgt
dictionary fields = {
    {"playername", "Ana"},
    {"money", 25},
    {"logged_in", var(true)},
    {"account_id", var(uint64(18446744073709551615))}
};
```

In the supported NVGT build, dictionary retrieval converts numeric types without
exposing their original type to this API. OpenSQCat does not infer bool from 0/1
or inspect dictionary serialization. Use typed setters for general fields, or
`var` for exact types in per-message arguments. Plain numeric entries remain
useful for ordinary amounts and conditions.

Field names must be nonempty UTF-8; names are case-sensitive. They need not be
catalog keys. Only names expressible by the format's identifier grammar can be
referenced as fields in templates.

General dictionaries and temporary arguments are validated and copied, including
`var` payloads; later mutations do not change the captured values. Use a provider
when fields should be obtained dynamically.

## field_provider

```nvgt
interface field_provider {
    bool resolve(const string&in name, var@&out result);
}
```

Implement `resolve` to return true and a non-null valid native scalar for a found
field. Return false for absence; the output is ignored in that case. Empty text,
false and zero are successful values. The translator retains the provider.

A provider is called only for fields actually needed after short-circuiting and
not already supplied by temporary or general fields. Its results are copied and
cached by name for one complete formatting operation, including references. They
are not cached across operations. An exception is caught and reported as a
`provider` error without copying the exception text into diagnostics.

Providers are application code: they must return promptly. Evaluation quotas
cannot interrupt a slow provider or bound recursion initiated by provider code.
Provider-held handles and delegates must be managed to avoid ownership cycles.

## field_resolver

```nvgt
funcdef bool field_resolver(const string&in name, var@&out result);
```

Functions and compatible delegates can be installed with `set_resolver` instead
of implementing a provider class. They use exactly the `field_provider` result,
validation, lifetime and caching rules:

```nvgt
bool resolve_player(const string&in name, var@&out result) {
    if (name != "playername") {
        return false;
    }
    @result = var(player_name);
    return true;
}
```

See [the complete console example](../../examples/messages.nvgt).
