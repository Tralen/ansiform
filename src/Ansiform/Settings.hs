module Ansiform.Settings (module Ansiform.Settings
                    , Internal.Config
                    , Internal.Settings
                    ) where


--------------------------------------------------------------------------------
import           Ansiform.Internal.Number
import           Ansiform.Internal.Settings as Internal


-- Default Settings
--------------------------------------------------------------------------------

settings :: [Config -> Config] -> Settings
settings = formSettings

defaultSettings :: Settings
defaultSettings = formSettings []


-- Configuration modifiers
--------------------------------------------------------------------------------
width :: Width -> Config -> Config
width = setWidth

minSpace :: Width -> Config -> Config
minSpace = setMinSpace

groupOverflow :: Number -> Config -> Config
groupOverflow = setGroupOverflow

overflow :: Number -> Config -> Config
overflow = setGroupOverflow


