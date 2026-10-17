# Design notes

These are the original project notes, translated and kept for historical context. They record ideas that were considered before the 0.3.0 revival. They are not a current roadmap; see [Roadmap](roadmap.md) for priorities and [Architecture](architecture.md) for the implemented design.

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
