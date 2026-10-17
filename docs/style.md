# Styles

A `VisStyle` combines a foreground color, a background color and a text
format. Styles are values; applying a style never mutates it.

## Colors

The public color values are ANSI colors with two intensities. The primed names
are the vivid variants.

```haskell
colorDefault :: VisColor
black, black' :: VisColor
red, red' :: VisColor
green, green' :: VisColor
yellow, yellow' :: VisColor
blue, blue' :: VisColor
magenta, magenta' :: VisColor
cyan, cyan' :: VisColor
white, white' :: VisColor
```

`colorDefault` leaves the terminal color unchanged.

## Formats

```haskell
formatDefault :: VisFormat
formatRegular :: VisFormat
formatBold, formatItalic, formatUnderline :: VisFormat
formatBoldItalic, formatBoldUnderline :: VisFormat
formatItalicUnderline, formatBoldItalicUnderline :: VisFormat
```

## Styles

```haskell
styleDefault :: VisStyle
normal, bold, italic, underline :: VisColor -> VisStyle
boldItalic, boldUnderline :: VisColor -> VisStyle
italicUnderline, boldItalicUnderline :: VisColor -> VisStyle
solid, solidBold :: VisColor -> VisStyle
```

- `normal c` sets the foreground to `c` and leaves the background default.
- `bold c` is `normal c` with bold intensity.
- `solid c` uses black text on a `c` background, useful for highlighted rows.
- `styleDefault` resets color and format.

```haskell
title :: VisStyle
title = bold cyan

selected :: VisStyle
selected = solid blue'

warning :: VisStyle
warning = bold red
```

## Text styles

Text styles are convenient values for paragraph fragments. They use the
terminal default foreground instead of fixing a color.

```haskell
textRegular :: VisStyle
textBold, textItalic, textUnderline :: VisStyle
textBoldItalic, textBoldUnderline :: VisStyle
textItalicUnderline, textBoldItalicUnderline :: VisStyle
textColor, textMark :: VisColor -> VisStyle
```

`textColor c` is `normal c`; `textMark c` is `solid c`.

```haskell
paragraph :: VisParagraph
paragraph =
  [ blockSimple "Regular text, " textRegular
  , blockSimple "bold text, " textBold
  , blockSimple "italic text, " textItalic
  , blockSimple "highlighted text." (textMark yellow)
  ]
```

## Backgrounds

Printers that draw solid backgrounds add the background to each item without
overwriting a background that the item already has. This lets a styled cell
keep its own highlight inside a zebra-striped table.
