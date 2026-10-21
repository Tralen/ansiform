module Ansiform.Internal.Number where

--------------------------------------------------------------------------------
import           Ansiform.Internal.Sample



-- | A non-negative number used for sizes, offsets and counts.
--
--   The 'Num' instance keeps numeric literals and addition convenient.
--   Subtraction through '(-)' caps at zero; use subtractNumberMaybe when
--   a negative result must be distinguished from zero.
newtype Number = Number Int
                    deriving (Eq, Ord, Show)


-- | Number of terminal columns.
type Width = Number

-- | Space between content and the edge of a background.
type Padding = Number

-- | Indentation from the left edge.
type Offset = Number


instance Num Number where
    fromInteger n = formNumber $ fromInteger n
    n + m = formNumber $ unn n + unn m
    n - m = formNumber $ unn n - unn m
    n * m = formNumber $ unn n * unn m
    negate _ = 0
    abs n = n
    signum n | n <= 0 = 0 | otherwise = 1 

instance Sample Number where
    sampleShow _ (Number n) = show n


-- | Adds two numbers.
addNumber :: Number -> Number -> Number
addNumber n m = formNumber (unn n + unn m)

-- | Subtracts the second number from the first, capping at zero.
--   This matches the behavior of '(-)' from the 'Num' instance.
subtractNumber :: Number -> Number -> Number
subtractNumber n m = formNumber (unn n - unn m)

-- | Subtracts the second number from the first.
--   Returns 'Nothing' when the result would be negative, making the failure
--   explicit instead of capping it silently.
subtractNumberMaybe :: Number -> Number -> Maybe Number
subtractNumberMaybe n m
    | unn n >= unn m = Just (Number (unn n - unn m))
    | otherwise = Nothing

formNumber :: Int -> Number
formNumber n | n <= 0 = Number 0 | otherwise = Number n

formNum :: Int -> Number
formNum = formNumber

unNumber :: Number -> Int
unNumber (Number n) = n

unn :: Number -> Int
unn = unNumber





