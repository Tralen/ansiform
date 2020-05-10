module Vis.Internal.Section where

--------------------------------------------------------------------------------
import           Control.Monad
import           Vis.Internal.Content
import           Vis.Internal.Number
import           Vis.Internal.Printer
import           Vis.Internal.Settings


-- Section Type
--------------------------------------------------------------------------------
-- A VisSection is a list of VisPrinters.
newtype VisSection = VisSection [VisPrinter]

instance Show VisSection where
    show (VisSection ps) = "VisSection\n" ++ show ps
    showList ss = showContentList (zip ss [0..]) 2


-- Wrappers
visSection :: [VisPrinter] -> VisSection
visSection ps = VisSection ps

unSection :: VisSection -> [VisPrinter]
unSection (VisSection ps) = ps


-- Functions to run the list of VisPrinters with the given settings.
runSection :: IO VisSettings -> VisSection -> IO VisNumber
runSection s = calcSection (runPrinter s)

-- Uses default settings.
runSection' :: VisSection -> IO VisNumber
runSection' = calcSection runPrinter'

-- Uses default settings, with given width and minSpace.
runSection'' :: VisNumber -> VisNumber -> VisSection -> IO VisNumber
runSection'' w m = calcSection (runPrinter'' w m)


-- Runs the Printers and calculates the total number of lines.
calcSection :: (VisPrinter -> IO VisNumber) -> VisSection -> IO VisNumber
calcSection f vs = foldM runCalc 0 $ unSection vs
   where runCalc acc p = f p >>= \n -> return (acc + n)

