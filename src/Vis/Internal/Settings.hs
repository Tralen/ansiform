module Vis.Internal.Settings where

--------------------------------------------------------------------------------
import           Vis.Internal.Number
import           Vis.Internal.Terminal


-- Settings type
--------------------------------------------------------------------------------

-- Settings are a tuple of the settings need to run the printers and more.
newtype VisSettings = VisSettings 
            ( VisWidth  -- Current screen width
            , VisWidth  -- Minimum space to be used bettwen blocks.
            , VisNumber -- Percentage that groups are allowed to overflow.
            , Bool      -- Verbose mode.
            )

instance Show VisSettings where
    show (VisSettings (w,m,g,v)) = "VisSettings"
                                ++ "\n  Screen Width: " ++ show w
                                ++ "\n  Minimum Space: " ++ show m
                                ++ "\n  Group Overflow: " ++ show g ++ "%"
                                ++ "\n  Verbose Mode: " ++ show v

-- Wrapper
visSettings :: VisWidth -> VisWidth -> VisNumber -> Bool -> VisSettings
visSettings w m g v = VisSettings (w, m, g, v)


-- Unwrappers
unSettings :: VisSettings -> (VisWidth, VisWidth, VisNumber, Bool)
unSettings (VisSettings s) = s

unWidth :: VisSettings -> VisWidth
unWidth (VisSettings (w,_,_,_)) = w

unMinSpace :: VisSettings -> VisWidth
unMinSpace (VisSettings (_,m,_,_)) = m

unGroupOverflow :: VisSettings -> VisWidth
unGroupOverflow (VisSettings (_,_,g,_)) = g

unVerbose :: VisSettings -> VisWidth
unVerbose (VisSettings (_,_,v,_)) = v

-- Default
defaultSettings :: VisSettings
defaultSettings = visSettings 80 2 25 True


-- Support Functions
--------------------------------------------------------------------------------

-- Maximum allowed for groups to exceed the average length, 
--    Converts the percentage to the divisor.
groupOverflowRatio :: VisNumber -> Int
groupOverflowRatio n | n <= 0 = 0 | n >= 100 = 1 | otherwise = div 100 (unn n)


setWidth :: VisWidth -> VisSettings -> VisSettings
setWidth n (VisSettings (_,m,g,v)) = visSettings n m g v

setMinSpace :: VisWidth -> VisSettings -> VisSettings
setMinSpace n (VisSettings (w,_,g,v)) = visSettings w n g v

setGroupOverflow :: VisNumber -> VisSettings -> VisSettings
setGroupOverflow n (VisSettings (w,m,_,v)) = visSettings w m n v

setVerbose :: Bool -> VisSettings -> VisSettings
setVerbose b (VisSettings (w,m,g,_)) = visSettings w m g b



