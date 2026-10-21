-- | Small bookmarks application used by the tutorial.
--
--   Run with:
--
--   > cabal run ansiform-tutorial
module Main where

import           Data.Char (toLower)
import           Ansiform

--------------------------------------------------------------------------------
-- Data model
--------------------------------------------------------------------------------

data Bookmark = Bookmark
  { bookmarkTitle :: String
  , bookmarkURL :: String
  } deriving (Eq, Show)

data Model = Model
  { modelBookmarks :: [Bookmark]
  , modelSelected :: Int
  } deriving (Eq, Show)

emptyModel :: Model
emptyModel = Model [] 0

addBookmark :: String -> String -> Model -> Model
addBookmark title url (Model bookmarks _) =
  Model (bookmarks ++ [Bookmark title url]) (length bookmarks)

deleteSelected :: Model -> Model
deleteSelected (Model [] _) = emptyModel
deleteSelected (Model bookmarks selected) =
  Model kept (clampSelection (length kept) selected)
  where
    kept = take selected bookmarks ++ drop (selected + 1) bookmarks

moveSelection :: Int -> Model -> Model
moveSelection delta (Model bookmarks selected) =
  Model bookmarks (clampSelection (length bookmarks) (selected + delta))

clampSelection :: Int -> Int -> Int
clampSelection count index
  | count <= 0 = 0
  | otherwise = max 0 (min (count - 1) index)

--------------------------------------------------------------------------------
-- Shared components
--------------------------------------------------------------------------------

theme :: Theme
theme = defaultTheme

urlStyle :: Style
urlStyle = italic white

bookmarkSettings :: Settings
bookmarkSettings = settings [minSpace 2]

header :: Section
header = sectionTop 1
  [ printerSolidLineCenter 0 1 (themeBar theme)
      [ blockSimple "Pocket Bookmarks" (themeHeader theme) ]
  , printerEmpty 1
  , printerLineCenter 4
      [ blockSimple "A small Ansiform tutorial" (themeSubtitle theme) ]
  ]

bottom :: Section
bottom = sectionRule (ruleDefault (themeRule theme))

ruleBody, ruleFooter :: Rule
ruleBody = rule '%' (themeRule theme)
ruleFooter = rule ':' (themeRule theme)

--------------------------------------------------------------------------------
-- List page
--------------------------------------------------------------------------------

listPage :: Model -> Page
listPage model = page [header, listBody model, listFooter, bottom]

listBody :: Model -> Section
listBody model = sectionBodyRule 1 ruleBody
  [ if null (modelBookmarks model)
      then printerLeft 2
        (blockSimple "No bookmarks yet. Press A to add one." (themeMuted theme))
      else printerColumn 2
        [ bookmarkBlock (index == modelSelected model) index bookmark
        | (index, bookmark) <- zip [0 ..] (modelBookmarks model) ]
  ]

bookmarkBlock :: Bool -> Int -> Bookmark -> Block
bookmarkBlock isSelected index (Bookmark title url) =
  blockCycle
    [ (if isSelected then "> " else "  ", style)
    , (show (index + 1) ++ ". ", style)
    , (title, style)
    , ("  " ++ url, urlStyle)
    ]
  where
    style = if isSelected then themeAccent theme else styleDefault

listFooter :: Section
listFooter = sectionBodyRule 1 ruleFooter
  [ printerLineCenter 4
      [ blockMenuStyle "A" "Add" (themeAccent theme)
      , blockMenuStyle "J" "Down" (themeAccent theme)
      , blockMenuStyle "K" "Up" (themeAccent theme)
      , blockMenuStyle "D" "Delete" (themeDanger theme)
      , blockMenuStyle "X" "Exit" (themeDanger theme) ]
  ]

--------------------------------------------------------------------------------
-- Form page
--------------------------------------------------------------------------------

formPage :: Page
formPage = page [header, formBody, formFooter, bottom]

formBody :: Section
formBody = sectionBodyRule 1 ruleBody
  [ printerLeft 2 (blockSimple "Title: " styleDefault)
  , printerEmpty 1
  , printerLeft 2 (blockSimple "URL:   " styleDefault)
  ]

formFooter :: Section
formFooter = sectionBodyRule 1 ruleFooter
  [ printerLineCenter 4
      [ blockSimple
          "Type a value and press Enter for each field; empty fields cancel."
          (themeFooter theme) ]
  ]

fieldColumn :: String -> Offset
fieldColumn label = formNumber (2 + textWidth label)

formPrompts :: [Prompt]
formPrompts =
  [ promptAt 1 2 (fieldColumn "Title: ")
  , promptAt 1 4 (fieldColumn "URL:   ") ]

--------------------------------------------------------------------------------
-- Application
--------------------------------------------------------------------------------

main :: IO ()
main = withImmediateInput $ do
  state <- start (listPage emptyModel) bookmarkSettings
  loop emptyModel state

loop :: Model -> State -> IO ()
loop model state = do
  key <- readKey
  case fmap toLower key of
    Nothing -> pure ()
    Just 'a' -> addFlow model state
    Just 'j' -> open (moveSelection 1 model) state
    Just 'k' -> open (moveSelection (-1) model) state
    Just 'd' -> open (deleteSelected model) state
    Just 'x' -> pure ()
    _ -> loop model state
  where
    open next st = draw (listPage next) st >>= loop next

addFlow :: Model -> State -> IO ()
addFlow model state = do
  (state', result) <- readForm formPage formPrompts state
  let next = case result of
        Right [title, url]
          | not (null title) && not (null url) ->
              addBookmark title url model
        _ -> model
  draw (listPage next) state' >>= loop next
