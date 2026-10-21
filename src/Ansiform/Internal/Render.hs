-- | Capture page, section and printer output as a string.
module Ansiform.Internal.Render (renderPage, renderSection, renderPrinter) where

import Ansiform.Internal.Page
import Ansiform.Internal.Printer
import Ansiform.Internal.Section
import Ansiform.Internal.Settings
--------------------------------------------------------------------------------
import Control.Exception (bracket)
import System.Directory (getTemporaryDirectory, removeFile)
import System.IO (Handle, hClose, hFlush, openTempFile)

-- Rendering
--------------------------------------------------------------------------------

-- | Renders a page and returns the captured output.
renderPage :: Page -> Settings -> IO String
renderPage p s = snd <$> captureOutput renderWithConfig
  where
    renderWithConfig h = do
        cfg <- runSettingsOn h s
        runPageIOOn h (return cfg) p

-- | Renders a section and returns the captured output.
renderSection :: Section -> Settings -> IO String
renderSection sec s = snd <$> captureOutput renderWithConfig
  where
    renderWithConfig h = do
        cfg <- runSettingsOn h s
        runSectionIOOn h (return cfg) sec

-- | Renders a single printer and returns the captured output.
renderPrinter :: Printer -> Settings -> IO String
renderPrinter pr s = snd <$> captureOutput renderWithConfig
  where
    renderWithConfig h = do
        cfg <- runSettingsOn h s
        runPrinterIOOn h (return cfg) pr

-- Support Functions
--------------------------------------------------------------------------------

-- Runs an action against a temporary output handle and returns its content.
captureOutput :: (Handle -> IO a) -> IO (a, String)
captureOutput action = do
    tmp <- getTemporaryDirectory
    bracket (openTempFile tmp "ansiform-render") cleanup $ \(path, h) -> do
        result <- action h
        hFlush h
        hClose h
        output <- readFile path
        length output `seq` return (result, output)
  where
    cleanup (path, h) = do
        hClose h
        removeFile path
