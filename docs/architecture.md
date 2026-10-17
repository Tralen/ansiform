# Architecture

Vis separates the description of a screen from the act of drawing it.

## Module layout

The public modules are thin, documented facades over internal modules.

| Public module | Responsibility | Internal module |
| --- | --- | --- |
| `Vis` | Umbrella re-export of the whole public API. | n/a |
| `Vis.Content` | Items, blocks, groups, tables and their builders. | `Vis.Internal.Content` |
| `Vis.Style` | Colors, formats and styles. | `Vis.Internal.Style` |
| `Vis.Number` | Non-negative numbers used for sizes. | `Vis.Internal.Number` |
| `Vis.Printer` | Printer builders. | `Vis.Internal.Printer` |
| `Vis.Section` | Section builders. | `Vis.Internal.Section` |
| `Vis.Page` | Page builders. | `Vis.Internal.Page` |
| `Vis.Settings` | Settings and configuration modifiers. | `Vis.Internal.Settings` |
| `Vis.Sample` | Inspection helpers for debugging. | `Vis.Internal.Sample` |
| `Vis.Draw` | Drawing and state lifecycle. | `Vis.Internal.State`, `Vis.Internal.Terminal` |

The `Vis.Internal.*` modules are implementation details. They are not exposed by the package and may change without a major version bump.

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

`VisPrinter` stores a function `VisConfig -> IO VisNumber`. The function is created by a pure builder, but it runs only when a section or page is drawn. This keeps the description of a screen pure while allowing the drawing layer to query the terminal width and move the cursor.

## Invariants

The builders enforce these invariants:

- `VisNumber` is never negative. Negative inputs are capped at zero.
- A `VisBlock` contains no empty items. Non-printable characters are removed from item text.
- A `VisGroup` is a header block followed by zero or more body blocks.
- A `VisTable` is a list of groups with the same number of blocks. Table builders return `Nothing` when this does not hold.
- A `VisPage` is a list of sections. Drawing returns one line count per section, in order.

## Errors as data

There is one expected error in the model: a malformed table. It is represented by `Maybe VisTable`:

```haskell
tableBlocks :: [VisBlock] -> [[VisBlock]] -> Maybe VisTable
tableSimple :: [VisBlock] -> VisStyle -> [[String]] -> Maybe VisTable
tableGroups :: [VisGroup] -> Maybe VisTable
```

No public function throws an exception for malformed input. Layout functions are total: empty lists and narrow terminals produce empty or overflowing output rather than a runtime failure.

## Versioning

The package follows the Haskell Package Versioning Policy (PVP). The version lives in `vis.cabal` and is recorded in `ChangeLog.md`.

- Patch: fixes and small refinements.
- Minor: new user-facing features or screens.
- Major 2: breaking data model changes.
- Major 1: major release milestones.

The demo executable also carries its own `demoVersion` constant so it can show the package version on screen.
