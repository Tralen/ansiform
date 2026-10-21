# Input

Ansiform's standard interaction is immediate: pressing a key runs an action without waiting for Enter. The library owns the terminal setup, so application code only reads keys and decides what to draw.

```haskell
withImmediateInput :: IO a -> IO a
readKey :: IO (Maybe Char)
readKeyPress :: IO (Maybe Char)

withLineInput :: IO a -> IO a
readLine :: IO (Maybe String)

readLineAt :: Number -> Offset -> IO (Maybe String)
readLineAtOn :: Handle -> Number -> Offset -> IO (Maybe String)

data Prompt  -- opaque
promptAt :: Number -> Number -> Offset -> Prompt
promptWithInitial :: Number -> Number -> Offset -> String -> Prompt

data FormError = PromptOutsidePage Prompt | FormInputEnded | FormCancelled

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

`readKeyPress` returns one key press, or `Nothing` at end of input. It discards terminal escape sequences, such as the ones sent by arrow keys, Home, End and function keys, so they cannot trigger shortcuts by accident. Lowercase the key when shortcuts are case-insensitive:

```haskell
import Data.Char (toLower)

loop :: State -> IO ()
loop state = do
  key <- readKeyPress
  case fmap toLower key of
    Just 'n' -> draw secondPage state >>= loop
    Just 'p' -> draw firstPage state >>= loop
    Just 'x' -> pure ()
    _ -> loop state
```

Pressing `N` or `P` changes the page immediately. The loop ignores unknown keys and keeps the current state.

`readKey` is the raw reader: it returns the character as typed, including the individual characters of an escape sequence. Use it only when the application interprets those characters itself, such as the line editor behind `readForm`. `readKeyPress` returns a lone Escape as `Just '\ESC'`, because it cannot be part of a longer sequence.

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

`promptAt section row column` places a prompt on a zero-based section index, a zero-based row inside that section and an absolute column. Section-relative rows stay correct when the other sections change height. Prompts are read in list order, should each occupy a different page line, and the helper moves the cursor up or down between them as needed. A form without editable fields enables line input once for the whole form. Editable fields switch to immediate input per field and restore the previous mode afterwards. In both cases, callers must not wrap `readForm` in `withLineInput`.

The result is an ADT: `Right values` contains one string per prompt, `Left (PromptOutsidePage p)` reports a prompt that does not fit the drawn page, `Left FormInputEnded` reports end of input, and `Left FormCancelled` reports that the user pressed Esc in an editable field. When a prompt does not fit, no input is read. The returned state is the one produced by drawing the page, so the caller can redraw or amend it.

Both helpers assume the typed text does not wrap to another terminal line.

## Editable fields

A field that edits an existing value needs the text to be in the editable buffer when it opens. The terminal's line discipline has no concept of an initial buffer, so `promptWithInitial` opts into a single-line editor owned by Ansiform:

```haskell
let prompts =
      [ promptWithInitial 2 0 14 (taskTitle task)
      , promptWithInitial 3 0 14 (taskContent task)
      ]
```

`promptWithInitial section row column initial` places the cursor at the end of `initial`, so the user can backspace, move and insert without retyping the value. Non-printable characters are removed, because the editor is single-line. An empty initial value is still meaningful: it opens the editor with an empty buffer, which lets a form use the same editor for every field.

When the form opens, every field with an initial value is drawn in its prompt line, so all current values are visible before the first field is focused. The active field redraws the same text and starts with the cursor at the end. Fields built with `promptAt` keep their page text and receive input through the terminal line discipline.

The editor owns the region from the prompt column to the end of the line. It clears that region and redraws the visible window on every key, scrolling horizontally when the value is wider than the terminal. The window uses `charWidth`, so wide characters and combining marks keep the cursor aligned.

| Key | Action |
| --- | --- |
| Printable character | Insert at the cursor. |
| `Backspace` | Delete the character before the cursor. |
| `Delete` | Delete the character at the cursor. |
| `Left` / `Right` | Move the cursor one code point. |
| `Home` / `End` | Move to the start or end of the buffer. |
| `Enter` | Submit the field. |
| `Esc` | Cancel the whole form. |

`Enter` prints a newline after the field, matching the line counts used by `readForm`. `Esc` cancels the whole form and returns `Left FormCancelled`; a partially completed form is rarely useful, and the caller can reopen it. Unknown escape sequences are ignored.

When stdin is not a terminal, as in pipes and CI, `readForm` falls back to `readLine` and ignores the initial value. The editor is a UI affordance; non-interactive consumers should send explicit values.

The form returns the exact edited buffers. It does not apply "empty means keep" semantics; that decision belongs to the caller. Prompts built with `promptAt` keep reading through the terminal's own line discipline, so existing forms behave as before.

The pure editing core lives in `Ansiform.Line`:

```haskell
data LineState = LineState
  { lineText :: String
  , lineCursor :: Int
  }

data LineKey
  = LineInsert Char
  | LineBackspace
  | LineDelete
  | LineMoveLeft
  | LineMoveRight
  | LineMoveHome
  | LineMoveEnd

applyLineKey :: LineKey -> LineState -> LineState
visibleLine :: Int -> LineState -> (String, Int)
```

`lineCursor` is a code-point index. `applyLineKey` and `visibleLine` are pure and testable without a terminal, while the IO loop only decodes keys, calls them and redraws.

## Terminal state

`withImmediateInput` changes stdin only when it is a terminal:

- it disables line buffering, so `readKey` and `readKeyPress` do not wait for Enter;
- it disables echo, so typed keys are not shown twice;
- it restores the original buffering and echo settings with `bracket` when the action ends, including on exceptions.

When stdin is not a terminal, as in pipes and CI, the settings are left untouched. `readKey` and `readKeyPress` still read one key at a time and return `Nothing` at end of input.

On Windows, immediate input also requires an I/O manager that delivers console input without waiting for Enter, normally `winio`. See [Platforms](platforms.md) for the runtime option, the terminal requirements and the known limitations.

## Keys

`readKey` returns the character as typed. `readKeyPress` goes one level up: it consumes complete escape sequences and returns only the keys a shortcut map should see. Neither filters newlines, spaces or control keys; the loop decides which keys are meaningful. This keeps the input layer small and lets every screen define its own shortcuts.
