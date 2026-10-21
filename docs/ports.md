# Ports

This page records assessments of porting Ansiform to other languages. It is a design note, not a commitment.

## Possible Rust Port

A Rust port is a moderate engineering effort, not a large rewrite. The library has about 3,600 lines of Haskell in `src`, including Haddock comments, and a large part of that is builders and documentation. For an experienced Rust developer who also knows the domain, a realistic estimate is:

| Scope | Time |
| --- | --- |
| MVP: styles, content, layout, tables and rendering to `String` | 3 to 4 weeks |
| Functional parity without forms and interactive input | 4 to 6 weeks |
| Full parity, including the line editor, forms, examples, documentation and cross-platform CI | 6 to 10 weeks |

For part-time work, multiply by two or three. The main risk is not the language, it is behavioural parity for spacing, Unicode widths, borders, wrapping and cursor arithmetic.

### What helps

- **Pure core:** `Content`, `Style`, `Table`, `Section`, `Page` and the builders map naturally to structs, enums and pure functions. The Haskell immutability model translates well to consuming builders that return a new value, with `#[must_use]` where it fits.
- **Algebraic data types:** `Color`, `Format`, `Align`, `Ellipsis`, `Borders`, `FormError` and `LineKey` become Rust enums.
- **Errors as data:** `Maybe` and `Either` become `Option` and `Result`; `tableBlocks` returning `Nothing` becomes `Result<Table, TableError>`.
- **`Number` and `Offset`:** newtypes over `u32` or `usize` with saturating arithmetic.
- **Rendering to a string:** this is simpler than the current Haskell code. Write into a `Vec<u8>` or `String` through `impl Write`; no temporary file is needed.
- **Interactive input:** `crossterm` provides `KeyEvent` with arrows, Home, End, Delete and modifiers, plus raw mode, cursor control and terminal size. This removes almost all of `Ansiform.Internal.Input`: the escape parser, the Escape timeout, `hSetEcho`, `hSetBuffering` and the CSI/SS3 handling.
- **Unicode width:** the `unicode-width` crate covers most of `charWidth`. Emoji, combining marks and zero-width characters still need parity tests.
- **Tests:** golden tests become easier because output can be captured in memory. Property tests with `proptest` help with wrapping and width calculations.

### What complicates

- **Ownership and lifetimes:** choosing between `&str`, `String`, `Cow<'static, str>` and `Arc<str>` in builders and styles. Haskell has no such friction; the Rust API must be designed to avoid unnecessary clones.
- **Representing `Printer`:** in Haskell, `Printer` stores a function. In Rust there are two options: an enum that represents the printing AST plus an interpreter, or `Box<dyn Fn(&mut dyn Write, &Config) -> io::Result<usize>>`. An enum tends to be better for tests and composition; a trait is better for extensibility. This choice defines the API.
- **The `State` lifecycle:** pages, line counts, `amend`, `replace` and `redraw` are simple, but must be reproduced carefully. A `struct State` with `Vec<usize>` and functions that accept `&mut impl Write` works well.
- **Raw mode and restoration:** Haskell uses `bracket`. In Rust, use a guard with `Drop` to disable raw mode, show the cursor and restore the screen even after an error or panic. This is a sensitive area because a failure can leave the terminal unusable.
- **Unicode:** cursor indices. Haskell uses code-point indices; Rust must choose between `Vec<char>`, byte indices with `char_indices`, or a string plus graphemes. The behaviour must be documented, as in the current library, where grapheme movement is a non-goal.
- **Windows:** `crossterm` covers the basics, but MinTTY, MSYS, Cygwin and legacy consoles still need real-terminal tests. The cross-platform CI work done for Ansiform would be repeated.
- **Exact parity:** column alignment, group padding, `BordersNone`, ellipsis truncation and styled wrapping have many edge cases. The Haskell golden tests can be reused as fixtures for Rust.

### Effort by area

| Area | Complexity | Notes |
| --- | --- | --- |
| `Style`, `Theme`, `Number` | Low | Enums, newtypes and constructors. |
| `Width` | Low to medium | `unicode-width` helps; emoji parity needs tests. |
| `Content` (Item, Block, Group, Table, Article) | Medium | Many builders and validations. |
| `Printer`, `Section`, `Page`, `Settings` | Medium | Layout, wrapping, offsets and line counts. |
| Tables and borders | Medium | Many details around alignment, maximum widths and padding. |
| `Draw`, `Terminal`, `Render` | Low to medium | `crossterm` and an in-memory `Write` simplify both. |
| `Input`, forms and line editor | Medium | `crossterm` removes the escape parser; the pure editor logic is small. |
| Tests, documentation, examples and CI | Medium | Golden tests and three operating systems. |

### Recommendation

A native Rust version is worthwhile if the goal is to offer the library to Rust users or embed it in a Rust application. The design is small and well separated, and Rust fits the pure core well. A phased plan:

1. Freeze the behavioural specification with golden outputs from Haskell.
2. Port `Style`, `Width`, `Number` and `Content`, with rendering to `String`.
3. Port printers, sections, pages and tables.
4. Add the terminal driver with `crossterm`.
5. Port the line editor and the forms.
6. Repeat the examples, documentation, CI and parity tests.
7. Publish as a crate, with an API reviewed for ownership and `Result`.

Avoid building the port on `ratatui`. `ratatui` is immediate and buffer-based, while Ansiform is declarative, with pages, line counts and `amend`/`replace`. Using `crossterm` directly preserves the model and avoids friction.

If the goal is only to use Ansiform from Rust, the alternative is to keep the Haskell library and use `crossterm` with `comfy-table` or `tabled` plus `textwrap` in the Rust project. That produces something similar in a few days, but without the same API, theming and page lifecycle.

In short, the algorithmic complexity is low to medium; engineering and parity are the real cost. Full parity is a realistic 6 to 10 week estimate; a useful MVP is 3 to 4 weeks.
