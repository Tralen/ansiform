-- | Colors, formats and reusable styles.
module Ansiform.Style ( module Ansiform.Style
                 , Internal.Color, Internal.Format, Internal.Style
                 ) where

--------------------------------------------------------------------------------
import qualified System.Console.ANSI as ANSI
import           Ansiform.Internal.Style as Internal


-- Colors
--------------------------------------------------------------------------------

colorDefault :: Color
colorDefault = ColorDefault

-- The ' version denotes vivid version.
black, black' :: Color
black = formColor Dull ANSI.Black
black' = formColor Vivid ANSI.Black

red, red' :: Color
red = formColor Dull ANSI.Red
red' = formColor Vivid ANSI.Red

green, green' :: Color
green = formColor Dull ANSI.Green
green' = formColor Vivid ANSI.Green

yellow, yellow' :: Color
yellow = formColor Dull ANSI.Yellow
yellow' = formColor Vivid ANSI.Yellow

blue, blue' :: Color
blue = formColor Dull ANSI.Blue
blue' = formColor Vivid ANSI.Blue

magenta, magenta' :: Color
magenta = formColor Dull ANSI.Magenta
magenta' = formColor Vivid ANSI.Magenta

cyan, cyan' :: Color
cyan = formColor Dull ANSI.Cyan
cyan' = formColor Vivid ANSI.Cyan

white, white' :: Color
white = formColor Dull ANSI.White
white' = formColor Vivid ANSI.White


-- Formats
--------------------------------------------------------------------------------

formatDefault :: Format
formatDefault = defaultFormat

formatRegular, formatBold, formatItalic, formatUnderline :: Format
formatRegular = formFormat NormalIntensity False NoUnderline
formatBold = formFormat BoldIntensity False NoUnderline
formatItalic = formFormat NormalIntensity True NoUnderline
formatUnderline = formFormat NormalIntensity False SingleUnderline

formatBoldItalic, formatBoldUnderline :: Format
formatBoldItalic = formFormat BoldIntensity True NoUnderline
formatBoldUnderline = formFormat BoldIntensity False SingleUnderline

formatItalicUnderline, formatBoldItalicUnderline :: Format
formatItalicUnderline = formFormat NormalIntensity True SingleUnderline
formatBoldItalicUnderline = formFormat BoldIntensity True SingleUnderline


-- Styles
--------------------------------------------------------------------------------

styleDefault :: Style
styleDefault = defaultStyle

normal, bold, italic, underline :: Color -> Style
normal c = formStyle c colorDefault formatDefault
bold c = formStyle c colorDefault formatBold
italic c = formStyle c colorDefault formatItalic
underline c = formStyle c colorDefault formatUnderline

boldItalic, boldUnderline :: Color -> Style
boldItalic c = formStyle c colorDefault formatBoldItalic
boldUnderline c = formStyle c colorDefault formatBoldUnderline

italicUnderline, boldItalicUnderline :: Color -> Style
italicUnderline c = formStyle c colorDefault formatItalicUnderline
boldItalicUnderline c = formStyle c colorDefault formatBoldItalicUnderline

solid, solidBold :: Color -> Style
solid c = formStyle black c formatDefault
solidBold c = formStyle black c formatBold


-- Text Styles
--------------------------------------------------------------------------------

textRegular :: Style
textRegular = defaultStyle

textBold, textItalic, textUnderline :: Style
textBold = formStyle colorDefault colorDefault formatBold
textItalic = formStyle colorDefault colorDefault formatItalic
textUnderline = formStyle colorDefault colorDefault formatUnderline

textBoldItalic, textBoldUnderline :: Style
textBoldItalic = formStyle colorDefault colorDefault formatBoldItalic
textBoldUnderline = formStyle colorDefault colorDefault formatBoldUnderline

textItalicUnderline, textBoldItalicUnderline :: Style
textItalicUnderline = formStyle colorDefault colorDefault formatItalicUnderline
textBoldItalicUnderline = formStyle colorDefault colorDefault formatBoldItalicUnderline

textColor, textMark :: Color -> Style
textColor = normal 
textMark = solid


