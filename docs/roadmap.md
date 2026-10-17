# Roadmap

This is a prioritized list of possible features and adjustments. It records the current design opinion, not a commitment.

## High value

### Unicode display width

The layout uses `length` on `String`, which counts code points rather than terminal columns. Wide characters, combining marks and emoji break alignment. Introduce a display-width function, for example through the small `unicode-width` package, and use it for text measurement, wrapping and table widths.

### Render to a string or handle

The printers write directly to stdout. A renderer that returns a `String` or writes to a `Handle` would make the library testable without capturing stdout, embeddable in other applications and suitable for golden tests. This is a larger architectural change because `Printer` is currently `Config -> IO Number`.

## Medium value

### Per-column alignment and truncation

Tables currently print left-aligned cells and do not truncate long content. Add per-column alignment (`Left`, `Center`, `Right`), a maximum width and an ellipsis policy. This is especially useful for numeric columns.

### Theme record

Introduce a `Theme` value grouping the styles used by headers, footers, accents, danger, muted text and tables. Reusable components can take a theme instead of hard-coded styles. This is a low-risk addition that reinforces the library's consistency goal.

### Table borders

Add optional box-drawing borders around tables and groups. This is mostly a rendering feature and should not complicate the content model.

## Publication quality

### Haddock coverage

The public modules build with Haddock, but function-level coverage is low. Convert the existing `--` comments to `-- |` Haddock comments and document the public types and functions. The `docs/` directory remains the long-form reference.

### CI matrix

The current CI targets GHC 9.14.1. Consider a matrix with the oldest supported GHC and the latest one once the lower bound is validated.

## Deferred

### Text and Seq

Deliberately deferred. CLI content is small, and `String`/lists keep the API simple. Revisit only if large documents or incremental sequences become a requirement.

### Monadic Printer and Section interface

Deliberately deferred. The list-based builders and the `State` lifecycle cover the common cases. A separate `Ansiform.Monad` layer can be added if a concrete need appears.

## Implemented

### Color mode and non-TTY detection

Released in 0.7.0. `ColorAuto` disables ANSI styling when stdout is not a terminal, when `NO_COLOR` is set or when `TERM=dumb`; `ColorAlways` and `ColorNever` override the detection. See [Settings](settings.md).
