module Vis.Internal.Section where

--------------------------------------------------------------------------------
import           Control.Monad
import           Vis.Internal.Content
import           Vis.Internal.Number
import           Vis.Internal.Printer
import           Vis.Internal.Settings
import           Vis.Printer


-- Section Type
--------------------------------------------------------------------------------
-- A VisSection is a list of VisPrinters.
--    The section takes a number as a minimum number of lines. If the printing
--    of the section doesn't reach that number, empty lines will be printed.
newtype VisSection = VisSection (VisNumber,[VisPrinter])
                     deriving (Eq)

instance Show VisSection where
    show (VisSection (n,ps)) = "VisSection  (minimum " ++ show n ++ " lines)\n" ++ show ps
    showList ss = showContentList (zip ss [0..]) 2


-- Wrappers
visSection :: VisNumber -> [VisPrinter] -> VisSection
visSection n ps = VisSection (n,ps)

unSectionPrinters :: VisSection -> [VisPrinter]
unSectionPrinters (VisSection (_,ps)) = ps

unSectionNumber :: VisSection -> VisNumber
unSectionNumber (VisSection (n,_)) = n

-- Section Runners
--------------------------------------------------------------------------------

-- Function to run the list of VisPrinters with the user settings.
runSection :: VisSettings -> VisSection -> IO VisNumber
runSection s = calcSection (runPrinter s) 

-- Version of runSection with settings in IO.
runSectionIO :: IO VisConfig -> VisSection -> IO VisNumber
runSectionIO cfg = calcSection (runPrinterIO cfg)

-- Uses default settings.
runSectionDefault :: VisSection -> IO VisNumber
runSectionDefault = calcSection runPrinterDefault

-- Uses default settings, with given width and minSpace.
runSectionDefault' :: VisNumber -> VisNumber -> VisSection -> IO VisNumber
runSectionDefault' w m = calcSection (runPrinterDefault' w m)


-- Runs the Printers and calculates the total number of lines.
calcSection :: (VisPrinter -> IO VisNumber) -> VisSection -> IO VisNumber
calcSection f vs = foldM runCalc 0 (unSectionPrinters vs) >>= enforceMin
   where 
      runCalc acc p = f p >>= \n -> return (acc + n)
      minNumber = unSectionNumber vs
      enforceMin n | n < minNumber = f (printerEmpty (minNumber - n)) >> return minNumber
                   | otherwise = return n

