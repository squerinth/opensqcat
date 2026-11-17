# evaluation_budget

Shares evaluation-step and generated-text allowances across rendering calls. When no budget is supplied, a translator operation creates a fresh one.

## Constructor:

`evaluation_budget();`

A new budget has zero counters and is not exhausted. There is no reset method.

## Properties
- [bytes](Properties/bytes.md)
- [exhausted](Properties/exhausted.md)
- [steps](Properties/steps.md)

## Methods
- [consume](Methods/consume.md)

The standard caps are 65,536 steps and 1 MiB of cumulative generated text. See [diagnostics and limits](../../../concepts/diagnostics.md#limits).
