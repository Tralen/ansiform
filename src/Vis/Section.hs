module Vis.Section where

--------------------------------------------------------------------------------
import           Control.Monad
import           Vis.Internal.Number
import           Vis.Internal.Settings
import           Vis.Internal.Terminal
import           Vis.Content
import           Vis.Printer


-- Section Type
--------------------------------------------------------------------------------
-- A VisSection is a list of VisPrinters.
newtype VisSection = VisSection [VisPrinter]

instance Show VisSection where
    show (VisSection ps) = "VisSection " ++ (concat $ fmap (("\n  "++) . show) ps)


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


-- Section Builders
--------------------------------------------------------------------------------

-- Builds a VisSection with a number of empty lines above and below.
sectionBody :: VisNumber -> [VisPrinter] -> VisSection
sectionBody n ps = visSection $ [ printerEmpty n ] ++ ps ++ [ printerEmpty n ]

-- Builds a VisSection with a number of empty lines above and below, followed by a VisRule.
sectionBody' :: VisNumber -> VisRule -> [VisPrinter] -> VisSection
sectionBody' n r ps = visSection $ [ printerEmpty n ] ++ ps ++ [ printerEmpty n, printerRule r]

-- Builds a VisSection with a number of empty lines only below.
sectionTop :: VisNumber -> [VisPrinter] -> VisSection
sectionTop n ps = visSection $ ps ++ [ printerEmpty n ]

-- Builds a VisSection with a number of empty lines only below, followed by a VisRule.
sectionTop' :: VisNumber -> VisRule -> [VisPrinter] -> VisSection
sectionTop' n r ps = visSection $ ps ++ [ printerEmpty n, printerRule r]
