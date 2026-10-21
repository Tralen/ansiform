# Tutorial: a small bookmarks screen

This tutorial builds **Pocket Bookmarks**, a small but complete program. It keeps a list of bookmarks in memory, moves the selection with the keyboard and reads new entries through a form printed inside the page.

The complete program is in `examples/Tutorial.hs` and is compiled by `cabal build all`. Run it with:

```sh
cabal run ansiform-tutorial
```

The keys are `A` to add, `J` and `K` to move the selection, `D` to delete, and `X` to exit.

## 1. Set up the project

Add `ansiform` to the dependencies of an executable. A minimal Cabal stanza looks like this:

```cabal
executable bookmarks
  main-is: Main.hs
  build-depends: base, ansiform
```

The program has two layers. The application model is a pure value, and the drawing layer writes pages to the terminal. Drawing functions return a `State` that records the page on screen and how many lines each section printed, so the next page can replace the previous one in place.

## 2. Describe the data

Start with the values the program needs. A bookmark has a title and a URL; the model keeps the list and the selected index:

```haskell
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
```

Updates are pure functions that return a new `Model`. Nothing is mutated:

```haskell
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
```

`Model` is the application state. It is separate from the `State` type in `Ansiform.Draw`, which tracks the terminal page.

## 3. Assemble the shared components

The header, footer and rules are used by both pages, so they live in one place. This keeps spacing, colors and wording consistent:

```haskell
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
```

`sectionTop 1` prints the header and then one empty line. `printerSolidLineCenter` fills a whole line with the theme bar color and centers the title on top. A `Theme` is a record of `Style` values, so replacing `defaultTheme` changes every component at once.

The URL uses `italic white` so it stays readable on dark terminals. The rules keep `themeRule`, which is black in the default theme; change `urlStyle` or `themeRule` independently if your terminal has a light background.

## 4. Draw the list

A `Page` is a list of sections. The list page has a header, a body, a footer and a bottom rule:

```haskell
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
```

`sectionBodyRule 1` prints a rule, one empty line, the body and one empty line after it. `printerColumn` prints one block per line. The empty list gets a helpful message instead of an empty screen.

`blockCycle` builds a `Block` from text fragments with their styles. The selected row changes the marker and the style, so the selection is visible without a separate cursor data type.

The footer is a single line of menu entries:

```haskell
listFooter :: Section
listFooter = sectionBodyRule 1 ruleFooter
  [ printerLineCenter 4
      [ blockMenuStyle "A" "Add" (themeAccent theme)
      , blockMenuStyle "J" "Down" (themeAccent theme)
      , blockMenuStyle "K" "Up" (themeAccent theme)
      , blockMenuStyle "D" "Delete" (themeDanger theme)
      , blockMenuStyle "X" "Exit" (themeDanger theme) ]
  ]
```

`printerLineCenter` spaces the entries across the line and keeps at least the configured minimum space between them.

## 5. Build the form

The add flow needs two values. Its page reuses the same header and bottom, and adds a body with two labeled lines:

```haskell
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
```

Now describe where the input goes. A `Prompt` is placed by **section index** and by **row inside that section**, which is easier to keep correct than counting all the lines below it:

```haskell
fieldColumn :: String -> Offset
fieldColumn label = formNumber (2 + textWidth label)

formPrompts :: [Prompt]
formPrompts =
  [ promptAt 1 2 (fieldColumn "Title: ")
  , promptAt 1 4 (fieldColumn "URL:   ") ]
```

The form body is section `1`. `sectionBodyRule 1` prints a rule on row `0` and an empty line on row `1`, so the title is row `2` and the URL is row `4`. The footer carries the instruction, so the body only reserves the two editable lines. The column is the label offset plus the display width of the label. `textWidth` understands wide characters and combining marks, so the cursor stays aligned even with Unicode labels.

`readForm` draws the page, places the cursor on each prompt in order and returns the typed values:

```haskell
readForm :: Page -> [Prompt] -> State -> IO (State, Either FormError [String])
```

The result is an ADT. `Right values` contains one string per prompt, `Left (PromptOutsidePage prompt)` means the prompt does not fit the drawn page, and `Left FormInputEnded` means stdin ended. Empty field values are still valid strings; this program decides to cancel the add when either value is empty.

Line input is enabled once for the whole form. Do not wrap `readForm` in `withLineInput`.

## 6. Run the interaction loop

The program starts in immediate input mode, draws the first page and reads one key at a time:

```haskell
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
```

Each action returns a new `Model`, draws the next page and continues the loop. The next `readKey` needs no Enter.

The add flow combines the form with the model update:

```haskell
addFlow :: Model -> State -> IO ()
addFlow model state = do
  (state', result) <- readForm formPage formPrompts state
  let next = case result of
        Right [title, url]
          | not (null title) && not (null url) ->
              addBookmark title url model
        _ -> model
  draw (listPage next) state' >>= loop next
```

`readForm` restores the immediate input settings when it returns, so the list keeps responding to single keys. If the form is cancelled or stdin ends, the model is unchanged and the list is drawn again.

## 7. Try it

Run the program:

```sh
cabal run ansiform-tutorial
```

Then:

1. Press `A` to open the form.
2. Type a title and press Enter.
3. Type a URL and press Enter.
4. Use `J` and `K` to move the selection.
5. Press `D` to delete the selected bookmark, or `X` to exit.

The program has no persistence and no error dialogs; it is intentionally small. The important part is the boundary: pure builders describe the screen, the drawing layer prints it, and the loop decides what to draw next.

## 8. Where to go next

- Add persistence by reading and writing a file outside the pure model functions. Keep the builders pure.
- Replace `printerColumn` with `printerTable` or `printerSequenceSel` to experiment with tables and highlighted paragraphs. See [Content](content.md) and [Printers](printers.md).
- Use `renderPage` or `renderPrinter` from [Render](render.md) to capture output in a `String` for golden tests.
- Read [Input](input.md) for the full input API and [Numbers](number.md) for checked arithmetic.
- Copy `examples/Tutorial.hs` into your own project and change the model. The example is compiled with the library, so it stays aligned with the documented API.
