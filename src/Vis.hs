module Vis (module All) where

--------------------------------------------------------------------------------
import           Vis.Content   as All
import           Vis.Draw      as All
import           Vis.Page      as All
import           Vis.Printer   as All
import           Vis.Section   as All
import           Vis.Settings  as All
import           Vis.Style     as All

 -- REMOVE --
import           Example       as All
import           Vis.Internal  as All


-- TODO:
--   Consider implementing the Empty Lines between sections as a Config.
--   Consider making the rules a part of the section?
--   Revert Show instances to default, create Sample functions.
--   Review if the Result type is needed.
--   Review if returning the IO VisNumber is necessary.
--   Create page for State.
--   Implement StateT.
--   Migration to Text.
--   Migration to Seq.
--   Rename types to remove the Vis prefix, leave that to namespacing.
--   Consider changing the visType builders, to mkType.
--   Run with -Wall and -Werror.

