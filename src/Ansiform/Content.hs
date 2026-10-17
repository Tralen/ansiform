module Ansiform.Content ( module Ansiform.Content
                   , Internal.Item, Internal.Block, Internal.Rule
                   , Internal.Group, Internal.Table
                   , Internal.Paragraph, Internal.Article
                   , Internal.blockEmpty, Internal.blockSimple ) where

--------------------------------------------------------------------------------
import           Data.List
import           Ansiform.Internal.Content as Internal
import           Ansiform.Style


-- Basic builders
--------------------------------------------------------------------------------

item :: String -> Style -> Item
item = formItem

block :: [Item] -> Block
block = formBlock

-- Block Builders
--------------------------------------------------------------------------------

-- Block formed by a list of Elements, each with its Style.
blockCycle :: [(String, Style)] -> Block
blockCycle = formBlock . formItemList

-- Block of the form 'Element1 S Element2 S Element3...',
--    where S is a repeated separator.
blockSeq :: [String] -> Style -> String -> Style -> Block
blockSeq ss v sep va = formBlock $ intersperse sep' $ fmap (\s -> formItem s v) ss
      where sep' = formItem sep va
       
-- Block of the form 'Element', where a given character has a different style.
blockMark :: Char -> String -> Style -> Style -> Block
blockMark e t ve vt = blockCycle testFirst
                     where splitted = span (/= e) t
                           rest = snd splitted
                           begin = fst splitted
                           build = [(take 1 rest, ve), (drop 1 rest, vt)]
                           testFirst | null begin = build
                                     | otherwise = (begin, vt) : build


-- Derivative Block Builders
--------------------------------------------------------------------------------

-- Block of the form 'Index Element' to be used on groups and lists.
blockEnum :: String -> String -> Color -> Block
blockEnum i t c = blockCycle [(i, normal c)
                             ,(" ", styleDefault)
                             ,(t, normal colorDefault)]

-- Block of the form 'Element / Element'.
blockSlash :: String -> String -> Color -> Block
blockSlash t1 t2 c = blockCycle [(t1, normal c)
                                ,(" / ", normal black')
                                ,(t2, normal c)]

-- Block of the form 'Index: Element' to be used on menus.
blockMenu :: String -> String -> Color -> Block
blockMenu i t c = blockCycle [(i, bold c)
                             ,(": ", normal black')
                             ,(t, normal colorDefault)]

-- Block of the form 'Element -> Val'.
blockVal :: String -> String -> Color -> Block
blockVal t v c = blockCycle [(t, styleDefault)
                            ,(" -> ", normal black')
                            ,(v, normal c)]

-- Block of the form 'Element1 -> Element2 -> Element3...'.
blockAssoc :: [String] -> Style -> Style -> Block
blockAssoc ss v va = blockSeq ss v " -> " va

-- Block of the form 'Element1 <- Element2 <- Element3...'.
blockAssoc' :: [String] -> Style -> Style -> Block
blockAssoc' ss v va = blockSeq ss v " <- " va

-- Block of the form 'Element1 | Element2 | Element3...'.
blockBars :: [String] -> Style -> Style -> Block
blockBars ss v va = blockSeq ss v " | " va


-- Block of the form 'Element' where one letter is of a different style.
blockMarked :: Char -> String -> Style -> Block
blockMarked e t ve = blockMark e t ve styleDefault


-- Group Builders
--------------------------------------------------------------------------------

-- Group builder, taking group header and contents separately.
groupSimple :: Block -> [Block] -> Group
groupSimple = formGroup


-- Table Builders
--------------------------------------------------------------------------------

-- Builds a table where each element has its own style and composition.
--   Each element is a Block so it can use composite styles.
tableBlocks :: [Block] -> [[Block]] -> Maybe Table
tableBlocks = formTableBlocks

-- Builds a table where every column has a single Style, given in the header.
--   An additional Style is used to style the header itself.
tableSimple :: [Block] -> Style -> [[String]] -> Maybe Table
tableSimple = formTableSimple

-- Builds a table that is already properly built, with a Group for each column,
tableGroups :: [Group] -> Maybe Table
tableGroups = formTableGroups


-- Rule Builders
--------------------------------------------------------------------------------
rule :: Char -> Style -> Rule
rule = formRule

ruleDefault :: Style -> Rule
ruleDefault v = formRule '.' v

ruleSolid :: Color -> Rule
ruleSolid c = formRule ' ' (solid c) 
