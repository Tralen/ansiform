module Vis.Internal.Terminal 
                    ( module Vis.Internal.Terminal
                    , ANSI.cursorUp, ANSI.cursorDown
                    ) where
           
--------------------------------------------------------------------------------
import           System.Console.ANSI as ANSI
import           System.Console.Terminal.Size
import           Vis.Internal.Number


-- Indentation
--------------------------------------------------------------------------------

-- Places the cursor at an absolute indentation level.
ind :: VisOffset -> IO ()
ind = indR . unn

-- Places the cursor at a relative indentation level.
ind' :: VisOffset -> IO ()
ind' = indR' . unn

-- Places the cursor at an absolute indentation level, raw version.
indR :: Int -> IO ()
indR = setCursorColumn

-- Places the cursor at a relative indentation level, raw version.
indR' :: Int -> IO ()
indR' = cursorForward


-- Clear
--------------------------------------------------------------------------------

-- Clear Screen from line.
clr :: VisNumber -> IO ()
clr n = setCursorPosition (unn n) 0 >> clearFromCursorToScreenEnd

clr0 = clr 0


-- Terminal Size
--------------------------------------------------------------------------------
termW :: IO Int
termW = size >>= \mr -> return $ maybe 80 width mr

termH :: IO Int
termH = size >>= \mr -> return $ maybe 24 height mr
