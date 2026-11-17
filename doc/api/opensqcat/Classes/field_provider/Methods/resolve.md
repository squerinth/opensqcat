# resolve

`bool field_provider::resolve(const string&in name, var@&out result);`

## Arguments:
* `const string&in name`: field name requested by the current template evaluation.
* `var@&out result`: on success, receives a non-null valid native scalar variant.

## Returns:
Return `true` and set `result` to a valid native scalar when the field is present. Return `false` when it is absent; the output is ignored in that case.

## Remarks:
Empty text, false and zero are valid present values. Empty/null variants, nonscalar values, invalid UTF-8 and nonfinite numbers are invalid. If the callback reports success with invalid data, formatting fails with a `provider` diagnostic. Exceptions are caught and reported as `provider` without including exception text.

Resolution happens only when needed after short-circuiting and after temporary/general fields. Each requested name, including absence, is cached for the full operation. It is resolved again on the next operation.
