module Vis.Settings (module Vis.Settings
                    , Internal.VisConfig
                    , Internal.VisSettings
                    ) where


--------------------------------------------------------------------------------
import           Vis.Internal.Number
import           Vis.Internal.Settings as Internal


-- Default Settings
--------------------------------------------------------------------------------

settings :: [VisConfig -> VisConfig] -> VisSettings
settings = visSettings

defaultSettings :: VisSettings
defaultSettings = visSettings []


-- Configuration modifiers
--------------------------------------------------------------------------------
width :: VisWidth -> VisConfig -> VisConfig
width = setWidth

minSpace :: VisWidth -> VisConfig -> VisConfig
minSpace = setMinSpace

groupOverflow :: VisNumber -> VisConfig -> VisConfig
groupOverflow = setGroupOverflow
overflow = setGroupOverflow


