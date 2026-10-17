-- | Internal style representation and ANSI SGR application.
module Ansiform.Internal.Style 
                    ( module Ansiform.Internal.Style
                    , ANSI.ColorIntensity(..)
                    , ANSI.ConsoleIntensity(..), ANSI.Underlining(..)
                    , ANSI.cursorUp, ANSI.cursorDown
                    ) where
           
--------------------------------------------------------------------------------
import           Control.Monad.IO.Class
import           System.Console.ANSI as ANSI hiding (Color)
import qualified System.Console.ANSI as ANSI
import           System.IO (Handle)
import           Ansiform.Internal.Sample
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
-- | An ANSI color, optionally with a specific intensity.
data Color = ColorDefault | Color ColorIntensity ANSI.Color
                deriving (Eq, Show)

instance Sample Color where
    sampleShow _ ColorDefault = "ColorDefault"
    sampleShow _ (Color Dull c) = show c
    sampleShow _ (Color Vivid c) = show c ++ "'"  


-- Wrapper and Default
formColor :: ColorIntensity -> ANSI.Color -> Color
formColor = Color

defaultColor :: Color
defaultColor = ColorDefault

-- Unwrappers
unColor :: Color -> ANSI.Color
unColor c = case c of
          ColorDefault -> ANSI.White
          Color _ c' -> c'

unIntensity  :: Color -> ColorIntensity
unIntensity c = case c of
          ColorDefault -> Dull
          Color i' _ -> i'

-- Default check.
isColorDefault :: Color -> Bool
isColorDefault vc = case vc of ColorDefault -> True ; _ -> False


-- Formatting
--------------------------------------------------------------------------------
--                                            Bold             Italic Underline
-- | Bold, italic and underline attributes.
data Format = FormatDefault | Format ConsoleIntensity Bool   Underlining
                 deriving (Eq, Show)

instance Sample Format where
    sampleShow _ FormatDefault = "FormatDefault"
    sampleShow _ (Format BoldIntensity False NoUnderline) = "Bold"
    sampleShow _ (Format NormalIntensity True NoUnderline) = "Italic"
    sampleShow _ (Format NormalIntensity False SingleUnderline) = "Underline"
    sampleShow _ (Format BoldIntensity True NoUnderline) = "BoldItalic"
    sampleShow _ (Format BoldIntensity False SingleUnderline) = "BoldUnderline"
    sampleShow _ (Format NormalIntensity True SingleUnderline) = "ItalicUnderline"
    sampleShow _ (Format BoldIntensity True SingleUnderline) = "BoldItalicUnderline"
    sampleShow _ _ = "Regular"


-- Wrapper and Default
formFormat :: ConsoleIntensity -> Bool -> Underlining -> Format 
formFormat = Format

defaultFormat :: Format
defaultFormat = FormatDefault

-- Unwrappers
unBold :: Format -> ConsoleIntensity
unBold vf = case vf of
      FormatDefault -> NormalIntensity
      Format b _ _ -> b

unItalic :: Format -> Bool
unItalic vf = case vf of
      FormatDefault -> False
      Format _ i _  -> i

unUnderline :: Format -> Underlining
unUnderline vf = case vf of
      FormatDefault -> NoUnderline
      Format _ _ u  -> u

-- Format checks.
isFormatDefault :: Format -> Bool
isFormatDefault vf = case vf of FormatDefault -> True ; _ -> False

isBold :: Format -> Bool
isBold vf = case unBold vf of BoldIntensity -> True; _ -> False

isItalic :: Format -> Bool
isItalic = unItalic

isUnderline :: Format -> Bool
isUnderline vf = case unUnderline vf of SingleUnderline -> True; _ -> False


-- Visual Styles
--------------------------------------------------------------------------------
-- | A foreground color, a background color and a format.
data Style = Zero | Style Color Color Format
                deriving (Eq, Show)

instance Sample Style where
  sampleShow _ Zero = "Reset"
  sampleShow _ (Style fc bg f) = "{" ++ sampleShow 0 fc ++ " " ++ sampleShow 0 bg ++ " " ++ sampleShow 0 f ++ "}"

-- Main function to apply SGR styles to a terminal handle.
--   When styling is disabled, no escape sequence is emitted.
applyStyle :: MonadIO m => Handle -> Bool -> Style -> m ()
applyStyle h True s = liftIO $ ANSI.hSetSGR h (Reset : styleCommands s)
applyStyle _ False _ = return ()

-- Resets visual styles, when styling is enabled.
resetStyle :: Handle -> Bool -> IO ()
resetStyle h enabled = applyStyle h enabled Zero

-- Constructs the final list of SGR instructions for Ansiform.
styleCommands ::  Style -> [SGR]
styleCommands s = case s of
                   Zero -> []
                   Style fc bc f ->
                        colorCommands fc bc ++ formatCommands f

-- Builds the color SGR list.
colorCommands :: Color -> Color -> [SGR]
colorCommands fc bc
    | isColorDefault fc && isColorDefault bc = []
    | isColorDefault bc = [ foregroundCommand fc ]
    | isColorDefault fc = [ backgroundCommand bc ]
    | otherwise = [ foregroundCommand fc, backgroundCommand bc ]
 where 
    foregroundCommand c = SetColor Foreground (unIntensity c) (unColor c)
    backgroundCommand c = SetColor Background (unIntensity c) (unColor c)


-- Builds the formatting SGR list.
formatCommands :: Format -> [SGR]
formatCommands f
      | isFormatDefault f = []
      | otherwise = [ SetConsoleIntensity (unBold f)
                    , SetItalicized (unItalic f)
                    , SetUnderlining (unUnderline f)
                    ]

-- Wrapper and Defaults
formStyle :: Color -> Color -> Format -> Style
formStyle = Style

defaultStyle :: Style
defaultStyle = formStyle defaultColor defaultColor defaultFormat

-- Unwrappers
unStyleForeground :: Style -> Color
unStyleForeground s = case s of Zero -> defaultColor ; Style fc _ _ -> fc

unStyleBackground :: Style -> Color
unStyleBackground s = case s of Zero -> defaultColor ; Style _ bc _ -> bc

unStyleFormat :: Style -> Format
unStyleFormat s = case s of Zero -> defaultFormat ; Style _ _ f -> f


-- Style checks
isZero :: Style -> Bool
isZero v = case v of Zero -> True ; _ -> False

isSpecial :: Style -> Bool
isSpecial vs = isBold vf || isItalic vf || isUnderline vf || isColored vs || isSolid vs
    where vf = unStyleFormat vs

isSolid :: Style -> Bool
isSolid vs = not . isColorDefault $ unStyleBackground vs

isColored :: Style -> Bool
isColored vs = not . isColorDefault $ unStyleForeground vs

-- Sets the background color to a given color, respects if there is already one.
setBackground :: Color -> Style -> Style
setBackground c v = case v of
   Zero -> v
   Style fc bc f -> case bc of 
                ColorDefault -> formStyle fc c f
                _ -> v

-- Swaps the foreground and background color.
swapBackground :: Style -> Style
swapBackground v = case v of
   Zero -> v
   Style fc bc f -> formStyle bc fc f




