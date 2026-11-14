# field_resolver

Function/delegate signature accepted by `translator::set_resolver` as an alternative to implementing `field_provider`.

```nvgt
funcdef bool field_resolver(const string&in name, var@&out result);
```

## Arguments:
* `const string&in name`: field name requested by template evaluation.
* `var@&out result`: set to a non-null valid native scalar when returning success.

## Returns:
Return `true` when found and `false` when absent. On absence, the output is ignored. Empty text, false and zero count as present.

## Remarks:
The translator retains the delegate through its provider adapter. The callback follows the same validation, caching and exception behavior as [field_provider.resolve](../Classes/field_provider/Methods/resolve.md). Install it with [set_resolver](../Classes/translator/Methods/set_resolver.md); null removes the dynamic resolver. Manage captured handles to avoid ownership cycles.
