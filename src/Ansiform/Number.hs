-- | Non-negative numbers used for widths, offsets and padding.
module Ansiform.Number ( Number
                  , Width
                  , Padding
                  , Offset
                  , formNumber
                  , unNumber
                  ) where

--------------------------------------------------------------------------------
import           Ansiform.Internal.Number hiding (formNumber, unNumber)


-- | Builds a 'Number', capping negative values at zero.
formNumber :: Int -> Number
formNumber = formNum

-- | Converts a 'Number' back to an 'Int'.
unNumber :: Number -> Int
unNumber = unn
