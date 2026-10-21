-- | Drawing functions and the page state lifecycle.
module Ansiform.Draw
    ( start
    , draw
    , redraw
    , amend
    , amend'
    , replace
    , replace'
    , startOn
    , drawOn
    , redrawOn
    , amendOn
    , amendOn'
    , replaceOn
    , replaceOn'
    , State
    ) where

import Ansiform.Internal.Number
import Ansiform.Internal.Page
import Ansiform.Internal.Section
import Ansiform.Internal.Settings
import Ansiform.Internal.State
import Ansiform.Internal.Terminal
import Ansiform.Page
--------------------------------------------------------------------------------
import System.IO (Handle, stdout)

-- Drawing Functions
--------------------------------------------------------------------------------

-- | Prints the first page and generates the initial state on stdout.
start :: Page -> Settings -> IO State
start = startOn stdout

-- | Prints the first page to a given handle.
startOn :: Handle -> Page -> Settings -> IO State
startOn h p s = drawOn h p $ formState s p []

-- | Draws a new page on stdout, erasing the current printed page.
draw :: Page -> State -> IO State
draw = drawOn stdout

-- | Draws a new page to a given handle.
drawOn :: Handle -> Page -> State -> IO State
drawOn h p st =
    clr h 0 >> unStateSettingsOn h st >>= \cfg ->
        runPageIOOn h (return cfg) p
            >>= \ns -> return $ updateState st p ns

-- | Redraws the last printed page on stdout.
redraw :: State -> IO State
redraw = redrawOn stdout

-- | Redraws the last printed page on a given handle.
redrawOn :: Handle -> State -> IO State
redrawOn h st = drawOn h (unStatePage st) st

-- | Amends a page on stdout, erasing the current page.
amend :: Section -> Number -> State -> IO State
amend = amendOn stdout

-- | Amends a page on a given handle.
amendOn :: Handle -> Section -> Number -> State -> IO State
amendOn h s = amendOn' h [s]

-- | Amends several sections on stdout.
amend' :: [Section] -> Number -> State -> IO State
amend' = amendOn' stdout

-- | Amends several sections on a given handle.
amendOn' :: Handle -> [Section] -> Number -> State -> IO State
amendOn' h ss n st = drawOn h (amendPage' (unStatePage st) ss n) st

-- | Replaces a single section on stdout, preserving what is above.
replace :: Section -> Number -> State -> IO State
replace = replaceOn stdout

-- | Replaces a single section on a given handle.
replaceOn :: Handle -> Section -> Number -> State -> IO State
replaceOn h s = replaceOn' h [s]

-- | Replaces a list of sections on stdout, preserving what is above.
replace' :: [Section] -> Number -> State -> IO State
replace' = replaceOn' stdout

-- | Replaces a list of sections on a given handle.
replaceOn' :: Handle -> [Section] -> Number -> State -> IO State
replaceOn' h ss n st =
    clr h preserve
        >> unStateSettingsOn h st
        >>= \cfg ->
            runPageIOOn h (return cfg) remainder
                >>= \ns -> return $ updateState st newPage (take n' oldResults ++ ns)
  where
    n' = unn n
    sections = unPage $ unStatePage st
    oldResults = unStateResults st
    preserve = sum $ take n' oldResults
    remainder = page $ ss ++ drop (n' + length ss) sections
    newPage = amendPage' (unStatePage st) ss n
