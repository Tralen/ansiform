# Theme

A `Theme` groups the styles and colors used by reusable interface components. Headers, footers, menus, rules and tables can share the same visual language instead of repeating hard-coded styles.

## Type

```haskell
data Theme = Theme
  { themeHeader :: Style
  , themeSubtitle :: Style
  , themeFooter :: Style
  , themeAccent :: Style
  , themeDanger :: Style
  , themeMuted :: Style
  , themeRule :: Style
  , themeBar :: Color
  , themeTableHeader :: Style
  , themeTableBody :: Style
  }

defaultTheme :: Theme
```

| Field | Intended use |
| --- | --- |
| `themeHeader` | Title text. |
| `themeSubtitle` | Secondary title text. |
| `themeFooter` | Footer messages. The default theme uses italic white. |
| `themeAccent` | Highlighted keys, links and selected values. |
| `themeDanger` | Exit and destructive actions. |
| `themeMuted` | Secondary and disabled text. The default theme uses italic white. |
| `themeRule` | Horizontal rules. The default theme uses bold vivid black. |
| `themeBar` | Solid bar background. |
| `themeTableHeader` | Table header text. |
| `themeTableBody` | Default table body text. |

## Customizing

The record is immutable. Create a new theme with record update syntax:

```haskell
myTheme :: Theme
myTheme = defaultTheme
  { themeAccent = bold magenta
  , themeRule = bold blue
  , themeBar = blue'
  }
```

## Reusable components

Pass the theme to the component that builds the screen:

```haskell
header :: Theme -> Section
header theme = sectionTopRule 1 (rule '=' (themeRule theme))
  [ printerSolidLineCenter 0 1 (themeBar theme)
      [ blockSimple "My Program" (themeHeader theme) ] ]

menu :: Theme -> [Block]
menu theme =
  [ blockMenuStyle "L" "List" (themeAccent theme)
  , blockMenuStyle "X" "Exit" (themeDanger theme)
  ]
```

`blockMenuStyle` takes a `Style` for the key, so it can use the theme directly. `blockMenu` remains the color-based convenience builder.

## Demo

The demo uses `defaultTheme` for its header, footer, rules, menus and simple table. The local components take the theme as a value, so the same components work with any theme.
