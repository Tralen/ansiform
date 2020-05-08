module Vis.Printer where

--------------------------------------------------------------------------------
import           Vis.Builder
import           Vis.Content
import           Vis.Number
import           Vis.Print
import           Vis.Settings
import           Vis.Style
import           Vis.Terminal
import           Vis.Utils


-- Printer Type
--------------------------------------------------------------------------------
-- A printer is a function, from Settings to IO, that prints on the screen.
--    It is expected that a Printer will print at least one line.
newtype VisPrinter = VisPrinter (VisSettings -> IO VisNumber)

visPrinter :: (VisSettings -> IO VisNumber) -> VisPrinter
visPrinter sio = VisPrinter sio

runPrinter :: VisSettings -> VisPrinter -> IO VisNumber
runPrinter s (VisPrinter sio) = sio s

runPrinter' :: VisWidth -> VisMinSpace -> VisPrinter -> IO VisNumber
runPrinter' w m (VisPrinter sio) = sio $ visSettings w m

runPrinter'' :: VisMinSpace -> VisPrinter -> IO VisNumber
runPrinter'' m (VisPrinter sio) = termW >>= \w -> sio $ visSettings (visNumber w) m

-- Basic Printing
--------------------------------------------------------------------------------

-- Printer for a number of empty lines.
printerEmpty :: VisNumber -> VisPrinter
printerEmpty n = visPrinter $ \_ -> printEmpty n

-- Printer for a VisBlock in single line, left aligned.
printerLeft :: VisOffset -> VisBlock -> VisPrinter
printerLeft o b = visPrinter $ \_ -> printLeft o b


-- Rules & Solid Printing
--------------------------------------------------------------------------------

-- Printer for a horizontal rule that spans the whole screen.
printerRule :: VisRule -> VisPrinter
printerRule r = visPrinter $ \s -> printRule 0 r s

-- Printer for a horizontal rule with an offset on both sides.
printerRule' :: VisOffset -> VisRule -> VisPrinter
printerRule' o r = visPrinter $ \s -> printRule o r s

-- Printer for a line filled with spaces with the background color given.
printerSolid :: VisColor -> VisPrinter
printerSolid c = visPrinter $ \s -> printRule 0 (ruleSolid c) s

-- Printer for a line filled with spaces with an offset from both sides.
printerSolid' :: VisOffset -> VisColor -> VisPrinter
printerSolid' o c = visPrinter $ \s -> printRule o (ruleSolid c) s


-- Line Printing
--------------------------------------------------------------------------------

-- Printer for single VisBlock, right aligned.
printerRight :: VisOffset -> VisBlock -> VisPrinter
printerRight o b = visPrinter $ \s -> printLineRight o [b] s

-- Printer for single VisBlock, center aligned.
printerCenter :: VisOffset -> VisBlock -> VisPrinter
printerCenter o b = visPrinter $ \s -> printLineCenter o [b] s

-- Printer for list of VisBlocks in a single line, center aligned.
printerLineLeft :: VisOffset -> [VisBlock] -> VisPrinter
printerLineLeft o bs = visPrinter $ \s -> printLineLeft o bs s

-- Printer for list of VisBlocks in a single line, center aligned.
printerLineRight :: VisOffset -> [VisBlock] -> VisPrinter
printerLineRight o bs = visPrinter $ \s -> printLineRight o bs s

-- Printer for list of VisBlocks in a single line, center aligned.
printerLineCenter :: VisOffset -> [VisBlock] -> VisPrinter
printerLineCenter o bs = visPrinter $ \s -> printLineCenter o bs s


-- Solid Text Printing
--------------------------------------------------------------------------------

printerSolidLeft :: VisOffset -> VisPadding -> VisColor -> VisBlock -> VisPrinter
printerSolidLeft o p c b = visPrinter $ \s -> printSolidLine o p c [b] printLineLeft s

printerSolidRight :: VisOffset -> VisPadding -> VisColor -> VisBlock -> VisPrinter
printerSolidRight o p c b = visPrinter $ \s -> printSolidLine o p c [b] printLineRight s

printerSolidCenter :: VisOffset -> VisPadding -> VisColor -> VisBlock -> VisPrinter
printerSolidCenter o p c b = visPrinter $ \s -> printSolidLine o p c [b] printLineCenter s

printerSolidLineLeft :: VisOffset -> VisPadding -> VisColor -> [VisBlock] -> VisPrinter
printerSolidLineLeft o p c bs = visPrinter $ \s -> printSolidLine o p c bs printLineLeft s

printerSolidLineRight :: VisOffset -> VisPadding -> VisColor -> [VisBlock] -> VisPrinter
printerSolidLineRight o p c bs = visPrinter $ \s -> printSolidLine o p c bs printLineRight s

printerSolidLineCenter :: VisOffset -> VisPadding -> VisColor -> [VisBlock] -> VisPrinter
printerSolidLineCenter o p c bs = visPrinter $ \s -> printSolidLine o p c bs printLineCenter s


-- List Printing
--------------------------------------------------------------------------------

-- Printer for a column of VisBlocks, with indentation.
printerColumn :: VisOffset -> [VisBlock] -> VisPrinter
printerColumn o bs = visPrinter $ \_ -> printColumn o bs

-- Printer for a list of VisBlocks, aiming for a specified number of rows.
printerList :: VisOffset -> VisNumber -> [VisBlock] -> VisPrinter
printerList o l bs = visPrinter $ \s -> printList o l bs s

-- Printer for a list of VisBlocks, aiming for a specified number of columns.
printerList' :: VisOffset -> VisNumber -> [VisBlock] -> VisPrinter
printerList' o l bs = visPrinter $ \s -> printList' o l bs s


-- Group Printing
--------------------------------------------------------------------------------

-- Printer for a single VisGroup, printed as a column with the given offset.
printerGroup :: VisOffset -> VisGroup -> VisPrinter
printerGroup o g = visPrinter $ \_ -> printGroup o g

-- Printer for a list of VisGroups with evenly spaced columns.
printerGroups :: VisOffset -> [VisGroup] -> VisPrinter
printerGroups o gs = visPrinter $ \s -> 
              printGroups o 0 0 True False (groupAverage gs) s

-- Printer for a list of VisGroups with minimum spaced columns.
printerGroups' :: VisOffset -> [VisGroup] -> VisPrinter
printerGroups' o gs = visPrinter $ \s -> 
              printGroups o 0 0 False False (groupAverage gs) s

-- Printer for a list of VisGroups with evenly spaced columns, limiting number of rows.
printerGroupsLimited :: VisOffset -> VisNumber -> [VisGroup] -> VisPrinter
printerGroupsLimited o r gs = visPrinter $ \s -> 
              printGroups o 0 r True False (groupAverage gs) s

-- Printer for a list of VisGroups with minimum spaced columns, limiting number of rows.
printerGroupsLimited' :: VisOffset -> VisNumber -> [VisGroup] -> VisPrinter
printerGroupsLimited' o r gs = visPrinter $ \s -> 
              printGroups o 0 r False False (groupAverage gs) s


-- Table Printing
--------------------------------------------------------------------------------

-- Prints a VisTable with alternating background, with minimum spaced columns.
printerTable :: VisOffset -> VisPadding -> Maybe VisTable -> VisPrinter
printerTable o p mt = visPrinter $ \s -> 
                 printGroups o p 0 False True (unMaybeTable mt) s

-- Prints a VisTable with alternating background, with evenly spaced columns.
printerTable' :: VisOffset -> VisPadding -> Maybe VisTable -> VisPrinter
printerTable' o p mt = visPrinter $ \s -> 
                 printGroups o p 0 True True (unMaybeTable mt) s

-- Prints a VisTable limiting the number of rows, with minimum spaced columns.
printerTableLimited :: VisOffset -> VisPadding -> VisNumber -> Maybe VisTable -> VisPrinter
printerTableLimited o p r mt = visPrinter $ \s -> 
                 printGroups o p r False True (unMaybeTable mt) s

-- Prints a VisTable limiting the number of rows, with evenly spaced columns.
printerTableLimited' :: VisOffset -> VisPadding -> VisNumber -> Maybe VisTable -> VisPrinter
printerTableLimited' o p r mt = visPrinter $ \s -> 
                 printGroups o p r True True (unMaybeTable mt) s


-- Text Printing
--------------------------------------------------------------------------------

-- Printer for a continuous paragraph, made from a list of VisBlocks.
printerParagraph :: VisOffset -> VisOffset -> VisParagraph -> VisPrinter
printerParagraph o o1 vbs = visPrinter $ \s -> 
                                printParagraph o o1 0 False vbs s

-- Printer for a list of paragraphs, separated by a single line, in the simplest manner.
printerArticle :: VisOffset -> VisOffset -> VisArticle -> VisPrinter
printerArticle o o1 vbss = visPrinter $ \s -> 
                                printSequence o o1 0 False odd vbss s


-- Printer for a sequence of paragraphs, separated by a single line,
--    alternating the background to solid on odd entries.
printerSequence :: VisOffset -> VisOffset -> VisPadding -> [VisParagraph] -> VisPrinter
printerSequence o o1 p vbss = printerSequencePred o o1 p odd vbss

-- Version of the Sequence Printer that changes the background of even items.
printerSequence' :: VisOffset -> VisOffset -> VisPadding -> [VisParagraph] -> VisPrinter
printerSequence' o o1 p vbss = printerSequencePred o o1 p even vbss

-- Version of the Sequence Printer that changes the background of a selected item.
--    The selection is given by the VisNumber, 0 indexed.
printerSequenceSel :: VisOffset -> VisOffset -> VisPadding -> VisNumber -> [VisParagraph] -> VisPrinter
printerSequenceSel o o1 p i vbss = printerSequencePred o o1 p (==unn i) vbss

-- Version of the Sequence Printer that changes the background of items after a certain number.
printerSequenceAfter :: VisOffset -> VisOffset -> VisPadding -> VisNumber -> [VisParagraph] -> VisPrinter
printerSequenceAfter o o1 p i vbss = printerSequencePred o o1 p (>=unn i) vbss

-- Version of the Sequence Printer that changes the background based on a predicate.
printerSequencePred :: VisOffset -> VisOffset -> VisPadding -> (Int -> Bool) -> [VisParagraph] -> VisPrinter
printerSequencePred o o1 p f vbss = visPrinter $ \s -> 
                                      printSequence o o1 p True f vbss s


