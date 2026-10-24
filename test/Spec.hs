-- | Small regression suite for the pure core of the library.
module Main where

import Ansiform
import Control.Exception (bracket, finally)
import Control.Monad (unless)
import Data.List (isInfixOf)
import Data.Maybe (isJust, isNothing)
import GHC.IO.Handle (hDuplicate, hDuplicateTo)
import System.Directory (getTemporaryDirectory, removeFile)
import System.Exit (exitFailure)
import System.IO
    ( SeekMode (AbsoluteSeek)
    , hClose
    , hFlush
    , hPutStr
    , hSeek
    , openTempFile
    , readFile'
    , stdin
    , stdout
    )
import Test.QuickCheck
    ( Args (..)
    , Gen
    , Property
    , arbitrary
    , choose
    , elements
    , forAll
    , ioProperty
    , listOf
    , listOf1
    , oneof
    , property
    , quickCheckWithResult
    , resize
    , stdArgs
    )
import Test.QuickCheck.Random (mkQCGen)
import Test.QuickCheck.Test (isSuccess, output)

main :: IO ()
main = do
    results <-
        sequence
            [ test
                "Number caps negative values"
                (unNumber (formNumber (-7)) == 0)
            , test
                "Number keeps positive values"
                (unNumber (formNumber 12) == 12)
            , test
                "Number addition"
                (unNumber (3 + 4 :: Number) == 7)
            , test
                "Number subtraction caps at zero"
                (unNumber (2 - 5 :: Number) == 0)
            , test
                "Number checked subtraction rejects negative results"
                ( isNothing (subtractNumberMaybe 2 5)
                    && subtractNumberMaybe 5 2 == Just 3
                )
            , test
                "Number explicit subtraction caps at zero"
                (unNumber (subtractNumber 2 5) == 0)
            , test
                "Number negation caps at zero"
                (unNumber (negate (5 :: Number)) == 0)
            , test
                "Number signum"
                ( unNumber (signum (0 :: Number)) == 0
                    && unNumber (signum (5 :: Number)) == 1
                )
            , test
                "Balanced block table is accepted"
                (isJust (tableBlocks header [row]))
            , test
                "Unbalanced block table is rejected"
                (isNothing (tableBlocks header [[blockSimple "only" styleDefault]]))
            , test
                "Balanced simple table is accepted"
                (isJust (tableSimple header styleDefault [["a", "b"]]))
            , test
                "Unbalanced simple table is rejected"
                (isNothing (tableSimple header styleDefault [["a"]]))
            , test
                "Balanced group table is accepted"
                (isJust (tableGroups [balancedGroup, otherBalancedGroup]))
            , test
                "Unbalanced group table is rejected"
                (isNothing (tableGroups [balancedGroup, shortGroup]))
            , test
                "Items are stripped of non-printable characters"
                ( let out = sampleShow 0 (item "a\tb\nc" styleDefault)
                   in "\"abc\"" `isInfixOf` out
                        && not ("\\" `isInfixOf` out)
                )
            , test
                "Empty items are removed from blocks"
                ( let out =
                        sampleShow
                            0
                            ( block
                                [ item "" styleDefault
                                , item "kept" styleDefault
                                ]
                            )
                   in "kept" `isInfixOf` out
                        && not ("\"\"" `isInfixOf` out)
                )
            , test
                "Composite block builder keeps its parts"
                ( let out = sampleShow 0 (blockEnum "01" "Item" blue)
                   in "01" `isInfixOf` out && "Item" `isInfixOf` out
                )
            , test
                "Default theme provides readable accent and muted styles"
                ( themeAccent defaultTheme == bold cyan
                    && themeDanger defaultTheme == bold red'
                    && themeFooter defaultTheme == italic white
                    && themeMuted defaultTheme == italic white
                )
            , test
                "Theme record update changes a style"
                (themeAccent (defaultTheme{themeAccent = bold magenta}) == bold magenta)
            , test
                "Page amendment replaces the selected section"
                ( let replaced = amendPage' oldPage [newSection] 0
                      out = sampleShow 0 replaced
                   in "<Right>" `isInfixOf` out
                        && not ("<Left>" `isInfixOf` out)
                        && "<Center>" `isInfixOf` out
                )
            , test
                "Printer exposes its diagnostic name"
                (printerName (printerLeft 0 (blockSimple "a" styleDefault)) == "Left")
            , testIO "Sequence predicate renders the paragraphs" $ do
                let paragraphs =
                        [ [blockSimple "first" styleDefault]
                        , [blockSimple "second" styleDefault]
                        ]
                out <-
                    renderPrinter
                        (printerSequencePred 0 0 0 (== 1) paragraphs)
                        (settings [width 20, neverColors])
                return $ "first" `isInfixOf` out && "second" `isInfixOf` out
            , test
                "Display width of ASCII text"
                (charWidth 'a' == 1 && textWidth "abc" == 3)
            , test
                "Display width of wide characters"
                (charWidth '漢' == 2 && textWidth "a漢" == 3)
            , test
                "Display width of combining marks"
                (charWidth '\x0301' == 0 && textWidth "e\x0301" == 1)
            , test
                "Display width of emoji"
                (charWidth '😀' == 2)
            , test
                "Display width of emoji modifiers"
                (charWidth '\x1F3FB' == 0)
            , test
                "Display width of Hangul medial jamo"
                (charWidth '\x1161' == 0)
            , test
                "Display width of fullwidth forms"
                (charWidth '\xFF21' == 2)
            , test
                "Line editor inserts at the end"
                (applyLineKey (LineInsert 'c') (LineState "ab" 2) == LineState "abc" 3)
            , test
                "Line editor inserts in the middle"
                (applyLineKey (LineInsert 'b') (LineState "ac" 1) == LineState "abc" 2)
            , test
                "Line editor inserts at the start"
                (applyLineKey (LineInsert 'a') (LineState "bc" 0) == LineState "abc" 1)
            , test
                "Line editor backspace removes the previous character"
                (applyLineKey LineBackspace (LineState "abc" 2) == LineState "ac" 1)
            , test
                "Line editor backspace at the start is a no-op"
                (applyLineKey LineBackspace (LineState "abc" 0) == LineState "abc" 0)
            , test
                "Line editor delete removes the character at the cursor"
                (applyLineKey LineDelete (LineState "abc" 1) == LineState "ac" 1)
            , test
                "Line editor delete at the end is a no-op"
                (applyLineKey LineDelete (LineState "abc" 3) == LineState "abc" 3)
            , test
                "Line editor movement stops at the buffer boundaries"
                ( applyLineKey LineMoveLeft (LineState "ab" 0) == LineState "ab" 0
                    && applyLineKey LineMoveRight (LineState "ab" 2) == LineState "ab" 2
                )
            , test
                "Line editor moves home and end"
                ( lineCursor (applyLineKey LineMoveHome (LineState "ab" 2)) == 0
                    && lineCursor (applyLineKey LineMoveEnd (LineState "ab" 0)) == 2
                )
            , test
                "Line editor ignores non-printable characters"
                (applyLineKey (LineInsert '\t') (LineState "a" 1) == LineState "a" 1)
            , test
                "Line window shows text that fits"
                (visibleLine 10 (LineState "abc" 3) == ("abc", 3))
            , test
                "Line window scrolls to keep the cursor visible"
                (visibleLine 5 (LineState "abcdef" 6) == ("cdef", 4))
            , test
                "Line window keeps wide characters aligned"
                (visibleLine 5 (LineState "漢漢漢" 3) == ("漢漢", 4))
            , test
                "Line window keeps combining marks attached"
                (visibleLine 5 (LineState "e\x0301x" 3) == ("e\x0301x", 2))
            , test
                "Line window keeps the cursor at the start"
                (visibleLine 5 (LineState "abcde" 0) == ("abcd", 0))
            , test
                "Line window of an empty buffer"
                (visibleLine 5 (LineState "" 0) == ("", 0))
            , test
                "Prompt without an initial value has no buffer"
                (isNothing (promptInitial (promptAt 0 0 0)))
            , test
                "Prompt with an initial value removes non-printable characters"
                (promptInitial (promptWithInitial 0 0 0 "a\tb\nc") == Just "abc")
            , testIO "Render printer without styling" $ do
                out <-
                    renderPrinter
                        (printerItem (item "plain" (bold red)))
                        (settings [neverColors])
                return $ out == "plain\n"
            , testIO "Page renders to a string" $ do
                let p = page [section [printerLeft 0 (blockSimple "rendered" styleDefault)]]
                out <- renderPage p (settings [width 20, neverColors])
                return $ "rendered" `isInfixOf` out
            , testIO "Formatted table aligns and truncates columns" $ do
                let tbl =
                        tableSimple
                            [ blockSimple "Name" styleDefault
                            , blockSimple "Age" styleDefault
                            ]
                            styleDefault
                            [ ["Alexandra", "7"]
                            , ["Bo", "42"]
                            ]
                    fmt =
                        tableFormat
                            [ defaultColumnSpec
                                { columnMaxWidth = Just 4
                                , columnEllipsis = EllipsisChar '.'
                                }
                            , defaultColumnSpec{columnAlign = AlignRight}
                            ]
                out <-
                    renderPrinter
                        (printerTableFormat fmt 0 0 tbl)
                        (settings [width 30, neverColors])
                return $ all (`isInfixOf` out) ["Ale.", "Bo  ", "  7", " 42"]
            , testIO "Formatted table centers columns" $ do
                let tbl =
                        tableSimple
                            [blockSimple "X" styleDefault]
                            styleDefault
                            [["ab"], ["abcd"]]
                    fmt =
                        tableFormat
                            [defaultColumnSpec{columnAlign = AlignCenter}]
                out <-
                    renderPrinter
                        (printerTableFormat fmt 0 0 tbl)
                        (settings [width 20, neverColors])
                return $ " ab " `isInfixOf` out
            , testIO "Truncated table styles the ellipsis like the last item" $ do
                let cell =
                        block
                            [ item "AB" (bold red)
                            , item "C" (italic blue)
                            ]
                    tbl =
                        tableBlocks
                            [blockSimple "H" styleDefault]
                            [[cell]]
                    fmt =
                        tableFormat
                            [ defaultColumnSpec
                                { columnMaxWidth = Just 2
                                , columnEllipsis = EllipsisChar '.'
                                }
                            ]
                out <-
                    renderPrinter
                        (printerTableFormat fmt 0 0 tbl)
                        (settings [width 20, alwaysColors])
                return $ "." `isInfixOf` out && ";3;" `isInfixOf` out
            , testIO "Evenly spaced tables render" $ do
                let tbl =
                        tableSimple
                            [ blockSimple "A" styleDefault
                            , blockSimple "B" styleDefault
                            ]
                            styleDefault
                            [["1", "2"]]
                out <-
                    renderPrinter
                        (printerTable' 0 0 tbl)
                        (settings [width 30, neverColors])
                return $ all (`isInfixOf` out) ["A", "B", "1", "2"]
            , testIO "Render preserves non-ASCII text" $ do
                out <-
                    renderPrinter
                        (printerItem (item "ação 漢" styleDefault))
                        (settings [neverColors])
                return $ "ação 漢" `isInfixOf` out
            , testIO "Bordered table draws a box" $ do
                let tbl =
                        tableSimple
                            [ blockSimple "A" styleDefault
                            , blockSimple "B" styleDefault
                            ]
                            styleDefault
                            [["x", "y"]]
                out <-
                    renderPrinter
                        (printerTableBordered BordersLight defaultTableFormat 0 0 tbl)
                        (settings [width 40, neverColors])
                return $ all (`isInfixOf` out) ["┌", "│", "└", "x", "y"]
            , testIO "Bordered groups pad unequal columns" $ do
                let tall =
                        groupSimple
                            (blockSimple "A" styleDefault)
                            [ blockSimple "1" styleDefault
                            , blockSimple "2" styleDefault
                            ]
                    short = groupSimple (blockSimple "B" styleDefault) []
                out <-
                    renderPrinter
                        (printerGroupsBordered BordersAscii 0 0 [tall, short])
                        (settings [width 30, neverColors])
                let outputLines = lines out
                    allSameWidth = case outputLines of
                        [] -> False
                        (firstLine : _) -> all ((== length firstLine) . length) outputLines
                return $ length outputLines == 7 && allSameWidth
            , testIO "BordersNone keeps tall tables in one borderless block" $ do
                let long = replicate 10 'A'
                    tall =
                        groupSimple
                            (blockSimple long styleDefault)
                            [ blockSimple "1" styleDefault
                            , blockSimple "2" styleDefault
                            ]
                    short = groupSimple (blockSimple "B" styleDefault) []
                out <-
                    renderPrinter
                        (printerGroupsBordered BordersNone 0 0 [tall, short])
                        (settings [width 15, neverColors])
                let outputLines = lines out
                    allSameWidth = case outputLines of
                        [] -> False
                        (firstLine : _) -> all ((== length firstLine) . length) outputLines
                return $
                    length outputLines == 3
                        && allSameWidth
                        && (long ++ "  B") `isInfixOf` out
                        && not (any (`elem` "+|") out)
            , testIO "Form rejects a prompt outside the page" $ do
                let p = page [section [printerLeft 0 (blockSimple "one" styleDefault)]]
                    prompt = promptAt 9 0 0
                (result, _) <- captureStdout $ do
                    st <- start p (settings [neverColors])
                    (_, formResult) <- readForm p [prompt] st
                    return formResult
                return $ result == Left (PromptOutsidePage prompt)
            , testIO "Form reads prompts in order" $ do
                let p =
                        page
                            [ section
                                [ printerLeft 0 (blockSimple "first" styleDefault)
                                , printerLeft 0 (blockSimple "second" styleDefault)
                                ]
                            ]
                    prompts = [promptAt 0 0 7, promptAt 0 1 8]
                (result, _) <- withStdin "Ada\n42\n" $ captureStdout $ do
                    st <- start p (settings [neverColors])
                    (_, formResult) <- readForm p prompts st
                    return formResult
                return $ result == Right ["Ada", "42"]
            , testIO "Form ignores initial values when stdin is not a terminal" $ do
                let p =
                        page
                            [ section
                                [ printerLeft 0 (blockSimple "first" styleDefault)
                                , printerLeft 0 (blockSimple "second" styleDefault)
                                ]
                            ]
                    prompts =
                        [ promptWithInitial 0 0 7 "old"
                        , promptWithInitial 0 1 8 "note"
                        ]
                (result, _) <- withStdin "Ada\n42\n" $ captureStdout $ do
                    st <- start p (settings [neverColors])
                    (_, formResult) <- readForm p prompts st
                    return formResult
                return $ result == Right ["Ada", "42"]
            , testIO "Shortcut reader returns a plain key" $ do
                result <- withStdin "x" readKeyPress
                return $ result == Just 'x'
            , testIO "Shortcut reader ignores arrow escape sequences" $ do
                result <- withStdin "\ESC[Aq" readKeyPress
                return $ result == Just 'q'
            , testIO "Shortcut reader ignores application cursor sequences" $ do
                result <- withStdin "\ESCOBr" readKeyPress
                return $ result == Just 'r'
            , testIO "Shortcut reader ignores parameterized sequences" $ do
                result <- withStdin "\ESC[1;5Bz" readKeyPress
                return $ result == Just 'z'
            , testIO "Shortcut reader reports end of input" $ do
                result <- withStdin "" readKeyPress
                return $ isNothing result
            , testIO "Raw key reader returns escape sequence characters" $ do
                result <- withStdin "\ESC[A" (sequence [readKey, readKey, readKey])
                return $ result == [Just '\ESC', Just '[', Just 'A']
            , testIO "Wide text wraps by display width" $ do
                (_, out) <-
                    captureStdout $
                        runPrinter
                            (settings [width 5, neverColors])
                            (printerParagraph 0 0 [blockSimple "漢漢 漢漢" styleDefault])
                return $ length (filter (== '\n') out) == 2
            , testIO "Styles are suppressed when colors are never" $ do
                (_, out) <-
                    captureStdout $
                        runPrinter (settings [neverColors]) (printerItem (item "plain" (bold red)))
                return $ '\ESC' `notElem` out && "plain" `isInfixOf` out
            , testIO "Styles are emitted when colors are always" $ do
                (_, out) <-
                    captureStdout $
                        runPrinter (settings [alwaysColors]) (printerItem (item "styled" (bold red)))
                return $ '\ESC' `elem` out && "styled" `isInfixOf` out
            ]
    propertyResults <- sequence propertyTests
    goldenResults <- sequence goldenTests
    unless (and (results ++ propertyResults ++ goldenResults)) exitFailure
    putStrLn "All tests passed."

test :: String -> Bool -> IO Bool
test name passed = do
    putStrLn ((if passed then "ok   " else "FAIL ") ++ name)
    return passed

testIO :: String -> IO Bool -> IO Bool
testIO name action = action >>= test name

testQuickCheck :: String -> Property -> IO Bool
testQuickCheck name prop = do
    result <- quickCheckWithResult args prop
    let passed = isSuccess result
    putStrLn ((if passed then "ok   " else "FAIL ") ++ name)
    unless passed $ putStr (output result)
    return passed
  where
    args =
        stdArgs
            { replay = Just (mkQCGen 42, 0)
            , maxSuccess = 100
            , chatty = False
            }

propertyTests :: [IO Bool]
propertyTests =
    [ testQuickCheck
        "Display width is additive"
        ( property $ \a b ->
            textWidth (a ++ b) == textWidth (a :: String) + textWidth b
        )
    , testQuickCheck
        "Display width is non-negative"
        (property $ \s -> textWidth (s :: String) >= 0)
    , testQuickCheck
        "Line editor keeps the cursor in range"
        ( forAll genLineKey $ \key ->
            forAll arbitrary $ \text ->
                forAll arbitrary $ \cursor ->
                    let next = applyLineKey key (LineState text cursor)
                     in lineCursor next >= 0
                            && lineCursor next <= length (lineText next)
        )
    , testQuickCheck
        "Line editor changes at most one character"
        ( forAll genLineKey $ \key ->
            forAll arbitrary $ \text ->
                forAll arbitrary $ \cursor ->
                    let next = applyLineKey key (LineState text cursor)
                     in abs (length (lineText next) - length text) <= 1
        )
    , testQuickCheck
        "Line movement leaves the text unchanged"
        ( forAll (elements [LineMoveLeft, LineMoveRight, LineMoveHome, LineMoveEnd]) $ \key ->
            forAll arbitrary $ \text ->
                let next = applyLineKey key (LineState text (length text))
                 in lineText next == text
        )
    , testQuickCheck
        "Printable insertion adds one character"
        ( forAll (choose ('a', 'z')) $ \c ->
            forAll arbitrary $ \text ->
                let next = applyLineKey (LineInsert c) (LineState text (length text))
                 in length (lineText next) == length text + 1
        )
    , testQuickCheck
        "Non-printable insertion is ignored"
        ( forAll (elements ['\t', '\n', '\DEL']) $ \c ->
            forAll arbitrary $ \text ->
                let next = applyLineKey (LineInsert c) (LineState text (length text))
                 in lineText next == text
        )
    , testQuickCheck
        "Visible line fits the available width"
        ( forAll (choose (1, 40)) $ \availableWidth ->
            forAll arbitrary $ \text ->
                forAll arbitrary $ \cursor ->
                    let (window, offset) = visibleLine availableWidth (LineState text cursor)
                     in textWidth window <= max 1 (availableWidth - 1)
                            && offset >= 0
                            && offset <= textWidth window
        )
    , testQuickCheck
        "Block tables accept exactly balanced rows"
        ( forAll (listOf genBlock) $ \headerBlocks ->
            forAll (listOf (listOf genBlock)) $ \rows ->
                isJust (tableBlocks headerBlocks rows)
                    == all ((== length headerBlocks) . length) rows
        )
    , testQuickCheck
        "Simple tables accept exactly balanced rows"
        ( forAll (listOf genBlock) $ \headerBlocks ->
            forAll (listOf (listOf arbitrary)) $ \rows ->
                isJust (tableSimple headerBlocks styleDefault rows)
                    == all ((== length headerBlocks) . length) rows
        )
    , testQuickCheck
        "Group tables accept groups of equal height"
        ( forAll (listOf1 (choose (0, 5))) $ \heights ->
            let groups = fmap genGroupOfHeight heights
             in case heights of
                    [] -> property False
                    (firstHeight : rest) ->
                        property $
                            isJust (tableGroups groups)
                                == all (== firstHeight) rest
        )
    , testQuickCheck
        "Number caps negative input"
        (property $ \n -> unNumber (formNumber n) == max 0 (n :: Int))
    , testQuickCheck
        "Checked subtraction is exact"
        ( forAll (choose (0, 1000)) $ \a ->
            forAll (choose (0, 1000)) $ \b ->
                let x = formNumber (a :: Int)
                    y = formNumber b
                 in case subtractNumberMaybe x y of
                        Nothing -> unNumber x < unNumber y
                        Just d -> unNumber d == unNumber x - unNumber y
        )
    , testQuickCheck
        "Paragraph lines fit the width"
        ( forAll (choose (10, 40)) $ \lineWidth ->
            forAll (resize 4 (listOf1 (listOf1 (choose ('a', 'z'))))) $ \wordList ->
                ioProperty $ do
                    out <-
                        renderPrinter
                            (printerParagraph 0 0 [blockSimple (unwords wordList) styleDefault])
                            (settings [width (formNumber lineWidth), neverColors])
                    return $ all (\line -> textWidth line <= lineWidth) (lines (stripCsi out))
        )
    ]

genLineKey :: Gen LineKey
genLineKey =
    oneof
        [ LineInsert <$> arbitrary
        , pure LineBackspace
        , pure LineDelete
        , pure LineMoveLeft
        , pure LineMoveRight
        , pure LineMoveHome
        , pure LineMoveEnd
        ]

genBlock :: Gen Block
genBlock = blockSimple <$> arbitrary <*> pure styleDefault

genGroupOfHeight :: Int -> Group
genGroupOfHeight height =
    groupSimple
        (blockSimple "header" styleDefault)
        (replicate height (blockSimple "body" styleDefault))

goldenTests :: [IO Bool]
goldenTests =
    [ goldenTest
        "Paragraph wraps at the width"
        ( renderPrinter
            (printerParagraph 0 0 [blockSimple "one two three four five" styleDefault])
            (settings [width 12, neverColors])
        )
        "one two \nthree four \nfive\n"
    , goldenTest
        "Unicode paragraph keeps wide and combining characters"
        ( renderPrinter
            (printerParagraph 0 0 [blockSimple "漢漢 e\x0301 漢" styleDefault])
            (settings [width 8, neverColors])
        )
        "漢漢 e\x0301 \n漢\n"
    , goldenTest
        "Bordered groups pad the shorter column"
        ( renderPrinter
            ( printerGroupsBordered
                BordersAscii
                0
                0
                [ groupSimple
                    (blockSimple "A" styleDefault)
                    [ blockSimple "1" styleDefault
                    , blockSimple "2" styleDefault
                    ]
                , groupSimple (blockSimple "B" styleDefault) []
                ]
            )
            (settings [width 32, neverColors])
        )
        "+-+-+\n|A|B|\n+-+-+\n|1| |\n+-+-+\n|2| |\n+-+-+\n"
    , goldenTest
        "Page renders a rule and a body line"
        ( renderPage
            ( page
                [ section [printerRule (rule '-' styleDefault)]
                , section [printerLeft 0 (blockSimple "body" styleDefault)]
                ]
            )
            (settings [width 20, neverColors])
        )
        "--------------------\nbody\n"
    ]

goldenTest :: String -> IO String -> String -> IO Bool
goldenTest name render expected = do
    actual <- render
    let normalized = stripCsi actual
        passed = normalized == expected
    putStrLn ((if passed then "ok   " else "FAIL ") ++ "Golden: " ++ name)
    unless passed $ do
        putStrLn "--- expected"
        putStr expected
        putStrLn "--- actual"
        putStr normalized
    return passed

-- Removes the cursor movement sequences that the drawing layer emits even
-- when styling is disabled, so a golden output compares only the layout.
stripCsi :: String -> String
stripCsi [] = []
stripCsi ('\ESC' : '[' : rest) = stripCsi (dropFinal rest)
  where
    dropFinal [] = []
    dropFinal (c : cs)
        | c >= '@' && c <= '~' = cs
        | otherwise = dropFinal cs
stripCsi (c : cs) = c : stripCsi cs

-- Runs an action with stdout redirected to a temporary file and returns
-- the captured output.
captureStdout :: IO a -> IO (a, String)
captureStdout action = do
    tmp <- getTemporaryDirectory
    bracket (openTempFile tmp "ansiform-test-output") cleanup $ \(path, handle) -> do
        original <- hDuplicate stdout
        result <-
            ( do
                hDuplicateTo handle stdout
                value <- action
                hFlush stdout
                return value
            )
                `finally` (hDuplicateTo original stdout >> hClose original)
        hClose handle
        captured <- readFile' path
        return (result, captured)
  where
    cleanup (path, handle) = do
        hClose handle
        removeFile path

-- Runs an action with stdin replaced by a temporary file containing the input.
withStdin :: String -> IO a -> IO a
withStdin input action = do
    tmp <- getTemporaryDirectory
    bracket (openTempFile tmp "ansiform-test-input") cleanup $ \(_path, handle) -> do
        hPutStr handle input
        hFlush handle
        hSeek handle AbsoluteSeek 0
        original <- hDuplicate stdin
        hDuplicateTo handle stdin
        action `finally` (hDuplicateTo original stdin >> hClose original)
  where
    cleanup (path, handle) = do
        hClose handle
        removeFile path

--------------------------------------------------------------------------------
-- Fixtures
--------------------------------------------------------------------------------

header :: [Block]
header =
    [ blockSimple "A" styleDefault
    , blockSimple "B" styleDefault
    ]

row :: [Block]
row =
    [ blockSimple "1" styleDefault
    , blockSimple "2" styleDefault
    ]

balancedGroup, otherBalancedGroup, shortGroup :: Group
balancedGroup = groupSimple (blockSimple "Header" styleDefault) [rowBlock]
otherBalancedGroup = groupSimple (blockSimple "Header" styleDefault) [rowBlock]
shortGroup = groupSimple (blockSimple "Header" styleDefault) []

rowBlock :: Block
rowBlock = blockSimple "value" styleDefault

oldPage :: Page
oldPage = page [oldSection, keptSection]

oldSection, keptSection, newSection :: Section
oldSection = section [printerLeft 0 (blockSimple "old" styleDefault)]
keptSection = section [printerCenter 0 (blockSimple "kept" styleDefault)]
newSection = section [printerRight 0 (blockSimple "new" styleDefault)]
