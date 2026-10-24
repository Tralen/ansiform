-- | Page builders and runners.
module Ansiform.Page
    ( module Ansiform.Page
    , Internal.Page
    , Internal.runPage
    , Internal.runPageDefault
    , Internal.runPageDefault'
    ) where

import Ansiform.Internal.Number
--------------------------------------------------------------------------------
import Ansiform.Internal.Page as Internal
import Ansiform.Internal.Section

-- Page Builders
--------------------------------------------------------------------------------

-- | Builds a page from a list of sections.
page :: [Section] -> Page
page = formPage

-- | Replaces one section at the given index.
amendPage :: Page -> Section -> Number -> Page
amendPage = Internal.amendPage

-- | Replaces the sections from the given index onwards.
amendPage' :: Page -> [Section] -> Number -> Page
amendPage' = Internal.amendPage'
