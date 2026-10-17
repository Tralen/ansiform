# Printers

A `VisPrinter` describes one printable element. Builders are pure; the printer
only runs when a section or page is drawn. Every printer returns the number of
lines it printed.

```haskell
-- Run a printer directly, useful for tests and small scripts.
runPrinter :: VisSettings -> VisPrinter -> IO VisNumber

-- Run with the default settings.
runPrinterDefault :: VisPrinter -> IO VisNumber

-- Run with the default settings and an explicit width and minimum space.
runPrinterDefault' :: VisWidth -> VisWidth -> VisPrinter -> IO VisNumber
```

## Arguments

- `VisOffset`: indentation from the left, in columns. Some printers also use it
  as an offset from both sides.
- `VisPadding`: space between the text and the edge of a solid background.
- `VisNumber`: a non-negative count, such as a number of lines or rows.

## Basic printing

```haskell
printerEmpty :: VisNumber -> VisPrinter
printerItem :: VisItem -> VisPrinter
```

`printerEmpty n` prints `n` empty lines. `printerItem` prints one `VisItem`
followed by a newline.

## Rules and solid lines

```haskell
printerRule :: VisRule -> VisPrinter
printerRule' :: VisOffset -> VisRule -> VisPrinter
printerSolid :: VisColor -> VisPrinter
printerSolid' :: VisOffset -> VisColor -> VisPrinter
```

`printerRule` fills the whole width with the rule character. `printerRule'`
leaves the offset free on both sides. `printerSolid` and `printerSolid'` do the
same with a background color.

## Single lines

```haskell
printerLeft :: VisOffset -> VisBlock -> VisPrinter
printerRight :: VisOffset -> VisBlock -> VisPrinter
printerCenter :: VisOffset -> VisBlock -> VisPrinter

printerLineLeft :: VisOffset -> [VisBlock] -> VisPrinter
printerLineRight :: VisOffset -> [VisBlock] -> VisPrinter
printerLineCenter :: VisOffset -> [VisBlock] -> VisPrinter
```

The `Line` variants print several blocks on the same line with the minimum
space from the settings between them. The first group takes a single block.

```haskell
printerLineCenter 4
  [ blockSimple "Search" (bold cyan)
  , blockSimple "Display" (bold yellow)
  , blockSimple "Exit" (bold red) ]
```

## Solid text lines

```haskell
printerSolidLeft :: VisOffset -> VisPadding -> VisColor -> VisBlock -> VisPrinter
printerSolidRight :: VisOffset -> VisPadding -> VisColor -> VisBlock -> VisPrinter
printerSolidCenter :: VisOffset -> VisPadding -> VisColor -> VisBlock -> VisPrinter

printerSolidLineLeft :: VisOffset -> VisPadding -> VisColor -> [VisBlock] -> VisPrinter
printerSolidLineRight :: VisOffset -> VisPadding -> VisColor -> [VisBlock] -> VisPrinter
printerSolidLineCenter :: VisOffset -> VisPadding -> VisColor -> [VisBlock] -> VisPrinter
```

These printers fill a whole line with the background color and then print the
text on top, with the given padding. They are useful for title bars and
selected rows.

## Columns and lists

```haskell
printerColumn :: VisOffset -> [VisBlock] -> VisPrinter
printerList :: VisOffset -> VisNumber -> [VisBlock] -> VisPrinter
printerList' :: VisOffset -> VisNumber -> [VisBlock] -> VisPrinter
```

`printerColumn` prints one block per line. `printerList` tries to reach a
target number of rows and grows the number of columns as needed.
`printerList'` takes a target number of columns instead. If the terminal is too
narrow, the printer falls back to a single column.

## Groups

```haskell
printerGroup :: VisOffset -> VisGroup -> VisPrinter
printerGroups :: VisOffset -> [VisGroup] -> VisPrinter
printerGroups' :: VisOffset -> [VisGroup] -> VisPrinter
printerGroupsLimited :: VisOffset -> VisNumber -> [VisGroup] -> VisPrinter
printerGroupsLimited' :: VisOffset -> VisNumber -> [VisGroup] -> VisPrinter
```

- `printerGroup` prints one group as a column.
- `printerGroups` spaces the groups evenly.
- `printerGroups'` gives each group the minimum width it needs.
- The `Limited` variants stop after a number of rows; `0` means no limit.

Groups that exceed the configured overflow ratio are split into extra rows by
the layout engine.

## Tables

```haskell
printerTable :: VisOffset -> VisPadding -> Maybe VisTable -> VisPrinter
printerTable' :: VisOffset -> VisPadding -> Maybe VisTable -> VisPrinter
printerTableLimited :: VisOffset -> VisPadding -> VisNumber -> Maybe VisTable -> VisPrinter
printerTableLimited' :: VisOffset -> VisPadding -> VisNumber -> Maybe VisTable -> VisPrinter
```

- `printerTable` uses minimum column spacing and a zebra background.
- `printerTable'` spaces the columns evenly.
- The `Limited` variants stop after a number of rows; `0` means no limit.
- A `Nothing` table is treated as an empty group, so invalid input still
  produces a well-defined (empty) result instead of an exception.

## Paragraphs and articles

```haskell
printerParagraph :: VisOffset -> VisOffset -> VisParagraph -> VisPrinter
printerArticle :: VisOffset -> VisOffset -> VisArticle -> VisPrinter

printerSequence :: VisOffset -> VisOffset -> VisPadding -> [VisParagraph] -> VisPrinter
printerSequence' :: VisOffset -> VisOffset -> VisPadding -> [VisParagraph] -> VisPrinter
printerSequenceSel :: VisOffset -> VisOffset -> VisPadding -> VisNumber -> [VisParagraph] -> VisPrinter
printerSequenceAfter :: VisOffset -> VisOffset -> VisPadding -> VisNumber -> [VisParagraph] -> VisPrinter
printerSequencePred :: VisOffset -> VisOffset -> VisPadding -> (Int -> Bool) -> [VisParagraph] -> VisPrinter
```

The first offset indents the whole paragraph. The second offset indents only
the first line.

- `printerParagraph` wraps the blocks at the terminal width.
- `printerArticle` prints paragraphs separated by a blank line.
- The `printerSequence` variants add a solid background to selected
  paragraphs: `printerSequence` selects odd indices, `printerSequence'`
  selects even indices, `printerSequenceSel` selects one index,
  `printerSequenceAfter` selects indices greater than or equal to a value, and
  `printerSequencePred` accepts any predicate.
