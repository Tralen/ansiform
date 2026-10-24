-- | Capture page, section and printer output as a string.
module Ansiform.Internal.Render (renderPage, renderSection, renderPrinter) where

import Ansiform.Internal.Page
import Ansiform.Internal.Printer
import Ansiform.Internal.Section
import Ansiform.Internal.Settings
--------------------------------------------------------------------------------
import Control.Exception (bracket)
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import System.Directory (getTemporaryDirectory, removeFile)
import System.IO
    ( Handle
    , SeekMode (AbsoluteSeek)
    , hClose
    , hFlush
    , hSeek
    , hSetEncoding
    , openTempFile
    , utf8
    )

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
    bracket (openTempFile tmp "ansiform-render") cleanup $ \(_path, h) -> do
        hSetEncoding h utf8
        result <- action h
        hFlush h
        hSeek h AbsoluteSeek 0
        output <- TIO.hGetContents h
        return (result, T.unpack output)
  where
    cleanup (path, h) = do
        hClose h
        removeFile path
