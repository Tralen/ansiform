module Vis.Internal.Style 
                    ( module Vis.Internal.Style
                    , ANSI.Color(..), ANSI.ColorIntensity(..)
                    , ANSI.ConsoleIntensity(..), ANSI.Underlining(..)
                    , ANSI.cursorUp, ANSI.cursorDown
                    ) where
           
--------------------------------------------------------------------------------
import           Control.Monad.IO.Class
import           Data.Char
import           Data.Word
import           System.Console.ANSI as ANSI
import           Vis.Internal.Number
import           Vis.Internal.Sample
--------------------------------------------------------------------------------

{-

ANSI options:
ConsoleLayer        Foreground    Background
Color               Black   Red   Green   Yellow   Blue   Magenta   Cyan   White
ColorIntensity      Dull    Vivid
ConsoleIntensity    BoldIntensity       NormalIntensity
Underlining         SingleUnderline     NoUnderline
BlinkSpeed          SlowBlink     RapidBlink    NoBlink  

ANSI commands:
Reset    
SetConsoleIntensity         ConsoleIntensity    
SetItalicized               Bool
SetUnderlining              Underlining  
SetBlinkSpeed               BlinkSpeed    
SetVisible                  Bool
SetSwapForegroundBackground Bool    
SetColor                    ConsoleLayer ColorIntensity Color    

-}

-- Colors
--------------------------------------------------------------------------------
data VisColor = VisColorDefault | VisColor ColorIntensity Color
                deriving (Eq, Show)

instance VisSample VisColor where
    sampleShow _ VisColorDefault = "ColorDefault"
    sampleShow _ (VisColor Dull c) = show c
    sampleShow _ (VisColor Vivid c) = show c ++ "'"  


-- Wrapper and Default
visColor :: ColorIntensity -> Color -> VisColor
visColor = VisColor

visColorDefault :: VisColor
visColorDefault = VisColorDefault

-- Unwrappers
unColor :: VisColor -> Color
unColor c = case c of
          VisColorDefault -> White
          VisColor _ c' -> c'

unIntensity  :: VisColor -> ColorIntensity
unIntensity c = case c of
          VisColorDefault -> Dull
          VisColor i' _ -> i'

-- Default check.
isColorDefault :: VisColor -> Bool
isColorDefault vc = case vc of VisColorDefault -> True ; _ -> False


-- Formatting
--------------------------------------------------------------------------------
--                                            Bold             Italic Underline
data VisFormat = VisFormatDefault | VisFormat ConsoleIntensity Bool   Underlining
                 deriving (Eq, Show)

instance VisSample VisFormat where
    sampleShow _ VisFormatDefault = "FormatDefault"
    sampleShow _ (VisFormat BoldIntensity False NoUnderline) = "Bold"
    sampleShow _ (VisFormat NormalIntensity True NoUnderline) = "Italic"
    sampleShow _ (VisFormat NormalIntensity False SingleUnderline) = "Underline"
    sampleShow _ (VisFormat BoldIntensity True NoUnderline) = "BoldItalic"
    sampleShow _ (VisFormat BoldIntensity False SingleUnderline) = "BoldUnderline"
    sampleShow _ (VisFormat NormalIntensity True SingleUnderline) = "ItalicUnderline"
    sampleShow _ (VisFormat BoldIntensity True SingleUnderline) = "BoldItalicUnderline"
    sampleShow _ _ = "Regular"


-- Wrapper and Default
visFormat :: ConsoleIntensity -> Bool -> Underlining -> VisFormat 
visFormat = VisFormat

visFormatDefault :: VisFormat
visFormatDefault = VisFormatDefault

-- Unwrappers
unBold :: VisFormat -> ConsoleIntensity
unBold vf = case vf of
      VisFormatDefault -> NormalIntensity
      VisFormat b _ _ -> b

unItalic :: VisFormat -> Bool
unItalic vf = case vf of
      VisFormatDefault -> False
      VisFormat _ i _  -> i

unUnderline :: VisFormat -> Underlining
unUnderline vf = case vf of
      VisFormatDefault -> NoUnderline
      VisFormat _ _ u  -> u

-- Format checks.
isFormatDefault :: VisFormat -> Bool
isFormatDefault vf = case vf of VisFormatDefault -> True ; _ -> False

isBold :: VisFormat -> Bool
isBold vf = case unBold vf of BoldIntensity -> True; _ -> False

isItalic :: VisFormat -> Bool
isItalic = unItalic

isUnderline :: VisFormat -> Bool
isUnderline vf = case unUnderline vf of SingleUnderline -> True; _ -> False


-- Visual Styles
--------------------------------------------------------------------------------
data VisStyle = VisZero | VisStyle VisColor VisColor VisFormat
                deriving (Eq, Show)

instance VisSample VisStyle where
  sampleShow _ VisZero = "Reset"
  sampleShow _ (VisStyle fc bg f) = "{" ++ sampleShow 0 fc ++ " " ++ sampleShow 0 bg ++ " " ++ sampleShow 0 f ++ "}"

-- Main function to apply SGR styles to the terminal.
vis :: MonadIO m => VisStyle -> m ()
vis s = liftIO $ setSGR (Reset : visBuilder s)

-- Resets visual styles.
visZero :: IO ()
visZero = vis VisZero
vis0 = visZero

-- Constructs the final list of SGR instructions for Vis.
visBuilder ::  VisStyle -> [SGR]
visBuilder s = case s of
                   VisZero -> []
                   VisStyle fc bc f ->
                        visColorBuilder fc bc ++ visFormatBuilder f

-- Builds the color SGR list.
visColorBuilder :: VisColor -> VisColor -> [SGR]
visColorBuilder fc bc
    | isColorDefault fc && isColorDefault bc = []
    | isColorDefault bc = [ setForeground fc ]
    | isColorDefault fc = [ setBackground bc ]
    | otherwise = [ setForeground fc, setBackground bc ]
 where 
    setForeground c = SetColor Foreground (unIntensity c) (unColor c)
    setBackground c = SetColor Background (unIntensity c) (unColor c)


-- Builds the formatting SGR list.
visFormatBuilder :: VisFormat -> [SGR]
visFormatBuilder f
      | isFormatDefault f = []
      | otherwise = [ SetConsoleIntensity (unBold f)
                    , SetItalicized (unItalic f)
                    , SetUnderlining (unUnderline f)
                    ]

-- Wrapper and Defaults
visStyle :: VisColor -> VisColor -> VisFormat -> VisStyle
visStyle = VisStyle

visDefault :: VisStyle
visDefault = visStyle visColorDefault visColorDefault visFormatDefault

-- Unwrappers
unStyleForeground :: VisStyle -> VisColor
unStyleForeground s = case s of VisZero -> visColorDefault ; VisStyle fc _ _ -> fc

unStyleBackground :: VisStyle -> VisColor
unStyleBackground s = case s of VisZero -> visColorDefault ; VisStyle _ bc _ -> bc

unStyleFormat :: VisStyle -> VisFormat
unStyleFormat s = case s of VisZero -> visFormatDefault ; VisStyle _ _ f -> f


-- Style checks
isZero :: VisStyle -> Bool
isZero v = case v of VisZero -> True ; _ -> False

isSpecial :: VisStyle -> Bool
isSpecial vs = isBold vf || isItalic vf || isUnderline vf || isColored vs || isSolid vs
    where vf = unStyleFormat vs

isSolid :: VisStyle -> Bool
isSolid vs = not . isColorDefault $ unStyleBackground vs

isColored :: VisStyle -> Bool
isColored vs = not . isColorDefault $ unStyleForeground vs

-- Sets the background color to a given color, respects if there is already one.
visSetBG :: VisColor -> VisStyle -> VisStyle
visSetBG c v = case v of
   VisZero -> v
   VisStyle fc bc f -> case bc of 
                VisColorDefault -> visStyle fc c f
                _ -> v

-- Swaps the foreground and background color.
visSwapBG :: VisStyle -> VisStyle
visSwapBG v = case v of
   VisZero -> v
   VisStyle fc bc f -> visStyle bc fc f




