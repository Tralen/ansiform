-- | Non-negative numbers used for widths, offsets and padding.
module Ansiform.Number ( Number
                  , Width
                  , Padding
                  , Offset
                  , visNumber
                  , unNumber
                  ) where

--------------------------------------------------------------------------------
import           Ansiform.Internal.Number hiding (visNumber, unNumber)


-- | Builds a 'Number', capping negative values at zero.
visNumber :: Int -> Number
visNumber = visNum

-- | Converts a 'Number' back to an 'Int'.
unNumber :: Number -> Int
unNumber = unn
