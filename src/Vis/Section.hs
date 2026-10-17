module Vis.Section ( module Vis.Section
                   , Internal.VisSection, Internal.runSection
                   , Internal.runSectionDefault, Internal.runSectionDefault'
                   ) where

--------------------------------------------------------------------------------
import           Vis.Internal.Number
import           Vis.Internal.Section as Internal
import           Vis.Content
import           Vis.Printer


-- Section Builders
--------------------------------------------------------------------------------

-- Builds the most basic VisSection, with just the list of Printers.
section ::  [VisPrinter] -> VisSection
section = section' 0

-- Builds a basic VisSection with minimum of lines set.
section' ::  VisNumber -> [VisPrinter] -> VisSection
section' n = visSection n


-- Builds a VisSection that just prints a single VisRule.
sectionRule :: VisRule -> VisSection
sectionRule r = visSection 1 [ printerRule r ]


-- Builds a VisSection with a number of empty lines above and below.
sectionBody :: VisNumber -> [VisPrinter] -> VisSection
sectionBody n ps = sectionBody' 0 n ps

-- Like sectionBody, but allows to set the minimum number of lines.
sectionBody' :: VisNumber -> VisNumber -> [VisPrinter] -> VisSection
sectionBody' m n ps = visSection m $ [ printerEmpty n ] ++ ps ++ [ printerEmpty n ]


-- Builds a VisSection with a number of empty lines above and below, preceded by a VisRule.
sectionBodyRule :: VisNumber -> VisRule -> [VisPrinter] -> VisSection
sectionBodyRule n r ps = sectionBodyRule' 0 n r ps

-- Like sectionBodyRule, but allows to set the minimum number of lines.
sectionBodyRule' :: VisNumber -> VisNumber -> VisRule -> [VisPrinter] -> VisSection
sectionBodyRule' m n r ps = visSection m $ [ printerRule r, printerEmpty n ] ++ ps ++ [ printerEmpty n ]


-- Builds a VisSection with a number of empty lines only below.
sectionTop :: VisNumber -> [VisPrinter] -> VisSection
sectionTop n ps = sectionTop' 0 n ps

-- Like sectionTop, but allows to set the minimum number of lines.
sectionTop' :: VisNumber -> VisNumber -> [VisPrinter] -> VisSection
sectionTop' m n ps = visSection m $ ps ++ [ printerEmpty n ]


-- Builds a VisSection with a number of empty lines only below, preceded by a VisRule.
sectionTopRule :: VisNumber -> VisRule -> [VisPrinter] -> VisSection
sectionTopRule n r ps = sectionTopRule' 0 n r ps

-- Like sectionTopRule, but allows to set the minimum number of lines.
sectionTopRule' :: VisNumber -> VisNumber -> VisRule -> [VisPrinter] -> VisSection
sectionTopRule' m n r ps = visSection m $ [ printerRule r ] ++ ps ++ [ printerEmpty n ]
