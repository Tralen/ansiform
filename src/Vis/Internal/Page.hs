module Vis.Internal.Page where

--------------------------------------------------------------------------------
import           Vis.Internal.Number
import           Vis.Internal.Section
import           Vis.Internal.Settings
import           Vis.Internal.Terminal


-- Page Type
--------------------------------------------------------------------------------

-- A VisPage is just a list of VisSections.
newtype VisPage = VisPage [VisSection]


instance Show VisPage where
    show (VisPage sns) = "VisPage\n" ++ show sns
    

-- Wrappers
visPage :: [VisSection] -> VisPage
visPage ss = VisPage ss

unPage :: VisPage -> [VisSection]
unPage (VisPage ss) = ss


-- Page Runners
--------------------------------------------------------------------------------
-- Functions to print the page with the user settings.
runPage :: VisSettings -> VisPage -> IO [VisNumber]
runPage s = mapM (runSection s) . unPage

-- Prints the page with the given settings still in IO.
runPageIO :: IO VisConfig -> VisPage -> IO [VisNumber]
runPageIO cfg = mapM (runSectionIO cfg) . unPage

-- Uses default settings.
runPageDefault :: VisPage -> IO [VisNumber]
runPageDefault = mapM (runSectionDefault) . unPage

-- Uses default settings, with given width and minSpace.
runPageDefault' :: VisNumber -> VisNumber -> VisPage -> IO [VisNumber]
runPageDefault' w m = mapM (runSectionDefault' w m) . unPage

