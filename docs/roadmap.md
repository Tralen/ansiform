# Roadmap

This is a prioritized list of possible features and adjustments. It records the current design opinion, not a commitment.

## High value

No pending high-value items.

## Medium value

No pending medium-value items.

## Publication quality

No pending publication-quality items.

## Deferred

### Text and Seq

Deliberately deferred. CLI content is small, and `String`/lists keep the API simple. Revisit only if large documents or incremental sequences become a requirement. The original rationale remains in the Git history.

### Monadic Printer and Section interface

Deliberately deferred. The list-based builders and the `State` lifecycle cover the common cases. A separate `Ansiform.Monad` layer can be added if a concrete need appears. See [Architecture](architecture.md) for the rationale.

## Implemented

### CI matrix

Released in 0.7.6.0. The CI workflow tests GHC 9.2.8 and GHC 9.14.1 with Cabal 3.18.1.0.

### Haddock coverage

Released in 0.7.5.1. Every public function and type is documented, and all public modules report 100% Haddock coverage. The remaining Haddock warnings are only about module re-exports.

### Table borders

Released in 0.7.5.0. `Borders` selects ASCII, light, heavy or double box characters, and the `printerTableBordered` and `printerGroupsBordered` families draw full borders around tables and groups. See [Table formatting](table-format.md).

### Theme record

Released in 0.7.4.0. `Ansiform.Theme` provides `Theme` and `defaultTheme`, with styles for headers, subtitles, footers, accents, danger, muted text, rules, bars and tables. The demo components take the theme as a value. See [Theme](theme.md).

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
