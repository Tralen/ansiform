# Printers

A `Printer` describes one printable element. Builders are pure; the printer only runs when a section or page is drawn. Every printer returns the number of lines it printed.

```haskell
-- Run a printer directly, useful for tests and small scripts.
runPrinter :: Settings -> Printer -> IO Number

-- Run with the default settings.
runPrinterDefault :: Printer -> IO Number

-- Run with the default settings and an explicit width and minimum space.
runPrinterDefault' :: Width -> Width -> Printer -> IO Number

-- Write to a specific handle instead of stdout.
runPrinterOn :: Handle -> Settings -> Printer -> IO Number
runPrinterDefaultOn :: Handle -> Printer -> IO Number
runPrinterDefaultOn' :: Handle -> Width -> Width -> Printer -> IO Number
```

The `On` variants are the base implementations; the others write to stdout. `renderPrinter` from `Ansiform.Render` captures the output in a `String`.

## Arguments

- `Offset`: indentation from the left, in columns. Some printers also use it as an offset from both sides.
- `Padding`: space between the text and the edge of a solid background.
- `Number`: a non-negative count, such as a number of lines or rows.

## Basic printing

```haskell
printerEmpty :: Number -> Printer
printerItem :: Item -> Printer
```

`printerEmpty n` prints `n` empty lines. `printerItem` prints one `Item` followed by a newline.

## Rules and solid lines

```haskell
printerRule :: Rule -> Printer
printerRule' :: Offset -> Rule -> Printer
printerSolid :: Color -> Printer
printerSolid' :: Offset -> Color -> Printer
```

`printerRule` fills the whole width with the rule character. `printerRule'` leaves the offset free on both sides. `printerSolid` and `printerSolid'` do the same with a background color.

## Single lines

```haskell
printerLeft :: Offset -> Block -> Printer
printerRight :: Offset -> Block -> Printer
printerCenter :: Offset -> Block -> Printer

printerLineLeft :: Offset -> [Block] -> Printer
printerLineRight :: Offset -> [Block] -> Printer
printerLineCenter :: Offset -> [Block] -> Printer
```

The `Line` variants print several blocks on the same line with the minimum space from the settings between them. The first group takes a single block. Centered lines respect the minimum space and overflow rather than overlapping when the blocks do not fit.

```haskell
printerLineCenter 4
  [ blockSimple "Search" (bold cyan)
  , blockSimple "Display" (bold yellow)
  , blockSimple "Exit" (bold red) ]
```

## Solid text lines

```haskell
printerSolidLeft :: Offset -> Padding -> Color -> Block -> Printer
printerSolidRight :: Offset -> Padding -> Color -> Block -> Printer
printerSolidCenter :: Offset -> Padding -> Color -> Block -> Printer

printerSolidLineLeft :: Offset -> Padding -> Color -> [Block] -> Printer
printerSolidLineRight :: Offset -> Padding -> Color -> [Block] -> Printer
printerSolidLineCenter :: Offset -> Padding -> Color -> [Block] -> Printer
```

These printers fill a whole line with the background color and then print the text on top, with the given padding. They are useful for title bars and selected rows.

## Columns and lists

```haskell
printerColumn :: Offset -> [Block] -> Printer
printerList :: Offset -> Number -> [Block] -> Printer
printerList' :: Offset -> Number -> [Block] -> Printer
```

`printerColumn` prints one block per line. `printerList` tries to reach a target number of rows and grows the number of columns as needed. `printerList'` takes a target number of columns instead. If the terminal is too narrow, the printer falls back to a single column.

## Groups

```haskell
printerGroup :: Offset -> Group -> Printer
printerGroups :: Offset -> [Group] -> Printer
printerGroups' :: Offset -> [Group] -> Printer
printerGroupsLimited :: Offset -> Number -> [Group] -> Printer
printerGroupsLimited' :: Offset -> Number -> [Group] -> Printer
```

- `printerGroup` prints one group as a column.
- `printerGroups` spaces the groups evenly.
- `printerGroups'` gives each group the minimum width it needs.
- The `Limited` variants stop after a number of rows; `0` means no limit.

Groups that exceed the configured overflow ratio are split into extra rows by the layout engine.

## Tables

```haskell
printerTable :: Offset -> Padding -> Maybe Table -> Printer
printerTable' :: Offset -> Padding -> Maybe Table -> Printer
printerTableLimited :: Offset -> Padding -> Number -> Maybe Table -> Printer
printerTableLimited' :: Offset -> Padding -> Number -> Maybe Table -> Printer
```

- `printerTable` uses minimum column spacing and a zebra background.
- `printerTable'` spaces the columns evenly.
- The `Limited` variants stop after a number of rows; `0` means no limit.
- A `Nothing` table is treated as an empty group, so invalid input still produces a well-defined (empty) result instead of an exception.

## Paragraphs and articles

```haskell
printerParagraph :: Offset -> Offset -> Paragraph -> Printer
printerArticle :: Offset -> Offset -> Article -> Printer

printerSequence :: Offset -> Offset -> Padding -> [Paragraph] -> Printer
printerSequence' :: Offset -> Offset -> Padding -> [Paragraph] -> Printer
printerSequenceSel :: Offset -> Offset -> Padding -> Number -> [Paragraph] -> Printer
printerSequenceAfter :: Offset -> Offset -> Padding -> Number -> [Paragraph] -> Printer
printerSequencePred :: Offset -> Offset -> Padding -> (Int -> Bool) -> [Paragraph] -> Printer
```

The first offset indents the whole paragraph. The second offset indents only the first line.

- `printerParagraph` wraps the blocks at the terminal width.
- `printerArticle` prints paragraphs separated by a blank line.
- The `printerSequence` variants add a solid background to selected paragraphs: `printerSequence` selects odd indices, `printerSequence'` selects even indices, `printerSequenceSel` selects one index, `printerSequenceAfter` selects indices greater than or equal to a value, and `printerSequencePred` accepts any predicate.
