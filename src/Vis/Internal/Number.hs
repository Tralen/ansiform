module Vis.Internal.Number where


--------------------------------------------------------------------------------

-- A VisNumber is capped at 0, so it is always positive.
newtype VisNumber = VisNumber Int
                    deriving (Eq, Ord)


type VisWidth = VisNumber
type VisPadding = VisNumber
type VisOffset = VisNumber


instance Num VisNumber where
    fromInteger n = visNumber $ fromInteger n
    n + m = visNumber $ unn n + unn m
    n - m = visNumber $ unn n - unn m
    n * m = visNumber $ unn n * unn m
    negate n = 0
    abs n = n
    signum n | n <= 0 = 0 | otherwise = 1 

instance Show VisNumber where
    show (VisNumber n) = show n


visNumber :: Int -> VisNumber
visNumber n | n <= 0 = VisNumber 0 | otherwise = VisNumber n
visNum = visNumber

unNumber :: VisNumber -> Int
unNumber (VisNumber n) = n
unn = unNumber





