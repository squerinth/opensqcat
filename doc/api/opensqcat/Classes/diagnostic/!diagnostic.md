# diagnostic

Mutable data describing the result or failure location of a catalog or translator operation. The `error` properties on those types return detached copies; editing one does not affect its owner.

## Constructor:

`diagnostic();`

Construction initializes strings to empty and line/column to zero.

## Properties

These are directly accessible mutable data fields, not accessor properties.
- [catalog](Properties/catalog.md)
- [code](Properties/code.md)
- [column](Properties/column.md)
- [key](Properties/key.md)
- [line](Properties/line.md)
- [message](Properties/message.md)
- [path](Properties/path.md)

## Methods
- [copy](Methods/copy.md)

See the [diagnostic codes and source-location rules](../../../concepts/diagnostics.md).
