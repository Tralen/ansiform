# Demo

The package ships with an interactive gallery:

```sh
cabal run ansiform-demo
```

The header and footer are shared components; only the body changes between screens. The footer always lists the keys accepted by the current screen. The demo uses `withImmediateInput` and `readKey` for navigation, and `withLineInput` and `readLine` for the philosopher prompt.

## Keys

| Key | Action |
| --- | --- |
| `L` | List of composers, flowing into columns. |
| `G` | Groups of philosophers, spaced across the width. |
| `T` | Simple table with right-aligned numeric columns and truncated composer names. |
| `H` | Rich table with light box borders and independently styled cells. |
| `A` | Article with styled paragraph fragments. |
| `C` | Showcase of the composite content builders. |
| `E` | On the Groups screen, prompts for a philosopher number. |
| `B` | Back. From a philosopher article, returns to Groups; elsewhere, returns to the menu. |
| `R` | Redraw the current screen. |
| `X` | Exit. |

The menu lists each shortcut next to its option, and the footer shows the same keys. On the main menu, the footer commands are split into two rows so longer labels do not crowd. Press a key directly; the screen changes immediately, with no prompt and no Enter. The demo restores the terminal settings when it exits. When stdin is not a terminal, for example with piped input, line breaks are ignored and each character is handled as a key.

On the Groups screen, the colored numbers 06 (Cicero) and 14 (Locke) identify selectable entries. The footer adds `E Escolher`, which opens a line prompt. Type any philosopher number from 01 to 15 and press Enter. The demo switches from immediate key input to line input for the prompt with `withLineInput`, then restores the immediate settings. The article footer uses `B`/`R`/`X`, and `B` returns to the Groups screen.

## Source

The executable lives in `examples/Demo.hs`. It uses only the public API, defines its version in `demoVersion`, and keeps a small `Screen` data type to select the body for each page. The version follows the package version in `ansiform.cabal`.
