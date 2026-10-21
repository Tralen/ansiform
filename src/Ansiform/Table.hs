-- | Per-column alignment and truncation for tables.
module Ansiform.Table
    ( Align (..)
    , Borders (..)
    , Ellipsis (..)
    , ColumnSpec (..)
    , TableFormat
    , defaultColumnSpec
    , defaultTableFormat
    , tableFormat
    ) where

--------------------------------------------------------------------------------
import Ansiform.Internal.Table

-- Builders
--------------------------------------------------------------------------------

-- | Builds a table format from a list of column specifications.
tableFormat :: [ColumnSpec] -> TableFormat
tableFormat = formTableFormat
