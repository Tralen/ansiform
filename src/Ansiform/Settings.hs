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

-- | Builds settings from a list of configuration modifiers.
settings :: [Config -> Config] -> Settings
settings = formSettings

-- | The settings that use only the terminal defaults.
defaultSettings :: Settings
defaultSettings = formSettings []


-- Configuration modifiers
--------------------------------------------------------------------------------

-- | Overrides the detected terminal width.
width :: Width -> Config -> Config
width = setWidth

-- | Sets the minimum space between adjacent blocks and columns.
minSpace :: Width -> Config -> Config
minSpace = setMinSpace

-- | Sets the percentage by which a group may exceed the average width.
groupOverflow :: Number -> Config -> Config
groupOverflow = setGroupOverflow

-- | Alias for 'groupOverflow'.
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
