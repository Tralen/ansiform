module Vis.Draw where

--------------------------------------------------------------------------------
import           Vis.Internal.Number
import           Vis.Internal.Page
import           Vis.Internal.Section
import           Vis.Internal.Settings
import           Vis.Internal.State
import           Vis.Internal.Terminal
import           Vis.Page


-- Drawing Functions
--------------------------------------------------------------------------------

-- Prints the first page and generates the initial state.
start :: VisPage -> VisSettings -> IO VisState 
start p s = draw p $ visState s p []


-- Draws a new page erasing the current printed page.
draw :: VisPage -> VisState -> IO VisState
draw p st = clr 0 >> runPageIO (unStateSettings st) p 
                     >>= \ns -> return $ updateState st p ns

-- Redraws the last printed page, saved on the state.
redraw :: VisState -> IO VisState
redraw st = draw (unStatePage st) st


-- Amends a page on the fly and draws it, erasing the current page.
amend :: VisSection -> VisNumber -> VisState -> IO VisState
amend s n st = amend' [s] n st

amend' :: [VisSection] -> VisNumber -> VisState -> IO VisState
amend' ss n st = draw (amendPage' (unStatePage st) ss n) st


-- Replaces a single VisSection, preserving what is above,
--    and reprinting what was after it.
replace :: VisSection -> VisNumber -> VisState -> IO VisState
replace s n st = replace' [s] n st

-- Replaces a list of VisSections, after an index, preserving what is above.
--    It is susceptible to visual breakage if the terminal width has changed.
replace' :: [VisSection] -> VisNumber -> VisState -> IO VisState
replace' ss n st = clr preserve
            >> runPageIO (unStateSettings st) remainder
            >>= \ns -> return $ updateState st newPage ns
    where n' = unn n
          sections = unPage $ unStatePage st
          preserve = sum $ take n' $ unStateResults st
          remainder = page $ ss ++ drop (n'+length ss) sections
          newPage = amendPage' (unStatePage st) ss n


