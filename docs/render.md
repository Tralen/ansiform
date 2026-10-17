# Rendering

Printers write to a `Handle`, not directly to stdout. The handle is carried by an internal `Output` value that combines the target with the resolved `Config`. Every printer has a default runner that uses stdout and an `On` variant that accepts another handle.

## Handles

```haskell
runPrinterOn :: Handle -> Settings -> Printer -> IO Number
runPrinterDefaultOn :: Handle -> Printer -> IO Number
runPrinterDefaultOn' :: Handle -> Width -> Width -> Printer -> IO Number
```

The drawing layer follows the same pattern:

```haskell
startOn :: Handle -> Page -> Settings -> IO State
drawOn :: Handle -> Page -> State -> IO State
redrawOn :: Handle -> State -> IO State

amendOn :: Handle -> Section -> Number -> State -> IO State
amendOn' :: Handle -> [Section] -> Number -> State -> IO State

replaceOn :: Handle -> Section -> Number -> State -> IO State
replaceOn' :: Handle -> [Section] -> Number -> State -> IO State
```

The original functions without the `On` suffix write to stdout and delegate to these variants.

## Strings

`Ansiform.Render` captures the same output in a `String`:

```haskell
renderPage :: Page -> Settings -> IO String
renderSection :: Section -> Settings -> IO String
renderPrinter :: Printer -> Settings -> IO String
```

```haskell
import Ansiform

main :: IO ()
main = do
  output <- renderPage examplePage (settings [width 40, neverColors])
  putStr output
```

Rendering uses a temporary handle, so nothing is written to stdout. The captured string contains the same terminal control sequences that would be written to a real handle:

- Use `neverColors` to remove SGR sequences.
- Cursor movement sequences remain, because they position columns and compose lines.
- Set `width` explicitly for deterministic output; terminal size detection returns `Nothing` for a temporary handle.

`renderPage` does not clear the screen. It runs the page printers, so the result is suitable for golden tests and for embedding in another application.
