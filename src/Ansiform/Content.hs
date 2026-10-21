-- | Pure builders for items, blocks, groups, tables, paragraphs and rules.
module Ansiform.Content
    ( module Ansiform.Content
    , Internal.Item
    , Internal.Block
    , Internal.Rule
    , Internal.Group
    , Internal.Table
    , Internal.Paragraph
    , Internal.Article
    , Internal.blockEmpty
    , Internal.blockSimple
    ) where

import Ansiform.Internal.Content as Internal
import Ansiform.Style
--------------------------------------------------------------------------------
import Data.List

-- Basic builders
--------------------------------------------------------------------------------

-- | Builds an item from text and a style, removing non-printable characters.
item :: String -> Style -> Item
item = formItem

-- | Builds a block, removing empty items.
block :: [Item] -> Block
block = formBlock

-- Block Builders
--------------------------------------------------------------------------------

-- | Builds a block from a list of text fragments and their styles.
blockCycle :: [(String, Style)] -> Block
blockCycle = formBlock . formItemList

-- | Builds a block with a repeated separator between elements.
blockSeq :: [String] -> Style -> String -> Style -> Block
blockSeq ss v sep va = formBlock $ intersperse sep' $ fmap (`formItem` v) ss
  where
    sep' = formItem sep va

-- | Builds a block where the first occurrence of a character uses a different style.
blockMark :: Char -> String -> Style -> Style -> Block
blockMark e t ve vt = blockCycle testFirst
  where
    splitted = span (/= e) t
    rest = snd splitted
    begin = fst splitted
    build = [(take 1 rest, ve), (drop 1 rest, vt)]
    testFirst
        | null begin = build
        | otherwise = (begin, vt) : build

-- Derivative Block Builders
--------------------------------------------------------------------------------

-- | Builds an index followed by text, used in groups and lists.
blockEnum :: String -> String -> Color -> Block
blockEnum i t c =
    blockCycle
        [ (i, normal c)
        , (" ", styleDefault)
        , (t, normal colorDefault)
        ]

-- | Builds a block of the form @left / right@.
blockSlash :: String -> String -> Color -> Block
blockSlash t1 t2 c =
    blockCycle
        [ (t1, normal c)
        , (" / ", normal black')
        , (t2, normal c)
        ]

-- | Builds a menu entry of the form @index: text@ with a custom key style.
blockMenuStyle :: String -> String -> Style -> Block
blockMenuStyle i t vs =
    blockCycle
        [ (i, vs)
        , (": ", normal black')
        , (t, normal colorDefault)
        ]

-- | Builds a menu entry of the form @index: text@ with a colored key.
blockMenu :: String -> String -> Color -> Block
blockMenu i t c = blockMenuStyle i t (bold c)

-- | Builds a block of the form @name -> value@.
blockVal :: String -> String -> Color -> Block
blockVal t v c =
    blockCycle
        [ (t, styleDefault)
        , (" -> ", normal black')
        , (v, normal c)
        ]

-- | Builds a chain of elements separated by @->@.
blockAssoc :: [String] -> Style -> Style -> Block
blockAssoc ss v = blockSeq ss v " -> "

-- | Builds a chain of elements separated by @<-@.
blockAssoc' :: [String] -> Style -> Style -> Block
blockAssoc' ss v = blockSeq ss v " <- "

-- | Builds a chain of elements separated by @|@.
blockBars :: [String] -> Style -> Style -> Block
blockBars ss v = blockSeq ss v " | "

-- | Builds a block where one letter uses a different style.
blockMarked :: Char -> String -> Style -> Block
blockMarked e t ve = blockMark e t ve styleDefault

-- Group Builders
--------------------------------------------------------------------------------

-- | Builds a group from a header and its body blocks.
groupSimple :: Block -> [Block] -> Group
groupSimple = formGroup

-- Table Builders
--------------------------------------------------------------------------------

-- | Builds a table where each cell is a block with its own style and composition.
tableBlocks :: [Block] -> [[Block]] -> Maybe Table
tableBlocks = formTableBlocks

-- | Builds a table where each column has a single style and the header has another.
tableSimple :: [Block] -> Style -> [[String]] -> Maybe Table
tableSimple = formTableSimple

-- | Builds a table from groups that are already organized by column.
tableGroups :: [Group] -> Maybe Table
tableGroups = formTableGroups

-- Rule Builders
--------------------------------------------------------------------------------

-- | Builds a horizontal rule from a character and a style.
rule :: Char -> Style -> Rule
rule = formRule

-- | Builds a rule that uses a dot.
ruleDefault :: Style -> Rule
ruleDefault = formRule '.'

-- | Builds a solid rule made of spaces with a background color.
ruleSolid :: Color -> Rule
ruleSolid c = formRule ' ' (solid c)
