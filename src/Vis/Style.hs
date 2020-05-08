module Vis.Style ( module Vis.Style
                 , Internal.VisColor, Internal.VisFormat, Internal.VisStyle
                 ) where

--------------------------------------------------------------------------------
import           Vis.Internal.Style as Internal


-- Colors
--------------------------------------------------------------------------------

colorDefault :: VisColor
colorDefault = VisColorDefault

-- The ' version denotes vivid version.
black, black' :: VisColor
black = visColor Dull Black
black' = visColor Vivid Black

red, red' :: VisColor
red = visColor Dull Red
red' = visColor Vivid Red

green, green' :: VisColor
green = visColor Dull Green
green' = visColor Vivid Green

yellow, yellow' :: VisColor
yellow = visColor Dull Yellow
yellow' = visColor Vivid Yellow

blue, blue' :: VisColor
blue = visColor Dull Blue
blue' = visColor Vivid Blue

magenta, magenta' :: VisColor
magenta = visColor Dull Magenta
magenta' = visColor Vivid Magenta

cyan, cyan' :: VisColor
cyan = visColor Dull Cyan
cyan' = visColor Vivid Cyan

white, white' :: VisColor
white = visColor Dull White
white' = visColor Vivid White


-- Formats
--------------------------------------------------------------------------------

formatDefault :: VisFormat
formatDefault = visFormatDefault

formatRegular, formatBold, formatItalic, formatUnderline :: VisFormat
formatRegular = visFormat NormalIntensity False NoUnderline
formatBold = visFormat BoldIntensity False NoUnderline
formatItalic = visFormat NormalIntensity True NoUnderline
formatUnderline = visFormat NormalIntensity False SingleUnderline

formatBoldItalic, formatBoldUnderline :: VisFormat
formatBoldItalic = visFormat BoldIntensity True NoUnderline
formatBoldUnderline = visFormat BoldIntensity False SingleUnderline

formatItalicUnderline, formatBoldItalicUnderline :: VisFormat
formatItalicUnderline = visFormat NormalIntensity True SingleUnderline
formatBoldItalicUnderline = visFormat BoldIntensity True SingleUnderline


-- Styles
--------------------------------------------------------------------------------

styleDefault :: VisStyle
styleDefault = visDefault

normal, bold, italic, underline :: VisColor -> VisStyle
normal c = visStyle c colorDefault formatDefault
bold c = visStyle c colorDefault formatBold
italic c = visStyle c colorDefault formatItalic
underline c = visStyle c colorDefault formatUnderline

boldItalic, boldUnderline :: VisColor -> VisStyle
boldItalic c = visStyle c colorDefault formatBoldItalic
boldUnderline c = visStyle c colorDefault formatBoldUnderline

italicUnderline, boldItalicUnderline :: VisColor -> VisStyle
italicUnderline c = visStyle c colorDefault formatItalicUnderline
boldItalicUnderline c = visStyle c colorDefault formatBoldItalicUnderline

solid, solidBold :: VisColor -> VisStyle
solid c = visStyle black c formatDefault
solidBold c = visStyle black c formatBold


-- Text Styles
--------------------------------------------------------------------------------

textRegular :: VisStyle
textRegular = visDefault

textBold, textItalic, textUnderline :: VisStyle
textBold = visStyle colorDefault colorDefault formatBold
textItalic = visStyle colorDefault colorDefault formatItalic
textUnderline = visStyle colorDefault colorDefault formatUnderline

textBoldItalic, textBoldUnderline :: VisStyle
textBoldItalic = visStyle colorDefault colorDefault formatBoldItalic
textBoldUnderline = visStyle colorDefault colorDefault formatBoldUnderline

textItalicUnderline, textBoldItalicUnderline :: VisStyle
textItalicUnderline = visStyle colorDefault colorDefault formatItalicUnderline
textBoldItalicUnderline = visStyle colorDefault colorDefault formatBoldItalicUnderline

textColor, textMark :: VisColor -> VisStyle
textColor = normal 
textMark = solid


