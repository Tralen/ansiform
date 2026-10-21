-- | Reusable styles for headers, footers, menus and tables.
module Ansiform.Theme (Theme (..), defaultTheme) where

--------------------------------------------------------------------------------
import Ansiform.Internal.Theme
import Ansiform.Style

-- Default Theme
--------------------------------------------------------------------------------

-- | The default interface theme.
defaultTheme :: Theme
defaultTheme =
    Theme
        { themeHeader = bold white'
        , themeSubtitle = bold yellow
        , themeFooter = italic white
        , themeAccent = bold cyan
        , themeDanger = bold red'
        , themeMuted = italic white
        , themeRule = bold black'
        , themeBar = blue
        , themeTableHeader = bold yellow
        , themeTableBody = normal blue'
        }
