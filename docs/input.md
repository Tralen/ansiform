# Input

Ansiform's standard interaction is immediate: pressing a key runs an action without waiting for Enter. The library owns the terminal setup, so application code only reads keys and decides what to draw.

```haskell
withImmediateInput :: IO a -> IO a
readKey :: IO (Maybe Char)
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

## Terminal state

`withImmediateInput` changes stdin only when it is a terminal:

- it disables line buffering, so `readKey` does not wait for Enter;
- it disables echo, so typed keys are not shown twice;
- it restores the original buffering and echo settings with `bracket` when the action ends, including on exceptions.

When stdin is not a terminal, as in pipes and CI, the settings are left untouched. `readKey` still reads one character at a time and returns `Nothing` at end of input.

## Keys

`readKey` returns the character as typed. It does not filter newlines, spaces or control keys; the loop decides which keys are meaningful. This keeps the input layer small and lets every screen define its own shortcuts.
