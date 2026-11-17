# catalog

Stores raw SQCat templates and compiled message representations. Keys are exact, case-sensitive UTF-8 strings. Loading is transactional: the current catalog is replaced only after the complete source has been validated and compiled.

## Constructor:

`catalog();`

Creates an empty catalog with no path provenance and no diagnostic error.

Copy construction and value assignment copy the messages, load provenance and
diagnostic. Later changes to either catalog's entries affect only that catalog.
Objects sharing a catalog handle see mutations to that same catalog.

## Properties
- [error](Properties/error.md) — detached diagnostic from the latest load or mutation.
- [loaded_path](Properties/loaded_path.md) — provenance of the latest successful load or empty after successful in-memory edits.
- [size](Properties/size.md) — number of stored keys.

## Methods
- [clear](Methods/clear.md)
- [contains](Methods/contains.md)
- [keys](Methods/keys.md)
- [load](Methods/load.md)
- [load_text](Methods/load_text.md)
- [lookup](Methods/lookup.md)
- [remove](Methods/remove.md)
- [render](Methods/render.md) — internal rendering hook exposed for composition; no compatibility guarantee.
- [set](Methods/set.md)
- [snapshot](Methods/snapshot.md) — internal snapshot hook exposed for composition; no compatibility guarantee.

See the [SQCat format](../../../../advanced/format.md).
