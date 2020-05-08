module Vis.Print where

-- INTERNAL --
--------------------------------------------------------------------------------
import           Data.Char
import           Data.List
import           Data.List.Split
import           Data.Maybe (fromMaybe)
import           Vis.Builder
import           Vis.Content
import           Vis.Number
import           Vis.Settings
import           Vis.Style
import           Vis.Terminal
import           Vis.Utils



-- Basic Printing
--------------------------------------------------------------------------------

-- Prints a number of empty lines.
printEmpty :: VisNumber -> IO ()
printEmpty n = vis0 >> sequence_ (putStrLn <$> replicate (unn n) "")

-- Prints the end of line character.
printEnd :: IO ()
printEnd = vis0 >> putStr "\n"

-- Prints a VisItem with the proper visual style.
printItem :: VisItem -> IO ()
printItem v = vis (unItemStyle v) >> putStr (unItemText v)

-- Prints each VisItem of a VisBlock, with the proper visual style.
printBlock :: VisBlock -> IO ()
printBlock b = mapM_ printItem (unBlock b)

-- Prints a VisBlock, left aligned, with proper indentation and line ending.
printLeft :: VisOffset -> VisBlock -> IO ()
printLeft o b = ind o >> printBlock b >> printEnd


-- Rules & Solid Printing
--------------------------------------------------------------------------------

-- Prints a horizontal rule with an offset on both sides.
printRule :: VisOffset -> VisRule -> VisSettings -> IO ()
printRule o r (w,_) = ind o >> printItem (visRuleItem r (w - o*2)) >> printEnd

-- Prints a line filled with spaces with the background color given.
printSolid :: VisOffset -> VisColor -> VisSettings -> IO ()
printSolid o c s = printRule o (ruleSolid c) s



-- Line Printing
--------------------------------------------------------------------------------

-- Prints a line of VisBlocks, left aligned.
printLineLeft :: VisOffset -> [VisBlock] -> VisSettings -> IO ()
printLineLeft o bs (_,m) = ind o >> mapM_ mainPrinter bs >> printEnd
        where 
           mainPrinter vb = printBlock vb >> ind' m

-- Prints a line of VisBlocks, right aligned.
printLineRight :: VisOffset -> [VisBlock] -> VisSettings -> IO ()
printLineRight o bs s@(w,m) = printLineLeft finalOffset bs s
       where
          m' = unn m
          finalOffset = w - o - totalWidth + m
          totalWidth = visNumber . sum $ fmap ((+m') . blockTextWidth) bs


-- Prints a list of VisBlocks in a single line, with center alignment.
-- Indentation level is given by the offset.
printLineCenter :: VisOffset -> [VisBlock] -> VisSettings -> IO ()
printLineCenter o bs (w,_) = mapM_ printText (zip bs [0..]) >> printEnd
     where 
        w' = unn w; o' = unn o
        numItems = length bs
        halfItems = quot numItems 2
        screenInd = quot w' numItems
        
        printText :: (VisBlock,Int) -> IO ()
        printText (v,i) 
              | odd numItems && i == halfItems = offsetMiddle >> printBlock'
              | i >= halfItems = offsetRight >> printBlock'
              | otherwise = offsetLeft >> printBlock'
            where
               i' = numItems - 1 - i
               printBlock' = printBlock v
               itemWidth = blockTextWidth v
               offsetMiddle = indR (quot w' 2 - quot itemWidth 2)
               offsetRight = indR (w' - (screenOffset i' + itemWidth + itemOffset i'))
               offsetLeft = indR (screenOffset i + itemOffset i)
               screenOffset x = quot o' (x+1) + screenInd * x
               itemOffset x = quot itemWidth (halfItems + 1) * x


type VisLineFunction = (VisOffset -> [VisBlock] -> VisSettings -> IO ())


-- Solid Text Printing
--------------------------------------------------------------------------------

-- Prints a list of VisBlocks in a single line, with a solid background.
--   The padding between background and text can be given as another offset.
printSolidLine :: VisOffset -> VisOffset -> VisColor -> [VisBlock]
               -> VisLineFunction -> VisSettings -> IO ()
printSolidLine o p c bs f s = printSolid o c s >> cursorUp 1 >> f (o + p) bs' s
          where bs' = fmap (blockSetBG c) bs


-- List Printing
--------------------------------------------------------------------------------

-- Prints a list of VisBlocks as a single Column, with the given offset.
printColumn :: VisOffset -> [VisBlock] -> IO ()
printColumn o bs = mapM_ (printLeft o) bs


-- Prints a list of VisBlocks in several columns, aiming for a specified length.
-- If the number of columns overflows the width, a larger length is tried.
printList :: VisOffset -> VisNumber -> [VisBlock] -> VisSettings -> IO ()
printList o l bs (w,m) = sequence_ $ mainPrinter (new (unn l)) bs
     where 
        w' = unn w ; o' = unn o ; m' = unn m
        maxWidth = blockTextMax bs + m'

        new :: Int -> Int
        new l'
            | desiredCols l' <= maxCols && l' > 0 = l'
            | otherwise = new (l' + 1)
          where maxCols = quot (w' - o' * 2 - quot maxWidth 2) maxWidth
                desiredCols l'' | l'' == 0 = numItems
                                | otherwise = quot numItems l''
                numItems = length bs
        
        mainPrinter :: Int -> [VisBlock] -> [IO ()]
        mainPrinter newL bs' = fmap printListColumn (zip splitCols [0..])
             where
                splitCols = chunksOf newL bs'
                
                printListColumn :: ([VisBlock], Int) -> IO ()
                printListColumn (b,i)
                       | i == 0 = printCol
                       | i == length splitCols - 1 = 
                            cursorUp newL >> printCol >> cursorDown (newL - length b)
                       | otherwise = cursorUp newL >> printCol
                     where printCol = printColumn currentOffset b
                           currentOffset = visNumber (i * maxWidth + o')


-- Version that allows to specify the number of columns.
-- By nature of the List printer, it won't allow more columns than can fit.
printList' :: VisOffset -> VisNumber -> [VisBlock] -> VisSettings -> IO ()
printList' o l bs s = printList o desiredLines bs s
          where desiredLines = visNumber $ quot (length bs) newL + 1
                newL | l == 0 = 1
                     | otherwise = unn l


-- Group & Table Printing
--------------------------------------------------------------------------------

-- Prints a single VisGroup as a column, with the given offset.
printGroup :: VisOffset -> VisGroup -> IO ()
printGroup o g = printColumn o (unGroup g)


-- Main function for printing groups and tables, used by the specialized versions.
--    Configured by the arguments:
--       VisOffset -> Offset from both sides.
--       VisOffset -> Padding between text and background.
--       VisNumber -> Sets the number of rows printed, rest is discarded, 0 is max.
--       Bool -> Sets the alignment to be evenly spaced if True, or max per row.
--       Bool -> Table mode: zebra background and repeating index column.
printGroups :: VisOffset -> VisOffset -> VisNumber -> Bool
            -> Bool -> [VisGroup] -> VisSettings -> IO ()
printGroups o p n bSpace bTable gs s@(w,m) = mainPrinter
    where
       w' = unn w ; m' = unn m ; n' = unn n
       offset = unn o + unn p
       finalWidth = w' - offset*2 + m'
       
       widthList = fmap ((+m') . blockTextMax . unGroup) gs
       maxWidth = maximumInt widthList
       evenList = replicate (length gs) maxWidth
       chosenWidthList | bSpace = evenList | otherwise = widthList

       initGroup = take 1 gs
       initWidth = take 1 chosenWidthList
       mainPrinter = printLoop gs chosenWidthList 0
         where
            printLoop :: [VisGroup] -> [Int] -> Int ->  IO ()
            printLoop rm wl ri
                    | null rm || (ri >= n' && n' /= 0) = return ()
                    | otherwise = executePrint >> restartLoop
              where                 
                 restartLoop = printLoop finalRemGroups finalRemWidths (ri + 1)
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
                 rowLength = maximumInt $ fmap (length . unGroup) curGroups
                 lastLength = length . unGroup $ last curGroups

                 curOffsets = scanl (+) 0 curWidths

                 finalRemGroups | validIndex = initGroup ++ remGroups | otherwise = remGroups
                 finalRemWidths | validIndex = initWidth ++ remWidths | otherwise = remWidths

                 remGroups = snd splitGroups
                 remWidths = snd splitWidths
                 curGroups = fst splitGroups
                 curWidths = fst splitWidths

                 splitGroups = splitAt splitPointList rm
                 splitWidths = splitAt splitPointList wl
                 splitPointList = splitPoint chosenWidthList finalWidth

                       
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
                           | lastRow = return () | otherwise = printEmpty 1

                      setBG :: VisGroup -> VisGroup
                      setBG g' | bTable = visGroup' $ changeBlocks <$> zip (unGroup g') [0..]
                                  | otherwise = g'
                               where changeBlocks (b,ib)
                                       | even ib = b
                                       | otherwise = blockSetBG black b


-- Text Printing
--------------------------------------------------------------------------------

-- Prints a list of VisBlocks as a continuous paragraph.
--     VisOffset -> Indentaion of the entire paragraph.
--     VisOffset -> Additional indentation for the first paragraph line.
--     VisOffset -> Padding between text and background.
--     Bool -> Sets the Background to solid grey.
printParagraph :: VisOffset -> VisOffset -> VisOffset -> Bool
                       -> VisParagraph -> VisSettings -> IO ()
printParagraph o o1 p bZebra vbs s@(w,_) =
               mapM_ printEachBlock $ blockPublish (w' - offset' * 2) (unn o1) vbs
    where
      w' = unn w
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
--     VisOffset -> Padding between text and background.
--     Bool -> Controls background alternation.
--     Function -> Predicate to test which paragraphs should have solid background.
printSequence :: VisOffset -> VisOffset -> VisOffset -> Bool -> (Int -> Bool)
             -> [VisParagraph] -> VisSettings -> IO ()
printSequence o o1 p bZebra fInt vbss s = mapM_ printEach (zip vbss [0..])
    where 
      printEach (vbs,i)
          | i == length vbss - 1 = printParagraph' predZebra
          | otherwise = printParagraph' predZebra >> printSeparation
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
printZebraBG :: VisOffset -> Int -> VisSettings -> IO ()
printZebraBG o n s = sequence_ $ take n $ cycle [printEmpty 1, printSolid o black s]

-- Prints a solid background of several lines of the same color.
printSolidBG :: VisOffset -> Int -> VisColor -> VisSettings -> IO ()
printSolidBG o n vc s = sequence_ $ replicate n (printSolid o vc s)
