# loaded_path

`string catalog::get_loaded_path() const property;`

## Returns:
The origin of the latest successful load: the path passed to `load` or the `origin` passed to `load_text`. Empty text means no successful load provenance is recorded.

A successful `set` clears it. `remove` clears it only when an entry was removed. `clear` clears it. Failed loads and failed `set` calls preserve it.
