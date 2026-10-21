-- | Interactive gallery for the Ansiform library.
--
--   Run with:
--
--   > cabal run ansiform-demo
module Main where

import           Data.Char (isSpace, toLower)
import           Data.List (elemIndex)
import           Data.Maybe (listToMaybe)
import           Ansiform

--------------------------------------------------------------------------------
-- Application
--------------------------------------------------------------------------------

-- Version of this demo, following the package version.
demoVersion :: String
demoVersion = "0.7.9.0"

-- The philosophers shown in the Groups screen.
data Philosopher
  = Socrates | Plato | Aristotle | Diogenes | Epicurus
  | Cicero | Seneca | Lucretius | MarcusAurelius | Virgil
  | Hobbes | Spinoza | Descartes | Locke | Hume
  deriving (Eq, Show)

-- The demo is a small screen machine.
data Screen = Menu | List | Groups | GroupsPrompt | Tables | Rich | Article
            | Blocks | PhilosopherPage Philosopher
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
    Just 'l' -> open List state
    Just 'g' -> open Groups state
    Just 't' -> open Tables state
    Just 'h' -> open Rich state
    Just 'a' -> open Article state
    Just 'c' -> case screen of
                  Groups -> choosePhilosopher state
                  _ -> open Blocks state
    Just 'r' -> do state' <- redraw state
                   loop screen state'
    Just 'b' -> open (backScreen screen) state
    Just 'x' -> finish
    Just '\n' -> loop screen state
    Just ' ' -> loop screen state
    Just _   -> loop screen state
  where
    open next st = do
      st' <- draw (screenPage next) st
      loop next st'

    choosePhilosopher st = do
      (st', input) <- readForm (screenPage GroupsPrompt)
        [promptAt 2 2 promptInputColumn] st
      open (chosenScreen (either (const Nothing) listToMaybe input)) st'

    chosenScreen input = case input >>= philosopherByNumber . trim of
      Just p -> PhilosopherPage p
      Nothing -> Groups

    finish = putStrLn "\nAnsiform demo finished."

-- Returns to the screen that contains the current one.
backScreen :: Screen -> Screen
backScreen (PhilosopherPage _) = Groups
backScreen _ = Menu

demoSettings :: Settings
demoSettings = settings [minSpace 2]

--------------------------------------------------------------------------------
-- Reusable components
--------------------------------------------------------------------------------

demoTheme :: Theme
demoTheme = defaultTheme

header :: Section
header = sectionTop 1
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

-- Footer with a single prompt line above the command keys.
footerPrompt :: String -> [[Block]] -> Section
footerPrompt message commandLines = sectionBodyRule 1 ruleFooter
  ( [ printerLeft promptOffset (blockSimple message (themeFooter demoTheme))
    , printerEmpty 1
    ] ++ fmap (printerLineCenter 4) commandLines )

promptOffset :: Offset
promptOffset = 2

promptMessage :: String
promptMessage = "Choose a philosopher by number and press Enter: "

-- The input column is the prompt offset plus its display width.
promptInputColumn :: Offset
promptInputColumn = formNumber (unNumber promptOffset + textWidth promptMessage)

ruleBody, ruleFooter, ruleBottom :: Rule
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
screenBody (PhilosopherPage p) =
  sectionBodyRule 1 ruleBody [printerArticle 2 0 (philosopherArticle p)]
screenBody GroupsPrompt = screenBody Groups

screenFooter :: Screen -> Section
screenFooter Menu = footer "Choose an option above: " menuCommands
screenFooter Groups = footer "Press C to choose a philosopher by number." groupsCommands
screenFooter GroupsPrompt =
  footerPrompt promptMessage pageCommands
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
  [ [ blockMenuStyle "C" "Choose" (themeAccent demoTheme)
    , blockMenuStyle "B" "Back" (themeAccent demoTheme)
    , blockMenuStyle "R" "Reload" (themeAccent demoTheme) ]
  , [ blockMenuStyle "X" "Exit" (themeDanger demoTheme) ]
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
-- Philosophers
--------------------------------------------------------------------------------

philosopherGroups :: [(String, [Philosopher])]
philosopherGroups =
  [ ("Greek", [Socrates, Plato, Aristotle, Diogenes, Epicurus])
  , ("Roman", [Cicero, Seneca, Lucretius, MarcusAurelius, Virgil])
  , ("Enlightenment", [Hobbes, Spinoza, Descartes, Locke, Hume])
  ]

philosophers :: [Philosopher]
philosophers = concatMap snd philosopherGroups

groups :: [Group]
groups =
  [ groupSimple (blockSimple title (normal yellow))
      [ philosopherBlock p | p <- ps ]
  | (title, ps) <- philosopherGroups ]

philosopherBlock :: Philosopher -> Block
philosopherBlock p =
  blockEnum (philosopherNumber p) (philosopherName p) (philosopherColor p)

philosopherName :: Philosopher -> String
philosopherName p = case p of
  Socrates -> "Socrates"
  Plato -> "Plato"
  Aristotle -> "Aristotle"
  Diogenes -> "Diogenes"
  Epicurus -> "Epicurus"
  Cicero -> "Cicero"
  Seneca -> "Seneca"
  Lucretius -> "Lucretius"
  MarcusAurelius -> "Marcus Aurelius"
  Virgil -> "Virgil"
  Hobbes -> "Hobbes"
  Spinoza -> "Spinoza"
  Descartes -> "Descartes"
  Locke -> "Locke"
  Hume -> "Hume"

philosopherColor :: Philosopher -> Color
philosopherColor p = case p of
  Cicero -> magenta
  Locke -> green
  _ -> black

philosopherNumber :: Philosopher -> String
philosopherNumber p = case elemIndex p philosophers of
  Just i -> pad2 (i + 1)
  Nothing -> "??"

pad2 :: Int -> String
pad2 n | n < 10 = '0' : show n
       | otherwise = show n

philosopherByNumber :: String -> Maybe Philosopher
philosopherByNumber s = case reads s :: [(Int, String)] of
  [(n, "")] -> lookup n [ (read (philosopherNumber p) :: Int, p) | p <- philosophers ]
  _ -> Nothing

trim :: String -> String
trim = f . f
  where f = reverse . dropWhile isSpace

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

philosopherArticle :: Philosopher -> Article
philosopherArticle p = case p of
  Socrates -> bio "Socrates " "(c. 470-399 BC) was an Athenian philosopher. "
                  "He examined ethical concepts through dialogue and questioning. "
                  "He wrote nothing and is known mainly through Plato."
  Plato -> bio "Plato " "(c. 427-347 BC) was an Athenian philosopher. "
               "He developed the theory of Forms and founded the Academy. "
               "His dialogues include the Republic and the Symposium."
  Aristotle -> bio "Aristotle " "(384-322 BC) was a Greek philosopher and student of Plato. "
                   "He worked on logic, ethics, politics and natural science. "
                   "He also tutored Alexander the Great."
  Diogenes -> bio "Diogenes " "(c. 412-323 BC) was a Cynic philosopher. "
                  "He rejected wealth and convention and lived with extreme simplicity. "
                  "His anecdotes illustrate independence and moral frankness."
  Epicurus -> bio "Epicurus " "(341-270 BC) was a Greek philosopher. "
                  "He founded a school known as the Garden and taught that pleasure is the absence of pain. "
                  "His atomism influenced later materialist thought."
  Cicero -> ciceroArticle
  Seneca -> bio "Seneca " "(c. 4 BC-AD 65) was a Roman Stoic philosopher and statesman. "
                 "He wrote letters and essays on ethics and advised Nero. "
                 "He was forced to commit suicide in AD 65."
  Lucretius -> bio "Lucretius " "(c. 99-55 BC) was a Roman poet and philosopher. "
                    "His poem De Rerum Natura explains Epicurean atomism. "
                    "It is a major source for ancient materialist ideas."
  MarcusAurelius -> bio "Marcus Aurelius " "(AD 121-180) was a Roman emperor and Stoic philosopher. "
                         "His Meditations record private reflections on duty and self-control. "
                         "He is often called the philosopher emperor."
  Virgil -> bio "Virgil " "(70-19 BC) was a Roman poet. "
                  "He wrote the Eclogues, the Georgics and the Aeneid. "
                  "The Aeneid became a foundational text of Roman literature."
  Hobbes -> bio "Thomas Hobbes " "(1588-1679) was an English philosopher. "
                  "He is known for Leviathan and for social contract theory. "
                  "He argued for a strong sovereign to prevent civil war."
  Spinoza -> bio "Baruch Spinoza " "(1632-1677) was a Dutch philosopher. "
                   "His Ethics presents a rationalist and monist system. "
                   "He defended freedom of thought and religious toleration."
  Descartes -> bio "René Descartes " "(1596-1650) was a French philosopher and mathematician. "
                     "He is known for the cogito and for mind-body dualism. "
                     "He helped shape modern rationalism and the scientific method."
  Locke -> lockeArticle
  Hume -> bio "David Hume " "(1711-1776) was a Scottish philosopher and historian. "
                "He developed empiricism and an influential analysis of causation. "
                "His works include A Treatise of Human Nature and An Enquiry Concerning Human Understanding."

bio :: String -> String -> String -> String -> Article
bio name dates role detail =
  [ [ blockSimple name textBold
    , blockSimple dates textRegular
    , blockSimple role textItalic
    , blockSimple detail textRegular
    ] ]
