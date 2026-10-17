module Ansiform.Internal.Printer where

--------------------------------------------------------------------------------
import           Control.Monad
import           Data.List.Split
import           Ansiform.Internal.Content
import           Ansiform.Internal.Number
import           Ansiform.Internal.Sample
import           Ansiform.Internal.Settings
import           Ansiform.Internal.Style
import           Ansiform.Internal.Terminal
import           Ansiform.Internal.Utils
import           Ansiform.Content
import           Ansiform.Style



-- Printer Type
--------------------------------------------------------------------------------
-- A printer is a function, from Config to IO Number, that prints on the screen.
--    It is expected that a Printer will print at least one line.
--    The Printer should return the number of lines printed as an IO Number.
--    An String is passed to identify the specific printer function used.
--    The Printer cant't show its content since it is restructured on the fly.
newtype Printer = Printer (String, (Config -> IO Number))

instance Eq Printer where
    Printer (n1,_) == Printer (n2,_) = n1 == n2

instance Show Printer where
    show (Printer (nm,_)) = "Printer <" ++ nm ++ ">"

instance Sample Printer where
    sampleShow _ vp = show vp


-- Wrapper
formPrinter :: String -> (Config -> IO Number) -> Printer
formPrinter nm fio = Printer (nm,fio)


-- Function to execute the printer by passing the user settings.
runPrinter :: Settings -> Printer -> IO Number
runPrinter s (Printer (_,fio)) = runSettings s >>= fio 

-- Equivalent to runPrinter, but with just the Config in IO.
runPrinterIO :: IO Config -> Printer -> IO Number
runPrinterIO cfg (Printer (_,fio)) = cfg >>= fio

-- Uses default settings.
runPrinterDefault :: Printer -> IO Number
runPrinterDefault (Printer (_,fio)) = initialConfig >>= fio

-- Uses default settings, with given width and minSpace.
runPrinterDefault' :: Width -> Width -> Printer -> IO Number
runPrinterDefault' w m (Printer (_,fio)) = initialConfig >>= \dft -> fio $ setWidth w $ setMinSpace m dft


-- Basic Printing
--------------------------------------------------------------------------------

-- Prints a number of empty lines.
printEmpty :: Config -> Number -> IO Number
printEmpty s n = resetStyle (colorsEnabled s) >> sequence_ (putStrLn <$> replicate (unn n) "") >> return n

-- Prints the end of line character.
printEnd :: Config -> IO Number
printEnd s = resetStyle (colorsEnabled s) >> putStr "\n" >> return 1

-- Prints a Item with the proper visual style.
printItem :: Config -> Item -> IO ()
printItem s v = applyStyle (colorsEnabled s) (unItemStyle v) >> putStr (unItemText v)

-- Prints each Item of a Block, with the proper visual style.
printBlock :: Config -> Block -> IO ()
printBlock s b = mapM_ (printItem s) (unBlock b)

-- Prints a Block, left aligned, with proper indentation and line ending.
printLeft :: Config -> Offset -> Block -> IO Number
printLeft s o b = ind o >> printBlock s b >> printEnd s

-- Function to execute the printing functions that sums the line counts.
printCounter :: (a -> IO Number) -> [a] -> IO Number
printCounter f = foldM (\ns l -> (+) ns <$> f l) 0


-- Rules & Solid Printing
--------------------------------------------------------------------------------

-- Prints a horizontal rule with an offset on both sides.
printRule :: Offset -> Rule -> Config -> IO Number
printRule o r s = ind o >> printItem s (formRuleItem r (w - o*2)) >> printEnd s
              where w = unWidth s

-- Prints a line filled with spaces with the background color given.
printSolid :: Offset -> Color -> Config -> IO Number
printSolid o c s = printRule o (ruleSolid c) s



-- Line Printing
--------------------------------------------------------------------------------

-- Prints a single Item as a line, left aligned.
printSingleItem :: Config -> Item -> IO Number
printSingleItem s i = printItem s i >> printEnd s


-- Prints a line of Blocks, left aligned.
printLineLeft :: Offset -> [Block] -> Config -> IO Number
printLineLeft o bs s = ind o >> mapM_ mainPrinter bs >> printEnd s
        where 
           m = unMinSpace s
           mainPrinter vb = printBlock s vb >> ind' m

-- Prints a line of Blocks, right aligned.
printLineRight :: Offset -> [Block] -> Config -> IO Number
printLineRight o bs s = printLineLeft finalOffset bs s
       where
          w = unWidth s ; m =  unMinSpace s ; m' = unn m
          finalOffset = w - o - totalWidth + m
          totalWidth = formNumber . sum $ fmap ((+m') . blockTextWidth) bs


-- Prints a list of Blocks in a single line, centered and spread across
--    the available width. Adjacent blocks are separated by at least the
--    minimum space setting. If the content does not fit, the line overflows
--    instead of overlapping.
printLineCenter :: Offset -> [Block] -> Config -> IO Number
printLineCenter _ [] s = printEnd s
printLineCenter o [b] s = indR centered >> printBlock s b >> printEnd s
     where
        w' = unn (unWidth s)
        o' = unn o
        width = blockTextWidth b
        centered = o' + max 0 (quot (w' - o' * 2 - width) 2)
printLineCenter o bs s = mapM_ printAt (zip positions bs) >> printEnd s
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
        printAt (x,b) = indR x >> printBlock s b


type LineFunction = (Offset -> [Block] -> Config -> IO Number)


-- Solid Text Printing
--------------------------------------------------------------------------------

-- Prints a list of Blocks in a single line, with a solid background.
--   The padding between background and text can be given as another offset.
printSolidLine :: Offset -> Padding -> Color -> [Block]
               -> LineFunction -> Config -> IO Number
printSolidLine o p c bs f s = printSolid o c s >> cursorUp 1 >> f (o + p) bs' s
          where bs' = fmap (blockSetBG c) bs


-- List Printing
--------------------------------------------------------------------------------

-- Prints a list of Blocks as a single Column, with the given offset.
printColumn :: Config -> Offset -> [Block] -> IO Number
printColumn s o bs = printCounter (printLeft s o) bs


-- Prints a list of Blocks in several columns, aiming for a specified length.
-- If the number of columns overflows the width, a larger length is tried.
printList :: Offset -> Number -> [Block] -> Config -> IO Number
printList _ _ [] _ = return 0
printList o l bs s
     | maxCols <= 0 = printColumn s o bs
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
        
        mainPrinter :: Int -> [Block] -> [IO Number]
        mainPrinter newL bs' = fmap printListColumn (zip splitCols [0..])
             where
                splitCols = chunksOf newL bs'
                
                printListColumn :: ([Block], Int) -> IO Number
                printListColumn (b,i)
                       | i == 0 = printCol
                       | i == length splitCols - 1 = 
                            cursorUp newL >> printCol >>= \n -> cursorDown (newL - length b) >> return n
                       | otherwise = cursorUp newL >> printCol
                     where printCol = printColumn s currentOffset b
                           currentOffset = formNumber (i * maxWidth + o')


-- Version that allows to specify the number of columns.
-- By nature of the List printer, it won't allow more columns than can fit.
printList' :: Offset -> Number -> [Block] -> Config -> IO Number
printList' o l bs s = printList o desiredLines bs s
          where desiredLines = formNumber $ quot (length bs) newL + 1
                newL | l == 0 = 1
                     | otherwise = unn l


-- Group & Table Printing
--------------------------------------------------------------------------------

-- Prints a single Group as a column, with the given offset.
printGroup :: Config -> Offset -> Group -> IO Number
printGroup s o g = printColumn s o (unGroup g)


-- Main function for printing groups and tables, used by the specialized versions.
--    Configured by the arguments:
--       Offset -> Offset from both sides.
--       Padding -> Padding between text and background.
--       Number -> Sets the number of rows printed, rest is discarded, 0 is max.
--       Bool -> Sets the alignment to be evenly spaced if True, or max per row.
--       Bool -> Table mode: zebra background and repeating index column.
printGroups :: Offset -> Padding -> Number -> Bool
            -> Bool -> [Group] -> Config -> IO Number
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
            printLoop :: [Group] -> [Int] -> Int -> Number -> IO Number
            printLoop rm wl ri nls
                    | null rm || (ri >= n' && n' /= 0) = return (nls + formNumber ri - 1)
                    | otherwise = executePrint >> restartLoop
              where                 
                 restartLoop = printLoop finalRemGroups finalRemWidths (ri + 1) (nls + formNumber rowLength)

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

                       
                 printEach :: (Group,Int,Int) -> IO ()
                 printEach (g,wg,i)
                      | i + 1 == rowColumns = printGroupChangeBG
                                           >> cursorDown (rowLength - curLength)
                                           >> printSpacing
                      | otherwise = printGroupChangeBG >> cursorUp curLength
                   where
                      printGroupChangeBG = printGroup' $ setBG g
                      colOffset = wg + offset
                      curLength = length (unGroup g)
                      printGroup' g' = printGroup s (formNumber colOffset) g'
                      printSpacing
                           | lastRow = return_ | otherwise = printEmpty s 1 >> return_

                      setBG :: Group -> Group
                      setBG g' | bTable = formGroup' $ changeBlocks <$> zip (unGroup g') [0..]
                                  | otherwise = g'
                               where changeBlocks :: (Block, Int) -> Block
                                     changeBlocks (b,ib)
                                       | even ib = b
                                       | otherwise = blockSetBG black b


-- Text Printing
--------------------------------------------------------------------------------

-- Prints a list of Blocks as a continuous paragraph.
--     Offset -> Indentaion of the entire paragraph.
--     Offset -> Additional indentation for the first paragraph line.
--     Padding -> Padding between text and background.
--     Bool -> Sets the Background to solid grey.
printParagraph :: Offset -> Offset -> Padding -> Bool
                       -> Paragraph -> Config -> IO Number
printParagraph o o1 p bZebra vbs s = printCounter printEachBlock 
                                         $ blockPublish (w' - offset' * 2) (unn o1) vbs
    where
      w = unWidth s; w' = unn w
      offset' = unn o + unn p
      offset = formNumber offset'
      printEachBlock vb
           | bZebra = printSolid o black s
                   >> cursorUp 1 
                   >> printLeft' (blockSetBG black blockPretty)
           | otherwise = printLeft' blockPretty
        where
          printLeft' vb' = printLeft s offset vb'
          blockPretty = blockPrettify vb


-- Prints a list of paragraphs, separated by a single line.
--   Additional configuration can be given below.
--     Offset -> Indentaion of the entire paragraphs.
--     Offset -> Additional indentation for the first line of each paragraph.
--     Padding -> Padding between text and background.
--     Bool -> Controls background alternation.
--     Function -> Predicate to test which paragraphs should have solid background.
printSequence :: Offset -> Offset -> Padding -> Bool -> (Int -> Bool)
             -> [Paragraph] -> Config -> IO Number
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
              | otherwise = printEmpty s 1  


-- Background Printing
--------------------------------------------------------------------------------
-- Prints a series of alternating lines, black and grey, for usage with tables.
--   The offset and number of lines are given as parameters.
printZebraBG :: Offset -> Int -> Config -> IO ()
printZebraBG o n s = sequence_ $ take n $ cycle [printEmpty s 1, printSolid o black s]

-- Prints a solid background of several lines of the same color.
printSolidBG :: Offset -> Int -> Color -> Config -> IO ()
printSolidBG o n vc s = replicateM_ n (printSolid o vc s)
