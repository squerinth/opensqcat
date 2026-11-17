# set_provider

`void translator::set_provider(field_provider@ source);`

## Arguments:
* `field_provider@ source`: provider to retain, or null to remove the provider.

## Remarks:
Changes the provider used by later formatting operations and clears `error`. The provider object is retained by handle, not copied. See [field_provider](../../field_provider/!field_provider.md) for resolution rules.
