module Ansiform.Internal.Content where

import Ansiform.Internal.Number
import Ansiform.Internal.Sample
import Ansiform.Internal.Settings
import Ansiform.Internal.Style
import Ansiform.Internal.Utils
import Ansiform.Internal.Width
--------------------------------------------------------------------------------
import Data.Bifunctor (bimap)
import Data.Char
import Data.List
import Data.List.Split
import Data.Maybe

-- Content Types
--------------------------------------------------------------------------------

-- | A piece of text with a single style. Non-printable characters are removed.
newtype Item = Item (String, Style)
    deriving (Eq, Show)

-- | A list of items printed without breaks. It contains no empty items.
newtype Block = Block [Item]
    deriving (Eq, Show)

-- | A header block followed by body blocks.
newtype Group = Group [Block]
    deriving (Eq, Show)

-- | A list of groups with the same number of blocks.
newtype Table = Table [Group]
    deriving (Eq, Show)

-- | A list of blocks wrapped as one paragraph.
type Paragraph = [Block]

-- | A list of paragraphs.
type Article = [Paragraph]

-- Sample Instances
--------------------------------------------------------------------------------

instance Sample Item where
    sampleShow _ (Item (s, v)) = "Item " ++ show s ++ " " ++ sampleShow 0 v

instance Sample Block where
    sampleShow n (Block is) = sampleFormat "Block" n is

instance Sample Group where
    sampleShow n (Group bs) = sampleFormat "Group" n bs

instance Sample Table where
    sampleShow n (Table gs) = sampleFormat "Table" n gs

-- Wrappers
--------------------------------------------------------------------------------
formItem :: String -> Style -> Item
formItem s v = Item (itemTextClean s, v)

formItemList :: [(String, Style)] -> [Item]
formItemList = fmap (uncurry formItem)

-- Block builder, removes empty items beforehand.
formBlock :: [Item] -> Block
formBlock = Block . itemsEmptyFilter

formBlockList :: [[Item]] -> [Block]
formBlockList = fmap formBlock

-- Group builder, taking group header and contents separately.
formGroup :: Block -> [Block] -> Group
formGroup h b = Group (h : b)

-- Allows to build a Group without a separate header.
formGroup' :: [Block] -> Group
formGroup' = Group

-- Allows to build any Table, with length checking previously done.
formTable :: [Group] -> Bool -> Maybe Table
formTable gs b | b = Just (Table gs) | otherwise = Nothing

-- Unrwappers
--------------------------------------------------------------------------------
unItem :: Item -> (String, Style)
unItem (Item (s, v)) = (s, v)

unItemText :: Item -> String
unItemText (Item (t, _)) = t

unItemStyle :: Item -> Style
unItemStyle (Item (_, v)) = v

unBlock :: Block -> [Item]
unBlock (Block xs) = xs

unItemList :: [Item] -> [(String, Style)]
unItemList = fmap unItem

unBlockList :: [Block] -> [[Item]]
unBlockList = fmap unBlock

unGroup :: Group -> [Block]
unGroup (Group bs) = bs

unTable :: Table -> [Group]
unTable (Table gs) = gs

unMaybeTable :: Maybe Table -> [Group]
unMaybeTable = maybe [groupEmpty] unTable

-- Basic Builders
--------------------------------------------------------------------------------

-- Trivial Item, not allowed in Blocks.
itemEmpty :: Item
itemEmpty = formItem "" defaultStyle

-- Trivial Block.

-- | An empty block.
blockEmpty :: Block
blockEmpty = formBlock []

-- | A block containing a single text and style.
blockSimple :: String -> Style -> Block
blockSimple s v = formBlock [formItem s v]

-- Trivial Group.
groupEmpty :: Group
groupEmpty = formGroup' [blockEmpty]

-- Utilities
--------------------------------------------------------------------------------

-- Removes non-printable characters from the text of a formItem.
itemTextClean :: String -> String
itemTextClean = filter isPrint

-- Removes empty Items from a list of Items.
--    Enforces the Block invariant, when used to build them.
itemsEmptyFilter :: [Item] -> [Item]
itemsEmptyFilter = filter (not . isItemNull)

-- Checks if a Block is empty.
isBlockNull :: Block -> Bool
isBlockNull = all isItemNull . unBlock

-- Checks if a Item is empty.
isItemNull :: Item -> Bool
isItemNull = null . unItemText

-- Calculates the maximum length of the text in a list of Blocks.
blockTextMax :: [Block] -> Int
blockTextMax bs =
    maximum' 0 $
        blockTextWidth . formBlock <$> unBlockList bs

-- Calculates the length of a Block text, summing each Item.
blockTextWidth :: Block -> Int
blockTextWidth vb = sum $ blockTextWidthList vb

-- Calculates the length of a Block text,
blockTextWidthList :: Block -> [Int]
blockTextWidthList vb = fmap itemTextWidth (unBlock vb)

-- Calculates the length of the text in a Item.
itemTextWidth :: Item -> Int
itemTextWidth vi = textWidth $ unItemText vi

-- Changes the background of each item in a Block.
blockSetBG :: Color -> Block -> Block
blockSetBG c b = formBlock $ fmap (itemSetBG c) (unBlock b)

-- Swaps the background of each item in a Block.
blockSwapBG :: Block -> Block
blockSwapBG b = formBlock $ fmap itemSwapBG (unBlock b)

-- Changes the background color of a Item.
itemSetBG :: Color -> Item -> Item
itemSetBG c i = itemChangeStyle i $ setBackground c $ unItemStyle i

-- Swaps the background of a Item.
itemSwapBG :: Item -> Item
itemSwapBG i = itemChangeStyle i $ swapBackground $ unItemStyle i

-- Changes the visual style of a Item.
itemChangeStyle :: Item -> Style -> Item
itemChangeStyle i = formItem (unItemText i)

-- Applies the Item prettifier to a whole block.
blockPrettify :: Block -> Block
blockPrettify vb = formBlock $ concatMap itemPrettify $ unBlock vb

-- Improves the styling of a Item so as to not style punctuation or spaces.
itemPrettify :: Item -> [Item]
itemPrettify vi
    | isSpecial vs =
        [ formItem (fst splitHead) defaultStyle
        , formItem (reverse (snd splitMiddle)) vs
        , formItem (reverse (fst splitMiddle)) defaultStyle
        ]
    | otherwise = [vi]
  where
    vs = unItemStyle vi
    vt = unItemText vi
    isBlank c = isPunctuation c || isSpace c
    splitHead = span isBlank vt
    splitMiddle = span isBlank $ reverse $ snd splitHead

-- Text Formatting
--------------------------------------------------------------------------------

-- Reformats a list of Blocks so they respect the same maximum width.
--    The first line can be indented using the padding given.
--    The function always makes progress, even when a single word is wider
--    than the available space, so narrow terminals cannot cause a loop.
blockPublish :: Int -> Int -> [Block] -> [Block]
blockPublish w p vbs
    | w <= 0 = vbs
    | otherwise = formBlock . reverse <$> publish firstLine p items
  where
    firstLine = [formItem (replicate p ' ') defaultStyle | p > 0]
    items = concatMap unBlock vbs

    publish :: [Item] -> Int -> [Item] -> [[Item]]
    publish line _ [] = [line]
    publish line cw (item : rest)
        | itemWidth <= remaining = publish (item : line) (cw + itemWidth) rest
        | otherwise = case itemSplit remaining item of
            (fit, remainder)
                | not (isItemNull fit) ->
                    publish (fit : line) (cw + itemTextWidth fit) next
                | null line ->
                    publish (item : line) (cw + itemWidth) rest
                | cw == p && p > 0 ->
                    publish (item : line) (cw + itemWidth) rest
                | otherwise ->
                    line : publish [] 0 (item : rest)
              where
                next = if isItemNull remainder then rest else remainder : rest
      where
        remaining = w - cw
        itemWidth = itemTextWidth item

-- Splits a Block into two, splitting on a desired text length.
blockSplit :: Int -> Block -> (Block, Block)
blockSplit w vb = bimap formBlock formBlock processItems
  where
    items = unBlock vb
    processItems = go [] 0 items
      where
        go cvis cw rvis
            | curWidth <= w && not (null rvis) = go (vi : cvis) curWidth (drop 1 rvis)
            | otherwise = (reverse (curItem : cvis), remItems : rvis)
          where
            vi = fromMaybe itemEmpty $ headMaybe rvis
            curWidth = itemWidth + cw
            itemWidth = itemTextWidth vi
            curItem = fst splitItem
            remItems = snd splitItem
            splitItem = itemSplit (w - cw) vi

-- Splits a Item into two, splitting on a desired text length, but keeping words atomic.
itemSplit :: Int -> Item -> (Item, Item)
itemSplit w vi =
    ( formItem (fst processText) vs
    , formItem (snd processText) vs
    )
  where
    vs = unItemStyle vi
    splitWords = split (keepDelimsR (whenElt isSpace)) $ unItemText vi
    processText = breakLength [] 0 splitWords
      where
        breakLength cwds cw wds
            | totalLength <= w && not (null wds) =
                breakLength (wd : cwds) totalLength (drop 1 wds)
            | otherwise = (concatRev cwds, concat wds)
          where
            wd = fromMaybe "" $ headMaybe wds
            wdLength = textWidth wd
            totalLength = wdLength + cw

-- Group and Table Formatters
--------------------------------------------------------------------------------
-- A table is simply a list of Groups of the same length.

-- Reduces the length of groups in a list of Groups so that they don't exceed
--   the average length too much, based on the excess configuration constant.
groupAverage :: Config -> [Group] -> [Group]
groupAverage s gs = foldr groupProcess [] gs
  where
    gof = unGroupOverflow s
    groupProcess g a
        | grpLength > tgtLength = fmap formGroup' headerBlocks ++ a
        | otherwise = g : a
      where
        grpLength = length blocks
        headerBlocks = take 1 splitBlocks ++ fmap (blockEmpty :) (drop 1 splitBlocks)
        splitBlocks = splitPlaces (tgtLength + 1 : repeat tgtLength) blocks
        blocks = unGroup g
    tgtLength
        | overflowRatio == 0 = avgLength
        | otherwise = avgLength + div avgLength overflowRatio
    overflowRatio = groupOverflowRatio gof
    avgLength = average $ fmap (length . unGroup) gs

-- Builds a table where each element has its own style and composition.
--   Each element is a Block so it can use composite styles.
--   The header and body must follow the table invariant or the build will fail.
formTableBlocks :: [Block] -> [[Block]] -> Maybe Table
formTableBlocks h rs = formTable fullTable (isTableBalanced h rs)
  where
    fullTable = zip h (transpose rs) >>= \(h', r) -> return $ formGroup h' r

-- Builds a table where every column has a single Style, given in the header.
-- An additional Style is used to style the header itself.
-- Each row is given simply as a list of strings.
-- The header and body must follow the table invariant or the build will fail.
formTableSimple :: [Block] -> Style -> [[String]] -> Maybe Table
formTableSimple h v sss = formTable fullTable (isTableBalanced h sss)
  where
    headerList = unBlockList h
    header = headerList >>= \b -> return $ blockSimple (concatMap (fst . unItem) b) v
    bodyVis = fmap (maybe defaultStyle (snd . unItem) . headMaybe) headerList
    body =
        transpose $
            fmap (\ss -> fmap (uncurry blockSimple) (zip ss bodyVis)) sss
    fullTable = fmap (uncurry formGroup) (zip header body)

-- Builds a table that is already properly built, with a Group for each column,
--     just lacking the invariant check.
formTableGroups :: [Group] -> Maybe Table
formTableGroups vgs = formTable vgs vgsLengthMatch
  where
    headLength = maybe 0 (length . unGroup) $ headMaybe vgs
    vgsLengthMatch = all ((== headLength) . length . unGroup) (drop 1 vgs)

-- Enforces the invariant that the header and each row
--    must have the same length.
isTableBalanced :: [Block] -> [[a]] -> Bool
isTableBalanced h = all (\r -> headLength == length r)
  where
    headLength = length (unBlockList h)

-- Rules && Solid
--------------------------------------------------------------------------------

-- | A character and a style used to draw a horizontal rule.
newtype Rule = Rule (Char, Style)
    deriving (Eq, Show)

instance Sample Rule where
    sampleShow _ (Rule (c, v)) = "Rule " ++ show c ++ " " ++ sampleShow 0 v

unRuleChar :: Rule -> Char
unRuleChar (Rule (c, _)) = c

unRuleStyle :: Rule -> Style
unRuleStyle (Rule (_, s)) = s

formRule :: Char -> Style -> Rule
formRule c v
    | isPrint c = Rule (c, v)
    | otherwise = Rule ('.', v)

-- Creates a Item for rules and solid spaces from a Rule.
--   Must be called direct from printing, as it calculates the width on the fly.
formRuleItem :: Rule -> Number -> Item
formRuleItem r n = formItem (replicate (unn n) (unRuleChar r)) (unRuleStyle r)
