module Vis.Printer where

--------------------------------------------------------------------------------
import           Vis.Internal.Content
import           Vis.Internal.Number
import           Vis.Internal.Print
import           Vis.Internal.Settings
import           Vis.Internal.Terminal
import           Vis.Content
import           Vis.Style


-- Printer Type
--------------------------------------------------------------------------------
-- A printer is a function, from Settings to IO VisNumber, that prints on the screen.
--    It is expected that a Printer will print at least one line.
--    The Printer should return the number of lines printed as an IO VisNumber.
--    An String is passed to make the VisPrinter showable.
newtype VisPrinter = VisPrinter (String, (VisSettings -> IO VisNumber))

instance Show VisPrinter where
    show (VisPrinter (nm,_)) = "VisPrinter " ++ nm

-- Wrapper
visPrinter :: String -> (VisSettings -> IO VisNumber) -> VisPrinter
visPrinter nm sio = VisPrinter (nm,sio)


-- Functions to generate a VisPrinter with its content as part of the name.
namePrinter :: Show a => String -> a -> (VisSettings -> IO VisNumber) -> VisPrinter
namePrinter nm ct vf = visPrinter (namePrefix nm ++ show ct) vf

namePrinterList :: Show a => String -> [a] -> (VisSettings -> IO VisNumber) -> VisPrinter
namePrinterList nm ct vf = visPrinter
    (namePrefix nm ++ (concat (fmap (("\n   "++) . show) ct))) vf

namePrefix :: String -> String
namePrefix nm = "<" ++ nm ++ ">" ++ " "


-- Functions to execute the printer by passing the settings.
runPrinter :: IO VisSettings -> VisPrinter -> IO VisNumber
runPrinter s (VisPrinter (_,sio)) = s >>= sio

-- Uses default settings.
runPrinter' :: VisPrinter -> IO VisNumber
runPrinter' (VisPrinter (_,sio)) = defaultSettings >>= sio

-- Uses default settings, with given width and minSpace.
runPrinter'' :: VisWidth -> VisWidth -> VisPrinter -> IO VisNumber
runPrinter'' w m (VisPrinter (_,sio)) = defaultSettings >>= \dft -> sio $ setWidth w $ setMinSpace m dft


-- Basic Printing
--------------------------------------------------------------------------------

-- Printer for a number of empty lines.
printerEmpty :: VisNumber -> VisPrinter
printerEmpty n = namePrinter "Empty" n $ \_ -> printEmpty n

-- Printer for a VisBlock in single line, left aligned.
printerLeft :: VisOffset -> VisBlock -> VisPrinter
printerLeft o b = namePrinter "Left" b $ \_ -> printLeft o b


-- Rules & Solid Printing
--------------------------------------------------------------------------------

-- Printer for a horizontal rule that spans the whole screen.
printerRule :: VisRule -> VisPrinter
printerRule r = namePrinter "Rule" r $ \s -> printRule 0 r s

-- Printer for a horizontal rule with an offset on both sides.
printerRule' :: VisOffset -> VisRule -> VisPrinter
printerRule' o r = namePrinter "Rule'" r $ \s -> printRule o r s

-- Printer for a line filled with spaces with the background color given.
printerSolid :: VisColor -> VisPrinter
printerSolid c = namePrinter "Solid" c $ \s -> printRule 0 (ruleSolid c) s

-- Printer for a line filled with spaces with an offset from both sides.
printerSolid' :: VisOffset -> VisColor -> VisPrinter
printerSolid' o c = namePrinter "Solid'" c $ \s -> printRule o (ruleSolid c) s


-- Line Printing
--------------------------------------------------------------------------------

-- Printer for single VisBlock, right aligned.
printerRight :: VisOffset -> VisBlock -> VisPrinter
printerRight o b = namePrinter "Right" b $ \s -> printLineRight o [b] s

-- Printer for single VisBlock, center aligned.
printerCenter :: VisOffset -> VisBlock -> VisPrinter
printerCenter o b = namePrinter "Center" b $ \s -> printLineCenter o [b] s

-- Printer for list of VisBlocks in a single line, center aligned.
printerLineLeft :: VisOffset -> [VisBlock] -> VisPrinter
printerLineLeft o bs = namePrinterList "LineLeft" bs $ \s -> printLineLeft o bs s

-- Printer for list of VisBlocks in a single line, center aligned.
printerLineRight :: VisOffset -> [VisBlock] -> VisPrinter
printerLineRight o bs = namePrinterList "LineRight" bs $ \s -> printLineRight o bs s

-- Printer for list of VisBlocks in a single line, center aligned.
printerLineCenter :: VisOffset -> [VisBlock] -> VisPrinter
printerLineCenter o bs = namePrinterList "LineCenter" bs $ \s -> printLineCenter o bs s


-- Solid Text Printing
--------------------------------------------------------------------------------

printerSolidLeft :: VisOffset -> VisPadding -> VisColor -> VisBlock -> VisPrinter
printerSolidLeft o p c b = namePrinter "SolidLeft" b $ \s -> printSolidLine o p c [b] printLineLeft s

printerSolidRight :: VisOffset -> VisPadding -> VisColor -> VisBlock -> VisPrinter
printerSolidRight o p c b = namePrinter "SolidRight" b $ \s -> printSolidLine o p c [b] printLineRight s

printerSolidCenter :: VisOffset -> VisPadding -> VisColor -> VisBlock -> VisPrinter
printerSolidCenter o p c b = namePrinter "SolidCenter" b $ \s -> printSolidLine o p c [b] printLineCenter s

printerSolidLineLeft :: VisOffset -> VisPadding -> VisColor -> [VisBlock] -> VisPrinter
printerSolidLineLeft o p c bs = namePrinterList "SolidLineLeft" bs $ \s -> printSolidLine o p c bs printLineLeft s

printerSolidLineRight :: VisOffset -> VisPadding -> VisColor -> [VisBlock] -> VisPrinter
printerSolidLineRight o p c bs = namePrinterList "SolidLineRight" bs $ \s -> printSolidLine o p c bs printLineRight s

printerSolidLineCenter :: VisOffset -> VisPadding -> VisColor -> [VisBlock] -> VisPrinter
printerSolidLineCenter o p c bs = namePrinterList "SolidLineCenter" bs $ \s -> printSolidLine o p c bs printLineCenter s


-- List Printing
--------------------------------------------------------------------------------

-- Printer for a column of VisBlocks, with indentation.
printerColumn :: VisOffset -> [VisBlock] -> VisPrinter
printerColumn o bs = namePrinterList "Column" bs $ \_ -> printColumn o bs

-- Printer for a list of VisBlocks, aiming for a specified number of rows.
printerList :: VisOffset -> VisNumber -> [VisBlock] -> VisPrinter
printerList o l bs = namePrinterList "List" bs $ \s -> printList o l bs s

-- Printer for a list of VisBlocks, aiming for a specified number of columns.
printerList' :: VisOffset -> VisNumber -> [VisBlock] -> VisPrinter
printerList' o l bs = namePrinterList "List'" bs $ \s -> printList' o l bs s


-- Group Printing
--------------------------------------------------------------------------------

-- Printer for a single VisGroup, printed as a column with the given offset.
printerGroup :: VisOffset -> VisGroup -> VisPrinter
printerGroup o g = namePrinter "Group" g $ \_ -> printGroup o g

-- Printer for a list of VisGroups with evenly spaced columns.
printerGroups :: VisOffset -> [VisGroup] -> VisPrinter
printerGroups o gs = namePrinterList "Groups" gs $ \s -> 
              printGroups o 0 0 True False (groupAverage s gs) s

-- Printer for a list of VisGroups with minimum spaced columns.
printerGroups' :: VisOffset -> [VisGroup] -> VisPrinter
printerGroups' o gs = namePrinterList "Groups'" gs $ \s -> 
              printGroups o 0 0 False False (groupAverage s gs) s

-- Printer for a list of VisGroups with evenly spaced columns, limiting number of rows.
printerGroupsLimited :: VisOffset -> VisNumber -> [VisGroup] -> VisPrinter
printerGroupsLimited o r gs = namePrinterList "GroupsLimited" gs $ \s -> 
              printGroups o 0 r True False (groupAverage s gs) s

-- Printer for a list of VisGroups with minimum spaced columns, limiting number of rows.
printerGroupsLimited' :: VisOffset -> VisNumber -> [VisGroup] -> VisPrinter
printerGroupsLimited' o r gs = namePrinterList "GroupsLimited'" gs $ \s -> 
              printGroups o 0 r False False (groupAverage s gs) s


-- Table Printing
--------------------------------------------------------------------------------

-- Prints a VisTable with alternating background, with minimum spaced columns.
printerTable :: VisOffset -> VisPadding -> Maybe VisTable -> VisPrinter
printerTable o p mt = namePrinter "Table" mt $ \s -> 
                 printGroups o p 0 False True (unMaybeTable mt) s

-- Prints a VisTable with alternating background, with evenly spaced columns.
printerTable' :: VisOffset -> VisPadding -> Maybe VisTable -> VisPrinter
printerTable' o p mt = namePrinter "Table'" mt $ \s -> 
                 printGroups o p 0 True True (unMaybeTable mt) s

-- Prints a VisTable limiting the number of rows, with minimum spaced columns.
printerTableLimited :: VisOffset -> VisPadding -> VisNumber -> Maybe VisTable -> VisPrinter
printerTableLimited o p r mt = namePrinter "TableLimited" mt $ \s -> 
                 printGroups o p r False True (unMaybeTable mt) s

-- Prints a VisTable limiting the number of rows, with evenly spaced columns.
printerTableLimited' :: VisOffset -> VisPadding -> VisNumber -> Maybe VisTable -> VisPrinter
printerTableLimited' o p r mt = namePrinter "TableLimited'" mt $ \s -> 
                 printGroups o p r True True (unMaybeTable mt) s


-- Text Printing
--------------------------------------------------------------------------------

-- Printer for a continuous paragraph, made from a list of VisBlocks.
printerParagraph :: VisOffset -> VisOffset -> VisParagraph -> VisPrinter
printerParagraph o o1 vbs = namePrinterList "Paragraph" vbs $ \s -> 
                                printParagraph o o1 0 False vbs s

-- Printer for a list of paragraphs, separated by a single line, in the simplest manner.
printerArticle :: VisOffset -> VisOffset -> VisArticle -> VisPrinter
printerArticle o o1 vbss = namePrinterList "Article" vbss $ \s -> 
                                printSequence o o1 0 False odd vbss s


-- Printer for a sequence of paragraphs, separated by a single line,
--    alternating the background to solid on odd entries.
printerSequence :: VisOffset -> VisOffset -> VisPadding -> [VisParagraph] -> VisPrinter
printerSequence o o1 p vbss = namePrinterList "Sequence" vbss $ \s -> 
                                      printSequence o o1 p True odd vbss s

-- Version of the Sequence Printer that changes the background of even items.
printerSequence' :: VisOffset -> VisOffset -> VisPadding -> [VisParagraph] -> VisPrinter
printerSequence' o o1 p vbss = namePrinterList "Sequence'" vbss $ \s -> 
                                      printSequence o o1 p True even vbss s

-- Version of the Sequence Printer that changes the background of a selected item.
--    The selection is given by the VisNumber, 0 indexed.
printerSequenceSel :: VisOffset -> VisOffset -> VisPadding -> VisNumber -> [VisParagraph] -> VisPrinter
printerSequenceSel o o1 p i vbss = namePrinter "SequenceSel" vbss $ \s -> 
                                      printSequence o o1 p True (==unn i) vbss s

-- Version of the Sequence Printer that changes the background of items after a certain number.
printerSequenceAfter :: VisOffset -> VisOffset -> VisPadding -> VisNumber -> [VisParagraph] -> VisPrinter
printerSequenceAfter o o1 p i vbss = namePrinter "SequenceAfter" vbss $ \s -> 
                                      printSequence o o1 p True (>=unn i) vbss s

-- Version of the Sequence Printer that changes the background based on a predicate.
printerSequencePred :: VisOffset -> VisOffset -> VisPadding -> (Int -> Bool) -> [VisParagraph] -> VisPrinter
printerSequencePred o o1 p f vbss = namePrinter "SequencePred" vbss $ \s -> 
                                      printSequence o o1 p True f vbss s


