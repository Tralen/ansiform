module Ansiform.Internal.Terminal 
                    ( module Ansiform.Internal.Terminal
                    , ANSI.cursorUp, ANSI.cursorDown
                    ) where
           
--------------------------------------------------------------------------------
import           System.Console.ANSI as ANSI
import           System.Console.Terminal.Size
import           Ansiform.Internal.Number


-- Indentation
--------------------------------------------------------------------------------

-- Places the cursor at an absolute indentation level.
ind :: Offset -> IO ()
ind = indR . unn

-- Places the cursor at a relative indentation level.
ind' :: Offset -> IO ()
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
clr :: Number -> IO ()
clr n = setCursorPosition (unn n) 0 >> clearFromCursorToScreenEnd

clr0 :: IO ()
clr0 = clr 0


-- Terminal Size
--------------------------------------------------------------------------------
termW :: IO Int
termW = size >>= \mr -> return $ maybe 80 width mr

termH :: IO Int
termH = size >>= \mr -> return $ maybe 24 height mr
