# SQCat 1 specification

SQCat is an open, versioned text-localization format using `.sqcat` files.
Its format version is independent of any implementation's release number.
OpenSQCat implements SQCat 1 for NVGT and AngelScript. The rules below define the
file format and expression language; implementation-specific API and resource
limits are linked separately.

## Contents

- [File structure](#file-structure)
- [Version declarations](#version-declarations)
- [Directives](#directives)
- [Loading stages](#loading-stages)
- [Text and expressions](#text-and-expressions)
- [Fields and references](#fields-and-references)
- [Expressions](#expressions)
- [Joining optional fragments](#joining-optional-fragments)
- [Numeric values](#numeric-values)
- [Grammar](#grammar)

A catalog is a case-sensitive map of message keys to text templates. Its contents
are interpreted independently of its file name or directory. OpenSQCat's
`translator.load(path)` uses the file name to choose a catalog registration name
when the caller omits an explicit name; see [catalog loading](../api/translator.md#loading-and-raw-lookup).

## File structure

- UTF-8, with an optional initial UTF-8 BOM.
- LF or CRLF line endings. Bare CR is rejected.
- Version declarations and directives occupy their own physical lines, as
  specified below.
- One `key = template` entry per physical line. The first `=` is the separator;
  later equals signs belong to the template, including comparison operators.
- ASCII spaces and tabs are trimmed from both ends of keys and templates.
  Interior whitespace is preserved. Other Unicode whitespace is ordinary data.
- Blank lines and lines whose first non-space/tab character is `#` are ignored.
  There are no inline comments.
- Keys must be nonempty and unique after trimming. `Name` and `name` are distinct.
  A template may be empty; this is a present message producing empty text.

```properties
!sqcat_format_version 1

# Entire-line comment
welcome = Hello, {playername}.
formula = a = b # this is part of the message
empty =
```

There are no sections, file includes, continuation lines or file-level escape
sequences. A key cannot contain `=`, begin with `#` or `!` after trimming, or retain
outer spaces/tabs in this file format. These restrictions do not apply to
in-memory keys installed with `catalog.set()`.

Loading validates the encoding, file structure and syntax of every template
before replacing the previous catalog. Field availability and referenced-message
existence are checked when the relevant expression is evaluated, allowing
optional fields and guarded references.

## Version declarations

```properties
!sqcat_format_version 1
```

The declaration can appear anywhere in the file, on its own line. A reader scans
the entire file for it before interpreting directives or message entries. Its
name is case-sensitive and fixed across format versions. Only a line whose first
non-space/tab character is `!` can be a declaration: text within a message and
comment lines are never scanned for embedded declarations.

The payload is a positive decimal integer, with no sign, leading zero, fractional
part, extra tokens or inline comment. A file may contain at most one version
declaration, even if repeated declarations would agree. The declaration cannot
be optional. Absence means SQCat 1; malformed or unsupported declarations are
errors, never a reason to use that default.

This specification defines version 1. Readers must reject versions they do not
support rather than guess how to interpret their entries. Supporting older
versions requires retaining their interpretation; the declaration alone does not
provide backwards compatibility.

## Directives

```text
required-directive := "!" name [space payload]
optional-directive := "!?" name [space payload]
name               := segment ("." segment)*
segment            := [A-Za-z_] [A-Za-z_0-9]*
space              := one or more ASCII spaces or tabs
```

Leading/trailing ASCII spaces and tabs are ignored. There must be no whitespace
between the marker and the name. A payload, if present, must be separated from
the name by spaces/tabs. It occupies the remainder of the physical line; there
are no inline comments or generic quoting/escaping rules. Each recognized
directive defines its own payload syntax and validation. A missing payload is
valid only when that directive permits it.

| Declaration | Recognized and valid | Recognized but invalid | Unknown |
| --- | --- | --- | --- |
| `!name payload` | Apply it. | Fail loading. | Fail loading. |
| `!?name payload` | Apply it. | Fail loading. | Ignore it. |

The marker and name must be well formed even for an unknown optional directive.
Its payload is opaque: a reader does not parse it as an expression, a template
or a message entry. File-level encoding and structural checks still apply.
The special version declaration uses only `!sqcat_format_version`, never `!?`.

After selecting the version, readers process directives from top to bottom,
validating every recognized occurrence. The last valid occurrence of a repeated
directive replaces its previous value; an invalid earlier occurrence still fails
the load. These effective settings apply to the whole catalog, including entries
before the directive. Duplicate message keys remain errors.

SQCat defines this declaration mechanism. Each implementation defines which
preprocessor directives it recognizes and their behavior. An optional directive
must be safe to omit for the catalog's intended use. Extension-specific names
should use a distinguishing dotted prefix to avoid collisions.

**OpenSQCat:** currently recognizes only the version declaration. All other
well-formed optional directives are ignored, and required directives fail.
There is no API for registering arbitrary application directives. Directives are
processed only during loading, never during lookup, field resolution or template
evaluation. Changing preprocessing decisions requires reloading the catalog.

## Loading stages

OpenSQCat performs these stages in order:

1. Validate byte size, UTF-8 encoding, optional BOM and line endings.
2. Scan for the version declaration and select the supported format version.
3. Validate and process directives in source order.
4. Parse message entries and compile their templates.
5. Install the completed catalog atomically.

Errors leave the previous catalog installed. Physical line numbers remain intact
for diagnostics. Only message pairs and their compiled representation become
catalog entries; version declarations, directives, comments and blank lines do
not appear in lookups, key enumeration or message counts. An implementation may
retain effective preprocessing configuration when needed, without retaining
source directives as message entries.

## Text and expressions

Outside `{...}`, all characters other than braces are literal text, including
quotes, `$`, `#`, backslashes and `+`. A stray `}` is an error. Inside braces,
the content is parsed as an expression. There is no execution of script code.

```properties
greeting = Hello, {playername}.
price = Price: ${amount}
quoted = Press "Enter".
permission = {"Can edit" if logged_in and (owner or admin) else "Read only"}
```

Strings in expressions must be enclosed in matching single or double quotes.
Inside a string, braces are ordinary characters. Supported escapes are `\\`,
`\"`, `\'`, `\n`, `\r` and `\t`. Unknown escapes are errors. Text outside
expressions does not process these escapes.

There are no `{{` or `}}` escapes. To produce literal braces, use strings:

```properties
literal = Write {"{playername}"} literally.
individual = {"{"}content{"}"}
spacing = {"  preserve outer spaces  "}
multiline = {"First line\nSecond line"}
```

Field values and string literals are inserted as data, never parsed again as
templates. A field containing `{admin}` therefore outputs `{admin}` literally.

## Fields and references

`{playername}` looks up a field from temporary arguments, then the general
dictionary, then the provider. A found empty string, zero or false value stops
the search. Fields are never implicitly looked up in the message catalog.

`{$hint.adjust}` includes and formats another message from the current catalog.
`{$common/hint.adjust}` selects a message from a loaded catalog named `common`.
Both components are literal names, not variables. The catalog name is a registry
identifier chosen by the caller, not a file path or an instruction to load a file.

Each component may be an identifier or a quoted string:

```properties
hint.adjust = Use the arrows.
volume = {name}: {value}. {$hint.adjust}
other = {$common/hint.adjust}
literal.slash = {$"common/hint.adjust"}
quoted.key = {$common/"key/with/slashes"}
quoted.catalog = {$"common messages"/"key/with/slashes"}
```

Only an unquoted `/` separates catalog and key. A quoted slash is part of the
literal name. Both components must be nonempty; more than one unquoted slash is
an error. ASCII whitespace may surround the components and separator. Dots in
identifiers remain part of the name, not object access.

Unqualified references are relative to the message containing them. If a message
in `dialogue` includes `common/help`, any local references inside `help` resolve
in `common`. There is no implicit search in other catalogs when a key is absent.
References may be expression values, including selected conditional branches.
Missing catalogs/messages and cycles fail the operation. Cycle identity is the
pair catalog name and key, so equal keys in different catalogs do not collide.
All included messages share the field cache and evaluation budgets.

**OpenSQCat:** the first installed catalog is the default. `load(path)` infers its
name from the filename without `.sqcat`; explicit names override that inference.
Caller APIs select roots with `get_from(catalog_name, key)`, keeping keys literal.
See [catalog management](../api/translator.md#catalog-management).

## Expressions

From highest to lowest precedence:

1. Literals, identifiers, references and parenthesized expressions.
2. One comparison: `==`, `!=`, `<`, `<=`, `>`, `>=`.
3. `not`.
4. `and`.
5. `or`.
6. `result if condition else alternative`, associating to the right.

```properties
guest = Hello, {playername if playername else "visitor"}.
amount = {count} {"item" if count == 1 else "items"}
access = {"Edit" if logged_in and not readonly else "Read"}
```

The item example implements a two-case selection only; it is not a general
language-dependent pluralization facility.

Truth rules: absent fields, empty strings, numeric zero and false are false;
nonempty strings, nonzero numbers and true are true. In particular, the string
`"false"` is true. `and`, `or` and `not` produce booleans. `and`, `or` and the
conditional short-circuit: unneeded operands are not evaluated or resolved.

A missing field is permitted as a condition, but directly outputting it or
using it in a comparison is an error. Thus `{player if player else "guest"}`
works when `player` is absent; `{player}` reports an unresolved field.

Equality is type-sensitive, except that signed integers, unsigned integers and
real numbers compare numerically. Booleans are distinct: `false == 0` is false.
Text is never implicitly converted to a number. Ordering
requires two numbers or two strings; strings use case-sensitive ordinal order
without normalization or locale collation. Chained comparisons are not supported;
write `low <= count and count <= high`.

## Joining optional fragments

`join(separator, fragment, ...)` composes scalar fragments with a text separator.
It is the only callable built-in in expressions; it does not invoke application
functions or methods.

```properties
person = {join(" ", first_name, middle_name, last_name)}
location = {join(", ", city, region, country)}
summary = {join(", ", join(" ", name, role), value, state)}
help = {join(" ", name, $hint)}
```

The separator must evaluate to present text. An empty separator is valid. Each
fragment is evaluated left to right and converted using ordinary scalar text
formatting. Absent fields and empty strings are omitted; zero, false and
whitespace-only strings are retained. There is no trimming of fragment text.
Missing message references and provider/evaluation errors still fail the operation.

Only retained fragments receive separators, so there is no leading/trailing
separator when an optional field is empty. With no retained fragments, the result
is empty. `join(" ")` is valid and returns empty text; `join()` is a syntax error.
One trailing argument comma is accepted.

Arguments can be references, conditionals or other joins. They share the existing
field cache, evaluation depth/step limits and cumulative generated-text budget.
A join in an unselected branch is not evaluated. Output produced elsewhere in
the template never affects its separator decisions.

## Numeric values

Integer literals without a decimal point or exponent retain exact 64-bit
precision: from -9223372036854775808 through 18446744073709551615. Nonnegative
values above signed int64's maximum use uint64. Out-of-range integers are syntax
errors. Typed setters and native `var` fields also preserve signed/unsigned
integers. Comparisons between integers do not convert them to double; mixed
integer/real comparisons account for the real value's represented magnitude and
fraction instead of first rounding the integer to double.

A decimal point or exponent selects a finite IEEE double: `-1.5`, `1e3`.
A leading digit and digits after a decimal point/exponent are required. Nonzero
literals that overflow or underflow to zero are rejected. Decimal conversion uses
NVGT's `parse_double`; its rounding can differ from AngelScript source literals,
including near 64-bit boundaries. Real values are approximate; use integer
literals or typed integer fields for exact counts and identifiers. Plain numeric
dictionary entries also undergo double conversion; see [field values](../api/values.md).

Integers format as decimal digits; real numbers use NVGT's double-to-string
conversion. Neither applies locale-specific currency or numeric formatting.

## Grammar

```text
template    := (text | "{" expression "}")*
expression  := disjunction ["if" disjunction "else" expression]
disjunction := conjunction ("or" conjunction)*
conjunction := negation ("and" negation)*
negation    := "not" negation | comparison
comparison  := primary [("==" | "!=" | "<" | "<=" | ">" | ">=") primary]
primary     := string | number | "true" | "false" | identifier
             | reference | "(" expression ")" | join
reference   := "$" component ["/" component]
component   := identifier | string
join        := "join" "(" expression ("," expression)* [","] ")"
identifier  := segment ("." segment)*
segment     := [A-Za-z_] [A-Za-z_0-9]*
number      := "-"? [0-9]+ ("." [0-9]+)? ([eE] [+-]? [0-9]+)?
```

ASCII whitespace is allowed between expression tokens. Identifiers are
case-sensitive. The words `if`, `else`, `and`, `or`, `not`, `true` and `false`
are reserved as complete field names. Quoted reference keys can contain any
valid UTF-8 text and the supported string escapes.

The name `join` remains usable as a field when not followed by `(`. There are no
arbitrary function calls, property access, assignments, arithmetic,
concatenation operators, loops, file operations or format specifiers in expressions.
Compose output by placing literal text, fields and references next to each other.
Evaluation limits are documented in [diagnostics and limits](../api/diagnostics.md).
