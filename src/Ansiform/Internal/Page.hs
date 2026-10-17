module Ansiform.Internal.Page where

--------------------------------------------------------------------------------
import           System.IO (Handle, stdout)
import           Ansiform.Internal.Number
import           Ansiform.Internal.Sample
import           Ansiform.Internal.Section
import           Ansiform.Internal.Settings


-- Page Type
--------------------------------------------------------------------------------

-- | An ordered list of sections.
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
-- | Runs a page on stdout with the given settings.
runPage :: Settings -> Page -> IO [Number]
runPage = runPageOn stdout

-- Version of runPage that writes to a given Handle.
runPageOn :: Handle -> Settings -> Page -> IO [Number]
runPageOn h s = mapM (runSectionOn h s) . unPage

-- Prints the page with the given settings still in IO.
runPageIO :: IO Config -> Page -> IO [Number]
runPageIO = runPageIOOn stdout

-- Version of runPageIO that writes to a given Handle.
runPageIOOn :: Handle -> IO Config -> Page -> IO [Number]
runPageIOOn h cfg = mapM (runSectionIOOn h cfg) . unPage

-- Uses default settings.
-- | Runs a page on stdout with the default settings.
runPageDefault :: Page -> IO [Number]
runPageDefault = runPageDefaultOn stdout

-- Version of runPageDefault that writes to a given Handle.
runPageDefaultOn :: Handle -> Page -> IO [Number]
runPageDefaultOn h = mapM (runSectionDefaultOn h) . unPage

-- Uses default settings, with given width and minSpace.
-- | Runs a page on stdout with default settings and explicit width and spacing.
runPageDefault' :: Number -> Number -> Page -> IO [Number]
runPageDefault' = runPageDefaultOn' stdout

-- Version of runPageDefault' that writes to a given Handle.
runPageDefaultOn' :: Handle -> Number -> Number -> Page -> IO [Number]
runPageDefaultOn' h w m = mapM (runSectionDefaultOn' h w m) . unPage

