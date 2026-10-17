module Ansiform.Settings (module Ansiform.Settings
                    , Internal.VisConfig
                    , Internal.VisSettings
                    ) where


--------------------------------------------------------------------------------
import           Ansiform.Internal.Number
import           Ansiform.Internal.Settings as Internal


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

overflow :: VisNumber -> VisConfig -> VisConfig
overflow = setGroupOverflow


