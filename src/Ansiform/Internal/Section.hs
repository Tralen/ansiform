module Ansiform.Internal.Section where

import Ansiform.Internal.Number
import Ansiform.Internal.Printer
import Ansiform.Internal.Sample
import Ansiform.Internal.Settings
--------------------------------------------------------------------------------
import Control.Monad
import System.IO (Handle, stdout)

-- Section Type
--------------------------------------------------------------------------------

-- | A list of printers and a minimum number of lines.
newtype Section = Section (Number, [Printer])
    deriving (Show)

instance Sample Section where
    sampleShow n (Section (m, ps)) = "Section (minimum lines: " ++ sampleShow 0 m ++ ")\n" ++ sampleShow n ps

-- Wrappers
formSection :: Number -> [Printer] -> Section
formSection n ps = Section (n, ps)

unSectionPrinters :: Section -> [Printer]
unSectionPrinters (Section (_, ps)) = ps

unSectionNumber :: Section -> Number
unSectionNumber (Section (n, _)) = n

-- Section Runners
--------------------------------------------------------------------------------

-- Function to run the list of Printers with the user settings.

-- | Runs a section on stdout with the given settings.
runSection :: Settings -> Section -> IO Number
runSection = runSectionOn stdout

-- Version of runSection that writes to a given Handle.
runSectionOn :: Handle -> Settings -> Section -> IO Number
runSectionOn h s = calcSection (runPrinterOn h s)

-- Version of runSection with settings in IO.
runSectionIO :: IO Config -> Section -> IO Number
runSectionIO = runSectionIOOn stdout

-- Version of runSectionIO that writes to a given Handle.
runSectionIOOn :: Handle -> IO Config -> Section -> IO Number
runSectionIOOn h cfg = calcSection (runPrinterIOOn h cfg)

-- Uses default settings.

-- | Runs a section on stdout with the default settings.
runSectionDefault :: Section -> IO Number
runSectionDefault = runSectionDefaultOn stdout

-- Version of runSectionDefault that writes to a given Handle.
runSectionDefaultOn :: Handle -> Section -> IO Number
runSectionDefaultOn h = calcSection (runPrinterDefaultOn h)

-- Uses default settings, with given width and minSpace.

-- | Runs a section on stdout with default settings and explicit width and spacing.
runSectionDefault' :: Number -> Number -> Section -> IO Number
runSectionDefault' = runSectionDefaultOn' stdout

-- Version of runSectionDefault' that writes to a given Handle.
runSectionDefaultOn' :: Handle -> Number -> Number -> Section -> IO Number
runSectionDefaultOn' h w m = calcSection (runPrinterDefaultOn' h w m)

-- Runs the Printers and calculates the total number of lines.
calcSection :: (Printer -> IO Number) -> Section -> IO Number
calcSection f vs = foldM runCalc 0 (unSectionPrinters vs) >>= enforceMin
  where
    runCalc acc p = f p >>= \n -> return (acc + n)
    minNumber = unSectionNumber vs
    enforceMin n
        | n < minNumber = f (emptyPrinter (minNumber - n)) >> return minNumber
        | otherwise = return n
