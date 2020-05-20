module Vis (module All) where

--------------------------------------------------------------------------------
import           Vis.Content   as All
import           Vis.Page      as All
import           Vis.Printer   as All
import           Vis.Section   as All
import           Vis.Settings  as All
import           Vis.Style     as All

 -- REMOVE --
import           Example       as All
import           Vis.Internal  as All


-- TODO:
--   Move IO to the outermost level.
--   See if IO can be restricted to Width in VisSettings.
--   Implement the minimum lines for Sections.
--   Consider a Manager type that handles the page swap, redraw, etc.
--   Migration to Text.
--   Migration to Seq.
--   Run with -Wall and -Werror


newtype VisState = VisState (VisSettings,VisPage,[VisNumber])

visState :: VisSettings -> VisPage -> [VisNumber] -> VisState
visState s p ns = VisState (s,p,ns)

unStateSettings :: VisState -> VisSettings
unStateSettings (VisState (s,_,_)) = s

unStatePage :: VisState -> VisPage
unStatePage (VisState (_,p,_)) = p

unStateResults :: VisState -> [VisNumber]
unStateResults (VisState (_,_,ns)) = ns

amendResults :: VisState -> [VisNumber] -> VisState
amendResults (VisState (s,p,_)) ns = visState s p ns


-- Workflow Functions
--------------------------------------------------------------------------------

start :: VisPage -> IO VisSettings -> IO VisState 
start p s = s >>= \s' -> replace p $ visState s' p []


replace :: VisPage -> VisState -> IO VisState
replace p st = clr 0 >> runPage (unStateSettings st) p 
                     >>= \ns -> return $ amendResults st ns


amend :: VisSection -> VisNumber -> VisState -> IO VisState
amend s n st = undefined -- prints only a section, redrawing following sections.


redraw = undefined -- prints the saved page again.


--------------------------------------------------------------------------------
testMain = start exPage_1 mySettings >>= \x -> 
           getLine >>
           replace exPage_2 x >>= \x' ->
           getLine >>
           amend exBody_3 1 x' >>
           getLine


mySettings = settings [width 120, minSpace 3]

