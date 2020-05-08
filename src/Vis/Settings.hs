module Vis.Settings where

--------------------------------------------------------------------------------
import           Vis.Number


-- Settings type
--------------------------------------------------------------------------------
-- Settings are a pair with:
--   Current screen width
--   Minimum space to be used bettwen blocks.
type VisSettings = (VisWidth,VisMinSpace)

visSettings :: VisWidth -> VisMinSpace -> VisSettings
visSettings w m = (w, m)


-- Maximum allowed for groups to exceed the average length, 
--    3 is a third larger, 4 is a fourth and so on.
groupExcessCfg :: Int
groupExcessCfg = 4
-- CALCULAR como 100 / x.
-- MUDAR PARA visNumber


-- setMinSpace n s = visSettings (unWidth s) n (unGroupFlow s)
-- setGroupFlow 
