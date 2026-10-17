module Ansiform.Internal.State where

--------------------------------------------------------------------------------
import           Ansiform.Internal.Number
import           Ansiform.Internal.Page
import           Ansiform.Internal.Settings


-- State Type
--------------------------------------------------------------------------------

-- State carries the data needed to print each page correctly.
newtype State = State (Settings,Page,[Number])


formState :: Settings -> Page -> [Number] -> State
formState s p ns = State (s,p,ns)

unStateSettings :: State -> IO Config
unStateSettings (State (s,_,_)) = runSettings s

unStatePage :: State -> Page
unStatePage (State (_,p,_)) = p

unStateResults :: State -> [Number]
unStateResults (State (_,_,ns)) = ns

updateState :: State -> Page -> [Number] -> State
updateState (State (s,_,_)) p ns = formState s p ns
