-- | Terminal display width for characters and strings.
module Ansiform.Internal.Width (charWidth, textWidth) where

--------------------------------------------------------------------------------
import Data.Char (GeneralCategory (..), generalCategory, ord)

-- Display Width
--------------------------------------------------------------------------------

-- | Number of terminal columns occupied by a character.
--   Combining marks and other zero width characters return zero,
--   East Asian wide characters and emoji return two.
charWidth :: Char -> Int
charWidth c
    | isZeroWidth c = 0
    | isWide c = 2
    | otherwise = 1

-- | Number of terminal columns occupied by a string.
textWidth :: String -> Int
textWidth = sum . fmap charWidth

-- Support Functions
--------------------------------------------------------------------------------

-- Checks for characters that do not advance the cursor.
isZeroWidth :: Char -> Bool
isZeroWidth c = case generalCategory c of
    NonSpacingMark -> True
    EnclosingMark -> True
    Format -> True
    _ ->
        inRange 0x1160 0x11FF c -- Hangul Jamo vowels and finals.
            || inRange 0x200B 0x200B c -- Zero width space.
            || inRange 0x1F3FB 0x1F3FF c -- Emoji skin tone modifiers.

-- Checks for characters that occupy two columns.
isWide :: Char -> Bool
isWide c = any (\(lo, hi) -> inRange lo hi c) wideRanges

inRange :: Int -> Int -> Char -> Bool
inRange lo hi c = lo <= ord c && ord c <= hi

-- East Asian wide and fullwidth ranges, plus the main emoji blocks.
wideRanges :: [(Int, Int)]
wideRanges =
    [ (0x1100, 0x115F) -- Hangul Jamo initials.
    , (0x2329, 0x232A) -- Angle brackets.
    , (0x2E80, 0x303E) -- CJK radicals, Kangxi and CJK symbols.
    , (0x3041, 0x33FF) -- Kana, Bopomofo, Jamo and compatibility.
    , (0x3400, 0x4DBF) -- CJK extension A.
    , (0x4E00, 0x9FFF) -- CJK unified ideographs.
    , (0xA000, 0xA4CF) -- Yi syllables.
    , (0xA960, 0xA97F) -- Hangul Jamo extended A.
    , (0xAC00, 0xD7A3) -- Hangul syllables.
    , (0xF900, 0xFAFF) -- CJK compatibility ideographs.
    , (0xFE10, 0xFE19) -- Vertical forms.
    , (0xFE30, 0xFE6F) -- CJK compatibility forms.
    , (0xFF00, 0xFF60) -- Fullwidth forms.
    , (0xFFE0, 0xFFE6) -- Fullwidth signs.
    , (0x1F004, 0x1F004) -- Mahjong red dragon.
    , (0x1F0CF, 0x1F0CF) -- Playing card joker.
    , (0x1F18E, 0x1F18E) -- Squared AB.
    , (0x1F191, 0x1F19A) -- Squared symbols.
    , (0x1F200, 0x1F2FF) -- Enclosed ideographic supplement.
    , (0x1F300, 0x1F64F) -- Pictographs and emoticons.
    , (0x1F680, 0x1F6FF) -- Transport and map symbols.
    , (0x1F780, 0x1F7FF) -- Geometric shapes extended.
    , (0x1F900, 0x1F9FF) -- Supplemental pictographs.
    , (0x1FA70, 0x1FAFF) -- Pictographs extended A.
    , (0x20000, 0x2FFFD) -- CJK extensions B to F.
    , (0x30000, 0x3FFFD) -- CJK extensions G and later.
    ]
