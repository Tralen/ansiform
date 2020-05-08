module Vis.Section where

--------------------------------------------------------------------------------
import           Vis.Builder
import           Vis.Number
import           Vis.Printer
import           Vis.Settings
import           Vis.Style
import           Vis.Terminal
import           Vis.Utils


-- Section Type
--------------------------------------------------------------------------------
-- A VisSection is a list of VisPrinters.
newtype VisSection = VisSection [VisPrinter]

-- A VisSection is a function that prints a list of VisPrinters, using the settings.
newtype VisSectionF = VisSectionF (VisSettings -> IO ())


visSection :: [VisPrinter] -> VisSection
visSection ps = VisSection ps

visSectionF :: (VisSettings -> IO ()) -> VisSectionF
visSectionF sio = VisSectionF sio

unSection :: VisSection -> [VisPrinter]
unSection (VisSection ps) = ps 


runSection :: VisSettings -> VisSection -> IO ()
runSection s = mapM_ (runPrinter s ) . unSection

runSection' :: VisNumber -> VisNumber -> VisSection -> IO ()
runSection' w m = mapM_ (runPrinter' w m ) . unSection

runSection'' :: VisNumber -> VisSection -> IO ()
runSection'' m vs = termW >>= \w -> mapM_ (runPrinter' (visNumber w) m ) $ unSection vs


runSectionF :: VisSettings -> VisSectionF -> IO ()
runSectionF s (VisSectionF sio) = sio s 

-- Section Builders
--------------------------------------------------------------------------------

-- Builds a VisSection with a number of empty lines above and below.
sectionBodyF :: VisNumber -> [VisPrinter] -> VisSectionF
sectionBodyF n ps = visSectionF $ \s -> mapM_ (runPrinter s) $ [ printerEmpty n ] ++ ps ++ [ printerEmpty n ]



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
