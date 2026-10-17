-- | Non-negative numbers used for widths, offsets and padding.
module Ansiform.Number ( VisNumber
                  , VisWidth
                  , VisPadding
                  , VisOffset
                  , visNumber
                  , unNumber
                  ) where

--------------------------------------------------------------------------------
import           Ansiform.Internal.Number hiding (visNumber, unNumber)


-- | Builds a 'VisNumber', capping negative values at zero.
visNumber :: Int -> VisNumber
visNumber = visNum

-- | Converts a 'VisNumber' back to an 'Int'.
unNumber :: VisNumber -> Int
unNumber = unn
