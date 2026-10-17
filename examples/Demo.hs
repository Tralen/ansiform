-- | Interactive gallery for the Vis library.
--
--   Run with:
--
--   > cabal run vis-demo
module Main where

import           Vis

--------------------------------------------------------------------------------
-- Application
--------------------------------------------------------------------------------

-- Version of this demo, following the package version.
demoVersion :: String
demoVersion = "0.3.0"

main :: IO ()
main = do
  state <- start menuPage demoSettings
  _ <- pause
  state' <- amend richTableBody 1 state
  _ <- pause
  state'' <- amend richTableFooter 2 state'
  _ <- pause
  state''' <- redraw state''
  _ <- pause
  state4 <- draw listPage state'''
  _ <- pause
  state5 <- draw groupsPage state4
  _ <- pause
  state6 <- draw tablesPage state5
  _ <- pause
  state7 <- draw articlePage state6
  _ <- pause
  _ <- replace blocksBody 1 state7
  _ <- pause
  putStrLn "Vis demo finished."

demoSettings :: VisSettings
demoSettings = settings [minSpace 2]

pause :: IO String
pause = putStrLn "\nPress Enter to continue..." >> getLine

--------------------------------------------------------------------------------
-- Reusable components
--------------------------------------------------------------------------------

themeAccent, themeMuted, themeDanger :: VisStyle
themeAccent = bold cyan
themeMuted = normal black'
themeDanger = bold red

header :: VisSection
header = sectionTopRule 1 ruleHeader
  [ printerSolidLineCenter 0 1 blue
      [ blockSimple "Vis" (bold white')
      , blockSimple demoVersion (bold white') ]
  , printerSolid' 8 blue
  , printerLineCenter 4
      [ blockSimple "CLI UI Library" (bold yellow)
      , blockSimple "Gallery" themeMuted
      , blockSimple "Demo" themeAccent ]
  ]

bottom :: VisSection
bottom = sectionRule ruleBottom

footer :: String -> [VisBlock] -> VisSection
footer message commandLine = sectionBodyRule 1 ruleFooter
  [ printerLeft 2 (blockSimple message styleDefault)
  , printerEmpty 1
  , printerLineCenter 4 commandLine
  ]

ruleHeader, ruleBody, ruleFooter, ruleBottom :: VisRule
ruleHeader = rule '=' (bold black')
ruleBody = rule '%' (bold black')
ruleFooter = rule ':' (bold black')
ruleBottom = ruleDefault (bold black')

--------------------------------------------------------------------------------
-- Pages
--------------------------------------------------------------------------------

menuPage, listPage, groupsPage, tablesPage, articlePage :: VisPage
menuPage = page [header, menuBody, menuFooter, bottom]
listPage = page [header, listBody, listFooter, bottom]
groupsPage = page [header, groupsBody, groupsFooter, bottom]
tablesPage = page [header, tablesBody, tablesFooter, bottom]
articlePage = page [header, articleBody, articleFooter, bottom]

menuBody, listBody, groupsBody, tablesBody, articleBody, blocksBody :: VisSection
menuBody = sectionBodyRule 1 ruleBody [printerColumn 8 menuBlocks]
listBody = sectionBodyRule 1 ruleBody [printerList 8 6 composers]
groupsBody = sectionBodyRule 1 ruleBody [printerGroups' 4 groups]
tablesBody = sectionBodyRule 1 ruleBody [printerTable' 4 1 simpleTable]
articleBody = sectionBodyRule 1 ruleBody [printerArticle 2 0 article]
blocksBody = sectionBodyRule 1 ruleBody
  [ printerItem (item "A single VisItem" (solid cyan))
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
      ]
  , printerEmpty 1
  , printerLeft 4 (blockSimple "left aligned line" (normal green))
  , printerCenter 4 (blockSimple "center aligned line" (normal yellow))
  , printerRight 4 (blockSimple "right aligned line" (normal cyan))
  ]

menuFooter, listFooter, groupsFooter, tablesFooter, articleFooter :: VisSection
menuFooter = footer "Choose an option above: " commands
listFooter = footer "Lists flow into multiple columns: " commands'
groupsFooter = footer "Groups share the available width: " commands
tablesFooter = footer "Simple tables reuse the header styles: " commands'
articleFooter = footer "Paragraphs flow and wrap automatically: " commands

richTableBody, richTableFooter :: VisSection
richTableBody = sectionBodyRule 1 ruleBody [printerTable 8 1 richTable]
richTableFooter = footer "Rich tables style every cell independently: " commands'

--------------------------------------------------------------------------------
-- Blocks
--------------------------------------------------------------------------------

menuBlocks :: [VisBlock]
menuBlocks =
  [ blockMarked 'I' "Introduction" themeAccent
  , blockMarked 'H' "History" themeAccent
  , blockMarked 'G' "Geography" themeAccent
  , blockMarked 'P' "Philosophy" themeAccent
  , blockMarked 'L' "Linguistics" themeAccent
  , blockMarked 'C' "Culture" themeAccent
  , blockMarked 'f' "Configuration" themeDanger
  ]

commands, commands' :: [VisBlock]
commands =
  [ blockMenu "S" "Search" cyan
  , blockMenu "D" "Display" cyan
  , blockMenu "R" "Reload" cyan
  , blockMenu "X" "Exit" red
  ]

commands' = take 3 commands ++ [blockMenu "G" "Generate" cyan] ++ drop 3 commands

composers :: [VisBlock]
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

groups :: [VisGroup]
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

richTable :: Maybe VisTable
richTable = tableBlocks richHeader richRows

richHeader :: [VisBlock]
richHeader =
  [ blockSimple "Flight" (bold yellow)
  , blockSimple "Company" (normal yellow)
  , blockAssoc ["Origin", "Destination"] (normal yellow) (normal magenta)
  , blockSimple "Departure" (normal cyan)
  , blockSimple "Arrival" (normal red)
  ]

richRows :: [[VisBlock]]
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

simpleTable :: Maybe VisTable
simpleTable = tableSimple simpleHeader (normal blue') simpleRows

simpleHeader :: [VisBlock]
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

article :: VisArticle
article = [paragraph1, paragraph2]

paragraph1, paragraph2 :: VisParagraph
paragraph1 =
  [ blockSimple "Vis " textBold
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
