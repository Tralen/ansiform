# Ansiform

[![CI](https://github.com/Tralen/ansiform/actions/workflows/ci.yml/badge.svg)](https://github.com/Tralen/ansiform/actions/workflows/ci.yml)
[![Hackage](https://img.shields.io/hackage/v/ansiform.svg)](https://hackage.haskell.org/package/ansiform)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/Tralen/ansiform/blob/master/LICENSE)

Ansiform is a small Haskell library for building visual command line interfaces. It provides a declarative format DSL for styled text, rules, aligned lines, lists, groups, tables, paragraphs and multi-section pages.

Builders are pure and produce immutable values. A thin drawing layer writes those values to the terminal and keeps track of how many lines were printed, so a page can be amended, replaced or redrawn in place.

> **Formerly known as Vis.** Ansiform is a terminal formatting library, unrelated to the JavaScript `vis-network` graph visualization library or to the Hackage package [`Vis`](https://hackage.haskell.org/package/Vis) (3D graphics). See [Naming](https://github.com/Tralen/ansiform/blob/master/docs/naming.md).

Current version: **1.0.0**.

Repository: <https://github.com/Tralen/ansiform>.

## Stack

Haskell with Cabal. Stack is not used.

## Versioning

PVP, single-sourced from the `ansiform.cabal` file.

## Features

- ANSI colors, bold, italic and underline, with automatic suppression on non-TTY output, `NO_COLOR` and `TERM=dumb`.
- Immediate single-key input: a key press changes the screen without Enter, and shortcut loops ignore arrow-key escape sequences.
- Line input for prompts and numeric selection, including prompts printed inside a page and typed in place.
- Forms that draw a page and read several prompts, with the cursor arithmetic handled by the library.
- Editable form fields that open with every initial value already visible, with arrows, Home, End, Delete and Esc cancellation.
- A pure line-editing core in `Ansiform.Line` that can be tested without a terminal.
- A step-by-step tutorial and a runnable bookmarks example.
- Unicode-aware display widths for alignment, wrapping, lists and tables.
- Rendering to any `Handle` or to a `String` for embedding and golden tests.
- Per-column table alignment, maximum widths and truncation with an ellipsis.
- Optional ASCII, light, heavy or double box borders for tables and groups.
- A true borderless table mode that keeps aligned columns without border characters or column bands.
- Automatic padding of unequal groups in bordered layouts, so the border stays rectangular.
- A reusable `Theme` record for consistent headers, footers, menus and tables.
- Horizontal rules, solid backgrounds, offsets and padding.
- Single-line and multi-line alignment.
- Columns, lists, groups, simple tables and rich tables.
- Paragraph and article wrapping with styled fragments.
- Multi-section pages with amend, replace and redraw support.
- Errors as data: malformed tables return `Nothing` instead of throwing.
- Explicit saturating and checked subtraction for non-negative `Number` values.
- Small dependency footprint: `ansi-terminal`, `terminal-size`, `split`, `transformers` and `directory`.

## Quick start

```haskell
module Main where

import Data.Char (toLower)
import Ansiform

main :: IO ()
main = withImmediateInput $ do
  state <- start examplePage defaultSettings
  loop state

loop :: State -> IO ()
loop state = do
  key <- readKeyPress
  case fmap toLower key of
    Just 'b' -> draw bodyPage state >>= loop
    Just 'h' -> draw examplePage state >>= loop
    Just 'x' -> pure ()
    _ -> loop state

examplePage :: Page
examplePage = page [header, body]

bodyPage :: Page
bodyPage = page [body]

header :: Section
header = sectionTopRule 1 (rule '=' (bold black'))
  [ printerSolidLineCenter 0 1 blue
      [ blockSimple "My Program" (bold white') ] ]

body :: Section
body = sectionBodyRule 1 (rule ':' (bold black'))
  [ printerLeft 2 (blockSimple "Hello, world!" styleDefault) ]
```

Pressing `B` or `H` switches pages immediately; `X` exits. There is no prompt and no Enter.

## Build, test and run

```sh
cabal build
cabal test
cabal run ansiform-demo
cabal run ansiform-tutorial
```

`ansiform-demo` is an interactive gallery. Press the keys shown in the footer; the screen changes immediately, without a prompt or Enter. `B` returns to the menu, `R` redraws the current screen and `X` exits.

`ansiform-tutorial` is the small bookmarks program from the [tutorial](https://github.com/Tralen/ansiform/blob/master/docs/tutorial.md).

## Documentation

- [Tutorial](https://github.com/Tralen/ansiform/blob/master/docs/tutorial.md): build a small bookmarks program step by step.
- [Architecture](https://github.com/Tralen/ansiform/blob/master/docs/architecture.md): module layout, invariants and the pure/IO boundary.
- [Content](https://github.com/Tralen/ansiform/blob/master/docs/content.md): items, blocks, groups, tables, paragraphs and their builders.
- [Styles](https://github.com/Tralen/ansiform/blob/master/docs/style.md): colors, formats and reusable text styles.
- [Theme](https://github.com/Tralen/ansiform/blob/master/docs/theme.md): reusable styles for headers, footers, menus and tables.
- [Printers](https://github.com/Tralen/ansiform/blob/master/docs/printers.md): every printer function and its arguments.
- [Table formatting](https://github.com/Tralen/ansiform/blob/master/docs/table-format.md): per-column alignment, maximum widths, truncation and borders.
- [Sections](https://github.com/Tralen/ansiform/blob/master/docs/sections.md): grouping printers and reserving minimum line counts.
- [Pages and drawing](https://github.com/Tralen/ansiform/blob/master/docs/pages.md): pages, state and the drawing lifecycle.
- [Input](https://github.com/Tralen/ansiform/blob/master/docs/input.md): immediate and line input, forms, and the standard interaction loop.
- [Platforms](https://github.com/Tralen/ansiform/blob/master/docs/platforms.md): Linux, macOS and Windows behaviour, terminal requirements and known limitations.
- [Ports](https://github.com/Tralen/ansiform/blob/master/docs/ports.md): an assessment of porting the library to Rust.
- [Render](https://github.com/Tralen/ansiform/blob/master/docs/render.md): rendering pages, sections and printers to a `Handle` or a `String`.
- [Settings](https://github.com/Tralen/ansiform/blob/master/docs/settings.md): width, spacing and group overflow configuration.
- [Numbers](https://github.com/Tralen/ansiform/blob/master/docs/number.md): non-negative arithmetic, saturation and checked subtraction.
- [Demo](https://github.com/Tralen/ansiform/blob/master/docs/demo.md): what the executable showcases.
- [Naming](https://github.com/Tralen/ansiform/blob/master/docs/naming.md): name rationale and disambiguation.
- [Releasing](https://github.com/Tralen/ansiform/blob/master/docs/releasing.md): Hackage and GitHub publication checklist.
- [Roadmap](https://github.com/Tralen/ansiform/blob/master/docs/roadmap.md): prioritized feature suggestions.

## Design principles

1. **Immutable values.** Every public builder returns a new value; nothing is mutated after creation.
2. **Pure core.** Layout, wrapping and table validation are pure functions. Only the drawing layer performs IO.
3. **Errors as data.** Table builders return `Maybe Table`. There are no exceptions in the public API.
4. **Immediate interaction.** The standard interaction is a single key press, handled by `Ansiform.Input` without Enter.
5. **Reusable components.** Screens are assembled from shared builders such as `header`, `footer` and `rule`, keeping behavior and theming consistent.
6. **Explicit versioning.** The package follows the PVP and every release is recorded in [CHANGELOG.md](https://hackage.haskell.org/package/ansiform/changelog).

## License

MIT. See [LICENSE](https://github.com/Tralen/ansiform/blob/master/LICENSE).
