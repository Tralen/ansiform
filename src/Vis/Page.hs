module Vis.Page ( module Vis.Page, Internal.VisPage
                , Internal.runPage, Internal.runPageIO
                , Internal.runPageDefault, Internal.runPageDefault'
                ) where

--------------------------------------------------------------------------------
import           Vis.Internal.Page as Internal
import           Vis.Internal.Section

-- Page Builder
--------------------------------------------------------------------------------
page :: [VisSection] -> VisPage
page = visPage










