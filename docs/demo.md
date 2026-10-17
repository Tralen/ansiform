# Demo

The package ships with an interactive gallery:

```sh
cabal run vis-demo
```

The header and footer are shared components; only the body changes between
screens. The footer always lists the keys accepted by the current screen.

## Keys

| Key | Action |
| --- | --- |
| `L` | List of composers, flowing into columns. |
| `G` | Groups of philosophers, spaced across the width. |
| `T` | Simple table, reusing the header styles for each column. |
| `H` | Rich table, with independently styled cells. |
| `A` | Article with styled paragraph fragments. |
| `C` | Showcase of the composite content builders. |
| `B` | Back to the main menu. |
| `R` | Redraw the current screen. |
| `X` | Exit. |

The menu marks the shortcut letter of each option. A `vis-demo>` prompt appears
below the page; type a key or a command word and press Enter.

## Source

The executable lives in `examples/Demo.hs`. It uses only the public API, defines
its version in `demoVersion`, and keeps a small `Screen` data type to select
the body for each page. The version follows the package version in
`vis.cabal`.
