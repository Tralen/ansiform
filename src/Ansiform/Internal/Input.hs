-- | Immediate single-key input and line input for interactive interfaces.
module Ansiform.Internal.Input (withImmediateInput, readKey, withLineInput, readLine,
                                readLineAt, readLineAtOn,
                                Prompt, promptAt, promptSection, promptRow, promptColumn,
                                FormError(..), readForm, readFormOn) where

--------------------------------------------------------------------------------
import           Control.Exception (bracket_)
import           Control.Monad (when)
import           System.Console.ANSI (hCursorUp, hCursorDown, hSetCursorColumn)
import           System.IO (BufferMode (..), Handle, hFlush, hGetBuffering,
                            hGetEcho, hIsTerminalDevice, hSetBuffering,
                            hSetEcho, isEOF, stdin, stdout)
import           Ansiform.Draw (drawOn)
import           Ansiform.Internal.Number
import           Ansiform.Internal.Page
import           Ansiform.Internal.State
import           Ansiform.Internal.Utils


-- Terminal Input
--------------------------------------------------------------------------------

-- | Runs an action with stdin configured for immediate single-key input.
--   Buffering and echo are changed only when stdin is a terminal,
--   and the original settings are restored when the action finishes.
withImmediateInput :: IO a -> IO a
withImmediateInput action = do
    interactive <- hIsTerminalDevice stdin
    oldBuffering <- hGetBuffering stdin
    oldEcho <- if interactive then hGetEcho stdin else return True
    let setup = when interactive $ do
                    hSetBuffering stdin NoBuffering
                    hSetEcho stdin False
        restore = when interactive $ do
                    hSetBuffering stdin oldBuffering
                    hSetEcho stdin oldEcho
    bracket_ setup restore action

-- | Reads one key without waiting for Enter.
--   Returns 'Nothing' at end of input.
readKey :: IO (Maybe Char)
readKey = do
    eof <- isEOF
    if eof then return Nothing else Just <$> getChar

-- | Runs an action with stdin configured for line input with echo.
--   This is useful for prompts that ask the user to type a value and press Enter.
withLineInput :: IO a -> IO a
withLineInput action = do
    interactive <- hIsTerminalDevice stdin
    oldBuffering <- hGetBuffering stdin
    oldEcho <- if interactive then hGetEcho stdin else return True
    let setup = when interactive $ do
                    hSetBuffering stdin LineBuffering
                    hSetEcho stdin True
        restore = when interactive $ do
                    hSetBuffering stdin oldBuffering
                    hSetEcho stdin oldEcho
    bracket_ setup restore action

-- | Reads one line, including the newline consumed by 'getLine'.
--   Returns 'Nothing' at end of input.
readLine :: IO (Maybe String)
readLine = do
    eof <- isEOF
    if eof then return Nothing else Just <$> getLine

-- | Reads one line with echo after moving the cursor up and to a column.
--   The first argument is the number of lines to move up from the current
--   position; the second is the absolute column. This places the input on
--   a prompt line that has other printed lines below it.
--   This function already wraps 'withLineInput'; wrapping it again changes
--   the terminal mode twice and can leave echo or buffering in the wrong
--   state. Use it directly, or use 'readForm' for several prompts.
readLineAt :: Number -> Offset -> IO (Maybe String)
readLineAt = readLineAtOn stdout

-- | Version of 'readLineAt' that moves the cursor on a given handle.
--   Cursor movement happens only when stdin is a terminal, matching
--   'withLineInput'. Like 'readLineAt', this function already wraps
--   'withLineInput'; do not wrap it again.
readLineAtOn :: Handle -> Number -> Offset -> IO (Maybe String)
readLineAtOn h up column = do
    moveCursorBy h (negate (unn up)) column
    withLineInput readLine


-- Page Forms
--------------------------------------------------------------------------------

-- | A line prompt placed in a section of a page.
data Prompt = Prompt
    { promptSection :: Number
      -- ^ Zero-based section index.
    , promptRow :: Number
      -- ^ Zero-based row inside the section.
    , promptColumn :: Offset
      -- ^ Absolute column where typing starts.
    } deriving (Eq, Show)

-- | Builds a prompt from a zero-based section index, a zero-based row inside
--   that section and an absolute column. A prompt row is easier to keep
--   correct than the number of lines below the prompt, and it survives
--   changes to the other sections of the page.
promptAt :: Number -> Number -> Offset -> Prompt
promptAt = Prompt

-- | Why a form could not be completed.
data FormError
    = PromptOutsidePage Prompt
    | FormInputEnded
    deriving (Eq, Show)

-- | Draws a page and reads one line for every prompt, in the order given.
--   The function computes the cursor movement from the line counts recorded
--   by the draw, so callers do not count the lines below each prompt.
--   Line input is enabled once for the whole form and prompts are read with
--   echo, without nesting 'withLineInput'.
--   Returns the state from drawing the page and either the values or the
--   reason the form stopped. A prompt outside the page fails before any input
--   is read.
readForm :: Page -> [Prompt] -> State -> IO (State, Either FormError [String])
readForm = readFormOn stdout

-- | Version of 'readForm' that draws the page on a given handle.
readFormOn :: Handle -> Page -> [Prompt] -> State -> IO (State, Either FormError [String])
readFormOn h p prompts st = do
    st' <- drawOn h p st
    let counts = fmap unNumber (unStateResults st')
        total = sum counts
        placed = traverse (promptLine counts) prompts
    case placed of
        Left bad -> return (st', Left (PromptOutsidePage bad))
        Right lines' -> do
            values <- withLineInput $ readAll total (zip lines' prompts)
            return (st', maybe (Left FormInputEnded) Right values)
  where
    readAll _ [] = return (Just [])
    readAll current ((line,prompt):rest) = do
        moveCursorBy h (line - current) (promptColumn prompt)
        value <- readLine
        case value of
            Nothing -> return Nothing
            Just v -> fmap (fmap (v:)) (readAll (line + 1) rest)

-- Converts a section and row to an absolute page line.
promptLine :: [Int] -> Prompt -> Either Prompt Int
promptLine counts p = case atMay counts section of
    Nothing -> Left p
    Just sectionLines
        | row < sectionLines -> Right (sum (take section counts) + row)
        | otherwise -> Left p
  where
    section = unNumber (promptSection p)
    row = unNumber (promptRow p)

-- Moves the cursor by a number of rows and sets an absolute column.
moveCursorBy :: Handle -> Int -> Offset -> IO ()
moveCursorBy h delta column = do
    interactive <- hIsTerminalDevice stdin
    when interactive $ do
        when (delta > 0) $ hCursorDown h delta
        when (delta < 0) $ hCursorUp h (negate delta)
        hSetCursorColumn h (unn column)
        hFlush h
