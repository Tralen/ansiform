module Ansiform.Internal.Content where

--------------------------------------------------------------------------------
import           Data.Char
import           Data.List
import           Data.List.Split
import           Data.Maybe
import           Ansiform.Internal.Number
import           Ansiform.Internal.Sample
import           Ansiform.Internal.Settings
import           Ansiform.Internal.Style
import           Ansiform.Internal.Utils




-- Content Types
--------------------------------------------------------------------------------
-- Combination of text and a Style for that text.
--   It should have no non-printable characters.
newtype Item = Item (String,Style)
                deriving (Eq, Show)

-- List of Items to be printed as a block. 
--   It should have no empty items, to avoid setting styles unnecessarely.
--   It is treated as a block and can only be separated by paragraph formatting.
newtype Block = Block [Item]
                deriving (Eq, Show)

-- List of Blocks that start with a title for that list.
newtype Group = Group [Block]
                 deriving (Eq, Show)

-- List of Groups where each group has the same length.
newtype Table = Table [Group]
                 deriving (Eq, Show)

-- A Paragraph is just a suggestive name for a list of Blocks.
type Paragraph = [Block]

-- An article is just a list of Paragraphs.
type Article = [Paragraph]

-- Sample Instances
--------------------------------------------------------------------------------

instance Sample Item where
  sampleShow _ (Item (s,v)) = "Item " ++ show s ++ " " ++ sampleShow 0 v  

instance Sample Block where
  sampleShow n (Block is) = sampleFormat "Block" n is

instance Sample Group where
  sampleShow n (Group bs) = sampleFormat "Group" n bs

instance Sample Table where
  sampleShow n (Table gs) = sampleFormat "Table" n gs


-- Wrappers
--------------------------------------------------------------------------------
visItem :: String -> Style -> Item
visItem s v = Item (itemTextClean s, v)

visItemList :: [(String, Style)] -> [Item]
visItemList = fmap (uncurry visItem)

-- Block builder, removes empty items beforehand.
visBlock :: [Item] -> Block
visBlock = Block . itemsEmptyFilter

visBlockList :: [[Item]] -> [Block]
visBlockList = fmap visBlock

-- Group builder, taking group header and contents separately.
visGroup :: Block -> [Block] -> Group
visGroup h b = Group (h:b)

-- Allows to build a Group without a separate header.
visGroup' :: [Block] -> Group
visGroup' = Group

-- Allows to build any Table, with length checking previously done.
visTable :: [Group] -> Bool -> Maybe Table
visTable gs b | b = Just (Table gs) | otherwise = Nothing

-- Unrwappers
--------------------------------------------------------------------------------
unItem :: Item -> (String, Style)
unItem (Item (s,v)) = (s,v)

unItemText :: Item -> String
unItemText (Item (t,_)) = t

unItemStyle :: Item -> Style
unItemStyle (Item (_,v)) = v

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
unMaybeTable mt = maybe[groupEmpty] unTable mt


-- Basic Builders
--------------------------------------------------------------------------------

-- Trivial Item, not allowed in Blocks.
itemEmpty :: Item
itemEmpty = visItem "" visDefault

-- Trivial Block.
blockEmpty :: Block
blockEmpty = visBlock []

-- Block with a single text and custom Style.
blockSimple :: String -> Style -> Block
blockSimple s v = visBlock [visItem s v]

-- Trivial Group.
groupEmpty :: Group
groupEmpty = visGroup' [blockEmpty]


-- Utilities
--------------------------------------------------------------------------------

-- Removes non-printable characters from the text of a visItem.
itemTextClean :: String -> String
itemTextClean = filter isPrint

-- Removes empty Items from a list of Items.
--    Enforces the Block invariant, when used to build them.
itemsEmptyFilter :: [Item] -> [Item]
itemsEmptyFilter = filter (not . isItemNull)
  
-- Checks if a Block is empty.
isBlockNull :: Block -> Bool
isBlockNull vb
     | null items = True
     | otherwise = and $ fmap isItemNull items
   where
     items = unBlock vb

-- Checks if a Item is empty.
isItemNull :: Item -> Bool
isItemNull = null . unItemText


-- Calculates the maximum length of the text in a list of Blocks.
blockTextMax :: [Block] -> Int
blockTextMax bs = maximum' 0
    $ (return . blockTextWidth . visBlock) =<< unBlockList bs

-- Calculates the length of a Block text, summing each Item.
blockTextWidth :: Block -> Int
blockTextWidth vb = sum $ blockTextWidthList vb

-- Calculates the length of a Block text,
blockTextWidthList :: Block -> [Int]
blockTextWidthList vb = fmap itemTextWidth (unBlock vb)

-- Calculates the length of the text in a Item.
itemTextWidth :: Item -> Int
itemTextWidth vi = length $ unItemText vi

-- Changes the background of each item in a Block.
blockSetBG :: Color -> Block -> Block
blockSetBG c b = visBlock $ fmap (itemSetBG c) (unBlock b)

-- Swaps the background of each item in a Block.
blockSwapBG :: Block -> Block
blockSwapBG b = visBlock $ fmap itemSwapBG (unBlock b)

-- Changes the background color of a Item.
itemSetBG :: Color -> Item -> Item
itemSetBG c i = itemChangeStyle i $ visSetBG c $ unItemStyle i

-- Swaps the background of a Item.
itemSwapBG :: Item -> Item
itemSwapBG i = itemChangeStyle i $ visSwapBG $ unItemStyle i
  
-- Changes the visual style of a Item.
itemChangeStyle :: Item -> Style -> Item
itemChangeStyle i s = visItem (unItemText i) s

-- Applies the Item prettifier to a whole block.
blockPrettify :: Block -> Block
blockPrettify vb = visBlock $ concatMap itemPrettify $ unBlock vb


-- Improves the styling of a Item so as to not style punctuation or spaces.
itemPrettify :: Item -> [Item]
itemPrettify vi
      | isSpecial vs = [ visItem (fst splitHead) visDefault
                       , visItem (reverse (snd splitMiddle)) vs
                       , visItem (reverse (fst splitMiddle)) visDefault
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
      | otherwise = fmap (visBlock . reverse) $ publish firstLine p items
      where
        firstLine = if p > 0 then [visItem (replicate p ' ') visDefault] else []
        items = concatMap unBlock vbs

        publish :: [Item] -> Int -> [Item] -> [[Item]]
        publish line _ [] = [line]
        publish line cw (item:rest)
            | itemWidth <= remaining = publish (item:line) (cw + itemWidth) rest
            | otherwise = case itemSplit remaining item of
                (fit, remainder)
                    | not (isItemNull fit) ->
                        publish (fit:line) (cw + itemTextWidth fit) next
                    | null line ->
                        publish (item:line) (cw + itemWidth) rest
                    | cw == p && p > 0 ->
                        publish (item:line) (cw + itemWidth) rest
                    | otherwise ->
                        line : publish [] 0 (item:rest)
                  where
                    next = if isItemNull remainder then rest else remainder:rest
          where
            remaining = w - cw
            itemWidth = itemTextWidth item


-- Splits a Block into two, splitting on a desired text length.
blockSplit :: Int -> Block -> (Block, Block)
blockSplit w vb = ( visBlock (fst processItems)
                  , visBlock (snd processItems) )
      where
        items = unBlock vb
        processItems = go [] 0 items
           where 
            go cvis cw rvis
                | curWidth <= w && not (null rvis) = go (vi:cvis) curWidth (drop 1 rvis)
                | otherwise = (reverse (curItem:cvis), remItems:rvis)
              where
                vi = fromMaybe itemEmpty $ headMaybe rvis
                curWidth = itemWidth + cw
                itemWidth = itemTextWidth vi
                curItem = fst splitItem
                remItems = snd splitItem
                splitItem = itemSplit (w - cw) vi


-- Splits a Item into two, splitting on a desired text length, but keeping words atomic.
itemSplit :: Int -> Item -> (Item, Item)
itemSplit w vi = ( visItem (fst processText) vs
                 , visItem (snd processText) vs )
     where 
       vs = unItemStyle vi
       splitWords = split (keepDelimsR (whenElt isSpace)) $ unItemText vi
       processText = breakLength [] 0 splitWords
            where
               breakLength cwds cw wds
                  | totalLength <= w && not (null wds) = 
                               breakLength (wd:cwds) totalLength (drop 1 wds)
                  | otherwise = (concatRev cwds, concat wds)
                where
                  wd = fromMaybe "" $ headMaybe wds
                  wdLength = length wd
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
           | grpLength > tgtLength = fmap visGroup' headerBlocks ++ a
           | otherwise = g : a
          where grpLength = length blocks
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
visTableBlocks :: [Block] -> [[Block]] -> Maybe Table
visTableBlocks h rs = visTable fullTable (isTableBalanced h rs)
     where
       fullTable = zip h (transpose rs) >>= \(h', r) -> return $ visGroup h' r


-- Builds a table where every column has a single Style, given in the header.
-- An additional Style is used to style the header itself.
-- Each row is given simply as a list of strings.
-- The header and body must follow the table invariant or the build will fail.
visTableSimple :: [Block] -> Style -> [[String]] -> Maybe Table
visTableSimple h v sss = visTable fullTable (isTableBalanced h sss)
    where 
       headerList = unBlockList h
       header = headerList >>= \b -> return $ blockSimple (concatMap (fst . unItem) b) v
       bodyVis = fmap (maybe visDefault (snd . unItem) . headMaybe) headerList
       body = transpose $
              fmap (\ss -> fmap (uncurry blockSimple)(zip ss bodyVis)) sss
       fullTable = fmap (uncurry visGroup) (zip header body)


-- Builds a table that is already properly built, with a Group for each column,
--     just lacking the invariant check.
visTableGroups :: [Group] -> Maybe Table
visTableGroups vgs = visTable vgs vgsLengthMatch
    where 
       headLength = maybe 0 (length . unGroup) $ headMaybe vgs
       vgsLengthMatch = and $ fmap ((==) headLength . length . unGroup) (drop 1 vgs)


-- Enforces the invariant that the header and each row 
--    must have the same length.
isTableBalanced :: [Block] -> [[a]] -> Bool
isTableBalanced h rs = and $ fmap (\r -> headLength == length r) rs
            where headLength = length (unBlockList h) 


-- Rules && Solid
--------------------------------------------------------------------------------
newtype Rule = Rule (Char, Style)
                  deriving (Eq, Show)

instance Sample Rule where
    sampleShow _ (Rule (c,v)) = "Rule " ++ show c ++ " " ++ sampleShow 0 v

unRuleChar :: Rule -> Char
unRuleChar (Rule (c,_)) = c

unRuleStyle :: Rule -> Style
unRuleStyle (Rule (_,s)) = s

visRule :: Char -> Style -> Rule
visRule c v
          | isPrint c = Rule (c,v)
          | otherwise = Rule ('.',v)


-- Creates a Item for rules and solid spaces from a Rule.
--   Must be called direct from printing, as it calculates the width on the fly.
visRuleItem :: Rule -> Number -> Item
visRuleItem r n = visItem (replicate (unn n) (unRuleChar r)) (unRuleStyle r)





