-- | Reusable style groups for headers, footers, menus and tables.
module Ansiform.Internal.Theme where

--------------------------------------------------------------------------------
import           Ansiform.Internal.Sample
import           Ansiform.Internal.Style


-- Theme Type
--------------------------------------------------------------------------------

-- | Styles and bar colors used by reusable interface components.
data Theme = Theme
    { themeHeader :: Style
    , themeSubtitle :: Style
    , themeFooter :: Style
    , themeAccent :: Style
    , themeDanger :: Style
    , themeMuted :: Style
    , themeRule :: Style
    , themeBar :: Color
    , themeTableHeader :: Style
    , themeTableBody :: Style
    } deriving (Eq, Show)

instance Sample Theme where
    sampleShow _ t = "Theme"
        ++ "\n  Header: " ++ sampleShow 0 (themeHeader t)
        ++ "\n  Subtitle: " ++ sampleShow 0 (themeSubtitle t)
        ++ "\n  Footer: " ++ sampleShow 0 (themeFooter t)
        ++ "\n  Accent: " ++ sampleShow 0 (themeAccent t)
        ++ "\n  Danger: " ++ sampleShow 0 (themeDanger t)
        ++ "\n  Muted: " ++ sampleShow 0 (themeMuted t)
        ++ "\n  Rule: " ++ sampleShow 0 (themeRule t)
        ++ "\n  Bar: " ++ sampleShow 0 (themeBar t)
        ++ "\n  Table Header: " ++ sampleShow 0 (themeTableHeader t)
        ++ "\n  Table Body: " ++ sampleShow 0 (themeTableBody t)
