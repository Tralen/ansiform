module Vis.Content ( module Vis.Builder
                   , Item.VisItem, Item.VisBlock, Item.VisRule
                   , Item.VisGroup, Item.VisTable
                   , Item.VisParagraph, Item.VisArticle
                   , Item.itemSimple
                   , Item.blockSimple ) where

--------------------------------------------------------------------------------
import           Data.List
import           Vis.Item as Item
import           Vis.Style


-- Block Builders
--------------------------------------------------------------------------------

-- VisBlock formed by a list of Elements, each with its VisStyle.
blockCycle :: [(String, VisStyle)] -> VisBlock
blockCycle = visBlock . visItemList

-- VisBlock of the form 'Element1 S Element2 S Element3...',
--    where S is a repeated separator.
blockSeq :: [String] -> VisStyle -> String -> VisStyle -> VisBlock
blockSeq ss v sep va = visBlock $ intersperse sep' $ fmap (\s -> visItem s v)ss
      where sep' = visItem sep va
       
-- VisBlock of the form 'Element', where a given character has a different style.
blockMark :: Char -> String -> VisStyle -> VisStyle -> VisBlock
blockMark e t ve vt = blockCycle testFirst
                     where splitted = span (/= e) t
                           rest = snd splitted
                           begin = fst splitted
                           build = [(take 1 rest, ve), (drop 1 rest, vt)]
                           testFirst | null begin = build
                                     | otherwise = (begin, vt) : build


-- Derivative Block Builders
--------------------------------------------------------------------------------

-- VisBlock of the form 'Index Element' to be used on groups and lists.
blockEnum :: String -> String -> VisColor -> VisBlock
blockEnum i t c = blockCycle [(i, normal c)
                             ,(" ", styleDefault)
                             ,(t, normal colorDefault)]

-- VisBlock of the form 'Element / Element'.
blockSlash :: String -> String -> VisColor -> VisBlock
blockSlash t1 t2 c = blockCycle [(t1, normal c)
                                ,(" / ", normal black')
                                ,(t2, normal c)]

-- VisBlock of the form 'Index: Element' to be used on menus.
blockMenu :: String -> String -> VisColor -> VisBlock
blockMenu i t c = blockCycle [(i, bold c)
                             ,(": ", normal black')
                             ,(t, normal colorDefault)]

-- VisBlock of the form 'Element -> Val'.
blockVal :: String -> String -> VisColor -> VisBlock
blockVal t v c = blockCycle [(t, styleDefault)
                            ,(" -> ", normal black')
                            ,(v, normal c)]

-- VisBlock of the form 'Element1 -> Element2 -> Element3...'.
blockAssoc :: [String] -> VisStyle -> VisStyle -> VisBlock
blockAssoc ss v va = blockSeq ss v " -> " va

-- VisBlock of the form 'Element1 <- Element2 <- Element3...'.
blockAssoc' :: [String] -> VisStyle -> VisStyle -> VisBlock
blockAssoc' ss v va = blockSeq ss v " <- " va

-- VisBlock of the form 'Element1 | Element2 | Element3...'.
blockBars :: [String] -> VisStyle -> VisStyle -> VisBlock
blockBars ss v va = blockSeq ss v " | " va


-- VisBlock of the form 'Element' where one letter is of a different style.
blockMarked :: Char -> String -> VisStyle -> VisBlock
blockMarked e t ve = blockMark e t ve styleDefault


-- Group Builders
--------------------------------------------------------------------------------

-- VisGroup builder, taking group header and contents separately.
groupSimple :: VisBlock -> [VisBlock] -> VisGroup
groupSimple = visGroup


-- Table Builders
--------------------------------------------------------------------------------

-- Builds a table where each element has its own style and composition.
--   Each element is a VisBlock so it can use composite styles.
tableBlocks :: [VisBlock] -> [[VisBlock]] -> Maybe VisTable
tableBlocks = visTableBlocks

-- Builds a table where every column has a single VisStyle, given in the header.
--   An additional VisStyle is used to style the header itself.
tableSimple :: [VisBlock] -> VisStyle -> [[String]] -> Maybe VisTable
tableSimple = visTableSimple

-- Builds a table that is already properly built, with a VisGroup for each column,
tableGroups :: [VisGroup] -> Maybe VisTable
tableGroups = visTableGroups


-- Rule Builders
--------------------------------------------------------------------------------
rule :: Char -> VisStyle -> VisRule
rule = visRule

ruleDefault :: VisStyle -> VisRule
ruleDefault v = visRule '.' v

ruleSolid :: VisColor -> VisRule
ruleSolid c = visRule ' ' (solid c) 
