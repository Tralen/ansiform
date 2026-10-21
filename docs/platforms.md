# Platforms

Ansiform targets Linux, macOS and Windows. The pure builders, layout and rendering code are portable. The differences are in terminal detection, key delivery and terminal size.

## Summary

| Area | Linux | macOS | Windows |
| --- | --- | --- | --- |
| ANSI styling | Native. | Native. | Native on Windows 10 and later; emulated on legacy consoles. |
| Terminal size | `ioctl`. | `ioctl`. | Win32 console API. |
| Immediate keys | Yes. | Yes. | Yes with the `winio` I/O manager and a native console or Windows Terminal. |
| Forms and line editor | Yes. | Yes. | Yes under the same conditions as immediate keys. |
| UTF-8 widths | Yes. | Yes. | Depends on the console code page and font. |

## Dependencies

- `ansi-terminal` writes ANSI sequences and provides the same operations through the Windows console API when native support is missing.
- `terminal-size` queries the size through `ioctl` on POSIX and the Win32 console API on Windows.
- `base` supplies handles, echo control, buffering and `hWaitForInput`.
- Nothing depends on `unix`. On Windows the dependency graph includes `Win32` only through `terminal-size`.

## Linux and macOS

Everything in this documentation applies as written. `hIsTerminalDevice` recognises the terminal, `hSetBuffering` and `hSetEcho` change the terminal mode, and escape sequences arrive as ordinary input. Terminal.app and iTerm2 send the CSI sequences listed in [Input](input.md).

Configured colour detection uses `hSupportsANSI`, which checks that the output handle is a terminal and that `TERM` is not `dumb`. `NO_COLOR` still disables styling.

Escape-sequence timeouts use `hWaitForInput`, so a lone Escape or an arrow key never interrupts a blocked read with an asynchronous exception. Without `-threaded`, `hWaitForInput` blocks other Haskell threads for the length of the timeout; this is fine for the single-threaded interaction loop and avoids a thread per keystroke.

## Windows

ANSI output, cursor movement and width queries work through `ansi-terminal` and `terminal-size` in `cmd.exe`, Windows Terminal and applications built with a native console. On Windows 10 and later the console processes ANSI sequences; on older consoles `ansi-terminal` emulates the operations it supports.

The size query runs only when the handle is a terminal. This avoids the `stty` fallback in `terminal-size`, which on Windows can close a non-console handle. As a consequence, MinTTY and MSYS sessions, whose handles look like pipes, use the 80 by 24 default instead of a detected size.

### Immediate input

Immediate input needs console input that does not wait for Enter. In GHC 9.14.1 the Windows build of the runtime enables the `winio` I/O manager but keeps `mio` as the default for the threaded runtime and `win32-legacy` as the default for the non-threaded runtime. With those defaults, `hSetBuffering stdin NoBuffering` may not take effect and `getChar` can wait for Enter, which is the long-standing behaviour tracked as GHC issue 2189.

Select the native manager when building an interactive program:

```cabal
if os(windows)
  ghc-options: -with-rtsopts=--io-manager=winio
```

The bundled `ansiform-demo` and `ansiform-tutorial` executables already set this option on Windows. Libraries cannot set RTS options, so applications that embed Ansiform must add it themselves.

`hIsTerminalDevice stdin` is reliable for the native console and Windows Terminal. MinTTY, MSYS and Cygwin connect standard input through pipes, so Ansiform sees a non-interactive stdin: immediate input is not enabled, `readKeyPress` returns characters only when a line is available, and forms fall back to line reading. Use Windows Terminal or `cmd.exe` for interactive screens.

The library handles the common Windows key codes: Enter arrives as `\r` or `\n`, and Backspace as `\b` or `DEL`. Arrow keys reach `readKeyPress` and the line editor only when the console delivers them as escape sequences. If the console instead reports them as key events, `getChar` cannot return them and the application sees no input for those keys; this requires Win32 input APIs, which Ansiform does not use. `readKeyPress` still protects every shortcut from any sequence that is delivered.

### Text

GHC uses the console code page for console input and output. Run `chcp 65001` and use a font with the required glyphs to display wide characters. The layout code measures them correctly even when the console cannot render them.

## Unsupported

- Immediate input through MinTTY, MSYS or Cygwin pipes.
- Mouse input.
- Bracketed paste.
- Grapheme-cluster cursor movement. Editing and cursor movement work by Unicode code point, so combining marks may be split.

## Testing

The CI matrix builds, tests, checks, documents and packages the library on Linux, macOS and Windows. Linux and Windows use GHC 9.2.8 and GHC 9.14.1; macOS uses GHC 9.14.1, because GHC 9.2.8 has no aarch64-darwin bindist for the arm64 runner. CI still cannot press keys, so the interaction statements above come from the GHC, `ansi-terminal`, `terminal-size` and base documentation and the manual checklist below.

A manual checklist for each platform:

1. Draw a page, press a key and confirm that the screen changes without Enter.
2. Press the four arrows in a menu and confirm that no shortcut runs.
3. Open a form with `promptWithInitial`, move, insert, Backspace, Delete, Home, End, submit with Enter and cancel with Esc.
4. Type a value wider than the terminal and confirm that the window scrolls with the cursor.
5. Confirm that colours appear on a terminal and disappear when output is redirected.
6. Resize the terminal and confirm that the layout uses the new width.
