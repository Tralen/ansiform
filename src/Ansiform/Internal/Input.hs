-- | Immediate single-key input and line input for interactive interfaces.
module Ansiform.Internal.Input (withImmediateInput, readKey, withLineInput, readLine,
                                readLineAt, readLineAtOn,
                                Prompt, promptAt, promptWithInitial,
                                promptSection, promptRow, promptColumn, promptInitial,
                                FormError(..), readForm, readFormOn) where

--------------------------------------------------------------------------------
import           Control.Exception (bracket_)
import           Control.Monad (when)
import           Data.Char (isPrint)
import           Data.Maybe (isJust)
import           System.Console.ANSI (hClearFromCursorToLineEnd, hCursorDown,
                                      hCursorUp, hSetCursorColumn)
import           System.IO (BufferMode (..), Handle, hFlush, hGetBuffering,
                            hGetEcho, hIsTerminalDevice, hPutStr, hSetBuffering,
                            hSetEcho, isEOF, stdin, stdout)
import           System.Timeout (timeout)
import           Ansiform.Draw (drawOn)
import           Ansiform.Internal.Line
import           Ansiform.Internal.Number
import           Ansiform.Internal.Page
import           Ansiform.Internal.State
import           Ansiform.Internal.Terminal (termWOn)
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
    , promptInitial :: Maybe String
      -- ^ Optional initial value read by the line editor.
    } deriving (Eq, Show)

-- | Builds a prompt from a zero-based section index, a zero-based row inside
--   that section and an absolute column. A prompt row is easier to keep
--   correct than the number of lines below the prompt, and it survives
--   changes to the other sections of the page.
promptAt :: Number -> Number -> Offset -> Prompt
promptAt section row column = Prompt section row column Nothing

-- | Builds a prompt that opens with an editable initial value.
--   Non-printable characters are removed, because the editor is single-line.
--   An empty initial value is still meaningful: it opens the line editor with
--   an empty buffer instead of falling back to the terminal line discipline.
promptWithInitial :: Number -> Number -> Offset -> String -> Prompt
promptWithInitial section row column initial =
    Prompt section row column (Just (filter isPrint initial))

-- | Why a form could not be completed.
data FormError
    = PromptOutsidePage Prompt
    | FormInputEnded
    | FormCancelled
    deriving (Eq, Show)

-- | Draws a page and reads one line for every prompt, in the order given.
--   The function computes the cursor movement from the line counts recorded
--   by the draw, so callers do not count the lines below each prompt.
--   Prompts without an initial value are read with 'readLine', and line input
--   is enabled once for the whole form, without nesting 'withLineInput'.
--   Prompts built with 'promptWithInitial' use the Ansiform line editor when
--   stdin is a terminal, so the value can be changed in place. When stdin is
--   not a terminal, they fall back to 'readLine' and ignore the initial value.
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
            interactive <- hIsTerminalDevice stdin
            let useEditor = interactive && any (isJust . promptInitial) prompts
                fields = zip lines' prompts
                readFields = if useEditor
                    then readEditorFields h total fields
                    else withLineInput (readPlainFields h total fields)
            values <- readFields
            return (st', values)

-- Reads prompts through the terminal line discipline.
readPlainFields :: Handle -> Int -> [(Int, Prompt)] -> IO (Either FormError [String])
readPlainFields _ _ [] = return (Right [])
readPlainFields h current ((line,prompt):rest) = do
    moveCursorBy h (line - current) (promptColumn prompt)
    value <- readLine
    case value of
        Nothing -> return (Left FormInputEnded)
        Just v -> fmap (fmap (v:)) (readPlainFields h (line + 1) rest)

-- Reads prompts in order, choosing the line editor or the line discipline.
readEditorFields :: Handle -> Int -> [(Int, Prompt)] -> IO (Either FormError [String])
readEditorFields _ _ [] = return (Right [])
readEditorFields h current ((line,prompt):rest) = do
    moveCursorBy h (line - current) (promptColumn prompt)
    value <- case promptInitial prompt of
        Nothing -> fmap (maybe (Left FormInputEnded) Right) (withLineInput readLine)
        Just initial ->
            withImmediateInput (readLineEditor h (promptColumn prompt) initial)
    case value of
        Left err -> return (Left err)
        Right v -> fmap (fmap (v:)) (readEditorFields h (line + 1) rest)

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


-- Line Editor
--------------------------------------------------------------------------------

-- | One decoded key press for the line editor.
data LineEvent = LineSubmit | LineCancel | LineEdit LineKey | LineIgnore

-- | Delay in microseconds used to tell a lone Escape from an escape sequence.
escapeDelay :: Int
escapeDelay = 50000

-- | Reads one field with an editable initial value.
--   When stdin is not a terminal the initial value is ignored and a regular
--   line is read, keeping non-interactive consumers neutral. The caller is
--   responsible for the immediate input mode of the interactive branch.
readLineEditor :: Handle -> Offset -> String -> IO (Either FormError String)
readLineEditor h column initial = do
    interactive <- hIsTerminalDevice stdin
    if not interactive
        then fmap (maybe (Left FormInputEnded) Right) readLine
        else do
            width <- termWOn h
            let start = LineState initial (length initial)
            redrawLine h width column start
            editLoop h width column start

-- Applies decoded keys until the field is submitted, cancelled or input ends.
editLoop :: Handle -> Int -> Offset -> LineState -> IO (Either FormError String)
editLoop h width column state = do
    event <- readLineEvent
    case event of
        Nothing -> return (Left FormInputEnded)
        Just LineCancel -> do
            newline h
            return (Left FormCancelled)
        Just LineSubmit -> do
            newline h
            return (Right (lineText state))
        Just (LineEdit key) -> do
            let next = applyLineKey key state
            redrawLine h width column next
            editLoop h width column next
        Just LineIgnore -> editLoop h width column state

-- Moves to the prompt column, draws the visible window and clears the rest of
-- the line, then places the cursor at its display offset.
redrawLine :: Handle -> Int -> Offset -> LineState -> IO ()
redrawLine h width column state = do
    let available = max 0 (width - unn column)
        (window, cursorOffset) = visibleLine available state
    hSetCursorColumn h (unn column)
    hPutStr h window
    hClearFromCursorToLineEnd h
    hSetCursorColumn h (unn column + cursorOffset)
    hFlush h

newline :: Handle -> IO ()
newline h = hPutStr h "\n" >> hFlush h

-- Decodes one key press, reading escape sequences with a short timeout.
readLineEvent :: IO (Maybe LineEvent)
readLineEvent = do
    key <- readKey
    case key of
        Nothing -> return Nothing
        Just '\r' -> return (Just LineSubmit)
        Just '\n' -> return (Just LineSubmit)
        Just '\DEL' -> return (Just (LineEdit LineBackspace))
        Just '\b' -> return (Just (LineEdit LineBackspace))
        Just '\ESC' -> readEscapeSequence
        Just c
            | isPrint c -> return (Just (LineEdit (LineInsert c)))
            | otherwise -> return (Just LineIgnore)

-- A lone Escape cancels; a bracket starts a control sequence.
readEscapeSequence :: IO (Maybe LineEvent)
readEscapeSequence = do
    next <- timeout escapeDelay readKey
    case next of
        Nothing -> return (Just LineCancel)
        Just Nothing -> return Nothing
        Just (Just '[') -> readControlSequence
        Just (Just _) -> return (Just LineIgnore)

-- Decodes the final byte of a CSI sequence. Unknown sequences are ignored.
readControlSequence :: IO (Maybe LineEvent)
readControlSequence = do
    next <- timeout escapeDelay readKey
    case next of
        Nothing -> return (Just LineIgnore)
        Just Nothing -> return Nothing
        Just (Just c) -> case c of
            'D' -> return (Just (LineEdit LineMoveLeft))
            'C' -> return (Just (LineEdit LineMoveRight))
            'H' -> return (Just (LineEdit LineMoveHome))
            'F' -> return (Just (LineEdit LineMoveEnd))
            '1' -> readTildeSequence LineMoveHome
            '4' -> readTildeSequence LineMoveEnd
            '3' -> readTildeSequence LineDelete
            _ -> return (Just LineIgnore)

-- Reads the final tilde of a numbered CSI sequence.
readTildeSequence :: LineKey -> IO (Maybe LineEvent)
readTildeSequence key = do
    next <- timeout escapeDelay readKey
    case next of
        Nothing -> return (Just LineIgnore)
        Just Nothing -> return Nothing
        Just (Just '~') -> return (Just (LineEdit key))
        Just (Just _) -> return (Just LineIgnore)
