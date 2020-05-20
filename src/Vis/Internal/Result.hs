module Vis.Internal.Result where

--------------------------------------------------------------------------------
import           Vis.Internal.Number
import           Vis.Internal.Section


-- Results type
--------------------------------------------------------------------------------

-- The results are a list of tuples, 
--   of VisSections paired with the printed lines for each section.
newtype VisResult = VisResult (VisSection, VisNumber)

visResult :: VisSection -> VisNumber -> VisResult
visResult s n = VisResult (s,n)

unResultSection :: VisResult -> VisSection
unResultSection (VisResult (s,_)) = s

unResultNumber :: VisResult -> VisNumber 
unResultNumber (VisResult (_,n)) = n
