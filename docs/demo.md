# Demo

The package ships with an interactive gallery:

```sh
cabal run ansiform-demo
```

The header and footer are shared components; only the body changes between screens. The footer always lists the keys accepted by the current screen. The demo uses `withImmediateInput` and `readKey` for navigation, and `readForm` with `promptAt` for the philosopher prompt.

## Keys

| Key | Action |
| --- | --- |
| `L` | List of composers, flowing into columns. |
| `G` | Groups of philosophers, spaced across the width. |
| `T` | Simple table with right-aligned numeric columns and truncated composer names. |
| `H` | Rich table with light box borders and independently styled cells. |
| `A` | Article with styled paragraph fragments. |
| `C` | Content builders, or on the Groups screen, prompts for a philosopher number. |
| `B` | Back. From a philosopher article, returns to Groups; elsewhere, returns to the menu. |
| `R` | Redraw the current screen. |
| `X` | Exit. |

The menu lists each shortcut next to its option, and the footer shows the same keys. On the main menu, the footer commands are split into two rows so longer labels do not crowd. Press a key directly; the screen changes immediately, with no prompt and no Enter. The demo restores the terminal settings when it exits. When stdin is not a terminal, for example with piped input, line breaks are ignored and each character is handled as a key.

On the Groups screen, the colored numbers 06 (Cicero) and 14 (Locke) identify selectable entries. The footer adds `C Choose`, which asks for a number on a single prompt line inside the footer. A blank line follows the prompt, then the `B`/`R`/`X` commands, and nothing is printed below the footer. Type any philosopher number from 01 to 15 and press Enter. The demo draws the prompt page, uses `readForm` with a section-relative `promptAt` position, then restores the immediate settings before opening the article. The prompt is section 2, row 2: the footer prints the rule on row 0, a blank line on row 1 and the prompt on row 2. Update `promptAt` if the footer composition changes. The article footer uses `B`/`R`/`X`, and `B` returns to the Groups screen, where `C` still works and another philosopher can be chosen.

## Source

The executable lives in `examples/Demo.hs`. It uses only the public API, defines its version in `demoVersion`, and keeps a small `Screen` data type to select the body for each page. The version follows the package version in `ansiform.cabal`.
