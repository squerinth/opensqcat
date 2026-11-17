# Changelog

## Unreleased

- Packages identify their release channel and source revision in the README.
- Restore isolation for catalog and translator copies and for evaluations that
  remain active while a provider copies and mutates those objects.
- Reject calls with an exhausted evaluation budget before parsing inline text.

## 0.1.0

Initial release of OpenSQCat for NVGT.

- UTF-8 SQCat 1 catalogs with validated, transactional loading.
- Named catalogs, default selection and cross-catalog message references.
- Fields, conditional expressions, comparisons and optional-fragment `join`.
- Typed general values, temporary dictionaries and dynamic providers or resolvers.
- Structured diagnostics, bounded evaluation and shared evaluation budgets.
- Format specification, API reference, runnable examples and standalone verification.

## 0.1.1

- Included the license and documentation in the installable library folder.
- Reorganized the documentation, clarified explanations, and corrected factual errors.
- Improved performance.
- Rewrote the repository README to give new users a clearer introduction to the library.
