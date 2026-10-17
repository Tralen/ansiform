-- | Immediate single-key input for interactive interfaces.
module Ansiform.Internal.Input (withImmediateInput, readKey, withLineInput, readLine,
                                readLineAt, readLineAtOn) where

--------------------------------------------------------------------------------
import           Control.Exception (bracket_)
import           Control.Monad (when)
import           System.Console.ANSI (hCursorUp, hSetCursorColumn)
import           System.IO (BufferMode (..), Handle, hFlush, hGetBuffering,
                            hGetEcho, hIsTerminalDevice, hSetBuffering,
                            hSetEcho, isEOF, stdin, stdout)
import           Ansiform.Internal.Number


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
readLineAt :: Number -> Offset -> IO (Maybe String)
readLineAt = readLineAtOn stdout

-- | Version of 'readLineAt' that moves the cursor on a given handle.
--   Cursor movement happens only when stdin is a terminal, matching
--   'withLineInput'.
readLineAtOn :: Handle -> Number -> Offset -> IO (Maybe String)
readLineAtOn h up column = do
    interactive <- hIsTerminalDevice stdin
    when interactive $ do
        hCursorUp h (unn up)
        hSetCursorColumn h (unn column)
        hFlush h
    withLineInput readLine
