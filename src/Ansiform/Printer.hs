-- | Printer builders for lines, lists, groups, tables and text.
module Ansiform.Printer
    ( module Ansiform.Printer
    , Internal.Printer
    , Internal.Selection (..)
    , Internal.runPrinter
    , Internal.runPrinterOn
    , Internal.runPrinterDefault
    , Internal.runPrinterDefaultOn
    , Internal.runPrinterDefault'
    , Internal.runPrinterDefaultOn'
    ) where

import Ansiform.Content
--------------------------------------------------------------------------------
import Ansiform.Internal.Number
import Ansiform.Internal.Printer as Internal
import Ansiform.Internal.Table (Align (..), Borders, TableFormat, defaultTableFormat)
import Ansiform.Style

-- Basic Printing
--------------------------------------------------------------------------------

-- | Printer for a number of empty lines.
printerEmpty :: Number -> Printer
printerEmpty = Internal.emptyPrinter

-- | Printer for a single item followed by a newline.
printerItem :: Item -> Printer
printerItem i = formPrinter "Item" (BodyItem i)

-- Rules & Solid Printing
--------------------------------------------------------------------------------

-- | Printer for a horizontal rule that spans the whole width.
printerRule :: Rule -> Printer
printerRule r = formPrinter "Rule" (BodyRule 0 r)

-- | Printer for a horizontal rule with an offset on both sides.
printerRule' :: Offset -> Rule -> Printer
printerRule' o r = formPrinter "Rule'" (BodyRule o r)

-- | Printer for a line filled with the given background color.
printerSolid :: Color -> Printer
printerSolid c = formPrinter "Solid" (BodySolid 0 c)

-- | Printer for a solid line with an offset on both sides.
printerSolid' :: Offset -> Color -> Printer
printerSolid' o c = formPrinter "Solid'" (BodySolid o c)

-- Line Printing
--------------------------------------------------------------------------------

-- | Printer for a block on a single left-aligned line.
printerLeft :: Offset -> Block -> Printer
printerLeft o b = formPrinter "Left" (BodyLine o (LineOne b) AlignLeft)

-- | Printer for a single right-aligned block.
printerRight :: Offset -> Block -> Printer
printerRight o b = formPrinter "Right" (BodyLine o (LineOne b) AlignRight)

-- | Printer for a single centered block.
printerCenter :: Offset -> Block -> Printer
printerCenter o b = formPrinter "Center" (BodyLine o (LineOne b) AlignCenter)

-- | Printer for several blocks on a single left-aligned line.
printerLineLeft :: Offset -> [Block] -> Printer
printerLineLeft o bs = formPrinter "LineLeft" (BodyLine o (LineMany bs) AlignLeft)

-- | Printer for several blocks on a single right-aligned line.
printerLineRight :: Offset -> [Block] -> Printer
printerLineRight o bs = formPrinter "LineRight" (BodyLine o (LineMany bs) AlignRight)

-- | Printer for several blocks on a single centered line.
printerLineCenter :: Offset -> [Block] -> Printer
printerLineCenter o bs = formPrinter "LineCenter" (BodyLine o (LineMany bs) AlignCenter)

-- Solid Text Printing
--------------------------------------------------------------------------------

-- | Printer for one block on a solid left-aligned line.
--   For several blocks, use 'printerSolidLineLeft'.
printerSolidLeft :: Offset -> Padding -> Color -> Block -> Printer
printerSolidLeft o p c b = formPrinter "SolidLeft" (BodySolidLine o p c (LineOne b) AlignLeft)

-- | Printer for one block on a solid right-aligned line.
--   For several blocks, use 'printerSolidLineRight'.
printerSolidRight :: Offset -> Padding -> Color -> Block -> Printer
printerSolidRight o p c b = formPrinter "SolidRight" (BodySolidLine o p c (LineOne b) AlignRight)

-- | Printer for one block on a solid centered line.
--   For several blocks, use 'printerSolidLineCenter'.
printerSolidCenter :: Offset -> Padding -> Color -> Block -> Printer
printerSolidCenter o p c b = formPrinter "SolidCenter" (BodySolidLine o p c (LineOne b) AlignCenter)

-- | Printer for several blocks on a solid left-aligned line.
--   Use 'printerSolidLeft' for a single block.
printerSolidLineLeft :: Offset -> Padding -> Color -> [Block] -> Printer
printerSolidLineLeft o p c bs = formPrinter "SolidLineLeft" (BodySolidLine o p c (LineMany bs) AlignLeft)

-- | Printer for several blocks on a solid right-aligned line.
--   Use 'printerSolidRight' for a single block.
printerSolidLineRight :: Offset -> Padding -> Color -> [Block] -> Printer
printerSolidLineRight o p c bs = formPrinter "SolidLineRight" (BodySolidLine o p c (LineMany bs) AlignRight)

-- | Printer for several blocks on a solid centered line.
--   Use 'printerSolidCenter' for a single block.
printerSolidLineCenter :: Offset -> Padding -> Color -> [Block] -> Printer
printerSolidLineCenter o p c bs = formPrinter "SolidLineCenter" (BodySolidLine o p c (LineMany bs) AlignCenter)

-- List Printing
--------------------------------------------------------------------------------

-- | Printer for a column of blocks with indentation.
printerColumn :: Offset -> [Block] -> Printer
printerColumn o bs = formPrinter "Column" (BodyColumn o bs)

-- | Printer for blocks flowing into columns, aiming for a number of rows.
printerList :: Offset -> Number -> [Block] -> Printer
printerList o l bs = formPrinter "List" (BodyList o l ListRows bs)

-- | Printer for blocks flowing into columns, aiming for a number of columns.
printerList' :: Offset -> Number -> [Block] -> Printer
printerList' o l bs = formPrinter "List'" (BodyList o l ListColumns bs)

-- Group Printing
--------------------------------------------------------------------------------

-- | Printer for a single group as a column.
printerGroup :: Offset -> Group -> Printer
printerGroup o g = formPrinter "Group" (BodyGroup o g)

-- | Printer for groups with evenly spaced columns.
printerGroups :: Offset -> [Group] -> Printer
printerGroups o gs =
    formGroupPrinter "Groups" o 0 0 SpacingEven GroupPlain Nothing defaultTableFormat (GroupSourceAveraged gs)

-- | Printer for groups with minimum spaced columns.
printerGroups' :: Offset -> [Group] -> Printer
printerGroups' o gs =
    formGroupPrinter "Groups'" o 0 0 SpacingMinimum GroupPlain Nothing defaultTableFormat (GroupSourceAveraged gs)

-- | Printer for evenly spaced groups, limiting the number of rows.
printerGroupsLimited :: Offset -> Number -> [Group] -> Printer
printerGroupsLimited o r gs =
    formGroupPrinter "GroupsLimited" o 0 r SpacingEven GroupPlain Nothing defaultTableFormat (GroupSourceAveraged gs)

-- | Printer for minimum spaced groups, limiting the number of rows.
printerGroupsLimited' :: Offset -> Number -> [Group] -> Printer
printerGroupsLimited' o r gs =
    formGroupPrinter "GroupsLimited'" o 0 r SpacingMinimum GroupPlain Nothing defaultTableFormat (GroupSourceAveraged gs)

-- | Printer for a list of Groups inside box borders, with minimum spaced columns.
printerGroupsBordered :: Borders -> Offset -> Padding -> [Group] -> Printer
printerGroupsBordered brd o p gs =
    formGroupPrinter "GroupsBordered" o p 0 SpacingMinimum GroupPlain (Just brd) defaultTableFormat (GroupSourceRaw gs)

-- | Printer for a list of Groups inside box borders, with evenly spaced columns.
printerGroupsBordered' :: Borders -> Offset -> Padding -> [Group] -> Printer
printerGroupsBordered' brd o p gs =
    formGroupPrinter "GroupsBordered'" o p 0 SpacingEven GroupPlain (Just brd) defaultTableFormat (GroupSourceRaw gs)

-- | Printer for Groups inside box borders, limiting the number of rows.
printerGroupsBorderedLimited :: Borders -> Offset -> Padding -> Number -> [Group] -> Printer
printerGroupsBorderedLimited brd o p r gs =
    formGroupPrinter "GroupsBorderedLimited" o p r SpacingMinimum GroupPlain (Just brd) defaultTableFormat (GroupSourceRaw gs)

-- | Printer for evenly spaced Groups inside box borders, limiting the number of rows.
printerGroupsBorderedLimited' :: Borders -> Offset -> Padding -> Number -> [Group] -> Printer
printerGroupsBorderedLimited' brd o p r gs =
    formGroupPrinter "GroupsBorderedLimited'" o p r SpacingEven GroupPlain (Just brd) defaultTableFormat (GroupSourceRaw gs)

-- Table Printing
--------------------------------------------------------------------------------

-- | Prints a table with a zebra background and minimum spaced columns.
printerTable :: Offset -> Padding -> Maybe Table -> Printer
printerTable o p mt =
    formGroupPrinter "Table" o p 0 SpacingMinimum GroupZebra Nothing defaultTableFormat (GroupSourceTable mt)

-- | Prints a table with a zebra background and evenly spaced columns.
printerTable' :: Offset -> Padding -> Maybe Table -> Printer
printerTable' o p mt =
    formGroupPrinter "Table'" o p 0 SpacingEven GroupZebra Nothing defaultTableFormat (GroupSourceTable mt)

-- | Prints a table with a zebra background, limiting the number of rows.
printerTableLimited :: Offset -> Padding -> Number -> Maybe Table -> Printer
printerTableLimited o p r mt =
    formGroupPrinter "TableLimited" o p r SpacingMinimum GroupZebra Nothing defaultTableFormat (GroupSourceTable mt)

-- | Prints an evenly spaced table, limiting the number of rows.
printerTableLimited' :: Offset -> Padding -> Number -> Maybe Table -> Printer
printerTableLimited' o p r mt =
    formGroupPrinter "TableLimited'" o p r SpacingEven GroupZebra Nothing defaultTableFormat (GroupSourceTable mt)

-- | Prints a formatted Table with alternating background, with minimum spaced columns.
printerTableFormat :: TableFormat -> Offset -> Padding -> Maybe Table -> Printer
printerTableFormat fmt o p mt =
    formGroupPrinter "TableFormat" o p 0 SpacingMinimum GroupZebra Nothing fmt (GroupSourceTable mt)

-- | Prints a formatted Table with alternating background, with evenly spaced columns.
printerTableFormat' :: TableFormat -> Offset -> Padding -> Maybe Table -> Printer
printerTableFormat' fmt o p mt =
    formGroupPrinter "TableFormat'" o p 0 SpacingEven GroupZebra Nothing fmt (GroupSourceTable mt)

-- | Prints a formatted Table limiting the number of rows, with minimum spaced columns.
printerTableLimitedFormat :: TableFormat -> Offset -> Padding -> Number -> Maybe Table -> Printer
printerTableLimitedFormat fmt o p r mt =
    formGroupPrinter "TableLimitedFormat" o p r SpacingMinimum GroupZebra Nothing fmt (GroupSourceTable mt)

-- | Prints a formatted Table limiting the number of rows, with evenly spaced columns.
printerTableLimitedFormat' :: TableFormat -> Offset -> Padding -> Number -> Maybe Table -> Printer
printerTableLimitedFormat' fmt o p r mt =
    formGroupPrinter "TableLimitedFormat'" o p r SpacingEven GroupZebra Nothing fmt (GroupSourceTable mt)

-- | Prints a bordered Table with minimum spaced columns.
printerTableBordered :: Borders -> TableFormat -> Offset -> Padding -> Maybe Table -> Printer
printerTableBordered brd fmt o p mt =
    formGroupPrinter "TableBordered" o p 0 SpacingMinimum GroupPlain (Just brd) fmt (GroupSourceTable mt)

-- | Prints a bordered Table with evenly spaced columns.
printerTableBordered' :: Borders -> TableFormat -> Offset -> Padding -> Maybe Table -> Printer
printerTableBordered' brd fmt o p mt =
    formGroupPrinter "TableBordered'" o p 0 SpacingEven GroupPlain (Just brd) fmt (GroupSourceTable mt)

-- | Prints a bordered Table limiting the number of rows, with minimum spaced columns.
printerTableBorderedLimited :: Borders -> TableFormat -> Offset -> Padding -> Number -> Maybe Table -> Printer
printerTableBorderedLimited brd fmt o p r mt =
    formGroupPrinter "TableBorderedLimited" o p r SpacingMinimum GroupPlain (Just brd) fmt (GroupSourceTable mt)

-- | Prints a bordered Table limiting the number of rows, with evenly spaced columns.
printerTableBorderedLimited' :: Borders -> TableFormat -> Offset -> Padding -> Number -> Maybe Table -> Printer
printerTableBorderedLimited' brd fmt o p r mt =
    formGroupPrinter "TableBorderedLimited'" o p r SpacingEven GroupPlain (Just brd) fmt (GroupSourceTable mt)

-- Text Printing
--------------------------------------------------------------------------------

-- | Prints a continuous paragraph made from a list of blocks.
printerParagraph :: Offset -> Offset -> Paragraph -> Printer
printerParagraph o o1 vbs = formPrinter "Paragraph" (BodyParagraph o o1 vbs)

-- | Prints paragraphs separated by a single line.
printerArticle :: Offset -> Offset -> Article -> Printer
printerArticle o o1 vbss = formPrinter "Article" (BodySequence o o1 0 False SelectOdd vbss)

-- | Prints paragraphs with alternating backgrounds on odd entries.
printerSequence :: Offset -> Offset -> Padding -> [Paragraph] -> Printer
printerSequence o o1 p vbss = formPrinter "Sequence" (BodySequence o o1 p True SelectOdd vbss)

-- | Version of 'printerSequence' that highlights even entries.
printerSequence' :: Offset -> Offset -> Padding -> [Paragraph] -> Printer
printerSequence' o o1 p vbss = formPrinter "Sequence'" (BodySequence o o1 p True SelectEven vbss)

-- | Prints paragraphs highlighting one selected index.
printerSequenceSel :: Offset -> Offset -> Padding -> Number -> [Paragraph] -> Printer
printerSequenceSel o o1 p i vbss = formPrinter "SequenceSel" (BodySequence o o1 p True (SelectAt i) vbss)

-- | Prints paragraphs highlighting entries at or after an index.
printerSequenceAfter :: Offset -> Offset -> Padding -> Number -> [Paragraph] -> Printer
printerSequenceAfter o o1 p i vbss = formPrinter "SequenceAfter" (BodySequence o o1 p True (SelectFrom i) vbss)

-- | Prints paragraphs selected by a 'Selection'.
printerSequenceSelect :: Offset -> Offset -> Padding -> Selection -> [Paragraph] -> Printer
printerSequenceSelect o o1 p selection vbss = formPrinter "SequenceSelect" (BodySequence o o1 p True selection vbss)

-- | The diagnostic name of a printer.
printerName :: Printer -> String
printerName = Internal.printerName
