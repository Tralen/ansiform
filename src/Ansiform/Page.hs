module Ansiform.Page ( module Ansiform.Page, Internal.Page, Internal.runPage
                , Internal.runPageDefault, Internal.runPageDefault'
                ) where

--------------------------------------------------------------------------------
import           Ansiform.Internal.Page as Internal
import           Ansiform.Internal.Number
import           Ansiform.Internal.Section

-- Page Builders
--------------------------------------------------------------------------------

-- Simplest page builder.
page :: [Section] -> Page
page = formPage

-- Builds a Page by replacing a single Section, based on an index.
amendPage :: Page -> Section -> Number -> Page
amendPage p s n = amendPage' p [s] n

-- Builds a Page by replacing all Sections after a chosen index.
amendPage' :: Page -> [Section] -> Number -> Page
amendPage' p ss n = formPage $ starter ++ remainder
    where p' = unPage p; n' = unn n
          remainder = ss ++ drop (n' + length ss) p'
          starter = take n' p'









