-- | Internal terminal cursor and size helpers.
module Ansiform.Internal.Terminal 
                    ( module Ansiform.Internal.Terminal
                    , ANSI.cursorUp, ANSI.cursorDown
                    , ANSI.hCursorUp, ANSI.hCursorDown
                    ) where
           
--------------------------------------------------------------------------------
import           System.Console.ANSI as ANSI
import           System.Console.Terminal.Size
import           System.IO (Handle, stdout)
import           Ansiform.Internal.Number


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

termWOn :: Handle -> IO Int
termWOn h = hSize h >>= \mr -> return $ maybe 80 width mr

termH :: IO Int
termH = termHOn stdout

termHOn :: Handle -> IO Int
termHOn h = hSize h >>= \mr -> return $ maybe 24 height mr
