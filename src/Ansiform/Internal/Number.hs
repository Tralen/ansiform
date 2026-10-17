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





