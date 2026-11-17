# set_variable

Sets or replaces one copied general field. The overloads accept the listed native types and normalize numeric values to library scalar categories: signed integers become `int64`, unsigned integers become `uint64`, and `float` and `double` become `double`. The original integer width and float-versus-double distinction are not retained.

1. `bool translator::set_variable(const string&in name, const string&in text);`
2. `bool translator::set_variable(const string&in name, bool flag);`
3. `bool translator::set_variable(const string&in name, int number);`
4. `bool translator::set_variable(const string&in name, uint number);`
5. `bool translator::set_variable(const string&in name, int64 number);`
6. `bool translator::set_variable(const string&in name, uint64 number);`
7. `bool translator::set_variable(const string&in name, float number);`
8. `bool translator::set_variable(const string&in name, double number);`
9. `bool translator::set_variable(const string&in name, var@ source);`

## Arguments (1):
* `const string&in name`: nonempty valid UTF-8 field name.
* `const string&in text`: UTF-8 text to store.

## Arguments (2):
* `const string&in name`: nonempty valid UTF-8 field name.
* `bool flag`: boolean value to store.

## Arguments (3):
* `const string&in name`: nonempty valid UTF-8 field name.
* `int number`: signed integer input; stored as `int64`.

## Arguments (4):
* `const string&in name`: nonempty valid UTF-8 field name.
* `uint number`: unsigned integer input; stored as `uint64`.

## Arguments (5):
* `const string&in name`: nonempty valid UTF-8 field name.
* `int64 number`: signed integer value to store.

## Arguments (6):
* `const string&in name`: nonempty valid UTF-8 field name.
* `uint64 number`: unsigned integer value to store.

## Arguments (7):
* `const string&in name`: nonempty valid UTF-8 field name.
* `float number`: finite real input; stored as `double`.

## Arguments (8):
* `const string&in name`: nonempty valid UTF-8 field name.
* `double number`: finite real value to store.

## Arguments (9):
* `const string&in name`: nonempty valid UTF-8 field name.
* `var@ source`: nonempty variant containing a native boolean, signed or unsigned integer, real or text scalar. Integer and real values are normalized to `int64`, `uint64` or `double`; empty text is valid, while an empty variant, object or array is invalid.

## Returns:
`true` when the name and value are valid and the field is stored. `false` on an invalid name or value; existing fields remain unchanged and `error` reports `argument`.

## Remarks:
All overloads copy the value; they do not bind to application variables. Signed and unsigned integers retain their category and 64-bit precision. Successful calls clear `error`. See [native field values](../../../../concepts/field-values.md#native-scalar-values).
