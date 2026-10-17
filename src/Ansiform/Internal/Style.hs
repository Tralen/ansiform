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
data Color = ColorDefault | Color ColorIntensity ANSI.Color
                deriving (Eq, Show)

instance Sample Color where
    sampleShow _ ColorDefault = "ColorDefault"
    sampleShow _ (Color Dull c) = show c
    sampleShow _ (Color Vivid c) = show c ++ "'"  


-- Wrapper and Default
visColor :: ColorIntensity -> ANSI.Color -> Color
visColor = Color

visColorDefault :: Color
visColorDefault = ColorDefault

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
visFormat :: ConsoleIntensity -> Bool -> Underlining -> Format 
visFormat = Format

visFormatDefault :: Format
visFormatDefault = FormatDefault

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
data Style = Zero | Style Color Color Format
                deriving (Eq, Show)

instance Sample Style where
  sampleShow _ Zero = "Reset"
  sampleShow _ (Style fc bg f) = "{" ++ sampleShow 0 fc ++ " " ++ sampleShow 0 bg ++ " " ++ sampleShow 0 f ++ "}"

-- Main function to apply SGR styles to the terminal.
vis :: MonadIO m => Style -> m ()
vis s = liftIO $ setSGR (Reset : visBuilder s)

-- Resets visual styles.
visZero :: IO ()
visZero = vis Zero

vis0 :: IO ()
vis0 = visZero

-- Constructs the final list of SGR instructions for Ansiform.
visBuilder ::  Style -> [SGR]
visBuilder s = case s of
                   Zero -> []
                   Style fc bc f ->
                        visColorBuilder fc bc ++ visFormatBuilder f

-- Builds the color SGR list.
visColorBuilder :: Color -> Color -> [SGR]
visColorBuilder fc bc
    | isColorDefault fc && isColorDefault bc = []
    | isColorDefault bc = [ setForeground fc ]
    | isColorDefault fc = [ setBackground bc ]
    | otherwise = [ setForeground fc, setBackground bc ]
 where 
    setForeground c = SetColor Foreground (unIntensity c) (unColor c)
    setBackground c = SetColor Background (unIntensity c) (unColor c)


-- Builds the formatting SGR list.
visFormatBuilder :: Format -> [SGR]
visFormatBuilder f
      | isFormatDefault f = []
      | otherwise = [ SetConsoleIntensity (unBold f)
                    , SetItalicized (unItalic f)
                    , SetUnderlining (unUnderline f)
                    ]

-- Wrapper and Defaults
visStyle :: Color -> Color -> Format -> Style
visStyle = Style

visDefault :: Style
visDefault = visStyle visColorDefault visColorDefault visFormatDefault

-- Unwrappers
unStyleForeground :: Style -> Color
unStyleForeground s = case s of Zero -> visColorDefault ; Style fc _ _ -> fc

unStyleBackground :: Style -> Color
unStyleBackground s = case s of Zero -> visColorDefault ; Style _ bc _ -> bc

unStyleFormat :: Style -> Format
unStyleFormat s = case s of Zero -> visFormatDefault ; Style _ _ f -> f


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
visSetBG :: Color -> Style -> Style
visSetBG c v = case v of
   Zero -> v
   Style fc bc f -> case bc of 
                ColorDefault -> visStyle fc c f
                _ -> v

-- Swaps the foreground and background color.
visSwapBG :: Style -> Style
visSwapBG v = case v of
   Zero -> v
   Style fc bc f -> visStyle bc fc f




