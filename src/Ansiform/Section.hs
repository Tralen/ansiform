-- | Section builders and runners.
module Ansiform.Section
    ( module Ansiform.Section
    , Internal.Section
    , Internal.runSection
    , Internal.runSectionDefault
    , Internal.runSectionDefault'
    ) where

import Ansiform.Content
--------------------------------------------------------------------------------
import Ansiform.Internal.Number
import Ansiform.Internal.Section as Internal
import Ansiform.Printer

-- Section Builders
--------------------------------------------------------------------------------

-- | Builds the simplest section from a list of printers.
section :: [Printer] -> Section
section = section' 0

-- | Builds a section with a minimum number of lines.
section' :: Number -> [Printer] -> Section
section' = formSection

-- | Builds a section that prints a single rule.
sectionRule :: Rule -> Section
sectionRule r = formSection 1 [printerRule r]

-- | Builds a section with empty lines above and below the printers.
sectionBody :: Number -> [Printer] -> Section
sectionBody = sectionBody' 0

-- | Like 'sectionBody', with an additional minimum number of lines.
sectionBody' :: Number -> Number -> [Printer] -> Section
sectionBody' m n ps = formSection m $ [printerEmpty n] ++ ps ++ [printerEmpty n]

-- | Builds a section preceded by a rule and with empty lines above and below.
sectionBodyRule :: Number -> Rule -> [Printer] -> Section
sectionBodyRule = sectionBodyRule' 0

-- | Like 'sectionBodyRule', with an additional minimum number of lines.
sectionBodyRule' :: Number -> Number -> Rule -> [Printer] -> Section
sectionBodyRule' m n r ps = formSection m $ [printerRule r, printerEmpty n] ++ ps ++ [printerEmpty n]

-- | Builds a section with empty lines only below the printers.
sectionTop :: Number -> [Printer] -> Section
sectionTop = sectionTop' 0

-- | Like 'sectionTop', with an additional minimum number of lines.
sectionTop' :: Number -> Number -> [Printer] -> Section
sectionTop' m n ps = formSection m $ ps ++ [printerEmpty n]

-- | Builds a section preceded by a rule and with empty lines below.
sectionTopRule :: Number -> Rule -> [Printer] -> Section
sectionTopRule = sectionTopRule' 0

-- | Like 'sectionTopRule', with an additional minimum number of lines.
sectionTopRule' :: Number -> Number -> Rule -> [Printer] -> Section
sectionTopRule' m n r ps = formSection m $ [printerRule r] ++ ps ++ [printerEmpty n]
