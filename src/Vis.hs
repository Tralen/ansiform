module Vis (module All) where

--------------------------------------------------------------------------------
import           Vis.Builder   as All
import           Vis.Printer   as All
import           Vis.Section   as All
import           Vis.Style     as All

 -- REMOVE --
import           Vis.Content   as All
import           Vis.Example   as All
import           Vis.Number    as All
import           Vis.Print     as All
import           Vis.Settings  as All
import           Vis.Terminal  as All
import           Vis.Utils     as All


-- TODO:
--   Transformar os Settings em um tipo de fato,
--     considerar colocar o settings do GroupAverage ali.
--   Rename Content to Block and Builder to Content.
--   Make so that VisItem doesn't accept non-printable chars.


