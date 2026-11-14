# exhausted

`bool evaluation_budget::get_exhausted() const property;`

## Returns:
`true` if a reservation has exceeded a remaining allowance; otherwise `false`. It starts false, is read-only and cannot be reset. Once exhausted, all further reservations and evaluations using the budget fail.
