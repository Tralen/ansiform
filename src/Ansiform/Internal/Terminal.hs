-- | Internal terminal cursor and size helpers.
module Ansiform.Internal.Terminal
    ( module Ansiform.Internal.Terminal
    , ANSI.cursorUp
    , ANSI.cursorDown
    , ANSI.hCursorUp
    , ANSI.hCursorDown
    ) where

import Ansiform.Internal.Number
--------------------------------------------------------------------------------
import System.Console.ANSI as ANSI
import System.Console.Terminal.Size
import System.IO (Handle, hIsTerminalDevice, stdout)

-- Indentation
--------------------------------------------------------------------------------

-- Places the cursor at an absolute indentation level.
ind :: Handle -> Offset -> IO ()
ind h = indR h . unn

-- Places the cursor at a relative indentation level.
ind' :: Handle -> Offset -> IO ()
ind' h = indR' h . unn

-- Places the cursor at an absolute indentation level, raw version.
indR :: Handle -> Int -> IO ()
indR = hSetCursorColumn

-- Places the cursor at a relative indentation level, raw version.
indR' :: Handle -> Int -> IO ()
indR' = hCursorForward

-- Clear
--------------------------------------------------------------------------------

-- Clear Screen from line.
clr :: Handle -> Number -> IO ()
clr h n = hSetCursorPosition h (unn n) 0 >> hClearFromCursorToScreenEnd h

clr0 :: Handle -> IO ()
clr0 h = clr h 0

-- Terminal Size
--------------------------------------------------------------------------------

termW :: IO Int
termW = termWOn stdout

-- | Width of the terminal behind a handle, or 80 when it is not a terminal.
--   The terminal check keeps size queries away from regular files and pipes.
--   On Windows, the stty fallback in terminal-size can close a non-console
--   handle, so it must not run for output captured in a temporary file.
termWOn :: Handle -> IO Int
termWOn h = do
    terminal <- hIsTerminalDevice h
    if terminal
        then hSize h >>= \mr -> return $ maybe 80 width mr
        else return 80

termH :: IO Int
termH = termHOn stdout

-- | Height of the terminal behind a handle, or 24 when it is not a terminal.
termHOn :: Handle -> IO Int
termHOn h = do
    terminal <- hIsTerminalDevice h
    if terminal
        then hSize h >>= \mr -> return $ maybe 24 height mr
        else return 24
