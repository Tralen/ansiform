module Ansiform.Internal.Number where

--------------------------------------------------------------------------------
import           Ansiform.Internal.Sample



-- | A non-negative number used for sizes, offsets and counts.
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


formNumber :: Int -> Number
formNumber n | n <= 0 = Number 0 | otherwise = Number n

formNum :: Int -> Number
formNum = formNumber

unNumber :: Number -> Int
unNumber (Number n) = n

unn :: Number -> Int
unn = unNumber





