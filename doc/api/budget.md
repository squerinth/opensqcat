# opensqcat::evaluation_budget

Shares bounded evaluation work and generated-text accounting between independent
rendering operations. Ordinary translator calls create their own budget; create
one explicitly only when several calls should consume a common allowance.

```nvgt
evaluation_budget();
uint get_steps() const property;
uint get_bytes() const property;
bool get_exhausted() const property;
bool consume(uint steps = 0, uint bytes = 0);
```

A new budget has zero counters and is not exhausted. Its limits are 65,536 steps
and 1 MiB of cumulative generated text, including intermediate reference/join
results. The counters are read-only. `consume` reserves both amounts atomically:
it returns true and adds them if they fit. Otherwise it returns false, leaves
counters unchanged and marks the budget exhausted. An exhausted budget rejects
all further reservations and evaluations, including empty results. Create a new
budget for a new group; there is no reset operation.

The evaluator uses `consume` automatically. Applications may also account for
surrounding work through that method. Counter checks use remaining capacity and
do not wrap when supplied large unsigned amounts.

```nvgt
opensqcat::evaluation_budget group;
string first = messages.get("first", null, group);
string second = messages.get("second", null, group);
```

All translator rendering methods accept the budget as their last optional
argument. They retain their normal failure behavior: strict methods clear output
and return false with a `limit` diagnostic; convenience getters return the key,
and convenience inline formatters return empty text. A failed reservation never
returns a partially formatted message.

Non-limit failures may consume steps/bytes but do not exhaust remaining capacity.
A later operation may use what remains. A separate budget can be used when a
recovery operation must have an independent allowance.

Sharing a budget does not share fields, providers' cached results or catalog
snapshots between operations. Each operation captures and validates its own
inputs. Parsing/loading, dictionary snapshots, and application/provider execution
are outside the evaluation counters; quotas do not interrupt arbitrary callbacks.
Instances are intended for sequential use.
