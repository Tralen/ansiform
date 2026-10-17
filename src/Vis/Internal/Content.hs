module Vis.Internal.Content where

--------------------------------------------------------------------------------
import           Data.Char
import           Data.List
import           Data.List.Split
import           Data.Maybe
import           Vis.Internal.Number
import           Vis.Internal.Sample
import           Vis.Internal.Settings
import           Vis.Internal.Style
import           Vis.Internal.Utils




-- Content Types
--------------------------------------------------------------------------------
-- Combination of text and a VisStyle for that text.
--   It should have no non-printable characters.
newtype VisItem = VisItem (String,VisStyle)
                deriving (Eq, Show)

-- List of VisItems to be printed as a block. 
--   It should have no empty items, to avoid setting styles unnecessarely.
--   It is treated as a block and can only be separated by paragraph formatting.
newtype VisBlock = VisBlock [VisItem]
                deriving (Eq, Show)

-- List of VisBlocks that start with a title for that list.
newtype VisGroup = VisGroup [VisBlock]
                 deriving (Eq, Show)

-- List of VisGroups where each group has the same length.
newtype VisTable = VisTable [VisGroup]
                 deriving (Eq, Show)

-- A VisParagraph is just a suggestive name for a list of VisBlocks.
type VisParagraph = [VisBlock]

-- An article is just a list of VisParagraphs.
type VisArticle = [VisParagraph]

-- Sample Instances
--------------------------------------------------------------------------------

instance VisSample VisItem where
  sampleShow _ (VisItem (s,v)) = "VisItem " ++ show s ++ " " ++ sampleShow 0 v  

instance VisSample VisBlock where
  sampleShow n (VisBlock is) = sampleFormat "VisBlock" n is

instance VisSample VisGroup where
  sampleShow n (VisGroup bs) = sampleFormat "VisGroup" n bs

instance VisSample VisTable where
  sampleShow n (VisTable gs) = sampleFormat "VisTable" n gs


-- Wrappers
--------------------------------------------------------------------------------
visItem :: String -> VisStyle -> VisItem
visItem s v = VisItem (itemTextClean s, v)

visItemList :: [(String, VisStyle)] -> [VisItem]
visItemList = fmap (uncurry visItem)

-- VisBlock builder, removes empty items beforehand.
visBlock :: [VisItem] -> VisBlock
visBlock = VisBlock . itemsEmptyFilter

visBlockList :: [[VisItem]] -> [VisBlock]
visBlockList = fmap visBlock

-- VisGroup builder, taking group header and contents separately.
visGroup :: VisBlock -> [VisBlock] -> VisGroup
visGroup h b = VisGroup (h:b)

-- Allows to build a VisGroup without a separate header.
visGroup' :: [VisBlock] -> VisGroup
visGroup' = VisGroup

-- Allows to build any VisTable, with length checking previously done.
visTable :: [VisGroup] -> Bool -> Maybe VisTable
visTable gs b | b = Just (VisTable gs) | otherwise = Nothing

-- Unrwappers
--------------------------------------------------------------------------------
unItem :: VisItem -> (String, VisStyle)
unItem (VisItem (s,v)) = (s,v)

unItemText :: VisItem -> String
unItemText (VisItem (t,_)) = t

unItemStyle :: VisItem -> VisStyle
unItemStyle (VisItem (_,v)) = v

unBlock :: VisBlock -> [VisItem]
unBlock (VisBlock xs) = xs 

unItemList :: [VisItem] -> [(String, VisStyle)]
unItemList = fmap unItem

unBlockList :: [VisBlock] -> [[VisItem]]
unBlockList = fmap unBlock

unGroup :: VisGroup -> [VisBlock]
unGroup (VisGroup bs) = bs

unTable :: VisTable -> [VisGroup]
unTable (VisTable gs) = gs

unMaybeTable :: Maybe VisTable -> [VisGroup]
unMaybeTable mt = maybe[groupEmpty] unTable mt


-- Basic Builders
--------------------------------------------------------------------------------

-- Trivial VisItem, not allowed in VisBlocks.
itemEmpty :: VisItem
itemEmpty = visItem "" visDefault

-- Trivial VisBlock.
blockEmpty :: VisBlock
blockEmpty = visBlock []

-- VisBlock with a single text and custom VisStyle.
blockSimple :: String -> VisStyle -> VisBlock
blockSimple s v = visBlock [visItem s v]

-- Trivial VisGroup.
groupEmpty :: VisGroup
groupEmpty = visGroup' [blockEmpty]


-- Utilities
--------------------------------------------------------------------------------

-- Removes non-printable characters from the text of a visItem.
itemTextClean :: String -> String
itemTextClean = filter isPrint

-- Removes empty Items from a list of VisItems.
--    Enforces the VisBlock invariant, when used to build them.
itemsEmptyFilter :: [VisItem] -> [VisItem]
itemsEmptyFilter = filter (not . isItemNull)
  
-- Checks if a VisBlock is empty.
isBlockNull :: VisBlock -> Bool
isBlockNull vb
     | null items = True
     | otherwise = and $ fmap isItemNull items
   where
     items = unBlock vb

-- Checks if a VisItem is empty.
isItemNull :: VisItem -> Bool
isItemNull = null . unItemText


-- Calculates the maximum length of the text in a list of VisBlocks.
blockTextMax :: [VisBlock] -> Int
blockTextMax bs = maximum' 0
    $ (return . blockTextWidth . visBlock) =<< unBlockList bs

-- Calculates the length of a VisBlock text, summing each VisItem.
blockTextWidth :: VisBlock -> Int
blockTextWidth vb = sum $ blockTextWidthList vb

-- Calculates the length of a VisBlock text,
blockTextWidthList :: VisBlock -> [Int]
blockTextWidthList vb = fmap itemTextWidth (unBlock vb)

-- Calculates the length of the text in a VisItem.
itemTextWidth :: VisItem -> Int
itemTextWidth vi = length $ unItemText vi

-- Changes the background of each item in a VisBlock.
blockSetBG :: VisColor -> VisBlock -> VisBlock
blockSetBG c b = visBlock $ fmap (itemSetBG c) (unBlock b)

-- Swaps the background of each item in a VisBlock.
blockSwapBG :: VisBlock -> VisBlock
blockSwapBG b = visBlock $ fmap itemSwapBG (unBlock b)

-- Changes the background color of a VisItem.
itemSetBG :: VisColor -> VisItem -> VisItem
itemSetBG c i = itemChangeStyle i $ visSetBG c $ unItemStyle i

-- Swaps the background of a VisItem.
itemSwapBG :: VisItem -> VisItem
itemSwapBG i = itemChangeStyle i $ visSwapBG $ unItemStyle i
  
-- Changes the visual style of a VisItem.
itemChangeStyle :: VisItem -> VisStyle -> VisItem
itemChangeStyle i s = visItem (unItemText i) s

-- Applies the Item prettifier to a whole block.
blockPrettify :: VisBlock -> VisBlock
blockPrettify vb = visBlock $ concatMap itemPrettify $ unBlock vb


-- Improves the styling of a VisItem so as to not style punctuation or spaces.
itemPrettify :: VisItem -> [VisItem]
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

-- Reformats a list of VisBlocks so they respect the same maximum width.
--    The first line can be indented using the padding given.
--    The function always makes progress, even when a single word is wider
--    than the available space, so narrow terminals cannot cause a loop.
blockPublish :: Int -> Int -> [VisBlock] -> [VisBlock] 
blockPublish w p vbs
      | w <= 0 = vbs
      | otherwise = fmap (visBlock . reverse) $ publish firstLine p items
      where
        firstLine = if p > 0 then [visItem (replicate p ' ') visDefault] else []
        items = concatMap unBlock vbs

        publish :: [VisItem] -> Int -> [VisItem] -> [[VisItem]]
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


-- Splits a VisBlock into two, splitting on a desired text length.
blockSplit :: Int -> VisBlock -> (VisBlock, VisBlock)
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


-- Splits a VisItem into two, splitting on a desired text length, but keeping words atomic.
itemSplit :: Int -> VisItem -> (VisItem, VisItem)
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


-- Reduces the length of groups in a list of VisGroups so that they don't exceed
--   the average length too much, based on the excess configuration constant.
groupAverage :: VisConfig -> [VisGroup] -> [VisGroup]
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
--   Each element is a VisBlock so it can use composite styles.
--   The header and body must follow the table invariant or the build will fail.
visTableBlocks :: [VisBlock] -> [[VisBlock]] -> Maybe VisTable
visTableBlocks h rs = visTable fullTable (isTableBalanced h rs)
     where
       fullTable = zip h (transpose rs) >>= \(h', r) -> return $ visGroup h' r


-- Builds a table where every column has a single VisStyle, given in the header.
-- An additional VisStyle is used to style the header itself.
-- Each row is given simply as a list of strings.
-- The header and body must follow the table invariant or the build will fail.
visTableSimple :: [VisBlock] -> VisStyle -> [[String]] -> Maybe VisTable
visTableSimple h v sss = visTable fullTable (isTableBalanced h sss)
    where 
       headerList = unBlockList h
       header = headerList >>= \b -> return $ blockSimple (concatMap (fst . unItem) b) v
       bodyVis = fmap (maybe visDefault (snd . unItem) . headMaybe) headerList
       body = transpose $
              fmap (\ss -> fmap (uncurry blockSimple)(zip ss bodyVis)) sss
       fullTable = fmap (uncurry visGroup) (zip header body)


-- Builds a table that is already properly built, with a VisGroup for each column,
--     just lacking the invariant check.
visTableGroups :: [VisGroup] -> Maybe VisTable
visTableGroups vgs = visTable vgs vgsLengthMatch
    where 
       headLength = maybe 0 (length . unGroup) $ headMaybe vgs
       vgsLengthMatch = and $ fmap ((==) headLength . length . unGroup) (drop 1 vgs)


-- Enforces the invariant that the header and each row 
--    must have the same length.
isTableBalanced :: [VisBlock] -> [[a]] -> Bool
isTableBalanced h rs = and $ fmap (\r -> headLength == length r) rs
            where headLength = length (unBlockList h) 


-- Rules && Solid
--------------------------------------------------------------------------------
newtype VisRule = VisRule (Char, VisStyle)
                  deriving (Eq, Show)

instance VisSample VisRule where
    sampleShow _ (VisRule (c,v)) = "VisRule " ++ show c ++ " " ++ sampleShow 0 v

unRuleChar :: VisRule -> Char
unRuleChar (VisRule (c,_)) = c

unRuleStyle :: VisRule -> VisStyle
unRuleStyle (VisRule (_,s)) = s

visRule :: Char -> VisStyle -> VisRule
visRule c v
          | isPrint c = VisRule (c,v)
          | otherwise = VisRule ('.',v)


-- Creates a VisItem for rules and solid spaces from a VisRule.
--   Must be called direct from printing, as it calculates the width on the fly.
visRuleItem :: VisRule -> VisNumber -> VisItem
visRuleItem r n = visItem (replicate (unn n) (unRuleChar r)) (unRuleStyle r)





