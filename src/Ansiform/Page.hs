module Ansiform.Page ( module Ansiform.Page, Internal.VisPage, Internal.runPage
                , Internal.runPageDefault, Internal.runPageDefault'
                ) where

--------------------------------------------------------------------------------
import           Ansiform.Internal.Page as Internal
import           Ansiform.Internal.Number
import           Ansiform.Internal.Section

-- Page Builders
--------------------------------------------------------------------------------

-- Simplest page builder.
page :: [VisSection] -> VisPage
page = visPage

-- Builds a VisPage by replacing a single VisSection, based on an index.
amendPage :: VisPage -> VisSection -> VisNumber -> VisPage
amendPage p s n = amendPage' p [s] n

-- Builds a VisPage by replacing all VisSections after a chosen index.
amendPage' :: VisPage -> [VisSection] -> VisNumber -> VisPage
amendPage' p ss n = visPage $ starter ++ remainder
    where p' = unPage p; n' = unn n
          remainder = ss ++ drop (n' + length ss) p'
          starter = take n' p'









