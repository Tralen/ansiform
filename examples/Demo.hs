-- | Interactive gallery for the Ansiform library.
--
--   Run with:
--
--   > cabal run ansiform-demo
module Main where

import           Control.Exception (bracket_)
import           Control.Monad (when)
import           Data.Char (toLower)
import           System.IO (BufferMode(..), hGetBuffering, hGetEcho,
                            hIsTerminalDevice, hSetBuffering, hSetEcho,
                            isEOF, stdin)
import           Ansiform

--------------------------------------------------------------------------------
-- Application
--------------------------------------------------------------------------------

-- Version of this demo, following the package version.
demoVersion :: String
demoVersion = "0.5.0"

-- The demo is a small screen machine.
data Screen = Menu | List | Groups | Tables | Rich | Article | Blocks
  deriving (Eq, Show)

main :: IO ()
main = do
  interactive <- hIsTerminalDevice stdin
  oldBuffering <- hGetBuffering stdin
  oldEcho <- if interactive then hGetEcho stdin else return True
  let setup = when interactive $ do
                hSetBuffering stdin NoBuffering
                hSetEcho stdin False
      restore = when interactive $ do
                  hSetBuffering stdin oldBuffering
                  hSetEcho stdin oldEcho
  bracket_ setup restore $ do
    state <- start (screenPage Menu) demoSettings
    loop Menu state

loop :: Screen -> State -> IO ()
loop screen state = do
  eof <- isEOF
  if eof
    then finish
    else do
      key <- getChar
      case toLower key of
        'l' -> open List state
        'g' -> open Groups state
        't' -> open Tables state
        'h' -> open Rich state
        'a' -> open Article state
        'c' -> open Blocks state
        'r' -> do state' <- redraw state
                  loop screen state'
        'b' -> do state' <- draw (screenPage Menu) state
                  loop Menu state'
        'x' -> finish
        '\n' -> loop screen state
        ' ' -> loop screen state
        _   -> do putStrLn "Unknown option. Use one of the keys shown in the footer."
                  loop screen state
  where
    open next st = do
      st' <- draw (screenPage next) st
      loop next st'
    finish = putStrLn "\nAnsiform demo finished."

demoSettings :: Settings
demoSettings = settings [minSpace 2]

--------------------------------------------------------------------------------
-- Reusable components
--------------------------------------------------------------------------------

themeAccent, themeMuted :: Style
themeAccent = bold cyan
themeMuted = normal black'

themeDanger :: Color
themeDanger = red'

header :: Section
header = sectionTopRule 1 ruleHeader
  [ printerSolidLineCenter 0 1 blue
      [ blockSimple "Ansiform" (bold white')
      , blockSimple demoVersion (bold white') ]
  , printerEmpty 1
  , printerLineCenter 4
      [ blockSimple "CLI UI Library" (bold yellow)
      , blockSimple "Gallery" themeMuted
      , blockSimple "Demo" themeAccent ]
  ]

bottom :: Section
bottom = sectionRule ruleBottom

footer :: String -> [[Block]] -> Section
footer message commandLines = sectionBodyRule 1 ruleFooter
  ( [ printerLeft 2 (blockSimple message styleDefault)
    , printerEmpty 1
    ] ++ fmap (printerLineCenter 4) commandLines )

ruleHeader, ruleBody, ruleFooter, ruleBottom :: Rule
ruleHeader = rule '=' (bold black')
ruleBody = rule '%' (bold black')
ruleFooter = rule ':' (bold black')
ruleBottom = ruleDefault (bold black')

--------------------------------------------------------------------------------
-- Screens
--------------------------------------------------------------------------------

screenPage :: Screen -> Page
screenPage screen = page [header, screenBody screen, screenFooter screen, bottom]

screenBody :: Screen -> Section
screenBody Menu = sectionBodyRule 1 ruleBody [printerColumn 8 menuBlocks]
screenBody List = sectionBodyRule 1 ruleBody [printerList 8 6 composers]
screenBody Groups = sectionBodyRule 1 ruleBody [printerGroups' 4 groups]
screenBody Tables = sectionBodyRule 1 ruleBody [printerTable' 4 1 simpleTable]
screenBody Rich = sectionBodyRule 1 ruleBody [printerTable 8 1 richTable]
screenBody Article = sectionBodyRule 1 ruleBody [printerArticle 2 0 article]
screenBody Blocks = blocksBody

screenFooter :: Screen -> Section
screenFooter Menu = footer "Choose an option above: " menuCommands
screenFooter _ = footer "Press B to go back or R to reload." pageCommands

menuCommands, pageCommands :: [[Block]]
menuCommands =
  [ [ blockMenu "L" "List" cyan
    , blockMenu "G" "Groups" cyan
    , blockMenu "T" "Tables" cyan
    , blockMenu "H" "Rich table" cyan ]
  , [ blockMenu "A" "Article" cyan
    , blockMenu "C" "Content builders" cyan
    , blockMenu "X" "Exit" themeDanger ]
  ]

pageCommands =
  [ [ blockMenu "B" "Back" cyan
    , blockMenu "R" "Reload" cyan
    , blockMenu "X" "Exit" themeDanger ]
  ]

--------------------------------------------------------------------------------
-- Menu and content
--------------------------------------------------------------------------------

menuBlocks :: [Block]
menuBlocks =
  [ blockMenu "L" "List composers" cyan
  , blockMenu "G" "Group philosophers" cyan
  , blockMenu "T" "Tabulate composers" cyan
  , blockMenu "H" "Rich flight table" cyan
  , blockMenu "A" "Article about Ansiform" cyan
  , blockMenu "C" "Content builders" cyan
  , blockMenu "X" "Exit" themeDanger
  ]

blocksBody :: Section
blocksBody = sectionBodyRule 1 ruleBody
  [ printerItem (item "A single Item" (solid cyan))
  , printerEmpty 1
  , printerColumn 4
      [ blockSimple "Content builders" (bold yellow)
      , blockVal "Version" demoVersion cyan
      , blockBars ["Left", "Center", "Right"] styleDefault (normal magenta)
      , blockSlash "Input" "Output" blue
      , blockCycle [ ("Cycle", bold green)
                   , (" with ", styleDefault)
                   , ("styles", bold green) ]
      , blockSeq ["A", "B", "C"] (normal blue) " -> " (normal black')
      , blockAssoc' ["Third", "Second", "First"] styleDefault (normal magenta)
      , blockMarked 'k' "marked letter" (bold green)
      ]
  , printerEmpty 1
  , printerLeft 4 (blockSimple "left aligned line" (normal green))
  , printerCenter 4 (blockSimple "center aligned line" (normal yellow))
  , printerRight 4 (blockSimple "right aligned line" (normal cyan))
  ]

composers :: [Block]
composers =
  [ blockEnum "00" "Tchaikovsky" blue
  , blockEnum "01" "Sibelius" blue
  , blockEnum "02" "Mussorgsky" blue
  , blockEnum "03" "Brahms" blue
  , blockEnum "04" "Chopin" blue
  , blockEnum "05" "Offenbach" blue
  , blockEnum "06" "Khachaturian" blue
  , blockEnum "07" "Holst" blue
  , blockEnum "08" "Bruckner" blue
  , blockEnum "09" "Prokofiev" blue
  , blockEnum "10" "Rimsky-Korsakov" blue
  , blockEnum "11" "Suppe" blue
  ]

--------------------------------------------------------------------------------
-- Groups
--------------------------------------------------------------------------------

groups :: [Group]
groups =
  [ groupSimple (blockSimple "Greek" (normal yellow))
      [ blockEnum "01" "Socrates" black
      , blockEnum "02" "Plato" black
      , blockEnum "03" "Aristotle" black
      , blockEnum "04" "Diogenes" black
      , blockEnum "05" "Epicurus" black ]
  , groupSimple (blockSimple "Roman" (normal yellow))
      [ blockEnum "06" "Cicero" magenta
      , blockEnum "07" "Seneca" black
      , blockEnum "08" "Lucretius" black
      , blockEnum "09" "Marcus Aurelius" black
      , blockEnum "10" "Virgil" black ]
  , groupSimple (blockSimple "Enlightenment" (normal yellow))
      [ blockEnum "11" "Hobbes" black
      , blockEnum "12" "Spinoza" black
      , blockEnum "13" "Descartes" black
      , blockEnum "14" "Locke" green
      , blockEnum "15" "Hume" black ]
  ]

--------------------------------------------------------------------------------
-- Tables
--------------------------------------------------------------------------------

richTable :: Maybe Table
richTable = tableBlocks richHeader richRows

richHeader :: [Block]
richHeader =
  [ blockSimple "Flight" (bold yellow)
  , blockSimple "Company" (normal yellow)
  , blockAssoc ["Origin", "Destination"] (normal yellow) (normal magenta)
  , blockSimple "Departure" (normal cyan)
  , blockSimple "Arrival" (normal red)
  ]

richRows :: [[Block]]
richRows =
  [ [ blockSimple "1929" (bold green)
    , blockSimple "American Airlines" (normal green)
    , blockAssoc ["PORTLAND", "CHARLOTTE"] styleDefault (normal magenta)
    , blockSimple "22:20" (normal cyan)
    , blockSimple "06:09" (normal red) ]
  , [ blockSimple "710" (bold green)
    , blockSimple "Arik Air" (normal green)
    , blockAssoc ["LAGOS", "ABUJA"] styleDefault (normal magenta)
    , blockSimple "06:00" (normal cyan)
    , blockSimple "07:15" (normal red) ]
  , [ blockSimple "309" (bold green)
    , blockSimple "British Airways" (normal green)
    , blockAssoc ["PARIS", "LONDON"] styleDefault (normal magenta)
    , blockSimple "12:10" (normal cyan)
    , blockSimple "12:30" (normal red) ]
  , [ blockSimple "3002" (bold green)
    , blockSimple "EgyptAir" (normal green)
    , blockAssoc ["CAIRO", "DUBAI"] styleDefault (normal magenta)
    , blockSimple "19:15" (normal cyan)
    , blockSimple "00:35" (normal red) ]
  , [ blockSimple "5139" (bold green)
    , blockSimple "AerCaribe Peru" (normal green)
    , blockAssoc ["BOGOTA", "LIMA"] styleDefault (normal magenta)
    , blockSimple "06:00" (normal cyan)
    , blockSimple "23:00" (normal red) ]
  ]

simpleTable :: Maybe Table
simpleTable = tableSimple simpleHeader (normal blue') simpleRows

simpleHeader :: [Block]
simpleHeader =
  [ blockSimple "Composer" (bold white)
  , blockSimple "Country" (bold cyan)
  , blockSimple "Born" (bold green)
  , blockSimple "Died" (bold green)
  , blockSimple "Works" (bold yellow)
  ]

simpleRows :: [[String]]
simpleRows =
  [ ["Tchaikovsky", "Russia", "1840", "1893", "6"]
  , ["Sibelius", "Finland", "1865", "1957", "7"]
  , ["Mussorgsky", "Russia", "1839", "1881", "5"]
  , ["Brahms", "Germany", "1833", "1897", "4"]
  , ["Chopin", "Poland", "1810", "1849", "6"]
  , ["Offenbach", "Germany", "1819", "1880", "5"]
  , ["Holst", "England", "1874", "1934", "5"]
  , ["Prokofiev", "Russia", "1891", "1953", "7"]
  ]

--------------------------------------------------------------------------------
-- Article
--------------------------------------------------------------------------------

article :: Article
article = [paragraph1, paragraph2]

paragraph1, paragraph2 :: Paragraph
paragraph1 =
  [ blockSimple "Ansiform " textBold
  , blockSimple "is a formatting DSL for command line interfaces. " textRegular
  , blockSimple "Builders are pure, " textItalic
  , blockSimple "pages are immutable, " textUnderline
  , blockSimple "and drawing is the only layer that talks to the terminal." textRegular
  ]

paragraph2 =
  [ blockSimple "Layout adapts to the terminal width. " textRegular
  , blockSimple "Tables reject malformed input, " (textMark yellow)
  , blockSimple "and paragraphs always make progress, " (textColor cyan)
  , blockSimple "even when a single word is wider than the screen." textRegular
  ]
