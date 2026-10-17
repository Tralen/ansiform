-- | A small formatting DSL for building visual command line interfaces.
--
--   The library is split in two layers:
--
--   * Pure builders produce immutable values such as 'VisBlock', 'VisTable',
--     'VisSection' and 'VisPage'.
--
--   * The drawing layer ('Ansiform.Draw') writes those values to the terminal and
--     keeps track of the number of lines printed, so pages can be redrawn.
--
--   Import this module to get the whole public API at once, or import the
--   individual modules for qualified access.
module Ansiform (module All) where

--------------------------------------------------------------------------------
import           Ansiform.Content   as All
import           Ansiform.Draw      as All
import           Ansiform.Number    as All
import           Ansiform.Page      as All
import           Ansiform.Printer   as All
import           Ansiform.Sample    as All
import           Ansiform.Section   as All
import           Ansiform.Settings  as All
import           Ansiform.Style     as All


-- TODO:
--   Migration to Text.
--   Migration to Seq.
--   Rename types to remove the Ansiform prefix, leave that to namespacing.
