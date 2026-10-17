# Pages and drawing

A `Page` is an ordered list of sections. Drawing a page prints every section and records how many lines each one produced. Those line counts are what make in-place updates possible.

```haskell
newtype Page  -- opaque

page :: [Section] -> Page
amendPage :: Page -> Section -> Number -> Page
amendPage' :: Page -> [Section] -> Number -> Page
```

- `page` builds a page.
- `amendPage p s n` returns a new page with section `n` replaced by `s`.
- `amendPage' p ss n` replaces section `n` and the following sections with the list `ss`. Sections after the inserted block are preserved.

Both functions are pure; they do not draw anything.

## State

`State` is opaque. It carries the settings, the page currently on screen and the line counts returned by the last draw. Create it with `start` and pass it to the drawing functions.

```haskell
start :: Page -> Settings -> IO State
```

`start` clears the screen and draws the initial page.

## Drawing functions

```haskell
draw :: Page -> State -> IO State
redraw :: State -> IO State

amend :: Section -> Number -> State -> IO State
amend' :: [Section] -> Number -> State -> IO State

replace :: Section -> Number -> State -> IO State
replace' :: [Section] -> Number -> State -> IO State
```

- `draw` clears from the top of the screen and draws a new page.
- `redraw` draws the page stored in the state again.
- `amend` applies `amendPage` and redraws the whole page.
- `replace` applies `amendPage'` but preserves the lines above the changed section and only reprints the remainder. It is faster for large pages, but it assumes the lines above still occupy the same rows; if the terminal width changed since the previous draw, use `amend` or `draw` instead.

All drawing functions return a new state; the old state is never mutated.

## Example

```haskell
main :: IO ()
main = do
  state <- start firstPage defaultSettings
  _ <- getLine
  state' <- draw secondPage state
  _ <- getLine
  state'' <- amend newBody 1 state'
  _ <- getLine
  _ <- redraw state''
  pure ()
```

A typical page uses section `0` for the header, the middle sections for the body and the last sections for the footer. Keeping those indices stable makes `amend` and `replace` predictable.
