module Ansiform.Internal.Settings where

--------------------------------------------------------------------------------
import qualified Data.List as List
import           Ansiform.Internal.Number
import           Ansiform.Internal.Sample
import           Ansiform.Internal.Terminal


-- Config type
--------------------------------------------------------------------------------

-- Config is just a list of functions to modify the settings, made by the user.
newtype Settings = Settings [Config -> Config]

instance Sample Settings where
    sample vs = sample =<< runSettings vs
    sampleShow _ (Settings _) = ""

visSettings :: [Config -> Config] -> Settings
visSettings = Settings

unSettings :: Settings -> [Config -> Config]
unSettings (Settings fs) = fs


-- Function to build the settings in a declarative style.
runSettings :: Settings -> IO Config
runSettings stgs = initialConfig >>= \dft ->
                  return $ List.foldl' (\sets f -> f sets) dft $ unSettings stgs

-- Settings type
--------------------------------------------------------------------------------

-- Config is a tuple of the values needed to run the printers and more.
newtype Config = Config 
            ( Width  -- Current screen width
            , Width  -- Minimum space to be used bettwen blocks.
            , Number -- Percentage that groups are allowed to overflow.
            ) deriving (Eq, Show)

instance Sample Config where
    sampleShow _ (Config (w,m,g)) = "Settings"
                               ++ "\n  Screen Width: " ++ show w
                               ++ "\n  Minimum Space: " ++ show m
                               ++ "\n  Group Overflow: " ++ show g ++ "%"

-- Wrapper
visConfig :: Width -> Width -> Number -> Config
visConfig w m g = Config (w, m, g)


-- Unwrappers
unConfig :: Config -> (Width, Width, Number)
unConfig (Config s) = s

unWidth :: Config -> Width
unWidth (Config (w,_,_)) = w

unMinSpace :: Config -> Width
unMinSpace (Config (_,m,_)) = m

unGroupOverflow :: Config -> Number
unGroupOverflow (Config (_,_,g)) = g


-- Generates the base settings to be configured.
initialConfig :: IO Config
initialConfig = termW >>= \w -> return $ visConfig (visNumber w) 2 25

-- Support Functions
--------------------------------------------------------------------------------

-- Maximum allowed for groups to exceed the average length, 
--    Converts the percentage to the divisor.
groupOverflowRatio :: Number -> Int
groupOverflowRatio n | n <= 0 = 0 | n >= 100 = 1 | otherwise = div 100 (unn n)


setWidth :: Width -> Config -> Config
setWidth n (Config (_,m,g)) = visConfig n m g

setMinSpace :: Width -> Config -> Config
setMinSpace n (Config (w,_,g)) = visConfig w n g

setGroupOverflow :: Number -> Config -> Config
setGroupOverflow n (Config (w,m,_)) = visConfig w m n



