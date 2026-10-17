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
black = visColor Dull ANSI.Black
black' = visColor Vivid ANSI.Black

red, red' :: Color
red = visColor Dull ANSI.Red
red' = visColor Vivid ANSI.Red

green, green' :: Color
green = visColor Dull ANSI.Green
green' = visColor Vivid ANSI.Green

yellow, yellow' :: Color
yellow = visColor Dull ANSI.Yellow
yellow' = visColor Vivid ANSI.Yellow

blue, blue' :: Color
blue = visColor Dull ANSI.Blue
blue' = visColor Vivid ANSI.Blue

magenta, magenta' :: Color
magenta = visColor Dull ANSI.Magenta
magenta' = visColor Vivid ANSI.Magenta

cyan, cyan' :: Color
cyan = visColor Dull ANSI.Cyan
cyan' = visColor Vivid ANSI.Cyan

white, white' :: Color
white = visColor Dull ANSI.White
white' = visColor Vivid ANSI.White


-- Formats
--------------------------------------------------------------------------------

formatDefault :: Format
formatDefault = visFormatDefault

formatRegular, formatBold, formatItalic, formatUnderline :: Format
formatRegular = visFormat NormalIntensity False NoUnderline
formatBold = visFormat BoldIntensity False NoUnderline
formatItalic = visFormat NormalIntensity True NoUnderline
formatUnderline = visFormat NormalIntensity False SingleUnderline

formatBoldItalic, formatBoldUnderline :: Format
formatBoldItalic = visFormat BoldIntensity True NoUnderline
formatBoldUnderline = visFormat BoldIntensity False SingleUnderline

formatItalicUnderline, formatBoldItalicUnderline :: Format
formatItalicUnderline = visFormat NormalIntensity True SingleUnderline
formatBoldItalicUnderline = visFormat BoldIntensity True SingleUnderline


-- Styles
--------------------------------------------------------------------------------

styleDefault :: Style
styleDefault = visDefault

normal, bold, italic, underline :: Color -> Style
normal c = visStyle c colorDefault formatDefault
bold c = visStyle c colorDefault formatBold
italic c = visStyle c colorDefault formatItalic
underline c = visStyle c colorDefault formatUnderline

boldItalic, boldUnderline :: Color -> Style
boldItalic c = visStyle c colorDefault formatBoldItalic
boldUnderline c = visStyle c colorDefault formatBoldUnderline

italicUnderline, boldItalicUnderline :: Color -> Style
italicUnderline c = visStyle c colorDefault formatItalicUnderline
boldItalicUnderline c = visStyle c colorDefault formatBoldItalicUnderline

solid, solidBold :: Color -> Style
solid c = visStyle black c formatDefault
solidBold c = visStyle black c formatBold


-- Text Styles
--------------------------------------------------------------------------------

textRegular :: Style
textRegular = visDefault

textBold, textItalic, textUnderline :: Style
textBold = visStyle colorDefault colorDefault formatBold
textItalic = visStyle colorDefault colorDefault formatItalic
textUnderline = visStyle colorDefault colorDefault formatUnderline

textBoldItalic, textBoldUnderline :: Style
textBoldItalic = visStyle colorDefault colorDefault formatBoldItalic
textBoldUnderline = visStyle colorDefault colorDefault formatBoldUnderline

textItalicUnderline, textBoldItalicUnderline :: Style
textItalicUnderline = visStyle colorDefault colorDefault formatItalicUnderline
textBoldItalicUnderline = visStyle colorDefault colorDefault formatBoldItalicUnderline

textColor, textMark :: Color -> Style
textColor = normal 
textMark = solid


