-- | Printer builders for lines, lists, groups, tables and text.
module Ansiform.Printer
    ( module Ansiform.Printer
    , Internal.Printer
    , Internal.runPrinter
    , Internal.runPrinterOn
    , Internal.runPrinterDefault
    , Internal.runPrinterDefaultOn
    , Internal.runPrinterDefault'
    , Internal.runPrinterDefaultOn'
    ) where

import Ansiform.Content
--------------------------------------------------------------------------------
import Ansiform.Internal.Content
import Ansiform.Internal.Number
import Ansiform.Internal.Output (outputConfig)
import Ansiform.Internal.Printer as Internal
import Ansiform.Internal.Table (Borders, TableFormat, defaultTableFormat)
import Ansiform.Style

-- Basic Printing
--------------------------------------------------------------------------------

-- | Printer for a number of empty lines.
printerEmpty :: Number -> Printer
printerEmpty = Internal.emptyPrinter

-- | Printer for a single item followed by a newline.
printerItem :: Item -> Printer
printerItem i = formPrinter "Item" $ \s -> printSingleItem s i

-- Rules & Solid Printing
--------------------------------------------------------------------------------

-- | Printer for a horizontal rule that spans the whole width.
printerRule :: Rule -> Printer
printerRule r = formPrinter "Rule" $ \s -> printRule 0 r s

-- | Printer for a horizontal rule with an offset on both sides.
printerRule' :: Offset -> Rule -> Printer
printerRule' o r = formPrinter "Rule'" $ \s -> printRule o r s

-- | Printer for a line filled with the given background color.
printerSolid :: Color -> Printer
printerSolid c = formPrinter "Solid" $ \s -> printRule 0 (ruleSolid c) s

-- | Printer for a solid line with an offset on both sides.
printerSolid' :: Offset -> Color -> Printer
printerSolid' o c = formPrinter "Solid'" $ \s -> printRule o (ruleSolid c) s

-- Line Printing
--------------------------------------------------------------------------------

-- | Printer for a block on a single left-aligned line.
printerLeft :: Offset -> Block -> Printer
printerLeft o b = formPrinter "Left" $ \s -> printLeft s o b

-- | Printer for a single right-aligned block.
printerRight :: Offset -> Block -> Printer
printerRight o b = formPrinter "Right" $ \s -> printLineRight o [b] s

-- | Printer for a single centered block.
printerCenter :: Offset -> Block -> Printer
printerCenter o b = formPrinter "Center" $ \s -> printLineCenter o [b] s

-- | Printer for several blocks on a single left-aligned line.
printerLineLeft :: Offset -> [Block] -> Printer
printerLineLeft o bs = formPrinter "LineLeft" $ \s -> printLineLeft o bs s

-- | Printer for several blocks on a single right-aligned line.
printerLineRight :: Offset -> [Block] -> Printer
printerLineRight o bs = formPrinter "LineRight" $ \s -> printLineRight o bs s

-- | Printer for several blocks on a single centered line.
printerLineCenter :: Offset -> [Block] -> Printer
printerLineCenter o bs = formPrinter "LineCenter" $ \s -> printLineCenter o bs s

-- Solid Text Printing
--------------------------------------------------------------------------------

-- | Printer for one block on a solid left-aligned line.
--   For several blocks, use 'printerSolidLineLeft'.
printerSolidLeft :: Offset -> Padding -> Color -> Block -> Printer
printerSolidLeft o p c b = formPrinter "SolidLeft" $ \s -> printSolidLine o p c [b] printLineLeft s

-- | Printer for one block on a solid right-aligned line.
--   For several blocks, use 'printerSolidLineRight'.
printerSolidRight :: Offset -> Padding -> Color -> Block -> Printer
printerSolidRight o p c b = formPrinter "SolidRight" $ \s -> printSolidLine o p c [b] printLineRight s

-- | Printer for one block on a solid centered line.
--   For several blocks, use 'printerSolidLineCenter'.
printerSolidCenter :: Offset -> Padding -> Color -> Block -> Printer
printerSolidCenter o p c b = formPrinter "SolidCenter" $ \s -> printSolidLine o p c [b] printLineCenter s

-- | Printer for several blocks on a solid left-aligned line.
--   Use 'printerSolidLeft' for a single block.
printerSolidLineLeft :: Offset -> Padding -> Color -> [Block] -> Printer
printerSolidLineLeft o p c bs = formPrinter "SolidLineLeft" $ \s -> printSolidLine o p c bs printLineLeft s

-- | Printer for several blocks on a solid right-aligned line.
--   Use 'printerSolidRight' for a single block.
printerSolidLineRight :: Offset -> Padding -> Color -> [Block] -> Printer
printerSolidLineRight o p c bs = formPrinter "SolidLineRight" $ \s -> printSolidLine o p c bs printLineRight s

-- | Printer for several blocks on a solid centered line.
--   Use 'printerSolidCenter' for a single block.
printerSolidLineCenter :: Offset -> Padding -> Color -> [Block] -> Printer
printerSolidLineCenter o p c bs = formPrinter "SolidLineCenter" $ \s -> printSolidLine o p c bs printLineCenter s

-- List Printing
--------------------------------------------------------------------------------

-- | Printer for a column of blocks with indentation.
printerColumn :: Offset -> [Block] -> Printer
printerColumn o bs = formPrinter "Column" $ \s -> printColumn s o bs

-- | Printer for blocks flowing into columns, aiming for a number of rows.
printerList :: Offset -> Number -> [Block] -> Printer
printerList o l bs = formPrinter "List" $ \s -> printList o l bs s

-- | Printer for blocks flowing into columns, aiming for a number of columns.
printerList' :: Offset -> Number -> [Block] -> Printer
printerList' o l bs = formPrinter "List'" $ \s -> printList' o l bs s

-- Group Printing
--------------------------------------------------------------------------------

-- | Printer for a single group as a column.
printerGroup :: Offset -> Group -> Printer
printerGroup o g = formPrinter "Group" $ \s -> printGroup s o g

-- | Printer for groups with evenly spaced columns.
printerGroups :: Offset -> [Group] -> Printer
printerGroups o gs = formPrinter "Groups" $ \s ->
    printGroups defaultTableFormat o 0 0 SpacingEven GroupPlain (groupAverage (outputConfig s) gs) s

-- | Printer for groups with minimum spaced columns.
printerGroups' :: Offset -> [Group] -> Printer
printerGroups' o gs = formPrinter "Groups'" $ \s ->
    printGroups defaultTableFormat o 0 0 SpacingMinimum GroupPlain (groupAverage (outputConfig s) gs) s

-- | Printer for evenly spaced groups, limiting the number of rows.
printerGroupsLimited :: Offset -> Number -> [Group] -> Printer
printerGroupsLimited o r gs = formPrinter "GroupsLimited" $ \s ->
    printGroups defaultTableFormat o 0 r SpacingEven GroupPlain (groupAverage (outputConfig s) gs) s

-- | Printer for minimum spaced groups, limiting the number of rows.
printerGroupsLimited' :: Offset -> Number -> [Group] -> Printer
printerGroupsLimited' o r gs = formPrinter "GroupsLimited'" $ \s ->
    printGroups defaultTableFormat o 0 r SpacingMinimum GroupPlain (groupAverage (outputConfig s) gs) s

-- | Printer for a list of Groups inside box borders, with minimum spaced columns.
printerGroupsBordered :: Borders -> Offset -> Padding -> [Group] -> Printer
printerGroupsBordered brd o p gs = formPrinter "GroupsBordered" $ \s ->
    printBorderedGroups brd defaultTableFormat o p 0 SpacingMinimum gs s

-- | Printer for a list of Groups inside box borders, with evenly spaced columns.
printerGroupsBordered' :: Borders -> Offset -> Padding -> [Group] -> Printer
printerGroupsBordered' brd o p gs = formPrinter "GroupsBordered'" $ \s ->
    printBorderedGroups brd defaultTableFormat o p 0 SpacingEven gs s

-- | Printer for Groups inside box borders, limiting the number of rows.
printerGroupsBorderedLimited :: Borders -> Offset -> Padding -> Number -> [Group] -> Printer
printerGroupsBorderedLimited brd o p r gs = formPrinter "GroupsBorderedLimited" $ \s ->
    printBorderedGroups brd defaultTableFormat o p r SpacingMinimum gs s

-- | Printer for evenly spaced Groups inside box borders, limiting the number of rows.
printerGroupsBorderedLimited' :: Borders -> Offset -> Padding -> Number -> [Group] -> Printer
printerGroupsBorderedLimited' brd o p r gs = formPrinter "GroupsBorderedLimited'" $ \s ->
    printBorderedGroups brd defaultTableFormat o p r SpacingEven gs s

-- Table Printing
--------------------------------------------------------------------------------

-- | Prints a table with a zebra background and minimum spaced columns.
printerTable :: Offset -> Padding -> Maybe Table -> Printer
printerTable o p mt = formPrinter "Table" $ \s ->
    printGroups defaultTableFormat o p 0 SpacingMinimum GroupZebra (unMaybeTable mt) s

-- | Prints a table with a zebra background and evenly spaced columns.
printerTable' :: Offset -> Padding -> Maybe Table -> Printer
printerTable' o p mt = formPrinter "Table'" $ \s ->
    printGroups defaultTableFormat o p 0 SpacingEven GroupZebra (unMaybeTable mt) s

-- | Prints a table with a zebra background, limiting the number of rows.
printerTableLimited :: Offset -> Padding -> Number -> Maybe Table -> Printer
printerTableLimited o p r mt = formPrinter "TableLimited" $ \s ->
    printGroups defaultTableFormat o p r SpacingMinimum GroupZebra (unMaybeTable mt) s

-- | Prints an evenly spaced table, limiting the number of rows.
printerTableLimited' :: Offset -> Padding -> Number -> Maybe Table -> Printer
printerTableLimited' o p r mt = formPrinter "TableLimited'" $ \s ->
    printGroups defaultTableFormat o p r SpacingEven GroupZebra (unMaybeTable mt) s

-- | Prints a formatted Table with alternating background, with minimum spaced columns.
printerTableFormat :: TableFormat -> Offset -> Padding -> Maybe Table -> Printer
printerTableFormat fmt o p mt = formPrinter "TableFormat" $ \s ->
    printGroups fmt o p 0 SpacingMinimum GroupZebra (unMaybeTable mt) s

-- | Prints a formatted Table with alternating background, with evenly spaced columns.
printerTableFormat' :: TableFormat -> Offset -> Padding -> Maybe Table -> Printer
printerTableFormat' fmt o p mt = formPrinter "TableFormat'" $ \s ->
    printGroups fmt o p 0 SpacingEven GroupZebra (unMaybeTable mt) s

-- | Prints a formatted Table limiting the number of rows, with minimum spaced columns.
printerTableLimitedFormat :: TableFormat -> Offset -> Padding -> Number -> Maybe Table -> Printer
printerTableLimitedFormat fmt o p r mt = formPrinter "TableLimitedFormat" $ \s ->
    printGroups fmt o p r SpacingMinimum GroupZebra (unMaybeTable mt) s

-- | Prints a formatted Table limiting the number of rows, with evenly spaced columns.
printerTableLimitedFormat' :: TableFormat -> Offset -> Padding -> Number -> Maybe Table -> Printer
printerTableLimitedFormat' fmt o p r mt = formPrinter "TableLimitedFormat'" $ \s ->
    printGroups fmt o p r SpacingEven GroupZebra (unMaybeTable mt) s

-- | Prints a bordered Table with minimum spaced columns.
printerTableBordered :: Borders -> TableFormat -> Offset -> Padding -> Maybe Table -> Printer
printerTableBordered brd fmt o p mt = formPrinter "TableBordered" $ \s ->
    printBorderedGroups brd fmt o p 0 SpacingMinimum (unMaybeTable mt) s

-- | Prints a bordered Table with evenly spaced columns.
printerTableBordered' :: Borders -> TableFormat -> Offset -> Padding -> Maybe Table -> Printer
printerTableBordered' brd fmt o p mt = formPrinter "TableBordered'" $ \s ->
    printBorderedGroups brd fmt o p 0 SpacingEven (unMaybeTable mt) s

-- | Prints a bordered Table limiting the number of rows, with minimum spaced columns.
printerTableBorderedLimited :: Borders -> TableFormat -> Offset -> Padding -> Number -> Maybe Table -> Printer
printerTableBorderedLimited brd fmt o p r mt = formPrinter "TableBorderedLimited" $ \s ->
    printBorderedGroups brd fmt o p r SpacingMinimum (unMaybeTable mt) s

-- | Prints a bordered Table limiting the number of rows, with evenly spaced columns.
printerTableBorderedLimited' :: Borders -> TableFormat -> Offset -> Padding -> Number -> Maybe Table -> Printer
printerTableBorderedLimited' brd fmt o p r mt = formPrinter "TableBorderedLimited'" $ \s ->
    printBorderedGroups brd fmt o p r SpacingEven (unMaybeTable mt) s

-- Text Printing
--------------------------------------------------------------------------------

-- | Prints a continuous paragraph made from a list of blocks.
printerParagraph :: Offset -> Offset -> Paragraph -> Printer
printerParagraph o o1 vbs = formPrinter "Paragraph" $ \s ->
    printParagraph o o1 0 False vbs s

-- | Prints paragraphs separated by a single line.
printerArticle :: Offset -> Offset -> Article -> Printer
printerArticle o o1 vbss = formPrinter "Article" $ \s ->
    printSequence o o1 0 False odd vbss s

-- | Prints paragraphs with alternating backgrounds on odd entries.
printerSequence :: Offset -> Offset -> Padding -> [Paragraph] -> Printer
printerSequence o o1 p vbss = formPrinter "Sequence" $ \s ->
    printSequence o o1 p True odd vbss s

-- | Version of 'printerSequence' that highlights even entries.
printerSequence' :: Offset -> Offset -> Padding -> [Paragraph] -> Printer
printerSequence' o o1 p vbss = formPrinter "Sequence'" $ \s ->
    printSequence o o1 p True even vbss s

-- | Prints paragraphs highlighting one selected index.
printerSequenceSel :: Offset -> Offset -> Padding -> Number -> [Paragraph] -> Printer
printerSequenceSel o o1 p i vbss = formPrinter "SequenceSel" $ \s ->
    printSequence o o1 p True (== unn i) vbss s

-- | Prints paragraphs highlighting entries at or after an index.
printerSequenceAfter :: Offset -> Offset -> Padding -> Number -> [Paragraph] -> Printer
printerSequenceAfter o o1 p i vbss = formPrinter "SequenceAfter" $ \s ->
    printSequence o o1 p True (>= unn i) vbss s

-- | Prints paragraphs highlighting entries selected by a predicate.
printerSequencePred :: Offset -> Offset -> Padding -> (Int -> Bool) -> [Paragraph] -> Printer
printerSequencePred o o1 p f vbss = formPrinter "SequencePred" $ \s ->
    printSequence o o1 p True f vbss s

-- | The diagnostic name of a printer.
printerName :: Printer -> String
printerName = Internal.printerName
