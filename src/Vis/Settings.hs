module Vis.Settings (module Vis.Settings
                    , Internal.VisSettings , Internal.defaultSettings
                    ) where


--------------------------------------------------------------------------------
import           Data.List
import           Vis.Internal.Number
import           Vis.Internal.Settings as Internal


-- Settings modifiers
--------------------------------------------------------------------------------
width :: VisWidth -> VisSettings -> VisSettings
width = setWidth

minSpace :: VisWidth -> VisSettings -> VisSettings
minSpace = setMinSpace

groupOverflow :: VisNumber -> VisSettings -> VisSettings
groupOverflow = setGroupOverflow
overflow = setGroupOverflow

-- Function to build the settings in a declarative style.
settings :: [(VisSettings -> VisSettings)] -> IO VisSettings
settings fs = defaultSettings >>= \dft -> return $ foldl' (\sets f -> f sets) dft fs 
