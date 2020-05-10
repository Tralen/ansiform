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
            )

instance Show VisSettings where
    show (VisSettings (w,m,g)) = "VisSettings"
                                ++ "\n  Screen Width: " ++ show w
                                ++ "\n  Minimum Space: " ++ show m
                                ++ "\n  Group Overflow: " ++ show g ++ "%"

-- Wrapper
visSettings :: VisWidth -> VisWidth -> VisNumber -> VisSettings
visSettings w m g = VisSettings (w, m, g)


-- Unwrappers
unSettings :: VisSettings -> (VisWidth, VisWidth, VisNumber)
unSettings (VisSettings s) = s

unWidth :: VisSettings -> VisWidth
unWidth (VisSettings (w,_,_)) = w

unMinSpace :: VisSettings -> VisWidth
unMinSpace (VisSettings (_,m,_)) = m

unGroupOverflow :: VisSettings -> VisNumber
unGroupOverflow (VisSettings (_,_,g)) = g


-- Default
defaultSettings :: IO VisSettings
defaultSettings = termW >>= \w -> return $ visSettings (visNumber w) 2 25


-- Support Functions
--------------------------------------------------------------------------------

-- Maximum allowed for groups to exceed the average length, 
--    Converts the percentage to the divisor.
groupOverflowRatio :: VisNumber -> Int
groupOverflowRatio n | n <= 0 = 0 | n >= 100 = 1 | otherwise = div 100 (unn n)


setWidth :: VisWidth -> VisSettings -> VisSettings
setWidth n (VisSettings (_,m,g)) = visSettings n m g

setMinSpace :: VisWidth -> VisSettings -> VisSettings
setMinSpace n (VisSettings (w,_,g)) = visSettings w n g

setGroupOverflow :: VisNumber -> VisSettings -> VisSettings
setGroupOverflow n (VisSettings (w,m,_)) = visSettings w m n



