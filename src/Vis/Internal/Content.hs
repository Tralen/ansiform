module Vis.Internal.Content where

--------------------------------------------------------------------------------
import           Data.Char
import           Data.List
import           Data.List.Split
import           Data.Maybe
import           Vis.Internal.Number
import           Vis.Internal.Settings
import           Vis.Internal.Style
import           Vis.Internal.Utils




-- Content Types
--------------------------------------------------------------------------------
-- Combination of text and a VisStyle for that text.
--   It should have no non-printable characters.
newtype VisItem = VisItem (String,VisStyle)
                deriving (Eq)

-- List of VisItems to be printed as a block. 
--   It should have no empty items, to avoid setting styles unnecessarely.
--   It is treated as a block and can only be separated by paragraph formatting.
newtype VisBlock = VisBlock [VisItem]
                deriving (Eq)

-- List of VisBlocks that start with a title for that list.
newtype VisGroup = VisGroup [VisBlock]
                 deriving (Eq)

-- List of VisGroups where each group has the same length.
newtype VisTable = VisTable [VisGroup]
                 deriving (Eq)

-- A VisParagraph is just a suggestive name for a list of VisBlocks.
type VisParagraph = [VisBlock]

-- An article is just a list of VisParagraphs.
type VisArticle = [VisParagraph]

-- Show Instances
--------------------------------------------------------------------------------

instance Show VisItem where
  show (VisItem (s,v)) = "VisItem " ++ show s ++ " " ++ show v  
  showList is = showContentList (zip is [0..]) 6

instance Show VisBlock where
   show (VisBlock is) = "VisBlock\n" ++ show is
   showList bs = showContentList (zip bs [0..]) 4

instance Show VisGroup where
    show (VisGroup bs) = "VisGroup\n" ++ show bs
    showList gs = showContentList (zip gs [0..]) 2

instance Show VisTable where
    show (VisTable gs) = "VisTable\n" ++ show gs
    showList ts = showContentList (zip ts [0..]) 0

-- Support function to assist in showing list of content types.
showContentList :: Show a => [(a,Int)] -> Int -> ShowS
showContentList [] _ = id
showContentList ((i,0):is) n = (showSpaces n ++) . shows i . showContentList is n
showContentList ((i,_):is) n = ("\n" ++) . (showSpaces n ++) . shows i . showContentList is n

showSpaces n = replicate n ' '

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

-- Single useful VisItem.
itemSimple :: String -> VisStyle -> VisItem
itemSimple = visItem

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
     | null vis = True
     | otherwise = and $ fmap isItemNull vis
   where
     vis = unBlock vb

-- Checks if a VisItem is empty.
isItemNull :: VisItem -> Bool
isItemNull = null . unItemText


-- Calculates the maximum length of the text in a list of VisBlocks.
blockTextMax :: [VisBlock] -> Int
blockTextMax bs = maximumInt
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
      pred c = isPunctuation c || isSpace c
      splitHead = span pred vt
      splitMiddle = span pred $ reverse $ snd splitHead


-- Text Formatting
--------------------------------------------------------------------------------

-- Reformats a list of VisBlocks so they respect the same maximum width.
--    The first line can be indented using the padding given.
blockPublish :: Int -> Int -> [VisBlock] -> [VisBlock] 
blockPublish w p vbs = rebuildBlocks [[]] p vbs
      where 
        rebuildBlocks cis cw rbs
            | null rbs = reverse $ fmap (visBlock . reverse) cis
            | p > 0 && exactLength 1 cis && null prevItemList = rebuildBlocks indentFirst cw rbs
            | curTotalWidth <= w = rebuildBlocks curInsert curTotalWidth (drop 1 rbs)
            | otherwise = rebuildBlocks fitInsert 0 (remInsert:drop 1 rbs)
          where 
            curItemList = unBlock . fromMaybe blockEmpty $ headMaybe rbs
            curItem = fromMaybe itemEmpty $ headMaybe curItemList
            curWidth = itemTextWidth curItem
            curTotalWidth = curWidth + cw

            prevItemList = head cis
            curInsert = (curItem:prevItemList) : drop 1 cis
            fitInsert = [] : ((fitItem:prevItemList) : drop 1 cis)
            remInsert = visBlock [remItem]

            remItem = snd splitItem
            fitItem = fst splitItem
            splitItem = itemSplit (w - cw) curItem

            indentFirst = [ visItem (repeatChar p ' ') visDefault : []]


-- Splits a VisBlock into two, splitting on a desired text length.
blockSplit :: Int -> VisBlock -> (VisBlock, VisBlock)
blockSplit w vb = ( visBlock (fst processItems)
                  , visBlock (snd processItems) )
      where
        items = unBlock vb
        processItems = processItems [] 0 items
           where 
            processItems cvis cw rvis
                | curWidth <= w && not (null rvis) = processItems (vi:cvis) curWidth (drop 1 rvis)
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
groupAverage :: VisSettings -> [VisGroup] -> [VisGroup]
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
       tgtLength = avgLength + div avgLength (groupOverflowRatio gof)
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
       bodyVis = headerList >>= fmap (snd . unItem ) . take 1
       body = transpose $
              fmap (\ss -> fmap (uncurry blockSimple)(zip ss bodyVis)) sss
       fullTable = fmap (uncurry visGroup) (zip header body)


-- Builds a table that is already properly built, with a VisGroup for each column,
--     just lacking the invariant check.
visTableGroups :: [VisGroup] -> Maybe VisTable
visTableGroups vgs = visTable vgs vgsLengthMatch
    where 
       headLength = maybe 0 (length . unGroup) $ headMaybe vgs
       vgsLengthMatch = and $ ((==) headLength . length . unGroup) <$> drop 1 vgs


-- Enforces the invariant that the header and each row 
--    must have the same length.
isTableBalanced :: [VisBlock] -> [[a]] -> Bool
isTableBalanced h rs = and $ fmap (\r -> headLength == length r) rs
            where headLength = length (unBlockList h) 


-- Rules && Solid
--------------------------------------------------------------------------------
newtype VisRule = VisRule (Char, VisStyle)
                  deriving (Eq)

instance Show VisRule where
    show (VisRule (c,v)) = "VisRule " ++ show c ++ " " ++ show v

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
visRuleItem r n = visItem (repeatChar (unn n) (unRuleChar r)) (unRuleStyle r)





