# Design notes

These are the original project notes, translated and kept for context. They record ideas that were considered before the 0.3.0 revival. The current status follows each one.

## Original notes

A library for controlling terminal formatting, used by every command-line program.

- Migrate to `Text`.
- Migrate to `Seq`.

### Printer

The `Printer` is similar to the `Reader` monad, so using `ReaderT` instead of a dedicated type could be considered. The point is that `Printer` has no parameter, so it would be a specialization.

### Section

`Section` should be a monad, because the cursor position has to be passed to the next section.

### Error

Only one error is expected in the system: a malformed table. If necessary, define the error in a way that lets it reach upper layers.

## Current status

- **Text**: deliberately deferred. CLI content is small, `String` keeps the public API simple, and the library only needs a handful of small dependencies. Revisit only if large documents or Unicode-heavy processing become a requirement; prefer a separate `Text`-based API over a breaking change to the core.
- **Seq**: deliberately deferred for the same reason. Lists are adequate for the size of menus, tables and articles, and they keep the types simple. Revisit only if incremental or very large sequences become a requirement.
- **Printer**: `Printer` is already a specialized `ReaderT Config IO` plus a line count. The representation stays hidden because exposing a monadic builder would leak IO and let callers bypass section and page bookkeeping. A separate `Ansiform.Monad` layer can be added later if a concrete need appears; the pure builders should remain the primary API.
- **Section**: cursor position and line counts are threaded explicitly by `runSection`/`runPage` and stored in `State`. A `State` monad would duplicate that mechanism and make simple sections more verbose, so it is deliberately deferred until there is a real use case. The existing `replace`/`amend` lifecycle already covers the practical need to preserve rows.
- **Error**: table builders return `Maybe Table`. A richer error ADT can be introduced later if callers need to distinguish why a table is malformed.
