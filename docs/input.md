# Input

Ansiform's standard interaction is immediate: pressing a key runs an action without waiting for Enter. The library owns the terminal setup, so application code only reads keys and decides what to draw.

```haskell
withImmediateInput :: IO a -> IO a
readKey :: IO (Maybe Char)

withLineInput :: IO a -> IO a
readLine :: IO (Maybe String)

readLineAt :: Number -> Offset -> IO (Maybe String)
readLineAtOn :: Handle -> Number -> Offset -> IO (Maybe String)

data Prompt  -- opaque
promptAt :: Number -> Number -> Offset -> Prompt

data FormError = PromptOutsidePage Prompt | FormInputEnded

readForm :: Page -> [Prompt] -> State -> IO (State, Either FormError [String])
readFormOn :: Handle -> Page -> [Prompt] -> State -> IO (State, Either FormError [String])
```

## Setting up

Wrap the interactive part of the program in `withImmediateInput`:

```haskell
main :: IO ()
main = withImmediateInput $ do
  state <- start firstPage defaultSettings
  loop state
```

## The standard loop

`readKey` returns one character, or `Nothing` at end of input. Lowercase the key when shortcuts are case-insensitive:

```haskell
import Data.Char (toLower)

loop :: State -> IO ()
loop state = do
  key <- readKey
  case fmap toLower key of
    Just 'n' -> draw secondPage state >>= loop
    Just 'p' -> draw firstPage state >>= loop
    Just 'x' -> pure ()
    _ -> loop state
```

Pressing `N` or `P` changes the page immediately. The loop ignores unknown keys and keeps the current state.

## Line input

Some screens need a value typed by the user. `withLineInput` temporarily restores line buffering and echo, and `readLine` reads until Enter:

```haskell
promptNumber :: IO (Maybe String)
promptNumber = withLineInput $ do
  putStr "Enter a number and press Enter: "
  hFlush stdout
  readLine
```

`withLineInput` restores the immediate input settings when the action ends, so the same program can mix key-driven and line-driven screens. `readLine` returns `Nothing` at end of input.

## Prompts inside a page

When the prompt belongs to the screen, print it as part of the page instead of writing it after the footer. Draw the page with a prompt line, then place the input on that line with `readLineAt`:

```haskell
ask state = do
  state' <- draw (screenPage GroupsPrompt) state
  input <- readLineAt rowsUp column
  open (chosenScreen input) state'
```

`readLineAt rowsUp column` moves the cursor up `rowsUp` lines, sets it to the absolute `column`, flushes the output and reads a line with echo. `rowsUp` counts the lines printed after the prompt plus the cursor row that follows them. `column` is the prompt offset plus the display width of the prompt text. Because the page is not redrawn until the input is complete, the typed text stays on the prompt line, above the command keys and with nothing printed below the footer.

`readLineAt` already wraps `withLineInput`. Do not wrap it again, either directly or through another helper: the terminal mode would be changed and restored twice, which can leave echo or buffering in the wrong state.

`readLineAtOn` writes the cursor movement to a given handle. Like `withLineInput`, it changes the cursor and echo only when stdin is a terminal.

## Forms

Counting the lines below every prompt is fragile. `readForm` takes a page and a list of prompts, draws the page, and computes the cursor movement from the line counts recorded by the draw:

```haskell
ask state = do
  (state', input) <- readForm page
    [ promptAt 2 2 nameColumn
    , promptAt 2 4 ageColumn ] state
  case input of
    Right [name, age] -> save name age state'
    Right _ -> retry state'
    Left _ -> retry state'
```

`promptAt section row column` places a prompt on a zero-based section index, a zero-based row inside that section and an absolute column. Section-relative rows stay correct when the other sections change height. Prompts are read in list order, should each occupy a different page line, and the helper moves the cursor up or down between them as needed. Line input is enabled once for the whole form, so callers must not wrap `readForm` in `withLineInput`.

The result is an ADT: `Right values` contains one string per prompt, `Left (PromptOutsidePage p)` reports a prompt that does not fit the drawn page, and `Left FormInputEnded` reports end of input. When a prompt does not fit, no input is read. The returned state is the one produced by drawing the page, so the caller can redraw or amend it.

Both helpers assume the typed text does not wrap to another terminal line.

## Terminal state

`withImmediateInput` changes stdin only when it is a terminal:

- it disables line buffering, so `readKey` does not wait for Enter;
- it disables echo, so typed keys are not shown twice;
- it restores the original buffering and echo settings with `bracket` when the action ends, including on exceptions.

When stdin is not a terminal, as in pipes and CI, the settings are left untouched. `readKey` still reads one character at a time and returns `Nothing` at end of input.

## Keys

`readKey` returns the character as typed. It does not filter newlines, spaces or control keys; the loop decides which keys are meaningful. This keeps the input layer small and lets every screen define its own shortcuts.
