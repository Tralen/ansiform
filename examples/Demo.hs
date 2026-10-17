-- | Interactive gallery for the Ansiform library.
--
--   Run with:
--
--   > cabal run ansiform-demo
module Main where

import           Data.Char (toLower)
import           Ansiform

--------------------------------------------------------------------------------
-- Application
--------------------------------------------------------------------------------

-- Version of this demo, following the package version.
demoVersion :: String
demoVersion = "0.7.6.0"

-- The demo is a small screen machine.
data Screen = Menu | List | Groups | Tables | Rich | Article | Blocks | Cicero | Locke
  deriving (Eq, Show)

main :: IO ()
main = withImmediateInput $ do
  state <- start (screenPage Menu) demoSettings
  loop Menu state

loop :: Screen -> State -> IO ()
loop screen state = do
  key <- readKey
  case fmap toLower key of
    Nothing -> finish
    Just 'g' -> open Groups state
    Just 't' -> open Tables state
    Just 'h' -> open Rich state
    Just 'a' -> open Article state
    Just 'c' -> case screen of
                  Groups -> open Cicero state
                  _ -> open Blocks state
    Just 'l' -> case screen of
                  Groups -> open Locke state
                  _ -> open List state
    Just 'r' -> do state' <- redraw state
                   loop screen state'
    Just 'b' -> do state' <- draw (screenPage Menu) state
                   loop Menu state'
    Just 'x' -> finish
    Just '\n' -> loop screen state
    Just ' ' -> loop screen state
    Just _   -> loop screen state
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

demoTheme :: Theme
demoTheme = defaultTheme

header :: Section
header = sectionTopRule 1 ruleHeader
  [ printerSolidLineCenter 0 1 (themeBar demoTheme)
      [ blockSimple "Ansiform" (themeHeader demoTheme)
      , blockSimple demoVersion (themeHeader demoTheme) ]
  , printerEmpty 1
  , printerLineCenter 4
      [ blockSimple "CLI UI Library" (themeSubtitle demoTheme)
      , blockSimple "Gallery" (themeMuted demoTheme)
      , blockSimple "Demo" (themeAccent demoTheme) ]
  ]

bottom :: Section
bottom = sectionRule ruleBottom

footer :: String -> [[Block]] -> Section
footer message commandLines = sectionBodyRule 1 ruleFooter
  ( [ printerLeft 2 (blockSimple message (themeFooter demoTheme))
    , printerEmpty 1
    ] ++ fmap (printerLineCenter 4) commandLines )

ruleHeader, ruleBody, ruleFooter, ruleBottom :: Rule
ruleHeader = rule '=' (themeRule demoTheme)
ruleBody = rule '%' (themeRule demoTheme)
ruleFooter = rule ':' (themeRule demoTheme)
ruleBottom = ruleDefault (themeRule demoTheme)

--------------------------------------------------------------------------------
-- Screens
--------------------------------------------------------------------------------

screenPage :: Screen -> Page
screenPage screen = page [header, screenBody screen, screenFooter screen, bottom]

screenBody :: Screen -> Section
screenBody Menu = sectionBodyRule 1 ruleBody [printerColumn 8 menuBlocks]
screenBody List = sectionBodyRule 1 ruleBody [printerList 8 6 composers]
screenBody Groups = sectionBodyRule 1 ruleBody [printerGroups' 4 groups]
screenBody Tables = sectionBodyRule 1 ruleBody [printerTableFormat' demoTablesFormat 4 1 simpleTable]
screenBody Rich = sectionBodyRule 1 ruleBody [printerTableBordered BordersLight defaultTableFormat 8 0 richTable]
screenBody Article = sectionBodyRule 1 ruleBody [printerArticle 2 0 article]
screenBody Blocks = blocksBody
screenBody Cicero = sectionBodyRule 1 ruleBody [printerArticle 2 0 ciceroArticle]
screenBody Locke = sectionBodyRule 1 ruleBody [printerArticle 2 0 lockeArticle]

screenFooter :: Screen -> Section
screenFooter Menu = footer "Choose an option above: " menuCommands
screenFooter Groups = footer "Cicero and Locke have dedicated pages." groupsCommands
screenFooter _ = footer "Press B to go back or R to reload." pageCommands

menuCommands, pageCommands, groupsCommands :: [[Block]]
menuCommands =
  [ [ blockMenuStyle "L" "List" (themeAccent demoTheme)
    , blockMenuStyle "G" "Groups" (themeAccent demoTheme)
    , blockMenuStyle "T" "Tables" (themeAccent demoTheme)
    , blockMenuStyle "H" "Rich table" (themeAccent demoTheme) ]
  , [ blockMenuStyle "A" "Article" (themeAccent demoTheme)
    , blockMenuStyle "C" "Content builders" (themeAccent demoTheme)
    , blockMenuStyle "X" "Exit" (themeDanger demoTheme) ]
  ]

pageCommands =
  [ [ blockMenuStyle "B" "Back" (themeAccent demoTheme)
    , blockMenuStyle "R" "Reload" (themeAccent demoTheme)
    , blockMenuStyle "X" "Exit" (themeDanger demoTheme) ]
  ]

groupsCommands =
  [ [ blockMenuStyle "C" "Cicero" (themeAccent demoTheme)
    , blockMenuStyle "L" "Locke" (themeAccent demoTheme)
    , blockMenuStyle "B" "Back" (themeAccent demoTheme) ]
  , [ blockMenuStyle "R" "Reload" (themeAccent demoTheme)
    , blockMenuStyle "X" "Exit" (themeDanger demoTheme) ]
  ]

--------------------------------------------------------------------------------
-- Menu and content
--------------------------------------------------------------------------------

menuBlocks :: [Block]
menuBlocks =
  [ blockMenuStyle "L" "List composers" (themeAccent demoTheme)
  , blockMenuStyle "G" "Group philosophers" (themeAccent demoTheme)
  , blockMenuStyle "T" "Tabulate composers" (themeAccent demoTheme)
  , blockMenuStyle "H" "Rich flight table" (themeAccent demoTheme)
  , blockMenuStyle "A" "Article about Ansiform" (themeAccent demoTheme)
  , blockMenuStyle "C" "Content builders" (themeAccent demoTheme)
  , blockMenuStyle "X" "Exit" (themeDanger demoTheme)
  ]

blocksBody :: Section
blocksBody = sectionBodyRule 1 ruleBody
  [ printerItem (item "A single Item" (solid cyan))
  , printerEmpty 1
  , printerColumn 4
      [ blockSimple "Content builders" (themeSubtitle demoTheme)
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
  [ blockSimple "Flight" (themeTableHeader demoTheme)
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
simpleTable = tableSimple simpleHeader (themeTableBody demoTheme) simpleRows

-- Right aligns the numeric columns and truncates long composer names.
demoTablesFormat :: TableFormat
demoTablesFormat = tableFormat
  [ defaultColumnSpec { columnMaxWidth = Just 11
                      , columnEllipsis = EllipsisChar '…' }
  , defaultColumnSpec
  , defaultColumnSpec { columnAlign = AlignRight }
  , defaultColumnSpec { columnAlign = AlignRight }
  , defaultColumnSpec { columnAlign = AlignRight }
  ]

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
article = [paragraph1, paragraph2, paragraph3]

paragraph1, paragraph2, paragraph3 :: Paragraph
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
  , blockSimple " Lists flow into columns, " textItalic
  , blockSimple "groups share space evenly, " textBold
  , blockSimple "and tables can mix independently styled cells." textRegular
  ]

paragraph3 =
  [ blockSimple "The standard interaction is immediate: " textRegular
  , blockSimple "press a key and the page changes, " textBold
  , blockSimple "without a prompt and without Enter. " textRegular
  , blockSimple "Styles are suppressed on redirected output, " textItalic
  , blockSimple "and wide characters, combining marks and emoji " textRegular
  , blockSimple "keep their alignment " (textMark cyan)
  , blockSimple "because layout measures terminal columns, not code points." textRegular
  ]

--------------------------------------------------------------------------------
-- Philosopher articles
--------------------------------------------------------------------------------

ciceroArticle :: Article
ciceroArticle = [ciceroParagraph1, ciceroParagraph2]

ciceroParagraph1, ciceroParagraph2 :: Paragraph
ciceroParagraph1 =
  [ blockSimple "Marcus Tullius Cicero " textBold
  , blockSimple "(106-43 BC) was a Roman statesman, orator and philosopher. " textRegular
  , blockSimple "He was consul in 63 BC " textItalic
  , blockSimple "and is known for the Catilinarian orations and for his many speeches." textRegular
  ]

ciceroParagraph2 =
  [ blockSimple "His philosophical works, " textRegular
  , blockSimple "such as De Re Publica and De Officiis, " (textMark yellow)
  , blockSimple "helped bring Greek philosophy into Latin. " textRegular
  , blockSimple "He was killed during the proscriptions of 43 BC." (textColor cyan)
  ]

lockeArticle :: Article
lockeArticle = [lockeParagraph1, lockeParagraph2]

lockeParagraph1, lockeParagraph2 :: Paragraph
lockeParagraph1 =
  [ blockSimple "John Locke " textBold
  , blockSimple "(1632-1704) was an English philosopher and physician. " textRegular
  , blockSimple "He is a central figure of empiricism " textItalic
  , blockSimple "and argued that the mind begins as a blank slate." textRegular
  ]

lockeParagraph2 =
  [ blockSimple "His Two Treatises of Government " textRegular
  , blockSimple "defended natural rights and government by consent. " (textMark yellow)
  , blockSimple "The Essay Concerning Human Understanding " textItalic
  , blockSimple "shaped modern epistemology and liberal thought." (textColor cyan)
  ]
