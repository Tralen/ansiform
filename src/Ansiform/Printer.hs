module Ansiform.Printer ( module Ansiform.Printer 
                   , Internal.Printer, Internal.runPrinter
                   , Internal.runPrinterDefault
                   , Internal.runPrinterDefault'
                   ) where

--------------------------------------------------------------------------------
import           Ansiform.Internal.Content
import           Ansiform.Internal.Number
import           Ansiform.Internal.Printer as Internal
import           Ansiform.Content
import           Ansiform.Style


-- Basic Printing
--------------------------------------------------------------------------------

-- Printer for a number of empty lines.
printerEmpty :: Number -> Printer
printerEmpty n = formPrinter "Empty" $ \_ -> printEmpty n

printerItem :: Item -> Printer
printerItem i = formPrinter "Item" $ \_ -> printSingleItem i


-- Rules & Solid Printing
--------------------------------------------------------------------------------

-- Printer for a horizontal rule that spans the whole screen.
printerRule :: Rule -> Printer
printerRule r = formPrinter "Rule" $ \s -> printRule 0 r s

-- Printer for a horizontal rule with an offset on both sides.
printerRule' :: Offset -> Rule -> Printer
printerRule' o r = formPrinter "Rule'" $ \s -> printRule o r s

-- Printer for a line filled with spaces with the background color given.
printerSolid :: Color -> Printer
printerSolid c = formPrinter "Solid" $ \s -> printRule 0 (ruleSolid c) s

-- Printer for a line filled with spaces with an offset from both sides.
printerSolid' :: Offset -> Color -> Printer
printerSolid' o c = formPrinter "Solid'" $ \s -> printRule o (ruleSolid c) s


-- Line Printing
--------------------------------------------------------------------------------

-- Printer for a Block in single line, left aligned.
printerLeft :: Offset -> Block -> Printer
printerLeft o b = formPrinter "Left" $ \_ -> printLeft o b

-- Printer for single Block, right aligned.
printerRight :: Offset -> Block -> Printer
printerRight o b = formPrinter "Right" $ \s -> printLineRight o [b] s

-- Printer for single Block, center aligned.
printerCenter :: Offset -> Block -> Printer
printerCenter o b = formPrinter "Center" $ \s -> printLineCenter o [b] s

-- Printer for list of Blocks in a single line, center aligned.
printerLineLeft :: Offset -> [Block] -> Printer
printerLineLeft o bs = formPrinter "LineLeft" $ \s -> printLineLeft o bs s

-- Printer for list of Blocks in a single line, center aligned.
printerLineRight :: Offset -> [Block] -> Printer
printerLineRight o bs = formPrinter "LineRight" $ \s -> printLineRight o bs s

-- Printer for list of Blocks in a single line, center aligned.
printerLineCenter :: Offset -> [Block] -> Printer
printerLineCenter o bs = formPrinter "LineCenter" $ \s -> printLineCenter o bs s


-- Solid Text Printing
--------------------------------------------------------------------------------

printerSolidLeft :: Offset -> Padding -> Color -> Block -> Printer
printerSolidLeft o p c b = formPrinter "SolidLeft" $ \s -> printSolidLine o p c [b] printLineLeft s

printerSolidRight :: Offset -> Padding -> Color -> Block -> Printer
printerSolidRight o p c b = formPrinter "SolidRight" $ \s -> printSolidLine o p c [b] printLineRight s

printerSolidCenter :: Offset -> Padding -> Color -> Block -> Printer
printerSolidCenter o p c b = formPrinter "SolidCenter" $ \s -> printSolidLine o p c [b] printLineCenter s

printerSolidLineLeft :: Offset -> Padding -> Color -> [Block] -> Printer
printerSolidLineLeft o p c bs = formPrinter "SolidLineLeft" $ \s -> printSolidLine o p c bs printLineLeft s

printerSolidLineRight :: Offset -> Padding -> Color -> [Block] -> Printer
printerSolidLineRight o p c bs = formPrinter "SolidLineRight" $ \s -> printSolidLine o p c bs printLineRight s

printerSolidLineCenter :: Offset -> Padding -> Color -> [Block] -> Printer
printerSolidLineCenter o p c bs = formPrinter "SolidLineCenter" $ \s -> printSolidLine o p c bs printLineCenter s


-- List Printing
--------------------------------------------------------------------------------

-- Printer for a column of Blocks, with indentation.
printerColumn :: Offset -> [Block] -> Printer
printerColumn o bs = formPrinter "Column" $ \_ -> printColumn o bs

-- Printer for a list of Blocks, aiming for a specified number of rows.
printerList :: Offset -> Number -> [Block] -> Printer
printerList o l bs = formPrinter "List" $ \s -> printList o l bs s

-- Printer for a list of Blocks, aiming for a specified number of columns.
printerList' :: Offset -> Number -> [Block] -> Printer
printerList' o l bs = formPrinter "List'" $ \s -> printList' o l bs s


-- Group Printing
--------------------------------------------------------------------------------

-- Printer for a single Group, printed as a column with the given offset.
printerGroup :: Offset -> Group -> Printer
printerGroup o g = formPrinter "Group" $ \_ -> printGroup o g

-- Printer for a list of Groups with evenly spaced columns.
printerGroups :: Offset -> [Group] -> Printer
printerGroups o gs = formPrinter "Groups" $ \s -> 
              printGroups o 0 0 True False (groupAverage s gs) s

-- Printer for a list of Groups with minimum spaced columns.
printerGroups' :: Offset -> [Group] -> Printer
printerGroups' o gs = formPrinter "Groups'" $ \s -> 
              printGroups o 0 0 False False (groupAverage s gs) s

-- Printer for a list of Groups with evenly spaced columns, limiting number of rows.
printerGroupsLimited :: Offset -> Number -> [Group] -> Printer
printerGroupsLimited o r gs = formPrinter "GroupsLimited" $ \s -> 
              printGroups o 0 r True False (groupAverage s gs) s

-- Printer for a list of Groups with minimum spaced columns, limiting number of rows.
printerGroupsLimited' :: Offset -> Number -> [Group] -> Printer
printerGroupsLimited' o r gs = formPrinter "GroupsLimited'" $ \s -> 
              printGroups o 0 r False False (groupAverage s gs) s


-- Table Printing
--------------------------------------------------------------------------------

-- Prints a Table with alternating background, with minimum spaced columns.
printerTable :: Offset -> Padding -> Maybe Table -> Printer
printerTable o p mt = formPrinter "Table" $ \s -> 
                 printGroups o p 0 False True (unMaybeTable mt) s

-- Prints a Table with alternating background, with evenly spaced columns.
printerTable' :: Offset -> Padding -> Maybe Table -> Printer
printerTable' o p mt = formPrinter "Table'" $ \s -> 
                 printGroups o p 0 True True (unMaybeTable mt) s

-- Prints a Table limiting the number of rows, with minimum spaced columns.
printerTableLimited :: Offset -> Padding -> Number -> Maybe Table -> Printer
printerTableLimited o p r mt = formPrinter "TableLimited" $ \s -> 
                 printGroups o p r False True (unMaybeTable mt) s

-- Prints a Table limiting the number of rows, with evenly spaced columns.
printerTableLimited' :: Offset -> Padding -> Number -> Maybe Table -> Printer
printerTableLimited' o p r mt = formPrinter "TableLimited'" $ \s -> 
                 printGroups o p r True True (unMaybeTable mt) s


-- Text Printing
--------------------------------------------------------------------------------

-- Printer for a continuous paragraph, made from a list of Blocks.
printerParagraph :: Offset -> Offset -> Paragraph -> Printer
printerParagraph o o1 vbs = formPrinter "Paragraph" $ \s -> 
                                printParagraph o o1 0 False vbs s

-- Printer for a list of paragraphs, separated by a single line, in the simplest manner.
printerArticle :: Offset -> Offset -> Article -> Printer
printerArticle o o1 vbss = formPrinter "Article" $ \s -> 
                                printSequence o o1 0 False odd vbss s


-- Printer for a sequence of paragraphs, separated by a single line,
--    alternating the background to solid on odd entries.
printerSequence :: Offset -> Offset -> Padding -> [Paragraph] -> Printer
printerSequence o o1 p vbss = formPrinter "Sequence" $ \s -> 
                                      printSequence o o1 p True odd vbss s

-- Version of the Sequence Printer that changes the background of even items.
printerSequence' :: Offset -> Offset -> Padding -> [Paragraph] -> Printer
printerSequence' o o1 p vbss = formPrinter "Sequence'" $ \s -> 
                                      printSequence o o1 p True even vbss s

-- Version of the Sequence Printer that changes the background of a selected item.
--    The selection is given by the Number, 0 indexed.
printerSequenceSel :: Offset -> Offset -> Padding -> Number -> [Paragraph] -> Printer
printerSequenceSel o o1 p i vbss = formPrinter "SequenceSel" $ \s -> 
                                      printSequence o o1 p True (==unn i) vbss s

-- Version of the Sequence Printer that changes the background of items after a certain number.
printerSequenceAfter :: Offset -> Offset -> Padding -> Number -> [Paragraph] -> Printer
printerSequenceAfter o o1 p i vbss = formPrinter "SequenceAfter" $ \s -> 
                                      printSequence o o1 p True (>=unn i) vbss s

-- Version of the Sequence Printer that changes the background based on a predicate.
printerSequencePred :: Offset -> Offset -> Padding -> (Int -> Bool) -> [Paragraph] -> Printer
printerSequencePred o o1 p f vbss = formPrinter "SequencePred" $ \s -> 
                                      printSequence o o1 p True f vbss s


