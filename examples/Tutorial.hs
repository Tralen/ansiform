-- | Small bookmarks application used by the tutorial.
--
--   Run with:
--
--   > cabal run ansiform-tutorial
module Main where

import Ansiform
import Data.Char (toLower)

--------------------------------------------------------------------------------
-- Data model
--------------------------------------------------------------------------------

data Bookmark = Bookmark
    { bookmarkTitle :: String
    , bookmarkURL :: String
    }
    deriving (Eq, Show)

data Model = Model
    { modelBookmarks :: [Bookmark]
    , modelSelected :: Int
    }
    deriving (Eq, Show)

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

updateSelected :: String -> String -> Model -> Model
updateSelected title url model@(Model bookmarks selected) = case bookmarks of
    [] -> model
    _ ->
        let index = clampSelection (length bookmarks) selected
         in Model (replaceAt index (Bookmark title url) bookmarks) index

replaceAt :: Int -> a -> [a] -> [a]
replaceAt index value values =
    take index values ++ [value] ++ drop (index + 1) values

selectedBookmark :: Model -> Maybe Bookmark
selectedBookmark (Model bookmarks selected) =
    bookmarkAt (clampSelection (length bookmarks) selected) bookmarks

bookmarkAt :: Int -> [Bookmark] -> Maybe Bookmark
bookmarkAt index bookmarks = case drop index bookmarks of
    [] -> Nothing
    (bookmark : _) -> Just bookmark

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
header =
    sectionTop
        1
        [ printerSolidLineCenter
            0
            1
            (themeBar theme)
            [blockSimple "Pocket Bookmarks" (themeHeader theme)]
        , printerEmpty 1
        , printerLineCenter
            4
            [blockSimple "A small Ansiform tutorial" (themeSubtitle theme)]
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
listBody model =
    sectionBodyRule
        1
        ruleBody
        [ if null (modelBookmarks model)
            then
                printerLeft
                    2
                    (blockSimple "No bookmarks yet. Press A to add one." (themeMuted theme))
            else
                printerColumn
                    2
                    [ bookmarkBlock (index == modelSelected model) index bookmark
                    | (index, bookmark) <- zip [0 ..] (modelBookmarks model)
                    ]
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
listFooter =
    sectionBodyRule
        1
        ruleFooter
        [ printerLineCenter
            4
            [ blockMenuStyle "A" "Add" (themeAccent theme)
            , blockMenuStyle "J" "Down" (themeAccent theme)
            , blockMenuStyle "K" "Up" (themeAccent theme)
            , blockMenuStyle "D" "Delete" (themeDanger theme)
            , blockMenuStyle "E" "Edit" (themeAccent theme)
            , blockMenuStyle "X" "Exit" (themeDanger theme)
            ]
        ]

--------------------------------------------------------------------------------
-- Form page
--------------------------------------------------------------------------------

formPage :: String -> Page
formPage instruction = page [header, formBody, formFooter instruction, bottom]

formBody :: Section
formBody =
    sectionBodyRule
        1
        ruleBody
        [ printerLeft 2 (blockSimple "Title: " styleDefault)
        , printerEmpty 1
        , printerLeft 2 (blockSimple "URL:   " styleDefault)
        ]

formFooter :: String -> Section
formFooter instruction =
    sectionBodyRule
        1
        ruleFooter
        [ printerLineCenter
            4
            [blockSimple instruction (themeFooter theme)]
        ]

addInstruction, editInstruction :: String
addInstruction =
    "Type a value and press Enter for each field; empty fields cancel."
editInstruction =
    "Edit the values and press Enter; Esc cancels."

fieldColumn :: String -> Offset
fieldColumn label = formNumber (2 + textWidth label)

formPrompts :: [Prompt]
formPrompts =
    [ promptAt 1 2 (fieldColumn "Title: ")
    , promptAt 1 4 (fieldColumn "URL:   ")
    ]

editPrompts :: Bookmark -> [Prompt]
editPrompts (Bookmark title url) =
    [ promptWithInitial 1 2 (fieldColumn "Title: ") title
    , promptWithInitial 1 4 (fieldColumn "URL:   ") url
    ]

--------------------------------------------------------------------------------
-- Application
--------------------------------------------------------------------------------

main :: IO ()
main = withImmediateInput $ do
    state <- start (listPage emptyModel) bookmarkSettings
    loop emptyModel state

loop :: Model -> State -> IO ()
loop model state = do
    key <- readKeyPress
    case fmap toLower key of
        Nothing -> pure ()
        Just 'a' -> addFlow model state
        Just 'j' -> open (moveSelection 1 model) state
        Just 'k' -> open (moveSelection (-1) model) state
        Just 'd' -> open (deleteSelected model) state
        Just 'e' -> editFlow model state
        Just 'x' -> pure ()
        _ -> loop model state
  where
    open next st = draw (listPage next) st >>= loop next

addFlow :: Model -> State -> IO ()
addFlow model state = do
    (state', result) <- readForm (formPage addInstruction) formPrompts state
    let next = case result of
            Right [title, url]
                | not (null title) && not (null url) ->
                    addBookmark title url model
            _ -> model
    draw (listPage next) state' >>= loop next

editFlow :: Model -> State -> IO ()
editFlow model state = case selectedBookmark model of
    Nothing -> draw (listPage model) state >>= loop model
    Just bookmark -> do
        (state', result) <-
            readForm
                (formPage editInstruction)
                (editPrompts bookmark)
                state
        let next = case result of
                Right [title, url]
                    | not (null title) && not (null url) ->
                        updateSelected title url model
                _ -> model
        draw (listPage next) state' >>= loop next
