# ls-compat contributor guide

## Scope

`ls-compat` is a deliberately small portability facade. Do not turn it into a
wrapper around all of UIOP, Bordeaux Threads, or USOCKET.

- Keep UIOP and Bordeaux Threads as direct project dependencies.
- Add a facade only when it removes an implementation-specific API from a
  client project.
- Keep POSIX and TCP APIs in their optional systems.
- Never silently weaken a semantic guarantee for an unsupported implementation.
  Signal `unsupported-operation` instead.

## Common Lisp style

- Use one public package per ASDF system, documented in `src/package.lisp`.
- Use `+constants+`, `*specials*`, kebab-case public names, and `--` private
  names.
- Give public definitions docstrings and declare their types with the local
  `->` macro.
- Define typed conditions with useful reports for recoverable portability
  failures.
- Keep two blank lines between major sections, one between definitions, and
  use 2-space indentation without trailing whitespace.

## Validation

Run the test system under both SBCL and CCL before committing:

```lisp
(asdf:test-system :ls-compat/tests)
```

Run focused client-project load tests after changing a public API. Test ECL
when available, but do not claim it supports a capability that was not run.
