# Ansiform

Ansiform is a small Haskell library for building visual command line interfaces. It provides a declarative format DSL for styled text, rules, aligned lines, lists, groups, tables, paragraphs and multi-section pages.

Builders are pure and produce immutable values. A thin drawing layer writes those values to the terminal and keeps track of how many lines were printed, so a page can be amended, replaced or redrawn in place.

> **Formerly known as Vis.** Ansiform is a terminal formatting library, unrelated to the JavaScript `vis-network` graph visualization library or to the Hackage package [`Vis`](https://hackage.haskell.org/package/Vis) (3D graphics). See [Naming](docs/naming.md).

Current version: **0.7.3.0**.

## Features

- ANSI colors, bold, italic and underline, with automatic suppression on non-TTY output, `NO_COLOR` and `TERM=dumb`.
- Immediate single-key input: a key press changes the screen without Enter.
- Unicode-aware display widths for alignment, wrapping, lists and tables.
- Rendering to any `Handle` or to a `String` for embedding and golden tests.
- Per-column table alignment, maximum widths and truncation with an ellipsis.
- Horizontal rules, solid backgrounds, offsets and padding.
- Single-line and multi-line alignment.
- Columns, lists, groups, simple tables and rich tables.
- Paragraph and article wrapping with styled fragments.
- Multi-section pages with amend, replace and redraw support.
- Errors as data: malformed tables return `Nothing` instead of throwing.
- Small dependency footprint: `ansi-terminal`, `terminal-size` and `split`.

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
  key <- readKey
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
```

`ansiform-demo` is an interactive gallery. Press the keys shown in the footer; the screen changes immediately, without a prompt or Enter. `B` returns to the menu, `R` redraws the current screen and `X` exits.

## Documentation

- [Architecture](docs/architecture.md): module layout, invariants and the pure/IO boundary.
- [Content](docs/content.md): items, blocks, groups, tables, paragraphs and their builders.
- [Styles](docs/style.md): colors, formats and reusable text styles.
- [Printers](docs/printers.md): every printer function and its arguments.
- [Table formatting](docs/table-format.md): per-column alignment, maximum widths and truncation.
- [Sections](docs/sections.md): grouping printers and reserving minimum line counts.
- [Pages and drawing](docs/pages.md): pages, state and the drawing lifecycle.
- [Input](docs/input.md): immediate single-key input and the standard interaction loop.
- [Render](docs/render.md): rendering pages, sections and printers to a `Handle` or a `String`.
- [Settings](docs/settings.md): width, spacing and group overflow configuration.
- [Demo](docs/demo.md): what the executable showcases.
- [Design notes](docs/design-notes.md): original project notes and their current status.
- [Naming](docs/naming.md): name rationale and disambiguation.
- [Releasing](docs/releasing.md): Hackage and GitHub publication checklist.
- [Roadmap](docs/roadmap.md): prioritized feature suggestions.

## Design principles

1. **Immutable values.** Every public builder returns a new value; nothing is mutated after creation.
2. **Pure core.** Layout, wrapping and table validation are pure functions. Only the drawing layer performs IO.
3. **Errors as data.** Table builders return `Maybe Table`. There are no exceptions in the public API.
4. **Immediate interaction.** The standard interaction is a single key press, handled by `Ansiform.Input` without Enter.
5. **Reusable components.** Screens are assembled from shared builders such as `header`, `footer` and `rule`, keeping behavior and theming consistent.
6. **Explicit versioning.** The package follows the PVP and every release is recorded in [CHANGELOG.md](CHANGELOG.md).

## License

MIT. See [LICENSE](LICENSE).
