-- | Colors, formats and reusable styles.
module Ansiform.Style
    ( module Ansiform.Style
    , Internal.Color
    , Internal.Format
    , Internal.Style
    ) where

import Ansiform.Internal.Style as Internal
--------------------------------------------------------------------------------
import qualified System.Console.ANSI as ANSI

-- Colors
--------------------------------------------------------------------------------

-- | Leaves the terminal color unchanged.
colorDefault :: Color
colorDefault = ColorDefault

-- | Black. The primed name is the vivid variant.
black, black' :: Color
black = formColor Dull ANSI.Black
black' = formColor Vivid ANSI.Black

-- | Red. The primed name is the vivid variant.
red, red' :: Color
red = formColor Dull ANSI.Red
red' = formColor Vivid ANSI.Red

-- | Green. The primed name is the vivid variant.
green, green' :: Color
green = formColor Dull ANSI.Green
green' = formColor Vivid ANSI.Green

-- | Yellow. The primed name is the vivid variant.
yellow, yellow' :: Color
yellow = formColor Dull ANSI.Yellow
yellow' = formColor Vivid ANSI.Yellow

-- | Blue. The primed name is the vivid variant.
blue, blue' :: Color
blue = formColor Dull ANSI.Blue
blue' = formColor Vivid ANSI.Blue

-- | Magenta. The primed name is the vivid variant.
magenta, magenta' :: Color
magenta = formColor Dull ANSI.Magenta
magenta' = formColor Vivid ANSI.Magenta

-- | Cyan. The primed name is the vivid variant.
cyan, cyan' :: Color
cyan = formColor Dull ANSI.Cyan
cyan' = formColor Vivid ANSI.Cyan

-- | White. The primed name is the vivid variant.
white, white' :: Color
white = formColor Dull ANSI.White
white' = formColor Vivid ANSI.White

-- Formats
--------------------------------------------------------------------------------

-- | Leaves the format unchanged.
formatDefault :: Format
formatDefault = defaultFormat

-- | Regular, bold, italic and underline formats.
formatRegular, formatBold, formatItalic, formatUnderline :: Format
formatRegular = formFormat NormalIntensity ItalicOff NoUnderline
formatBold = formFormat BoldIntensity ItalicOff NoUnderline
formatItalic = formFormat NormalIntensity ItalicOn NoUnderline
formatUnderline = formFormat NormalIntensity ItalicOff SingleUnderline

-- | Bold italic and bold underline formats.
formatBoldItalic, formatBoldUnderline :: Format
formatBoldItalic = formFormat BoldIntensity ItalicOn NoUnderline
formatBoldUnderline = formFormat BoldIntensity ItalicOff SingleUnderline

-- | Italic underline and bold italic underline formats.
formatItalicUnderline, formatBoldItalicUnderline :: Format
formatItalicUnderline = formFormat NormalIntensity ItalicOn SingleUnderline
formatBoldItalicUnderline = formFormat BoldIntensity ItalicOn SingleUnderline

-- Styles
--------------------------------------------------------------------------------

-- | Resets color and format to the terminal defaults.
styleDefault :: Style
styleDefault = defaultStyle

-- | Foreground color with the default format, bold, italic or underline.
normal, bold, italic, underline :: Color -> Style
normal c = formStyle c colorDefault formatDefault
bold c = formStyle c colorDefault formatBold
italic c = formStyle c colorDefault formatItalic
underline c = formStyle c colorDefault formatUnderline

-- | Foreground color with bold italic or bold underline.
boldItalic, boldUnderline :: Color -> Style
boldItalic c = formStyle c colorDefault formatBoldItalic
boldUnderline c = formStyle c colorDefault formatBoldUnderline

-- | Foreground color with italic underline or bold italic underline.
italicUnderline, boldItalicUnderline :: Color -> Style
italicUnderline c = formStyle c colorDefault formatItalicUnderline
boldItalicUnderline c = formStyle c colorDefault formatBoldItalicUnderline

-- | Black text on the given background color, optionally bold.
solid, solidBold :: Color -> Style
solid c = formStyle black c formatDefault
solidBold c = formStyle black c formatBold

-- Text Styles
--------------------------------------------------------------------------------

-- | Default terminal text.
textRegular :: Style
textRegular = defaultStyle

-- | Bold, italic and underline text that keeps the terminal foreground.
textBold, textItalic, textUnderline :: Style
textBold = formStyle colorDefault colorDefault formatBold
textItalic = formStyle colorDefault colorDefault formatItalic
textUnderline = formStyle colorDefault colorDefault formatUnderline

-- | Bold italic and bold underline text.
textBoldItalic, textBoldUnderline :: Style
textBoldItalic = formStyle colorDefault colorDefault formatBoldItalic
textBoldUnderline = formStyle colorDefault colorDefault formatBoldUnderline

-- | Italic underline and bold italic underline text.
textItalicUnderline, textBoldItalicUnderline :: Style
textItalicUnderline = formStyle colorDefault colorDefault formatItalicUnderline
textBoldItalicUnderline = formStyle colorDefault colorDefault formatBoldItalicUnderline

-- | Colored text, or colored text on a solid background.
textColor, textMark :: Color -> Style
textColor = normal
textMark = solid
