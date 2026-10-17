module Ansiform.Internal.Page where

--------------------------------------------------------------------------------
import           Ansiform.Internal.Number
import           Ansiform.Internal.Sample
import           Ansiform.Internal.Section
import           Ansiform.Internal.Settings


-- Page Type
--------------------------------------------------------------------------------

-- A Page is just a list of Sections.
newtype Page = Page [Section]
                deriving (Eq,Show)


instance Sample Page where
    sampleShow n (Page sns) = sampleFormat "Page" n sns
    

-- Wrappers
formPage :: [Section] -> Page
formPage = Page

unPage :: Page -> [Section]
unPage (Page ss) = ss


-- Page Runners
--------------------------------------------------------------------------------
-- Functions to print the page with the user settings.
runPage :: Settings -> Page -> IO [Number]
runPage s = mapM (runSection s) . unPage

-- Prints the page with the given settings still in IO.
runPageIO :: IO Config -> Page -> IO [Number]
runPageIO cfg = mapM (runSectionIO cfg) . unPage

-- Uses default settings.
runPageDefault :: Page -> IO [Number]
runPageDefault = mapM runSectionDefault . unPage

-- Uses default settings, with given width and minSpace.
runPageDefault' :: Number -> Number -> Page -> IO [Number]
runPageDefault' w m = mapM (runSectionDefault' w m) . unPage

