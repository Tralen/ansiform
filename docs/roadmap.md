# Roadmap

This is a prioritized list of possible features and adjustments. It records the current design opinion, not a commitment.

## High value

No pending high-value items.

## Medium value

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

### Per-column alignment and truncation

Released in 0.7.3.0. `Ansiform.Table` adds `Align`, `Ellipsis` and `ColumnSpec`, and the `printerTableFormat` family applies right, center or left alignment, maximum widths and ellipsis truncation per column. See [Table formatting](table-format.md).

### Rendering to a handle or string

Released in 0.7.2.0. All printers write to a `Handle`; the default runners use stdout and the `On` variants accept any handle. `Ansiform.Render` captures pages, sections and printers in a `String` through a temporary handle, which supports embedding and golden tests. See [Render](render.md).

### Immediate single-key input

Released in 0.7.1.0. `Ansiform.Input` provides `withImmediateInput` and `readKey`, so pressing a key changes the screen without Enter. The terminal state is restored when the interaction ends. See [Input](input.md).

### Unicode display width

Released in 0.7.1.0. Layout now measures text in terminal columns instead of code points. Combining marks are zero width, wide CJK characters and emoji are two columns, and wrapping, alignment, lists and tables share the same `textWidth` function. See [Content](content.md).

### Color mode and non-TTY detection

Released in 0.7.0. `ColorAuto` disables ANSI styling when stdout is not a terminal, when `NO_COLOR` is set or when `TERM=dumb`; `ColorAlways` and `ColorNever` override the detection. See [Settings](settings.md).
