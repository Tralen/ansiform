module Vis.Internal.State where

--------------------------------------------------------------------------------
import           Vis.Internal.Number
import           Vis.Internal.Page
import           Vis.Internal.Settings


-- State Type
--------------------------------------------------------------------------------

-- VisState carries the data needed to print each page correctly.
newtype VisState = VisState (VisSettings,VisPage,[VisNumber])


visState :: VisSettings -> VisPage -> [VisNumber] -> VisState
visState s p ns = VisState (s,p,ns)

unStateSettings :: VisState -> IO VisConfig
unStateSettings (VisState (s,_,_)) = runSettings s

unStatePage :: VisState -> VisPage
unStatePage (VisState (_,p,_)) = p

unStateResults :: VisState -> [VisNumber]
unStateResults (VisState (_,_,ns)) = ns

updateState :: VisState -> VisPage -> [VisNumber] -> VisState
updateState (VisState (s,_,_)) p ns = visState s p ns
