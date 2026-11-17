# consume

`bool evaluation_budget::consume(uint steps = 0, uint bytes = 0);`

## Arguments:
* `uint steps = 0`: number of evaluation steps to reserve.
* `uint bytes = 0`: number of generated-text bytes to reserve.

## Returns:
`true` when both amounts fit; the method increments both counters. `false` if the budget is already exhausted or either request exceeds remaining capacity; it leaves both counters unchanged and marks the budget exhausted.

## Remarks:
Both reservations are checked atomically. Checks use remaining capacity, so oversized unsigned values do not wrap the counters. A zero-amount request also fails after exhaustion. The evaluator calls this method automatically; applications may call it to account for surrounding work. The built-in limits are 65,536 steps and 1 MiB cumulative generated text.
