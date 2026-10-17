# Settings

Settings are built from a list of configuration modifiers. They are applied in order to a configuration derived from the terminal.

```haskell
newtype VisSettings  -- opaque

settings :: [VisConfig -> VisConfig] -> VisSettings
defaultSettings :: VisSettings
```

`defaultSettings` is `settings []`. The initial configuration uses the current terminal width, a minimum space of `2` and a group overflow of `25` percent.

## Modifiers

```haskell
width :: VisWidth -> VisConfig -> VisConfig
minSpace :: VisWidth -> VisConfig -> VisConfig
groupOverflow :: VisNumber -> VisConfig -> VisConfig
overflow :: VisNumber -> VisConfig -> VisConfig
```

- `width n` overrides the detected terminal width. Useful for deterministic output or for rendering into a fixed-width surface.
- `minSpace n` is the minimum number of columns between blocks on a line, list columns and table columns.
- `groupOverflow n` is the percentage by which a group may exceed the average group width before it is split into extra rows. `0` disables overflow; `100` allows a group to reach twice the average.

`overflow` is an alias for `groupOverflow`.

```haskell
mySettings :: VisSettings
mySettings = settings [ width 100
                      , minSpace 2
                      , groupOverflow 25 ]
```

## Configuration values

`VisConfig` is opaque. The drawing layer reads three values from it:

| Value | Meaning |
| --- | --- |
| Width | Columns available for layout. |
| Minimum space | Minimum gap between adjacent blocks. |
| Group overflow | Percentage used when splitting long groups. |

Because settings are resolved at draw time, the same page can be drawn at different widths. `redraw` and `draw` both re-read the configuration.

## Terminal detection

When no width is given, `Vis` asks the terminal for its size and falls back to `80` columns when the size is unavailable (for example, when output is redirected). The terminal height is available internally, but the current layout engine only depends on the width.
