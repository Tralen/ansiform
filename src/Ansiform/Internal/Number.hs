module Ansiform.Internal.Number where

--------------------------------------------------------------------------------
import           Ansiform.Internal.Sample



-- A Number is capped at 0, so it is always positive.
newtype Number = Number Int
                    deriving (Eq, Ord, Show)


type Width = Number
type Padding = Number
type Offset = Number


instance Num Number where
    fromInteger n = visNumber $ fromInteger n
    n + m = visNumber $ unn n + unn m
    n - m = visNumber $ unn n - unn m
    n * m = visNumber $ unn n * unn m
    negate _ = 0
    abs n = n
    signum n | n <= 0 = 0 | otherwise = 1 

instance Sample Number where
    sampleShow _ (Number n) = show n


visNumber :: Int -> Number
visNumber n | n <= 0 = Number 0 | otherwise = Number n

visNum :: Int -> Number
visNum = visNumber

unNumber :: Number -> Int
unNumber (Number n) = n

unn :: Number -> Int
unn = unNumber





