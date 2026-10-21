# Architecture

Ansiform separates the description of a screen from the act of drawing it.

## Module layout

The public modules are thin, documented facades over internal modules.

| Public module | Responsibility | Internal module |
| --- | --- | --- |
| `Ansiform` | Umbrella re-export of the whole public API. | n/a |
| `Ansiform.Content` | Items, blocks, groups, tables and their builders. | `Ansiform.Internal.Content` |
| `Ansiform.Style` | Colors, formats and styles. | `Ansiform.Internal.Style` |
| `Ansiform.Number` | Non-negative numbers used for sizes. | `Ansiform.Internal.Number` |
| `Ansiform.Printer` | Printer builders. | `Ansiform.Internal.Printer` |
| `Ansiform.Section` | Section builders. | `Ansiform.Internal.Section` |
| `Ansiform.Page` | Page builders. | `Ansiform.Internal.Page` |
| `Ansiform.Settings` | Settings and configuration modifiers. | `Ansiform.Internal.Settings` |
| `Ansiform.Table` | Per-column table formatting. | `Ansiform.Internal.Table` |
| `Ansiform.Theme` | Reusable styles for interface components. | `Ansiform.Internal.Theme` |
| `Ansiform.Input` | Immediate single-key input, line input and page forms. | `Ansiform.Internal.Input` |
| `Ansiform.Line` | Pure single-line editing state and width-aware windowing. | `Ansiform.Internal.Line` |
| `Ansiform.Render` | Rendering to a `Handle` or a `String`. | `Ansiform.Internal.Output`, `Ansiform.Internal.Render` |
| `Ansiform.Width` | Display width of characters and strings. | `Ansiform.Internal.Width` |
| `Ansiform.Sample` | Inspection helpers for debugging. | `Ansiform.Internal.Sample` |
| `Ansiform.Draw` | Drawing and state lifecycle. | `Ansiform.Internal.State`, `Ansiform.Internal.Terminal` |

The `Ansiform.Internal.*` modules are implementation details. They are not exposed by the package and may change without a major version bump.

## Layering

```text
+--------------------------------------------------------------+
|  User code: builds pages with pure functions                 |
+--------------------------------------------------------------+
|  Content, Style, Number, Printer, Section, Page, Settings    |
|  Pure builders returning immutable values                    |
+--------------------------------------------------------------+
|  Draw: start, draw, amend, replace, redraw                   |
|  IO boundary; tracks printed line counts                     |
+--------------------------------------------------------------+
|  Terminal: ANSI escape codes and terminal size               |
+--------------------------------------------------------------+
```

`Printer` stores a function `Output -> IO Number`. `Output` combines the target `Handle` with the `Config` resolved for it. The function is created by a pure builder, but it runs only when a section or page is drawn. This keeps the description of a screen pure while allowing the drawing layer to query the terminal width and move the cursor.

The default runners write to stdout. The `On` variants accept any handle, and `Ansiform.Render` captures the same output in a `String` through a temporary handle.

`Ansiform.Input` is the other IO boundary. It configures stdin for immediate single-key reads or line input and restores the terminal state when the interaction ends. The prefilled field editor lives behind `promptWithInitial`; its buffer operations and visible window are pure functions in `Ansiform.Line`, and the IO loop only decodes keys, applies them and redraws.

## Invariants

The builders enforce these invariants:

- `Number` is never negative. Negative inputs are capped at zero.
- A `Block` contains no empty items. Non-printable characters are removed from item text.
- A `Group` is a header block followed by zero or more body blocks.
- A `Table` is a list of groups with the same number of blocks. Table builders return `Nothing` when this does not hold.
- A `Page` is a list of sections. Drawing returns one line count per section, in order.

## Errors as data

There is one expected error in the model: a malformed table. It is represented by `Maybe Table`:

```haskell
tableBlocks :: [Block] -> [[Block]] -> Maybe Table
tableSimple :: [Block] -> Style -> [[String]] -> Maybe Table
tableGroups :: [Group] -> Maybe Table
```

No public function throws an exception for malformed input. Layout functions are total: empty lists and narrow terminals produce empty or overflowing output rather than a runtime failure.

## Versioning

The package follows the Haskell Package Versioning Policy (PVP). The version lives in `ansiform.cabal` and is recorded in `ChangeLog.md`.

- Patch: fixes and small refinements.
- Minor: new user-facing features or screens.
- Major 2: breaking data model changes.
- Major 1: major release milestones.

The demo executable also carries its own `demoVersion` constant so it can show the package version on screen.
