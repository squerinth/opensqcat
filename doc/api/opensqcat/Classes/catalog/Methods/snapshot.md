# snapshot

`catalog@ catalog::snapshot() const;`

## Returns:
A new catalog with the receiver's entry dictionary and loaded-path provenance as they were at call time. Parsed message records are shared. The new catalog has an empty `error`; the receiver's diagnostic is not copied.

## Remarks:
This method is an internal snapshot hook publicly exposed for composition. Public mutations replace entries rather than modifying existing parsed records, allowing an operation to retain a stable view. The returned object has separate catalog state. This hook is not covered by compatibility guarantees.
