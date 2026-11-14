# render

`bool catalog::render(const string&in key, detail::evaluation@ state, string&out text) const;`

## Arguments:
* `const string&in key`: exact key to render.
* `detail::evaluation@ state`: internal evaluation state for fields, references and limits.
* `string&out text`: receives rendered output when successful.

## Returns:
`true` if the key exists and rendering succeeds. If the key is absent or any evaluation error occurs, `text` is cleared and the method returns `false`. A missing key does not change the evaluation error; errors during rendering are recorded on `state`.

## Remarks:
This publicly exposed method is an internal rendering hook. Its parameter belongs to `opensqcat::detail`; neither this hook nor that type is covered by compatibility guarantees.
