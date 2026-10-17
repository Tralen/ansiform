# Styles

A `Style` combines a foreground color, a background color and a text format. Styles are values; applying a style never mutates it.

## Colors

The public color values are ANSI colors with two intensities. The primed names are the vivid variants.

```haskell
colorDefault :: Color
black, black' :: Color
red, red' :: Color
green, green' :: Color
yellow, yellow' :: Color
blue, blue' :: Color
magenta, magenta' :: Color
cyan, cyan' :: Color
white, white' :: Color
```

`colorDefault` leaves the terminal color unchanged.

## Formats

```haskell
formatDefault :: Format
formatRegular :: Format
formatBold, formatItalic, formatUnderline :: Format
formatBoldItalic, formatBoldUnderline :: Format
formatItalicUnderline, formatBoldItalicUnderline :: Format
```

## Styles

```haskell
styleDefault :: Style
normal, bold, italic, underline :: Color -> Style
boldItalic, boldUnderline :: Color -> Style
italicUnderline, boldItalicUnderline :: Color -> Style
solid, solidBold :: Color -> Style
```

- `normal c` sets the foreground to `c` and leaves the background default.
- `bold c` is `normal c` with bold intensity.
- `solid c` uses black text on a `c` background, useful for highlighted rows.
- `styleDefault` resets color and format.

```haskell
title :: Style
title = bold cyan

selected :: Style
selected = solid blue'

warning :: Style
warning = bold red
```

## Text styles

Text styles are convenient values for paragraph fragments. They use the terminal default foreground instead of fixing a color.

```haskell
textRegular :: Style
textBold, textItalic, textUnderline :: Style
textBoldItalic, textBoldUnderline :: Style
textItalicUnderline, textBoldItalicUnderline :: Style
textColor, textMark :: Color -> Style
```

`textColor c` is `normal c`; `textMark c` is `solid c`.

```haskell
paragraph :: Paragraph
paragraph =
  [ blockSimple "Regular text, " textRegular
  , blockSimple "bold text, " textBold
  , blockSimple "italic text, " textItalic
  , blockSimple "highlighted text." (textMark yellow)
  ]
```

## Backgrounds

Printers that draw solid backgrounds add the background to each item without overwriting a background that the item already has. This lets a styled cell keep its own highlight inside a zebra-striped table.
