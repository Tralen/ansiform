# Settings

Settings are built from a list of configuration modifiers. They are applied in order to a configuration derived from the terminal.

```haskell
newtype Settings  -- opaque

settings :: [Config -> Config] -> Settings
defaultSettings :: Settings
```

`defaultSettings` is `settings []`. The initial configuration uses the current terminal width, a minimum space of `2` and a group overflow of `25` percent.

## Modifiers

```haskell
width :: Width -> Config -> Config
minSpace :: Width -> Config -> Config
groupOverflow :: Number -> Config -> Config
overflow :: Number -> Config -> Config
colorMode :: ColorMode -> Config -> Config
autoColors, alwaysColors, neverColors :: Config -> Config
```

- `width n` overrides the detected terminal width. Useful for deterministic output or for rendering into a fixed-width surface.
- `minSpace n` is the minimum number of columns between blocks on a line, list columns and table columns.
- `groupOverflow n` is the percentage by which a group may exceed the average group width before it is split into extra rows. `0` disables overflow; `100` allows a group to reach twice the average.
- `colorMode m` selects how ANSI styling is handled. `autoColors`, `alwaysColors` and `neverColors` are shortcuts for the three modes.

`overflow` is an alias for `groupOverflow`.

```haskell
mySettings :: Settings
mySettings = settings [ width 100
                      , minSpace 2
                      , groupOverflow 25
                      , neverColors ]
```

## Color mode

```haskell
data ColorMode = ColorAuto | ColorAlways | ColorNever
```

`ColorAuto` is the default. It disables ANSI styling when stdout is not a terminal, when `NO_COLOR` is present and non-empty, or when `TERM=dumb`. `ColorAlways` forces styling, which is useful for files and captured output. `ColorNever` disables it unconditionally.

When styling is disabled, no SGR sequence is emitted; the text and its layout are unchanged. Cursor movement sequences are still written because the layout engine uses them to position columns and redraw pages.

## Configuration values

`Config` is opaque. The drawing layer reads four values from it:

| Value | Meaning |
| --- | --- |
| Width | Columns available for layout. |
| Minimum space | Minimum gap between adjacent blocks. |
| Group overflow | Percentage used when splitting long groups. |
| Color mode | Whether ANSI styling is enabled. |

Because settings are resolved at draw time, the same page can be drawn at different widths. `redraw` and `draw` both re-read the configuration.

## Terminal detection

When no width is given, `Ansiform` asks the terminal for its size and falls back to `80` columns when the size is unavailable (for example, when output is redirected). The terminal height is available internally, but the current layout engine only depends on the width.

Color support follows the same rule: `ColorAuto` checks `NO_COLOR`, `TERM` and whether stdout is a terminal each time the settings are resolved. Resolution happens once per draw, so changing those variables between draws is reflected on the next `redraw`.
