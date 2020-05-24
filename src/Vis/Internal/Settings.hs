module Vis.Internal.Settings where

--------------------------------------------------------------------------------
import           Data.List
import           Vis.Internal.Number
import           Vis.Internal.Sample
import           Vis.Internal.Terminal


-- Config type
--------------------------------------------------------------------------------

-- Config is just a list of functions to modify the settings, made by the user.
newtype VisSettings = VisSettings [VisConfig -> VisConfig]

instance VisSample VisSettings where
    sample vs = sample =<< runSettings vs
    show' _ (VisSettings fs) = ""

visSettings :: [VisConfig -> VisConfig] -> VisSettings
visSettings = VisSettings

unSettings :: VisSettings -> [VisConfig -> VisConfig]
unSettings (VisSettings fs) = fs


-- Function to build the settings in a declarative style.
runSettings :: VisSettings -> IO VisConfig
runSettings stgs = initialConfig >>= \dft ->
                  return $ foldl' (\sets f -> f sets) dft $ unSettings stgs 

-- Settings type
--------------------------------------------------------------------------------

-- Config is a tuple of the values needed to run the printers and more.
newtype VisConfig = VisConfig 
            ( VisWidth  -- Current screen width
            , VisWidth  -- Minimum space to be used bettwen blocks.
            , VisNumber -- Percentage that groups are allowed to overflow.
            )

instance VisSample VisConfig where
    sample vc = putStrLn $ show' 0 vc
    show' _ (VisConfig (w,m,g)) = "Settings"
                               ++ "\n  Screen Width: " ++ show w
                               ++ "\n  Minimum Space: " ++ show m
                               ++ "\n  Group Overflow: " ++ show g ++ "%"

-- Wrapper
visConfig :: VisWidth -> VisWidth -> VisNumber -> VisConfig
visConfig w m g = VisConfig (w, m, g)


-- Unwrappers
unConfig :: VisConfig -> (VisWidth, VisWidth, VisNumber)
unConfig (VisConfig s) = s

unWidth :: VisConfig -> VisWidth
unWidth (VisConfig (w,_,_)) = w

unMinSpace :: VisConfig -> VisWidth
unMinSpace (VisConfig (_,m,_)) = m

unGroupOverflow :: VisConfig -> VisNumber
unGroupOverflow (VisConfig (_,_,g)) = g


-- Generates the base settings to be configured.
initialConfig :: IO VisConfig
initialConfig = termW >>= \w -> return $ visConfig (visNumber w) 2 25

-- Support Functions
--------------------------------------------------------------------------------

-- Maximum allowed for groups to exceed the average length, 
--    Converts the percentage to the divisor.
groupOverflowRatio :: VisNumber -> Int
groupOverflowRatio n | n <= 0 = 0 | n >= 100 = 1 | otherwise = div 100 (unn n)


setWidth :: VisWidth -> VisConfig -> VisConfig
setWidth n (VisConfig (_,m,g)) = visConfig n m g

setMinSpace :: VisWidth -> VisConfig -> VisConfig
setMinSpace n (VisConfig (w,_,g)) = visConfig w n g

setGroupOverflow :: VisNumber -> VisConfig -> VisConfig
setGroupOverflow n (VisConfig (w,m,_)) = visConfig w m n



