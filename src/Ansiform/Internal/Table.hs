-- | Per-column formatting for tables and groups.
module Ansiform.Internal.Table where

--------------------------------------------------------------------------------
import           Ansiform.Internal.Content
import           Ansiform.Internal.Number
import           Ansiform.Internal.Sample
import           Ansiform.Internal.Style
import           Ansiform.Internal.Width


-- Table Format Types
--------------------------------------------------------------------------------

-- | Horizontal alignment of a column.
data Align = AlignLeft | AlignCenter | AlignRight
             deriving (Eq, Show)

-- | Marker appended when a cell is truncated.
data Ellipsis = EllipsisNone | EllipsisChar Char
                deriving (Eq, Show)

-- | Alignment, maximum width and truncation for one column.
data ColumnSpec = ColumnSpec
    { columnAlign :: Align
    , columnMaxWidth :: Maybe Width
    , columnEllipsis :: Ellipsis
    } deriving (Eq, Show)

-- | Formatting options for all columns of a table.
newtype TableFormat = TableFormat [ColumnSpec]
                      deriving (Eq, Show)

instance Sample Align where
    sampleShow _ = show

instance Sample Ellipsis where
    sampleShow _ = show

instance Sample ColumnSpec where
    sampleShow _ = show

instance Sample TableFormat where
    sampleShow _ = show


-- Wrappers and Defaults
--------------------------------------------------------------------------------

-- | Left-aligned, without a maximum width and without an ellipsis.
defaultColumnSpec :: ColumnSpec
defaultColumnSpec = ColumnSpec AlignLeft Nothing EllipsisNone

-- | Empty format; every column uses 'defaultColumnSpec'.
defaultTableFormat :: TableFormat
defaultTableFormat = TableFormat []

formTableFormat :: [ColumnSpec] -> TableFormat
formTableFormat = TableFormat

unTableFormat :: TableFormat -> [ColumnSpec]
unTableFormat (TableFormat cs) = cs

-- Returns the spec for a column, falling back to the default.
columnSpecAt :: TableFormat -> Int -> ColumnSpec
columnSpecAt fmt i = case drop i (unTableFormat fmt) of
    (c:_) -> c
    [] -> defaultColumnSpec


-- Formatting
--------------------------------------------------------------------------------

-- Natural width of a group, capped by its specification.
cappedWidth :: ColumnSpec -> Group -> Int
cappedWidth spec g = case columnMaxWidth spec of
    Nothing -> natural
    Just cap -> min natural (unn cap)
  where natural = blockTextMax (unGroup g)

-- Formats every block of a group to a target width.
formatGroup :: ColumnSpec -> Width -> Group -> Group
formatGroup spec w g = formGroup' $ fmap (formatBlock spec w) (unGroup g)

-- Truncates and pads a block to a target width.
formatBlock :: ColumnSpec -> Width -> Block -> Block
formatBlock spec w b = padBlock w (columnAlign spec) $
                       truncateBlock w (columnEllipsis spec) b

-- Pads a block with spaces according to the alignment.
padBlock :: Width -> Align -> Block -> Block
padBlock w align b = formBlock (leftItems ++ unBlock b ++ rightItems)
  where
    missing = max 0 (unn w - blockTextWidth b)
    (left, right) = case align of
        AlignLeft -> (0, missing)
        AlignRight -> (missing, 0)
        AlignCenter -> (missing `div` 2, missing - missing `div` 2)
    leftItems = if left > 0 then [formItem (replicate left ' ') defaultStyle] else []
    rightItems = if right > 0 then [formItem (replicate right ' ') defaultStyle] else []

-- Truncates a block to a display width, optionally appending an ellipsis.
truncateBlock :: Width -> Ellipsis -> Block -> Block
truncateBlock w ell b
    | blockTextWidth b <= w' = b
    | otherwise = formBlock $ takeItems contentWidth (unBlock b) ++ ellipsisItems
  where
    w' = unn w
    (contentWidth, ellipsisItems) = case ell of
        EllipsisNone -> (w', [])
        EllipsisChar c ->
            let cw = charWidth c
            in if cw <= w'
                 then (w' - cw, [formItem [c] ellipsisStyle])
                 else (w', [])
    ellipsisStyle = case unBlock b of
        [] -> defaultStyle
        items -> unItemStyle (last items)

-- Keeps items while their display width fits.
takeItems :: Int -> [Item] -> [Item]
takeItems _ [] = []
takeItems n (i:is)
    | n <= 0 = []
    | itemWidth <= n = i : takeItems (n - itemWidth) is
    | otherwise = case splitTextAtWidth n (unItemText i) of
        ("", _) -> []
        (kept, _) -> [formItem kept (unItemStyle i)]
  where itemWidth = textWidth (unItemText i)

-- Splits a string at a display width, keeping combining marks with their base.
splitTextAtWidth :: Int -> String -> (String, String)
splitTextAtWidth n = go 0 []
  where
    go _ acc [] = (reverse acc, [])
    go cw acc (c:cs)
        | cw + charWidth c <= n = go (cw + charWidth c) (c:acc) cs
        | otherwise = (reverse acc, c:cs)
