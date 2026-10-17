module Vis.Internal.Printer where

--------------------------------------------------------------------------------
import           Control.Monad
import           Data.List.Split
import           Vis.Internal.Content
import           Vis.Internal.Number
import           Vis.Internal.Sample
import           Vis.Internal.Settings
import           Vis.Internal.Style
import           Vis.Internal.Terminal
import           Vis.Internal.Utils
import           Vis.Content
import           Vis.Style



-- Printer Type
--------------------------------------------------------------------------------
-- A printer is a function, from Config to IO VisNumber, that prints on the screen.
--    It is expected that a Printer will print at least one line.
--    The Printer should return the number of lines printed as an IO VisNumber.
--    An String is passed to identify the specific printer function used.
--    The Printer cant't show its content since it is restructured on the fly.
newtype VisPrinter = VisPrinter (String, (VisConfig -> IO VisNumber))

instance Eq VisPrinter where
    VisPrinter (n1,_) == VisPrinter (n2,_) = n1 == n2

instance Show VisPrinter where
    show (VisPrinter (nm,_)) = "VisPrinter <" ++ nm ++ ">"

instance VisSample VisPrinter where
    sampleShow _ vp = show vp


-- Wrapper
visPrinter :: String -> (VisConfig -> IO VisNumber) -> VisPrinter
visPrinter nm fio = VisPrinter (nm,fio)


-- Function to execute the printer by passing the user settings.
runPrinter :: VisSettings -> VisPrinter -> IO VisNumber
runPrinter s (VisPrinter (_,fio)) = runSettings s >>= fio 

-- Equivalent to runPrinter, but with just the VisConfig in IO.
runPrinterIO :: IO VisConfig -> VisPrinter -> IO VisNumber
runPrinterIO cfg (VisPrinter (_,fio)) = cfg >>= fio

-- Uses default settings.
runPrinterDefault :: VisPrinter -> IO VisNumber
runPrinterDefault (VisPrinter (_,fio)) = initialConfig >>= fio

-- Uses default settings, with given width and minSpace.
runPrinterDefault' :: VisWidth -> VisWidth -> VisPrinter -> IO VisNumber
runPrinterDefault' w m (VisPrinter (_,fio)) = initialConfig >>= \dft -> fio $ setWidth w $ setMinSpace m dft


-- Basic Printing
--------------------------------------------------------------------------------

-- Prints a number of empty lines.
printEmpty :: VisNumber -> IO VisNumber
printEmpty n = vis0 >> sequence_ (putStrLn <$> replicate (unn n) "") >> return n

-- Prints the end of line character.
printEnd :: IO VisNumber
printEnd = vis0 >> putStr "\n" >> return 1

-- Prints a VisItem with the proper visual style.
printItem :: VisItem -> IO ()
printItem v = vis (unItemStyle v) >> putStr (unItemText v)

-- Prints each VisItem of a VisBlock, with the proper visual style.
printBlock :: VisBlock -> IO ()
printBlock b = mapM_ printItem (unBlock b)

-- Prints a VisBlock, left aligned, with proper indentation and line ending.
printLeft :: VisOffset -> VisBlock -> IO VisNumber
printLeft o b = ind o >> printBlock b >> printEnd

-- Function to execute the printing functions that sums the line counts.
printCounter :: (a -> IO VisNumber) -> [a] -> IO VisNumber
printCounter f = foldM (\ns l -> (+) ns <$> f l) 0


-- Rules & Solid Printing
--------------------------------------------------------------------------------

-- Prints a horizontal rule with an offset on both sides.
printRule :: VisOffset -> VisRule -> VisConfig -> IO VisNumber
printRule o r s = ind o >> printItem (visRuleItem r (w - o*2)) >> printEnd
              where w = unWidth s

-- Prints a line filled with spaces with the background color given.
printSolid :: VisOffset -> VisColor -> VisConfig -> IO VisNumber
printSolid o c s = printRule o (ruleSolid c) s



-- Line Printing
--------------------------------------------------------------------------------

-- Prints a single Item as a line, left aligned.
printSingleItem :: VisItem -> IO VisNumber
printSingleItem i = printItem i >> printEnd


-- Prints a line of VisBlocks, left aligned.
printLineLeft :: VisOffset -> [VisBlock] -> VisConfig -> IO VisNumber
printLineLeft o bs s = ind o >> mapM_ mainPrinter bs >> printEnd
        where 
           m = unMinSpace s
           mainPrinter vb = printBlock vb >> ind' m

-- Prints a line of VisBlocks, right aligned.
printLineRight :: VisOffset -> [VisBlock] -> VisConfig -> IO VisNumber
printLineRight o bs s = printLineLeft finalOffset bs s
       where
          w = unWidth s ; m =  unMinSpace s ; m' = unn m
          finalOffset = w - o - totalWidth + m
          totalWidth = visNumber . sum $ fmap ((+m') . blockTextWidth) bs


-- Prints a list of VisBlocks in a single line, centered and spread across
--    the available width. Adjacent blocks are separated by at least the
--    minimum space setting. If the content does not fit, the line overflows
--    instead of overlapping.
printLineCenter :: VisOffset -> [VisBlock] -> VisConfig -> IO VisNumber
printLineCenter _ [] _ = printEnd
printLineCenter o [b] s = indR centered >> printBlock b >> printEnd
     where
        w' = unn (unWidth s)
        o' = unn o
        width = blockTextWidth b
        centered = o' + max 0 (quot (w' - o' * 2 - width) 2)
printLineCenter o bs s = mapM_ printAt (zip positions bs) >> printEnd
     where
        w' = unn (unWidth s)
        o' = unn o
        m = unn (unMinSpace s)
        widths = fmap blockTextWidth bs
        gaps = length bs - 1
        total = sum widths + m * gaps
        available = w' - o' * 2
        extra = max 0 (available - total)
        baseGap = m + quot extra gaps
        remainder = rem extra gaps
        gapsList = [ baseGap + if i < remainder then 1 else 0
                   | i <- [0 .. gaps - 1] ]
        positions = scanl (\x (width,gap) -> x + width + gap) o'
                          (zip widths gapsList)
        printAt (x,b) = indR x >> printBlock b


type VisLineFunction = (VisOffset -> [VisBlock] -> VisConfig -> IO VisNumber)


-- Solid Text Printing
--------------------------------------------------------------------------------

-- Prints a list of VisBlocks in a single line, with a solid background.
--   The padding between background and text can be given as another offset.
printSolidLine :: VisOffset -> VisPadding -> VisColor -> [VisBlock]
               -> VisLineFunction -> VisConfig -> IO VisNumber
printSolidLine o p c bs f s = printSolid o c s >> cursorUp 1 >> f (o + p) bs' s
          where bs' = fmap (blockSetBG c) bs


-- List Printing
--------------------------------------------------------------------------------

-- Prints a list of VisBlocks as a single Column, with the given offset.
printColumn :: VisOffset -> [VisBlock] -> IO VisNumber
printColumn o bs = printCounter (printLeft o) bs


-- Prints a list of VisBlocks in several columns, aiming for a specified length.
-- If the number of columns overflows the width, a larger length is tried.
printList :: VisOffset -> VisNumber -> [VisBlock] -> VisConfig -> IO VisNumber
printList _ _ [] _ = return 0
printList o l bs s
     | maxCols <= 0 = printColumn o bs
     | otherwise = fmap (head' 0) . sequence $ mainPrinter (new (unn l)) bs
     where 
        w' = unn (unWidth s); m = unMinSpace s
        o' = unn o ; m' = unn m
        maxWidth = max 1 (blockTextMax bs + m')
        maxCols = quot (w' - o' * 2 - quot maxWidth 2) maxWidth

        new :: Int -> Int
        new l'
            | l' > 0 && desiredCols l' <= maxCols = l'
            | otherwise = new (l' + 1)
          where desiredCols l'' | l'' == 0 = numItems
                                | otherwise = quot numItems l''
                numItems = length bs
        
        mainPrinter :: Int -> [VisBlock] -> [IO VisNumber]
        mainPrinter newL bs' = fmap printListColumn (zip splitCols [0..])
             where
                splitCols = chunksOf newL bs'
                
                printListColumn :: ([VisBlock], Int) -> IO VisNumber
                printListColumn (b,i)
                       | i == 0 = printCol
                       | i == length splitCols - 1 = 
                            cursorUp newL >> printCol >>= \n -> cursorDown (newL - length b) >> return n
                       | otherwise = cursorUp newL >> printCol
                     where printCol = printColumn currentOffset b
                           currentOffset = visNumber (i * maxWidth + o')


-- Version that allows to specify the number of columns.
-- By nature of the List printer, it won't allow more columns than can fit.
printList' :: VisOffset -> VisNumber -> [VisBlock] -> VisConfig -> IO VisNumber
printList' o l bs s = printList o desiredLines bs s
          where desiredLines = visNumber $ quot (length bs) newL + 1
                newL | l == 0 = 1
                     | otherwise = unn l


-- Group & Table Printing
--------------------------------------------------------------------------------

-- Prints a single VisGroup as a column, with the given offset.
printGroup :: VisOffset -> VisGroup -> IO VisNumber
printGroup o g = printColumn o (unGroup g)


-- Main function for printing groups and tables, used by the specialized versions.
--    Configured by the arguments:
--       VisOffset -> Offset from both sides.
--       VisPadding -> Padding between text and background.
--       VisNumber -> Sets the number of rows printed, rest is discarded, 0 is max.
--       Bool -> Sets the alignment to be evenly spaced if True, or max per row.
--       Bool -> Table mode: zebra background and repeating index column.
printGroups :: VisOffset -> VisPadding -> VisNumber -> Bool
            -> Bool -> [VisGroup] -> VisConfig -> IO VisNumber
printGroups o p n bSpace bTable gs s = mainPrinter
    where
       w = unWidth s; m = unMinSpace s
       w' = unn w ; m' = unn m ; n' = unn n
       offset = unn o + unn p
       finalWidth = w' - offset*2 + m'
       
       widthList = fmap ((+m') . blockTextMax . unGroup) gs
       maxWidth = maximum' 0 widthList
       evenList = replicate (length gs) maxWidth
       chosenWidthList | bSpace = evenList | otherwise = widthList

       initGroup = take 1 gs
       initWidth = take 1 chosenWidthList
       mainPrinter = printLoop gs chosenWidthList 0 0
         where
            printLoop :: [VisGroup] -> [Int] -> Int -> VisNumber -> IO VisNumber
            printLoop rm wl ri nls
                    | null rm || (ri >= n' && n' /= 0) = return (nls + visNumber ri - 1)
                    | otherwise = executePrint >> restartLoop
              where                 
                 restartLoop = printLoop finalRemGroups finalRemWidths (ri + 1) (nls + visNumber rowLength)

                 executePrint :: IO ()
                 executePrint
                        | bTable = printZebraBG o rowLength s >> cursorUp rowLength
                                >> printContent
                        | otherwise = printContent
                      where 
                        printContent = 
                          mapM_ printEach (zip3 (fst splitGroups) curOffsets [0..])

                 lastRow = null remWidths
                 validIndex = bTable && not lastRow
                 rowColumns = length curWidths
                 rowLength = maximum' 0 $ fmap (length . unGroup) curGroups

                 curOffsets = scanl (+) 0 curWidths

                 finalRemGroups | validIndex = initGroup ++ remGroups | otherwise = remGroups
                 finalRemWidths | validIndex = initWidth ++ remWidths | otherwise = remWidths

                 remGroups = snd splitGroups
                 remWidths = snd splitWidths
                 curGroups = fst splitGroups
                 curWidths = fst splitWidths

                 splitGroups = splitAt splitPointList rm
                 splitWidths = splitAt splitPointList wl
                 splitPointList = availableSplitPoint

                 availableSplitPoint
                     | null chosenWidthList = 0
                     | otherwise = max 1 (splitPoint chosenWidthList finalWidth)

                       
                 printEach :: (VisGroup,Int,Int) -> IO ()
                 printEach (g,wg,i)
                      | i + 1 == rowColumns = printGroupChangeBG
                                           >> cursorDown (rowLength - curLength)
                                           >> printSpacing
                      | otherwise = printGroupChangeBG >> cursorUp curLength
                   where
                      printGroupChangeBG = printGroup' $ setBG g
                      colOffset = wg + offset
                      curLength = length (unGroup g)
                      printGroup' g' = printGroup (visNumber colOffset) g'
                      printSpacing
                           | lastRow = return_ | otherwise = printEmpty 1 >> return_

                      setBG :: VisGroup -> VisGroup
                      setBG g' | bTable = visGroup' $ changeBlocks <$> zip (unGroup g') [0..]
                                  | otherwise = g'
                               where changeBlocks :: (VisBlock, Int) -> VisBlock
                                     changeBlocks (b,ib)
                                       | even ib = b
                                       | otherwise = blockSetBG black b


-- Text Printing
--------------------------------------------------------------------------------

-- Prints a list of VisBlocks as a continuous paragraph.
--     VisOffset -> Indentaion of the entire paragraph.
--     VisOffset -> Additional indentation for the first paragraph line.
--     VisPadding -> Padding between text and background.
--     Bool -> Sets the Background to solid grey.
printParagraph :: VisOffset -> VisOffset -> VisPadding -> Bool
                       -> VisParagraph -> VisConfig -> IO VisNumber
printParagraph o o1 p bZebra vbs s = printCounter printEachBlock 
                                         $ blockPublish (w' - offset' * 2) (unn o1) vbs
    where
      w = unWidth s; w' = unn w
      offset' = unn o + unn p
      offset = visNumber offset'
      printEachBlock vb
           | bZebra = printSolid o black s
                   >> cursorUp 1 
                   >> printLeft' (blockSetBG black blockPretty)
           | otherwise = printLeft' blockPretty
        where
          printLeft' vb' = printLeft offset vb'
          blockPretty = blockPrettify vb


-- Prints a list of paragraphs, separated by a single line.
--   Additional configuration can be given below.
--     VisOffset -> Indentaion of the entire paragraphs.
--     VisOffset -> Additional indentation for the first line of each paragraph.
--     VisPadding -> Padding between text and background.
--     Bool -> Controls background alternation.
--     Function -> Predicate to test which paragraphs should have solid background.
printSequence :: VisOffset -> VisOffset -> VisPadding -> Bool -> (Int -> Bool)
             -> [VisParagraph] -> VisConfig -> IO VisNumber
printSequence o o1 p bZebra fInt vbss s = printCounter printEach (zip vbss [0..])
    where 
      printEach (vbs,i)
          | i == length vbss - 1 = printParagraph' predZebra
          | otherwise = printParagraph' predZebra >>= \n -> printSeparation >>= \n' -> return (n+n')
        where 
          predZebra = bZebra && fInt i
          printParagraph' bZebra' = printParagraph o o1 p bZebra' vbs s
          printSeparation
              | predZebra = printSolid o black s
              | otherwise = printEmpty 1  


-- Background Printing
--------------------------------------------------------------------------------
-- Prints a series of alternating lines, black and grey, for usage with tables.
--   The offset and number of lines are given as parameters.
printZebraBG :: VisOffset -> Int -> VisConfig -> IO ()
printZebraBG o n s = sequence_ $ take n $ cycle [printEmpty 1, printSolid o black s]

-- Prints a solid background of several lines of the same color.
printSolidBG :: VisOffset -> Int -> VisColor -> VisConfig -> IO ()
printSolidBG o n vc s = replicateM_ n (printSolid o vc s)
