# field_provider

Implement this interface to supply dynamic scalar fields when a template references a name not found in the call's argument dictionary or the translator's general fields. The translator retains the provider handle.

```nvgt
interface field_provider {
	bool resolve(const string&in name, var@&out result);
}
```

## Methods
- [resolve](Methods/resolve.md)

Providers run only for fields that evaluation reaches after short-circuiting. Results and absence are cached once by field name for a complete formatting operation. They are not cached across operations. Provider code and application state are not copied or snapshotted, so unresolved fields observe external state when the callback runs. Callbacks must return promptly; evaluation limits do not interrupt them or bound recursion initiated by provider code. Manage provider-held handles and delegates so their ownership does not form cycles.
