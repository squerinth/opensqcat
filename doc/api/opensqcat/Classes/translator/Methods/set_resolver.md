# set_resolver

`void translator::set_resolver(field_resolver@ callback);`

## Arguments:
* `field_resolver@ callback`: function or compatible delegate to call for unresolved fields; null removes the provider.

## Remarks:
Installs a provider adapter around the callback, replacing any previous provider. Callback results follow the [field_resolver contract](../../../Funcdefs/field_resolver.md) and the same validation/caching rules as a [field_provider](../../field_provider/!field_provider.md). Clears `error`.
