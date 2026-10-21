module Ansiform.Internal.State where

import Ansiform.Internal.Number
import Ansiform.Internal.Page
import Ansiform.Internal.Settings
--------------------------------------------------------------------------------
import System.IO (Handle)

-- State Type
--------------------------------------------------------------------------------

-- State carries the data needed to print each page correctly.

-- | Drawing state: the settings, the page on screen and the line counts from the last draw.
newtype State = State (Settings, Page, [Number])

formState :: Settings -> Page -> [Number] -> State
formState s p ns = State (s, p, ns)

unStateSettings :: State -> IO Config
unStateSettings (State (s, _, _)) = runSettings s

-- Resolves the state settings for a given output handle.
unStateSettingsOn :: Handle -> State -> IO Config
unStateSettingsOn h (State (s, _, _)) = runSettingsOn h s

unStatePage :: State -> Page
unStatePage (State (_, p, _)) = p

unStateResults :: State -> [Number]
unStateResults (State (_, _, ns)) = ns

updateState :: State -> Page -> [Number] -> State
updateState (State (s, _, _)) = formState s
