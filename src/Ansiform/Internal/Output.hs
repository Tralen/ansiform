-- | Output target for the printing layer.
module Ansiform.Internal.Output where

import Ansiform.Internal.Settings
--------------------------------------------------------------------------------
import System.IO (Handle)

-- Output Type
--------------------------------------------------------------------------------

-- | A handle together with the configuration resolved for it.
data Output = Output
    { outputHandle :: Handle
    , outputConfig :: Config
    }

instance Show Output where
    show out = "Output " ++ show (outputConfig out)

-- Wrapper
formOutput :: Handle -> Config -> Output
formOutput = Output

-- Unwrappers
unOutputHandle :: Output -> Handle
unOutputHandle = outputHandle

unOutputConfig :: Output -> Config
unOutputConfig = outputConfig

-- Reports whether ANSI styles should be emitted for this output.
outputColors :: Output -> Bool
outputColors = colorsEnabled . outputConfig
