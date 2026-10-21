module Ansiform.Internal.Printer where

--------------------------------------------------------------------------------
import           Control.Monad
import           Data.List (transpose, zipWith4)
import           Data.List.Split
import           System.IO (Handle, hPutStr, hPutStrLn, stdout)
import           Ansiform.Internal.Content
import           Ansiform.Internal.Number
import           Ansiform.Internal.Output
import           Ansiform.Internal.Sample
import           Ansiform.Internal.Settings
import           Ansiform.Internal.Style
import           Ansiform.Internal.Table
import           Ansiform.Internal.Terminal
import           Ansiform.Internal.Utils
import           Ansiform.Content
import           Ansiform.Style



-- Printer Type
--------------------------------------------------------------------------------
-- | A printer is a function from the output target to the number of lines printed.
--   The printer name is used for inspection and equality.
newtype Printer = Printer (String, (Output -> IO Number))

instance Eq Printer where
    Printer (n1,_) == Printer (n2,_) = n1 == n2

instance Show Printer where
    show (Printer (nm,_)) = "Printer <" ++ nm ++ ">"

instance Sample Printer where
    sampleShow _ vp = show vp


-- Wrapper
formPrinter :: String -> (Output -> IO Number) -> Printer
formPrinter nm fio = Printer (nm,fio)


-- | Runs a printer on stdout with the given settings.
runPrinter :: Settings -> Printer -> IO Number
runPrinter = runPrinterOn stdout

-- | Runs a printer on a given handle.
runPrinterOn :: Handle -> Settings -> Printer -> IO Number
runPrinterOn h s (Printer (_,fio)) = runSettingsOn h s >>= \cfg -> fio (formOutput h cfg)

-- | Runs a printer with a configuration resolved in IO, on stdout.
runPrinterIO :: IO Config -> Printer -> IO Number
runPrinterIO = runPrinterIOOn stdout

-- | Runs a printer with a configuration resolved in IO, on a given handle.
runPrinterIOOn :: Handle -> IO Config -> Printer -> IO Number
runPrinterIOOn h cfg (Printer (_,fio)) = cfg >>= \c -> fio (formOutput h c)

-- | Runs a printer on stdout with the default settings.
runPrinterDefault :: Printer -> IO Number
runPrinterDefault = runPrinterDefaultOn stdout

-- | Runs a printer on a given handle with the default settings.
runPrinterDefaultOn :: Handle -> Printer -> IO Number
runPrinterDefaultOn h (Printer (_,fio)) = initialConfigOn h >>= \cfg -> fio (formOutput h cfg)

-- | Runs a printer on stdout with the default settings and explicit width and spacing.
runPrinterDefault' :: Width -> Width -> Printer -> IO Number
runPrinterDefault' = runPrinterDefaultOn' stdout

-- | Runs a printer on a given handle with the default settings and explicit width and spacing.
runPrinterDefaultOn' :: Handle -> Width -> Width -> Printer -> IO Number
runPrinterDefaultOn' h w m (Printer (_,fio)) =
              initialConfigOn h >>= \dft -> fio (formOutput h (setWidth w $ setMinSpace m dft))


-- Basic Printing
--------------------------------------------------------------------------------

-- Prints a number of empty lines.
printEmpty :: Output -> Number -> IO Number
printEmpty o n = resetStyle h (outputColors o)
              >> sequence_ (hPutStrLn h <$> replicate (unn n) "")
              >> return n
  where h = outputHandle o

-- Prints the end of line character.
printEnd :: Output -> IO Number
printEnd o = resetStyle h (outputColors o) >> hPutStr h "\n" >> return 1
  where h = outputHandle o

-- Prints a Item with the proper visual style.
printItem :: Output -> Item -> IO ()
printItem o v = applyStyle h (outputColors o) (unItemStyle v) >> hPutStr h (unItemText v)
  where h = outputHandle o

-- Prints each Item of a Block, with the proper visual style.
printBlock :: Output -> Block -> IO ()
printBlock o b = mapM_ (printItem o) (unBlock b)

-- Prints a Block, left aligned, with proper indentation and line ending.
printLeft :: Output -> Offset -> Block -> IO Number
printLeft o off b = ind h off >> printBlock o b >> printEnd o
  where h = outputHandle o

-- Function to execute the printing functions that sums the line counts.
printCounter :: (a -> IO Number) -> [a] -> IO Number
printCounter f = foldM (\ns l -> addNumber ns <$> f l) 0


-- Rules & Solid Printing
--------------------------------------------------------------------------------

-- Prints a horizontal rule with an offset on both sides.
printRule :: Offset -> Rule -> Output -> IO Number
printRule o r out = ind h o >> printItem out (formRuleItem r (subtractNumber w (o * 2))) >> printEnd out
              where w = unWidth (outputConfig out)
                    h = outputHandle out

-- Prints a line filled with spaces with the background color given.
printSolid :: Offset -> Color -> Output -> IO Number
printSolid o c out = printRule o (ruleSolid c) out



-- Line Printing
--------------------------------------------------------------------------------

-- Prints a single Item as a line, left aligned.
printSingleItem :: Output -> Item -> IO Number
printSingleItem out i = printItem out i >> printEnd out


-- Prints a line of Blocks, left aligned.
printLineLeft :: Offset -> [Block] -> Output -> IO Number
printLineLeft o bs out = ind h o >> mapM_ mainPrinter bs >> printEnd out
        where 
           m = unMinSpace (outputConfig out)
           h = outputHandle out
           mainPrinter vb = printBlock out vb >> ind' h m

-- Prints a line of Blocks, right aligned.
printLineRight :: Offset -> [Block] -> Output -> IO Number
printLineRight o bs out = printLineLeft finalOffset bs out
       where
          w = unWidth (outputConfig out)
          m = unMinSpace (outputConfig out)
          m' = unn m
          finalOffset = addNumber (subtractNumber (subtractNumber w o) totalWidth) m
          totalWidth = formNumber . sum $ fmap ((+m') . blockTextWidth) bs


-- Prints a list of Blocks in a single line, centered and spread across
--    the available width. Adjacent blocks are separated by at least the
--    minimum space setting. If the content does not fit, the line overflows
--    instead of overlapping.
printLineCenter :: Offset -> [Block] -> Output -> IO Number
printLineCenter _ [] out = printEnd out
printLineCenter o [b] out = indR h centered >> printBlock out b >> printEnd out
     where
        cfg = outputConfig out
        h = outputHandle out
        w' = unn (unWidth cfg)
        o' = unn o
        width = blockTextWidth b
        centered = o' + max 0 (quot (w' - o' * 2 - width) 2)
printLineCenter o bs out = mapM_ printAt (zip positions bs) >> printEnd out
     where
        cfg = outputConfig out
        h = outputHandle out
        w' = unn (unWidth cfg)
        o' = unn o
        m = unn (unMinSpace cfg)
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
        printAt (x,b) = indR h x >> printBlock out b


type LineFunction = (Offset -> [Block] -> Output -> IO Number)


-- Solid Text Printing
--------------------------------------------------------------------------------

-- Prints a list of Blocks in a single line, with a solid background.
--   The padding between background and text can be given as another offset.
printSolidLine :: Offset -> Padding -> Color -> [Block]
               -> LineFunction -> Output -> IO Number
printSolidLine o p c bs f out = printSolid o c out >> hCursorUp h 1 >> f (addNumber o p) bs' out
          where bs' = fmap (blockSetBG c) bs
                h = outputHandle out


-- List Printing
--------------------------------------------------------------------------------

-- Prints a list of Blocks as a single Column, with the given offset.
printColumn :: Output -> Offset -> [Block] -> IO Number
printColumn out o bs = printCounter (printLeft out o) bs


-- Prints a list of Blocks in several columns, aiming for a specified length.
-- If the number of columns overflows the width, a larger length is tried.
printList :: Offset -> Number -> [Block] -> Output -> IO Number
printList _ _ [] _ = return 0
printList o l bs out
     | maxCols <= 0 = printColumn out o bs
     | otherwise = fmap (head' 0) . sequence $ mainPrinter (new (unn l)) bs
     where 
        cfg = outputConfig out
        h = outputHandle out
        w' = unn (unWidth cfg)
        m = unMinSpace cfg
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
                            hCursorUp h newL >> printCol >>= \n -> hCursorDown h (newL - length b) >> return n
                       | otherwise = hCursorUp h newL >> printCol
                     where printCol = printColumn out currentOffset b
                           currentOffset = formNumber (i * maxWidth + o')


-- Version that allows to specify the number of columns.
-- By nature of the List printer, it won't allow more columns than can fit.
printList' :: Offset -> Number -> [Block] -> Output -> IO Number
printList' o l bs out = printList o desiredLines bs out
          where desiredLines = formNumber $ quot (length bs) newL + 1
                newL | l == 0 = 1
                     | otherwise = unn l


-- Group & Table Printing
--------------------------------------------------------------------------------

-- Prints a single Group as a column, with the given offset.
printGroup :: Output -> Offset -> Group -> IO Number
printGroup out o g = printColumn out o (unGroup g)


-- Main function for printing groups and tables, used by the specialized versions.
--    Configured by the arguments:
--       Offset -> Offset from both sides.
--       Padding -> Padding between text and background.
--       Number -> Sets the number of rows printed, rest is discarded, 0 is max.
--       Bool -> Sets the alignment to be evenly spaced if True, or max per row.
--       Bool -> Table mode: zebra background and repeating index column.
printGroups :: TableFormat -> Offset -> Padding -> Number -> Bool
            -> Bool -> [Group] -> Output -> IO Number
printGroups fmt o p n bSpace bTable gs out = mainPrinter
    where
       cfg = outputConfig out
       h = outputHandle out
       w = unWidth cfg
       m = unMinSpace cfg
       w' = unn w ; m' = unn m ; n' = unn n
       offset = unn o + unn p
       finalWidth = w' - offset*2 + m'

       specs = fmap (columnSpecAt fmt) [0 .. length gs - 1]
       cappedWidths = zipWith cappedWidth specs gs
       widthList = fmap (+m') cappedWidths
       maxWidth = maximum' 0 widthList
       evenList = replicate (length gs) maxWidth
       chosenWidthList | bSpace = evenList | otherwise = widthList
       formattedGroups = zipWith4 formatOne specs cappedWidths chosenWidthList gs

       formatOne :: ColumnSpec -> Int -> Int -> Group -> Group
       formatOne spec capped chosen g = formatGroup spec (formNumber target) g
         where
           chosenContent = chosen - m'
           target = case columnAlign spec of
               AlignLeft -> capped
               _ -> chosenContent

       initGroup = take 1 formattedGroups
       initWidth = take 1 chosenWidthList
       mainPrinter = printLoop formattedGroups chosenWidthList 0 0
         where
            printLoop :: [Group] -> [Int] -> Int -> Number -> IO Number
            printLoop rm wl ri nls
                    | null rm || (ri >= n' && n' /= 0) = return (subtractNumber (addNumber nls (formNumber ri)) 1)
                    | otherwise = executePrint >> restartLoop
              where                 
                 restartLoop = printLoop finalRemGroups finalRemWidths (ri + 1) (addNumber nls (formNumber rowLength))

                 executePrint :: IO ()
                 executePrint
                        | bTable = printZebraBG o rowLength out >> hCursorUp h rowLength
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
                                           >> hCursorDown h (rowLength - curLength)
                                           >> printSpacing
                      | otherwise = printGroupChangeBG >> hCursorUp h curLength
                   where
                      printGroupChangeBG = printGroup' $ setBG g
                      colOffset = wg + offset
                      curLength = length (unGroup g)
                      printGroup' g' = printGroup out (formNumber colOffset) g'
                      printSpacing
                           | lastRow = return_ | otherwise = printEmpty out 1 >> return_

                      setBG :: Group -> Group
                      setBG g' | bTable = formGroup' $ changeBlocks <$> zip (unGroup g') [0..]
                                  | otherwise = g'
                               where changeBlocks :: (Block, Int) -> Block
                                     changeBlocks (b,ib)
                                       | even ib = b
                                       | otherwise = blockSetBG black b


-- Bordered Groups & Tables
--------------------------------------------------------------------------------

-- Prints groups or tables inside a box border.
--   The table does not split into column bands; it overflows when it does not fit.
--   Groups with fewer blocks than the tallest group are padded with empty
--   blocks, so every column reaches the bottom border.
printBorderedGroups :: Borders -> TableFormat -> Offset -> Padding -> Number
                    -> Bool -> [Group] -> Output -> IO Number
printBorderedGroups brd fmt o p n bSpace gs out
    | null gs = return 0
    | otherwise = case borderChars brd of
        Nothing -> printGroups fmt o p n bSpace False gs out
        Just bc -> printBordered bc
  where
    h = outputHandle out
    p' = unn p
    specs = fmap (columnSpecAt fmt) [0 .. length gs - 1]
    cappedWidths = zipWith cappedWidth specs gs
    maxWidth = maximum' 0 cappedWidths
    contentWidths = if bSpace then replicate (length gs) maxWidth else cappedWidths
    cellWidths = fmap (+ (2 * p')) contentWidths
    rows = transpose (fmap unGroup (padGroups gs))
    n' = unn n
    limitedRows = if n' == 0 then rows else take n' rows

    printBordered bc = do
        top <- printHorizontal (borderTopLeft bc) (borderTopMid bc) (borderTopRight bc)
        bodyCount <- printRows
        bottom <- printHorizontal (borderBottomLeft bc) (borderBottomMid bc) (borderBottomRight bc)
        return (top + bodyCount + bottom)
      where
        printRows = go limitedRows
          where
            go [] = return 0
            go (row:rest) = do
                printRow row
                sep <- if null rest
                         then return 0
                         else printHorizontal (borderMidLeft bc) (borderMidMid bc) (borderMidRight bc)
                restCount <- go rest
                return (1 + sep + restCount)

        printRow row = do
            indR h (unn o)
            resetStyle h (outputColors out)
            hPutStr h [borderLeft bc]
            printCells 0 (zip contentWidths row)
            hPutStr h "\n"
          where
            printCells _ [] = return ()
            printCells i ((w,cell):rest) = do
                let spec = columnSpecAt fmt i
                    aligned = formatBlock spec (formNumber w) cell
                    padded = padBlock (formNumber (w + 2 * p')) AlignCenter aligned
                printBlock out padded
                resetStyle h (outputColors out)
                if null rest
                  then hPutStr h [borderRight bc]
                  else hPutStr h [borderVertical bc]
                printCells (i + 1) rest

        printHorizontal first middle lastChar = do
            indR h (unn o)
            resetStyle h (outputColors out)
            hPutStr h (borderLine first middle lastChar cellWidths (borderHorizontal bc))
            hPutStr h "\n"
            return 1

-- Pads every group with empty blocks so all groups have the same height.
padGroups :: [Group] -> [Group]
padGroups gs = fmap padGroup gs
  where
    tallest = maximum' 0 (fmap (length . unGroup) gs)
    padGroup g = formGroup' (unGroup g ++ replicate missing blockEmpty)
      where missing = max 0 (tallest - length (unGroup g))

-- Builds one horizontal line of a box border.
borderLine :: Char -> Char -> Char -> [Int] -> Char -> String
borderLine first middle lastChar widths horizontal = case widths of
    [] -> [first, lastChar]
    _ -> first : concat
        [ replicate w horizontal ++ [if i == length widths - 1 then lastChar else middle]
        | (i,w) <- zip [0 :: Int ..] widths ]


-- Text Printing
--------------------------------------------------------------------------------

-- Prints a list of Blocks as a continuous paragraph.
--     Offset -> Indentaion of the entire paragraph.
--     Offset -> Additional indentation for the first paragraph line.
--     Padding -> Padding between text and background.
--     Bool -> Sets the Background to solid grey.
printParagraph :: Offset -> Offset -> Padding -> Bool
                       -> Paragraph -> Output -> IO Number
printParagraph o o1 p bZebra vbs out = printCounter printEachBlock 
                                         $ blockPublish (w' - offset' * 2) (unn o1) vbs
    where
      cfg = outputConfig out
      h = outputHandle out
      w = unWidth cfg; w' = unn w
      offset' = unn o + unn p
      offset = formNumber offset'
      printEachBlock vb
           | bZebra = printSolid o black out
                   >> hCursorUp h 1 
                   >> printLeft' (blockSetBG black blockPretty)
           | otherwise = printLeft' blockPretty
        where
          printLeft' vb' = printLeft out offset vb'
          blockPretty = blockPrettify vb


-- Prints a list of paragraphs, separated by a single line.
--   Additional configuration can be given below.
--     Offset -> Indentaion of the entire paragraphs.
--     Offset -> Additional indentation for the first line of each paragraph.
--     Padding -> Padding between text and background.
--     Bool -> Controls background alternation.
--     Function -> Predicate to test which paragraphs should have solid background.
printSequence :: Offset -> Offset -> Padding -> Bool -> (Int -> Bool)
             -> [Paragraph] -> Output -> IO Number
printSequence o o1 p bZebra fInt vbss out = printCounter printEach (zip vbss [0..])
    where 
      printEach (vbs,i)
          | i == length vbss - 1 = printParagraph' predZebra
          | otherwise = printParagraph' predZebra >>= \n -> printSeparation >>= \n' -> return (addNumber n n')
        where 
          predZebra = bZebra && fInt i
          printParagraph' bZebra' = printParagraph o o1 p bZebra' vbs out
          printSeparation
              | predZebra = printSolid o black out
              | otherwise = printEmpty out 1  


-- Background Printing
--------------------------------------------------------------------------------
-- Prints a series of alternating lines, black and grey, for usage with tables.
--   The offset and number of lines are given as parameters.
printZebraBG :: Offset -> Int -> Output -> IO ()
printZebraBG o n out = sequence_ $ take n $ cycle [printEmpty out 1, printSolid o black out]

-- Prints a solid background of several lines of the same color.
printSolidBG :: Offset -> Int -> Color -> Output -> IO ()
printSolidBG o n vc out = replicateM_ n (printSolid o vc out)
