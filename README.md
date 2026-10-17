# Vis

Vis is a small Haskell library for building visual command line interfaces.
It provides a declarative format DSL for styled text, rules, aligned lines,
lists, groups, tables, paragraphs and multi-section pages.

Builders are pure and produce immutable values. A thin drawing layer writes
those values to the terminal and keeps track of how many lines were printed,
so a page can be amended, replaced or redrawn in place.

Current version: **0.3.1**.

## Features

- ANSI colors, bold, italic and underline.
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

import Vis

main :: IO ()
main = do
  state <- start examplePage defaultSettings
  _ <- getLine
  _ <- redraw state
  pure ()

examplePage :: VisPage
examplePage = page [header, body]

header :: VisSection
header = sectionTopRule 1 (rule '=' (bold black'))
  [ printerSolidLineCenter 0 1 blue
      [ blockSimple "My Program" (bold white') ] ]

body :: VisSection
body = sectionBodyRule 1 (rule ':' (bold black'))
  [ printerLeft 2 (blockSimple "Hello, world!" styleDefault) ]
```

## Build, test and run

```sh
cabal build
cabal test
cabal run vis-demo
```

`vis-demo` is an interactive gallery. Use the keys shown in the footer to open
list, group, table and article screens; `B` returns to the menu, `R` redraws
the current screen and `X` exits.

## Documentation

- [Architecture](docs/architecture.md): module layout, invariants and the pure/IO boundary.
- [Content](docs/content.md): items, blocks, groups, tables, paragraphs and their builders.
- [Styles](docs/style.md): colors, formats and reusable text styles.
- [Printers](docs/printers.md): every printer function and its arguments.
- [Sections](docs/sections.md): grouping printers and reserving minimum line counts.
- [Pages and drawing](docs/pages.md): pages, state and the drawing lifecycle.
- [Settings](docs/settings.md): width, spacing and group overflow configuration.
- [Demo](docs/demo.md): what the executable showcases.
- [Design notes](docs/design-notes.md): original project notes and their current status.

## Design principles

1. **Immutable values.** Every public builder returns a new value; nothing is
   mutated after creation.
2. **Pure core.** Layout, wrapping and table validation are pure functions.
   Only the drawing layer performs IO.
3. **Errors as data.** Table builders return `Maybe VisTable`. There are no
   exceptions in the public API.
4. **Reusable components.** Screens are assembled from shared builders such as
   `header`, `footer` and `rule`, keeping behavior and theming consistent.
5. **Explicit versioning.** The package follows the PVP and every release is
   recorded in [ChangeLog.md](ChangeLog.md).

## License

GPL-3. See [LICENSE](LICENSE).
