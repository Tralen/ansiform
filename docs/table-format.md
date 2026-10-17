# Table formatting

Tables are left-aligned by default. `Ansiform.Table` adds per-column alignment, maximum widths and truncation.

## Types

```haskell
data Align = AlignLeft | AlignCenter | AlignRight
data Ellipsis = EllipsisNone | EllipsisChar Char

data ColumnSpec = ColumnSpec
  { columnAlign :: Align
  , columnMaxWidth :: Maybe Width
  , columnEllipsis :: Ellipsis
  }

defaultColumnSpec :: ColumnSpec
```

`defaultColumnSpec` is left-aligned, has no maximum width and adds no ellipsis. This preserves the previous table behavior.

## Format

```haskell
tableFormat :: [ColumnSpec] -> TableFormat
defaultTableFormat :: TableFormat
```

The list is matched to the table columns in order. Columns beyond the end of the list use `defaultColumnSpec`; extra specifications are ignored.

## Printers

```haskell
printerTableFormat :: TableFormat -> Offset -> Padding -> Maybe Table -> Printer
printerTableFormat' :: TableFormat -> Offset -> Padding -> Maybe Table -> Printer

printerTableLimitedFormat :: TableFormat -> Offset -> Padding -> Number -> Maybe Table -> Printer
printerTableLimitedFormat' :: TableFormat -> Offset -> Padding -> Number -> Maybe Table -> Printer
```

The primed variants space columns evenly. The `Limited` variants stop after a number of rows, where `0` means no limit. The original `printerTable` family is equivalent to `defaultTableFormat`.

## Example

```haskell
import Ansiform

format :: TableFormat
format = tableFormat
  [ defaultColumnSpec { columnMaxWidth = Just 12
                      , columnEllipsis = EllipsisChar '…' }
  , defaultColumnSpec
  , defaultColumnSpec { columnAlign = AlignRight }
  , defaultColumnSpec { columnAlign = AlignRight } ]

screen :: Section
screen = sectionBodyRule 1 (rule ':' (bold black'))
  [ printerTableFormat format 2 1 people ]
```

In this example the first column is capped at 12 columns, the second is left-aligned, and the last two, usually numbers, are right-aligned.

## Truncation

A cell longer than `columnMaxWidth` is cut at the display width. If the ellipsis is a character and it fits, it is appended to the truncated cell. Truncation preserves the style of the last kept item.

## Display width

Alignment, maximum widths and truncation use `textWidth`, the same function used by wrapping and lists. Wide CJK characters and emoji occupy two columns, and combining marks occupy zero, so numeric and mixed-language tables stay aligned.
