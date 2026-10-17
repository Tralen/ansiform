-- | Small regression suite for the pure core of the library.
module Main where

import           Control.Monad (unless)
import           Data.List (isInfixOf)
import           Data.Maybe (isJust, isNothing)
import           GHC.IO.Handle (hDuplicate, hDuplicateTo)
import           System.Directory (getTemporaryDirectory, removeFile)
import           System.Exit (exitFailure)
import           System.IO (hClose, hFlush, openTempFile, stdout)
import           Ansiform

main :: IO ()
main = do
  results <- sequence
    [ test "Number caps negative values"
        (unNumber (formNumber (-7)) == 0)
    , test "Number keeps positive values"
        (unNumber (formNumber 12) == 12)
    , test "Number addition"
        (unNumber (3 + 4 :: Number) == 7)
    , test "Number subtraction caps at zero"
        (unNumber (2 - 5 :: Number) == 0)
    , test "Number negation caps at zero"
        (unNumber (negate (5 :: Number)) == 0)
    , test "Number signum"
        (unNumber (signum (0 :: Number)) == 0
          && unNumber (signum (5 :: Number)) == 1)
    , test "Balanced block table is accepted"
        (isJust (tableBlocks header [row]))
    , test "Unbalanced block table is rejected"
        (isNothing (tableBlocks header [[blockSimple "only" styleDefault]]))
    , test "Balanced simple table is accepted"
        (isJust (tableSimple header styleDefault [["a", "b"]]))
    , test "Unbalanced simple table is rejected"
        (isNothing (tableSimple header styleDefault [["a"]]))
    , test "Balanced group table is accepted"
        (isJust (tableGroups [balancedGroup, otherBalancedGroup]))
    , test "Unbalanced group table is rejected"
        (isNothing (tableGroups [balancedGroup, shortGroup]))
    , test "Items are stripped of non-printable characters"
        (let out = sampleShow 0 (item "a\tb\nc" styleDefault)
         in "\"abc\"" `isInfixOf` out
              && not ("\\" `isInfixOf` out))
    , test "Empty items are removed from blocks"
        (let out = sampleShow 0 (block [ item "" styleDefault
                                       , item "kept" styleDefault ])
         in "kept" `isInfixOf` out
              && not ("\"\"" `isInfixOf` out))
    , test "Composite block builder keeps its parts"
        (let out = sampleShow 0 (blockEnum "01" "Item" blue)
         in "01" `isInfixOf` out && "Item" `isInfixOf` out)
    , test "Page amendment replaces the selected section"
        (let replaced = amendPage' oldPage [newSection] 0
             out = sampleShow 0 replaced
         in "<Right>" `isInfixOf` out
              && not ("<Left>" `isInfixOf` out)
              && "<Center>" `isInfixOf` out)
    , testIO "Styles are suppressed when colors are never" $ do
        (_, out) <- captureStdout
          $ runPrinter (settings [neverColors]) (printerItem (item "plain" (bold red)))
        return $ '\ESC' `notElem` out && "plain" `isInfixOf` out
    , testIO "Styles are emitted when colors are always" $ do
        (_, out) <- captureStdout
          $ runPrinter (settings [alwaysColors]) (printerItem (item "styled" (bold red)))
        return $ '\ESC' `elem` out && "styled" `isInfixOf` out
    ]
  unless (and results) exitFailure
  putStrLn "All tests passed."

test :: String -> Bool -> IO Bool
test name passed = do
  putStrLn ((if passed then "ok   " else "FAIL ") ++ name)
  return passed

testIO :: String -> IO Bool -> IO Bool
testIO name action = action >>= test name

-- Runs an action with stdout redirected to a temporary file and returns
-- the captured output.
captureStdout :: IO a -> IO (a, String)
captureStdout action = do
  tmp <- getTemporaryDirectory
  (path, handle) <- openTempFile tmp "ansiform-test-output"
  original <- hDuplicate stdout
  hDuplicateTo handle stdout
  result <- action
  hFlush stdout
  hDuplicateTo original stdout
  hClose original
  hClose handle
  output <- readFile path
  removeFile path
  return (result, output)

--------------------------------------------------------------------------------
-- Fixtures
--------------------------------------------------------------------------------

header :: [Block]
header = [ blockSimple "A" styleDefault
         , blockSimple "B" styleDefault ]

row :: [Block]
row = [ blockSimple "1" styleDefault
      , blockSimple "2" styleDefault ]

balancedGroup, otherBalancedGroup, shortGroup :: Group
balancedGroup = groupSimple (blockSimple "Header" styleDefault) [rowBlock]
otherBalancedGroup = groupSimple (blockSimple "Header" styleDefault) [rowBlock]
shortGroup = groupSimple (blockSimple "Header" styleDefault) []

rowBlock :: Block
rowBlock = blockSimple "value" styleDefault

oldPage :: Page
oldPage = page [ oldSection, keptSection ]

oldSection, keptSection, newSection :: Section
oldSection = section [ printerLeft 0 (blockSimple "old" styleDefault) ]
keptSection = section [ printerCenter 0 (blockSimple "kept" styleDefault) ]
newSection = section [ printerRight 0 (blockSimple "new" styleDefault) ]
