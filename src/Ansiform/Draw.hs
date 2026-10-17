module Ansiform.Draw ( start, draw, redraw
                , amend, amend'
                , replace, replace'
                , State
                ) where

--------------------------------------------------------------------------------
import           Ansiform.Internal.Number
import           Ansiform.Internal.Page
import           Ansiform.Internal.Section
import           Ansiform.Internal.Settings
import           Ansiform.Internal.State
import           Ansiform.Internal.Terminal
import           Ansiform.Page


-- Drawing Functions
--------------------------------------------------------------------------------

-- Prints the first page and generates the initial state.
start :: Page -> Settings -> IO State 
start p s = draw p $ visState s p []


-- Draws a new page erasing the current printed page.
draw :: Page -> State -> IO State
draw p st = clr 0 >> unStateSettings st >>= \cfg ->
                     runPageIO (return cfg) p
                     >>= \ns -> return $ updateState st p ns

-- Redraws the last printed page, saved on the state.
redraw :: State -> IO State
redraw st = draw (unStatePage st) st


-- Amends a page on the fly and draws it, erasing the current page.
amend :: Section -> Number -> State -> IO State
amend s n st = amend' [s] n st

amend' :: [Section] -> Number -> State -> IO State
amend' ss n st = draw (amendPage' (unStatePage st) ss n) st


-- Replaces a single Section, preserving what is above,
--    and reprinting what was after it.
replace :: Section -> Number -> State -> IO State
replace s n st = replace' [s] n st

-- Replaces a list of Sections, after an index, preserving what is above.
--    It is susceptible to visual breakage if the terminal width has changed.
replace' :: [Section] -> Number -> State -> IO State
replace' ss n st = clr preserve
            >> unStateSettings st
            >>= \cfg -> runPageIO (return cfg) remainder
            >>= \ns -> return $ updateState st newPage (take n' oldResults ++ ns)
    where n' = unn n
          sections = unPage $ unStatePage st
          oldResults = unStateResults st
          preserve = sum $ take n' oldResults
          remainder = page $ ss ++ drop (n'+length ss) sections
          newPage = amendPage' (unStatePage st) ss n


