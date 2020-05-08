module Example where

--------------------------------------------------------------------------------
import           Vis.Internal.Utils
import           Vis.Content
import           Vis.Printer
import           Vis.Section
import           Vis.Style



-- Section Examples
--------------------------------------------------------------------------------
exHeader :: VisSection
exHeader = sectionTop' 1 exRule [ exTopBar, printerEmpty 1, exMainLine ]


exBody_1 :: VisSection
exBody_1 = sectionBody' 1 exRule' [ exBodyMenu ]

exBody_2 :: VisSection
exBody_2 = sectionBody' 1 exRule' [ exBodyList ]

exBody_3 :: VisSection
exBody_3 = sectionBody' 1 exRule' [ exBodyTable ]


exFooter_1 :: VisSection
exFooter_1 = sectionBody' 1 exRule'' [ exInstrunction_1 ]

exFooter_2 :: VisSection
exFooter_2 = sectionBody' 1 exRule'' [ exInstrunction_2
                                     , printerEmpty 1
                                     , exCommands ]

exFooter_3 :: VisSection
exFooter_3 = sectionBody' 1 exRule'' [ exInstrunction_2
                                     , printerEmpty 1
                                     , exCommands' ]

-- Printer Examples
--------------------------------------------------------------------------------
exTopBar :: VisPrinter
exTopBar = printerSolidLineCenter 0 1 red
                           ([ blockSimple "Prog Name" (bold white')
                            , blockSimple "0.1.0.0" (bold white') ])

exMainLine :: VisPrinter
exMainLine = printerLineCenter 4 ([ blockSimple "Context" (bold yellow) 
                                  , blockSimple "Main Article" (bold white) 
                                  , blockSimple "User Name" (bold red) ])


exBodyMenu :: VisPrinter
exBodyMenu = printerColumn 8 exMenu

exBodyList :: VisPrinter
exBodyList = printerList 8 6 exList

exBodyTable :: VisPrinter
exBodyTable = printerTable 8 1 exTableBlocks


exInstrunction_1 :: VisPrinter
exInstrunction_1 = printerLeft 2 (blockSimple "Choose an option above: " styleDefault)

exInstrunction_2 :: VisPrinter
exInstrunction_2 = printerLeft 2 (blockSimple "Choose one of the options: " styleDefault)

exCommands :: VisPrinter
exCommands = printerLineCenter 4 exLine

exCommands' :: VisPrinter
exCommands' = printerLineCenter 4 exLine'


-- Rules Examples
--------------------------------------------------------------------------------
exRule :: VisRule
exRule = rule '%' (bold black')

exRule' :: VisRule
exRule' = rule ':' (bold black')

exRule'' :: VisRule
exRule'' = ruleDefault (bold black')

exRuleSolid :: VisRule
exRuleSolid = ruleSolid red'


-- Content Examples
--------------------------------------------------------------------------------
exItem :: VisItem
exItem = itemSimple "Person Name" (solid cyan)

exBlock :: VisBlock
exBlock = blockSimple "Another Name" styleDefault

exBlockVal :: VisBlock
exBlockVal = blockVal "Property" "12" red

exLine :: [VisBlock]
exLine = [ blockMenu "S" "Search" cyan
         , blockMenu "D" "Display" cyan
         , blockMenu "R" "Reload" cyan
         , blockMenu "X" "Exit" red
         ]

exLine' :: [VisBlock]
exLine' = insertAt 3 (blockMenu "G" "Generate" cyan) exLine


exAssoc :: VisBlock
exAssoc = blockAssoc ["First", "Second", "Third"] styleDefault (normal blue) 

exAssoc' :: VisBlock
exAssoc' = blockAssoc' ["The End", "The Middle", "The Start"] styleDefault (normal blue)


exMenu :: [VisBlock]
exMenu = [ blockMarked 'I' "Introduction" (bold green)
         , blockMarked 'H' "History" (bold green)
         , blockMarked 'G' "Geography" (bold green)
         , blockMarked 'P' "Philosophy" (bold green)
         , blockMarked 'L' "Linguistics" (bold green)
         , blockMarked 'C' "Culture" (bold green)
         , blockMarked 'f' "Configuration" (bold green)
         ]

exList :: [VisBlock]
exList = [ blockEnum "00" "Tchaikovsky" blue
         , blockEnum "01" "Sibelius" blue
         , blockEnum "02" "Mussorgsky" blue
         , blockEnum "03" "Brahms" blue
         , blockEnum "04" "Chopin" blue
         , blockEnum "05" "Offenbach" blue
         , blockEnum "06" "Khachaturian" blue
         , blockEnum "07" "Holst" blue
         , blockEnum "08" "Bruckner" blue
         , blockEnum "09" "Prokofiev" blue
         , blockEnum "10" "Rismky-Korsakov" blue
         , blockEnum "11" "Suppé" blue
         , blockEnum "12" "Berlioz" blue
         , blockEnum "13" "Stravinksy" blue
         , blockEnum "14" "Ravel" blue
         , blockEnum "15" "Mahler" blue
         ]

exGroup :: VisGroup
exGroup = groupSimple (blockSimple "Composers" (normal yellow)) exList

exCountries :: [VisBlock]
exCountries = [ blockEnum "AA" "Argentina" black
              , blockEnum "BB" "Brazil" black
              , blockEnum "CC" "China" black
              , blockEnum "DD" "Dominican Rep." black
              , blockEnum "EE" "Egypt" black
              , blockEnum "FF" "France" black
              , blockEnum "GG" "Germany" black
              , blockEnum "HH" "Honduras" black
              , blockEnum "II" "Indonesia" black
              , blockEnum "JJ" "Jamaica" black
              , blockEnum "KK" "Kazakhstan" black
              , blockEnum "LL" "Lebanon" black
              , blockEnum "MM" "Mexico" black
              , blockEnum "NN" "New Zealand" black
              , blockEnum "OO" "Oman" black
              , blockEnum "PP" "Pakistan" black
              , blockEnum "QQ" "Qatar" black
              , blockEnum "RR" "Russia" black
              , blockEnum "SS" "South Africa" black
              , blockEnum "TT" "Turkey" black
              , blockEnum "UU" "United States" black
              , blockEnum "VV" "Venezuela" black
              , blockEnum "WW" "No Countries" red
              , blockEnum "XX" "No Countries" red
              , blockEnum "YY" "Yemen" black
              , blockEnum "ZZ" "Zimbabwe" black
              ]

exGroups :: [VisGroup]
exGroups = [ groupSimple
               (blockSimple "Greek" (normal yellow))
              
               [ blockEnum "01" "Socrates" black
               , blockEnum "02" "Plato" black
               , blockEnum "03" "Aristoteles" black
               , blockEnum "04" "Diogenes" black
               , blockEnum "05" "Epicurus" black
               , blockEnum "06" "Pythagoras" black
               , blockEnum "07" "Anaxagoras" black]
           , groupSimple
               (blockSimple "Roman" (normal yellow))

               [ blockEnum "08" "Cicero" magenta
               , blockEnum "09" "Seneca" black
               , blockEnum "10" "Lucretius" black
               , blockEnum "11" "Marcus Aurelius" black]
           , groupSimple
               (blockSimple "Enlightenment" (normal yellow))

               [ blockEnum "12" "Hobbes" black
               , blockEnum "13" "Spinoza" black
               , blockEnum "14" "Descartes" black
               , blockEnum "15" "Locke" green
               , blockEnum "16" "Hume" black
               , blockEnum "17" "Montesquieu" black]
           ]

exGroups' :: [VisGroup]
exGroups' = groupSimple (blockSimple "Countries" (normal yellow)) exCountries : exGroups


-- Table Examples
--------------------------------------------------------------------------------
exTableBlocks :: Maybe VisTable
exTableBlocks = tableBlocks exTableBlocksHeader exTableBlocksBody

exTableBlocksHeader :: [VisBlock]
exTableBlocksHeader = [ blockSimple "Flight" (bold yellow)
                      , blockSimple "Company" (normal yellow)
                      , blockAssoc ["Origin", "Destination"] (normal yellow) (normal magenta)
                      , blockSimple "Departure" (normal yellow)
                      , blockSimple "Arrival" (normal yellow)
                      , blockSimple "Aircraft" (normal yellow)
                      ]

exTableBlocksBody :: [[VisBlock]]
exTableBlocksBody = [ [ blockSimple "1929" (bold green), blockSimple "American Airlines" (normal green), blockAssoc ["PORTLAND", "CHARLOTTE"] styleDefault (normal magenta), blockSimple "22:20" (normal cyan), blockSimple "06:09" (normal red), blockSimple "Airbus A321" (normal blue) ]
                    , [ blockSimple "710" (bold green), blockSimple "Arik Air" (normal green), blockAssoc ["LAGOS", "ABUJA"] styleDefault (normal magenta), blockSimple "06:00" (normal cyan), blockSimple "07:15" (normal red), blockSimple "Boeing 737-700 Passenger" (normal yellow) ]
                    , [ blockSimple "309" (bold green), blockSimple "British Airways" (normal green), blockAssoc ["PARIS", "LONDON"] styleDefault (normal magenta), blockSimple "12:10" (normal cyan), blockSimple "12:30" (normal red), blockSimple "Airbus A320neo" (normal blue) ]
                    , [ blockSimple "3002" (bold green), blockSimple "EgyptAir" (normal green), blockAssoc ["CAIRO", "DUBAI"] styleDefault (normal magenta), blockSimple "19:15" (normal cyan), blockSimple "00:35" (normal red), blockSimple "Airbus A320neo" (normal blue) ]
                    , [ blockSimple "5139" (bold green), blockSimple "AerCaribe Peru" (normal green), blockAssoc ["BOGOTA", "LIMA"] styleDefault (normal magenta), blockSimple "06:00" (normal cyan), blockSimple "23:00" (normal red), blockSimple "Boeing 737 Passenger" (normal yellow) ]
                    , [ blockSimple "422" (bold green), blockSimple "ANA Wings" (normal green), blockAssoc ["FUKUOKA", "OSAKA"] styleDefault (normal magenta), blockSimple "08:50" (normal cyan), blockSimple "10:05" (normal red), blockSimple "DHC-8-400 Dash 8Q" (normal magenta) ]
                    , [ blockSimple "9535" (bold green), blockSimple "Shanghai Airlines" (normal green), blockAssoc ["SHANGHAI", "XIAMEN"] styleDefault (normal magenta), blockSimple "07:50" (normal cyan), blockSimple "09:40" (normal red), blockSimple "Boeing 737-800 Passenger" (normal yellow) ]
                    ]


exTableSimple :: Maybe VisTable
exTableSimple = tableSimple exTableSimpleHeader (normal blue') exTableSimpleBody

exTableSimpleHeader :: [VisBlock]
exTableSimpleHeader = [ blockSimple "Actress" (bold white)
                      , blockSimple "Personal Name" (bold magenta)
                      , blockSimple "Family Name" (bold magenta)
                      , blockSimple "Birthplace" (bold cyan)
                      , blockSimple "Country" (bold cyan)
                      , blockSimple "Citizenship" (bold red)
                      , blockSimple "Birth" (bold green)
                      , blockSimple "Death" (bold green)
                      , blockSimple "Age" (bold green)
                      , blockSimple "Partners" (bold yellow)
                      ]

exTableSimpleBody :: [[String]]
exTableSimpleBody = [ ["Audrey Hepburn", "Audrey Kathleen", "Ruston", "Ixelles", "Belgium", "British", "1929", "1993", "63", "3"]
                    , ["Marilyn Monroe", "Norma Jeane", "Mortenson", "Los Angeles", "United States", "American", "1926", "1962", "36", "3"]
                    , ["Elizabeth Taylor", "Elizabeth Rosemond", "Taylor", "London", "England", "British", "1932", "2011", "79", "7"]
                    , ["Grace Kelly", "Grace Patricia", "Kelly", "Philadelphia", "United States", "American", "1929", "1982", "52", "1"]
                    , ["Joan Crawford", "Lucille Fay", "LeSueur", "San Antonio", "United States", "American", "1906", "1977", "71", "4"]
                    , ["Katharine Hepburn", "Katharine Houghton", "Hepburn", "Hartford", "United States", "American", "1907", "2003", "96", "2"]
                    , ["Sophia Loren", "Sofia Villani", "Scicolone", "Rome", "Italy", "Italian", "1934", "--", "85", "1"]
                    , ["Lauren Bacall", "Betty Joan", "Perske", "New York", "United States", "American", "1924", "2014", "89", "2"]
                    , ["Julie Andrews", "Julia Elizabeth", "Wells", "Walton-on-Thames", "England", "British", "1935", "--", "84", "2"]
                    ]


exTableGroups :: Maybe VisTable
exTableGroups = tableGroups exTableGroupsGroups

exTableGroupsGroups :: [VisGroup]
exTableGroupsGroups = [ groupSimple (blockSimple "Species" (normal yellow)) [ blockSimple "Lion" (bold white), blockSimple "Cougar" (bold white), blockSimple "Tiger" (bold white), blockSimple "Snow Leopard" (bold white) ]
                      , groupSimple (blockSimple "Binomial" (normal yellow)) [ blockSimple "Panthera Leo" (normal cyan), blockSimple "Puma Concolor" (normal cyan), blockSimple "Panthera Tigris" (normal cyan), blockSimple "Panthera Uncia" (normal cyan) ]
                      , groupSimple (blockSimple "Conservation Status" (normal yellow)) [ blockSimple "Vulnerable" (normal magenta), blockSimple "Least Concern" (normal green), blockSimple "Endangered" (normal red), blockSimple "Vulnerable" (normal magenta) ]
                      ]



-- Text Examples
--------------------------------------------------------------------------------

-- No attention is needed for the length of each item, it will be formatted properly.
exParagraph :: VisParagraph
exParagraph = 
      [ blockSimple "The Marriage of Figaro, " textBold
      , blockSimple "K. 492, " textItalic
      , blockSimple "is an opera buffa (comic opera) in four acts composed in 1786 by " textRegular
      , blockSimple "Wolfgang Amadeus Mozart, " textBold
      , blockSimple "with an Italian libretto written by Lorenzo Da Ponte. It premiered at the Burgtheater in Vienna on 1 May 1786. The opera's libretto is based on a stage comedy by Pierre Beaumarchais, " textRegular
      , blockSimple "La folle journée, ou le Mariage de Figaro " textItalic
      , blockSimple "(\"The Mad Day, or The Marriage of Figaro\"), which was first performed in 1784. It tells how the servants Figaro and Susanna succeed in getting married, foiling the efforts of their philandering employer Count Almaviva to seduce Susanna and teaching him a lesson in fidelity. " textRegular
      , blockSimple "The opera is a cornerstone of the repertoire and appears consistently among the top ten in the " textRegular
      , blockSimple "Operabase " textUnderline
      , blockSimple "list of most frequently performed operas. " textRegular
      , blockSimple "Beaumarchais's earlier play " textRegular
      , blockSimple "The Barber of Seville " (textColor red')
      , blockSimple "had already made a successful transition to opera in a version by " textRegular
      , blockSimple "Paisiello. " textUnderline
      , blockSimple "Beaumarchais's Mariage de Figaro was at first banned in Vienna; " textRegular
      , blockSimple "Emperor Joseph II " (textMark yellow)
      , blockSimple "stated that " textRegular
      , blockSimple "\"since the piece contains much that is objectionable, I therefore expect that the Censor shall either reject it altogether, or at any rate have such alterations made in it that he shall be responsible for the performance of this play and for the impression it may make\", " (textColor cyan)
      , blockSimple "after which the Austrian Censor duly forbade performing the German version of the play." textRegular
      ]


exArticle :: [VisParagraph]
exArticle = replicate 4 exParagraph
