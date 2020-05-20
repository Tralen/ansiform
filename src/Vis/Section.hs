module Vis.Section ( module Vis.Section
                   , Internal.VisSection
                   , Internal.runSection, Internal.runSectionIO
                   , Internal.runSectionDefault, Internal.runSectionDefault'
                   ) where

--------------------------------------------------------------------------------
import           Vis.Internal.Number
import           Vis.Internal.Settings
import           Vis.Internal.Section as Internal
import           Vis.Content
import           Vis.Printer


-- Section Builders
--------------------------------------------------------------------------------

-- Builds the most basic VisSection, with just the list of Printers.
section :: [VisPrinter] -> VisSection
section = visSection

-- Builds a VisSection with a number of empty lines above and below.
sectionBody :: VisNumber -> [VisPrinter] -> VisSection
sectionBody n ps = visSection $ [ printerEmpty n ] ++ ps ++ [ printerEmpty n ]

-- Builds a VisSection with a number of empty lines above and below, followed by a VisRule.
sectionBody' :: VisNumber -> VisRule -> [VisPrinter] -> VisSection
sectionBody' n r ps = visSection $ [ printerEmpty n ] ++ ps ++ [ printerEmpty n, printerRule r]

-- Builds a VisSection with a number of empty lines only below.
sectionTop :: VisNumber -> [VisPrinter] -> VisSection
sectionTop n ps = visSection $ ps ++ [ printerEmpty n ]

-- Builds a VisSection with a number of empty lines only below, followed by a VisRule.
sectionTop' :: VisNumber -> VisRule -> [VisPrinter] -> VisSection
sectionTop' n r ps = visSection $ ps ++ [ printerEmpty n, printerRule r]
