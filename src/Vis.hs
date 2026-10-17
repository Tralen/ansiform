-- | A small formatting DSL for building visual command line interfaces.
--
--   The library is split in two layers:
--
--   * Pure builders produce immutable values such as 'VisBlock', 'VisTable',
--     'VisSection' and 'VisPage'.
--
--   * The drawing layer ('Vis.Draw') writes those values to the terminal and
--     keeps track of the number of lines printed, so pages can be redrawn.
--
--   Import this module to get the whole public API at once, or import the
--   individual modules for qualified access.
module Vis (module All) where

--------------------------------------------------------------------------------
import           Vis.Content   as All
import           Vis.Draw      as All
import           Vis.Number    as All
import           Vis.Page      as All
import           Vis.Printer   as All
import           Vis.Sample    as All
import           Vis.Section   as All
import           Vis.Settings  as All
import           Vis.Style     as All


-- TODO:
--   Migration to Text.
--   Migration to Seq.
--   Rename types to remove the Vis prefix, leave that to namespacing.
