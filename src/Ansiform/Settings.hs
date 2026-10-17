-- | Settings and configuration modifiers.
module Ansiform.Settings (module Ansiform.Settings
                    , Internal.Config
                    , Internal.Settings
                    , Internal.ColorMode(..)
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

-- | Selects how ANSI styling is handled.
colorMode :: ColorMode -> Config -> Config
colorMode = setColorMode

-- | Detects color support from the environment and from stdout.
autoColors :: Config -> Config
autoColors = colorMode ColorAuto

-- | Forces ANSI styling, even when stdout is not a terminal.
alwaysColors :: Config -> Config
alwaysColors = colorMode ColorAlways

-- | Disables ANSI styling unconditionally.
neverColors :: Config -> Config
neverColors = colorMode ColorNever


