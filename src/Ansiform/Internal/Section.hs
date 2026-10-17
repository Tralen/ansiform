module Ansiform.Internal.Section where

--------------------------------------------------------------------------------
import           Control.Monad
import           Ansiform.Internal.Number
import           Ansiform.Internal.Printer
import           Ansiform.Internal.Sample
import           Ansiform.Internal.Settings
import           Ansiform.Printer


-- Section Type
--------------------------------------------------------------------------------
-- A Section is a list of Printers.
--    The section takes a number as a minimum number of lines. If the printing
--    of the section doesn't reach that number, empty lines will be printed.
newtype Section = Section (Number,[Printer])
                     deriving (Eq, Show)

instance Sample Section where
    sampleShow n (Section (m,ps)) = "Section (minimum lines: " ++ sampleShow 0 m ++ ")\n" ++ sampleShow n ps

-- Wrappers
visSection :: Number -> [Printer] -> Section
visSection n ps = Section (n,ps)

unSectionPrinters :: Section -> [Printer]
unSectionPrinters (Section (_,ps)) = ps

unSectionNumber :: Section -> Number
unSectionNumber (Section (n,_)) = n

-- Section Runners
--------------------------------------------------------------------------------

-- Function to run the list of Printers with the user settings.
runSection :: Settings -> Section -> IO Number
runSection s = calcSection (runPrinter s) 

-- Version of runSection with settings in IO.
runSectionIO :: IO Config -> Section -> IO Number
runSectionIO cfg = calcSection (runPrinterIO cfg)

-- Uses default settings.
runSectionDefault :: Section -> IO Number
runSectionDefault = calcSection runPrinterDefault

-- Uses default settings, with given width and minSpace.
runSectionDefault' :: Number -> Number -> Section -> IO Number
runSectionDefault' w m = calcSection (runPrinterDefault' w m)


-- Runs the Printers and calculates the total number of lines.
calcSection :: (Printer -> IO Number) -> Section -> IO Number
calcSection f vs = foldM runCalc 0 (unSectionPrinters vs) >>= enforceMin
   where 
      runCalc acc p = f p >>= \n -> return (acc + n)
      minNumber = unSectionNumber vs
      enforceMin n | n < minNumber = f (printerEmpty (minNumber - n)) >> return minNumber
                   | otherwise = return n

