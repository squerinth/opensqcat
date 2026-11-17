# Shared evaluation budgets

Ordinary translator rendering calls use a fresh allowance. Pass the same [evaluation_budget](../opensqcat/Classes/evaluation_budget/!evaluation_budget.md) to several calls when they should share work and generated-text limits.

A new budget has zero counters and is not exhausted. The implementation caps each budget at 65,536 evaluation steps and 1 MiB of cumulative generated text. Generated text includes intermediate reference and join results.

```nvgt
opensqcat::evaluation_budget group;
string first = messages.get("first", null, group);
string second = messages.get("second", null, group);
```

The translator's message-evaluation methods—`try_get`, `try_get_from`, `get`, `get_from`, `try_format`, `try_format_from`, `format` and `format_from`—accept the budget as their last optional argument. A failed reservation exhausts the budget. Subsequent calls with that budget fail before parsing inline templates or looking up catalogs and messages, including calls that would produce empty results. Strict methods clear output and return false with a `limit` diagnostic. Convenience getters return the key, and inline formatters return empty text. Failed operations never return partially formatted text.

A non-limit failure may consume some allowance without exhausting the budget; later calls can use what remains. Use a separate budget when a recovery operation needs an independent allowance. There is no reset operation; create a new budget for a new group.

Sharing a budget does not share field dictionaries, provider caches or catalog snapshots. Each call captures its own inputs. Parsing/loading, dictionary copies, and application/provider execution are outside the evaluation counters, and quotas do not interrupt callbacks. Depth and active-reference limits remain per operation. Instances are intended for sequential use.
