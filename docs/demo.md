# Demo

The package ships with an interactive gallery:

```sh
cabal run ansiform-demo
```

The header and footer are shared components; only the body changes between screens. The footer always lists the keys accepted by the current screen. The demo uses `withImmediateInput` and `readKey` from `Ansiform.Input`, the same immediate input API available to applications.

## Keys

| Key | Action |
| --- | --- |
| `L` | List of composers; on the Groups screen, opens the Locke article. |
| `G` | Groups of philosophers, spaced across the width. |
| `T` | Simple table with right-aligned numeric columns and truncated composer names. |
| `H` | Rich table with light box borders and independently styled cells. |
| `A` | Article with styled paragraph fragments. |
| `C` | Showcase of the composite content builders; on the Groups screen, opens the Cicero article. |
| `B` | Back to the main menu. |
| `R` | Redraw the current screen. |
| `X` | Exit. |

The menu lists each shortcut next to its option, and the footer shows the same keys. On the main menu, the footer commands are split into two rows so longer labels do not crowd. Press a key directly; the screen changes immediately, with no prompt and no Enter. The demo restores the terminal settings when it exits. When stdin is not a terminal, for example with piped input, line breaks are ignored and each character is handled as a key.

On the Groups screen, the colored numbers 06 (Cicero) and 14 (Locke) identify the philosophers that have dedicated articles. The footer adds `C` for Cicero and `L` for Locke; both articles use the standard `B`/`R`/`X` footer.

## Source

The executable lives in `examples/Demo.hs`. It uses only the public API, defines its version in `demoVersion`, and keeps a small `Screen` data type to select the body for each page. The version follows the package version in `ansiform.cabal`.
