-- | Non-negative numbers used for widths, offsets and padding.
module Ansiform.Number
    ( Number
    , Width
    , Padding
    , Offset
    , formNumber
    , unNumber
    , addNumber
    , subtractNumber
    , subtractNumberMaybe
    ) where

--------------------------------------------------------------------------------
import Ansiform.Internal.Number
    ( Number
    , Offset
    , Padding
    , Width
    , formNum
    , unn
    )
import qualified Ansiform.Internal.Number as Internal

-- | Builds a 'Number', capping negative values at zero.
formNumber :: Int -> Number
formNumber = formNum

-- | Adds two numbers.
addNumber :: Number -> Number -> Number
addNumber = Internal.addNumber

-- | Subtracts the second number from the first, capping at zero.
subtractNumber :: Number -> Number -> Number
subtractNumber = Internal.subtractNumber

-- | Subtracts the second number from the first.
--   Returns 'Nothing' when the result would be negative.
subtractNumberMaybe :: Number -> Number -> Maybe Number
subtractNumberMaybe = Internal.subtractNumberMaybe

-- | Converts a 'Number' back to an 'Int'.
unNumber :: Number -> Int
unNumber = unn
