-- | Section builders and runners.
module Ansiform.Section ( module Ansiform.Section
                   , Internal.Section, Internal.runSection
                   , Internal.runSectionDefault, Internal.runSectionDefault'
                   ) where

--------------------------------------------------------------------------------
import           Ansiform.Internal.Number
import           Ansiform.Internal.Section as Internal
import           Ansiform.Content
import           Ansiform.Printer


-- Section Builders
--------------------------------------------------------------------------------

-- Builds the most basic Section, with just the list of Printers.
section ::  [Printer] -> Section
section = section' 0

-- Builds a basic Section with minimum of lines set.
section' ::  Number -> [Printer] -> Section
section' n = formSection n


-- Builds a Section that just prints a single Rule.
sectionRule :: Rule -> Section
sectionRule r = formSection 1 [ printerRule r ]


-- Builds a Section with a number of empty lines above and below.
sectionBody :: Number -> [Printer] -> Section
sectionBody n ps = sectionBody' 0 n ps

-- Like sectionBody, but allows to set the minimum number of lines.
sectionBody' :: Number -> Number -> [Printer] -> Section
sectionBody' m n ps = formSection m $ [ printerEmpty n ] ++ ps ++ [ printerEmpty n ]


-- Builds a Section with a number of empty lines above and below, preceded by a Rule.
sectionBodyRule :: Number -> Rule -> [Printer] -> Section
sectionBodyRule n r ps = sectionBodyRule' 0 n r ps

-- Like sectionBodyRule, but allows to set the minimum number of lines.
sectionBodyRule' :: Number -> Number -> Rule -> [Printer] -> Section
sectionBodyRule' m n r ps = formSection m $ [ printerRule r, printerEmpty n ] ++ ps ++ [ printerEmpty n ]


-- Builds a Section with a number of empty lines only below.
sectionTop :: Number -> [Printer] -> Section
sectionTop n ps = sectionTop' 0 n ps

-- Like sectionTop, but allows to set the minimum number of lines.
sectionTop' :: Number -> Number -> [Printer] -> Section
sectionTop' m n ps = formSection m $ ps ++ [ printerEmpty n ]


-- Builds a Section with a number of empty lines only below, preceded by a Rule.
sectionTopRule :: Number -> Rule -> [Printer] -> Section
sectionTopRule n r ps = sectionTopRule' 0 n r ps

-- Like sectionTopRule, but allows to set the minimum number of lines.
sectionTopRule' :: Number -> Number -> Rule -> [Printer] -> Section
sectionTopRule' m n r ps = formSection m $ [ printerRule r ] ++ ps ++ [ printerEmpty n ]
