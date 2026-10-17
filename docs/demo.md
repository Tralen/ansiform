# Demo

The package ships with an interactive gallery:

```sh
cabal run vis-demo
```

Press Enter at each prompt to advance. The demo keeps the same header and
footer components across screens and changes only the body, which is the
pattern recommended for applications built with Vis.

## Sequence

1. **Menu page.** A column of marked menu items.
2. **Rich table.** The body section is amended in place with a table whose
   cells use independent styles.
3. **Footer update.** The footer section is amended with a different command
   line.
4. **Redraw.** The current page is redrawn without changing its content.
5. **List page.** A list of composers flows into multiple columns.
6. **Groups page.** Three groups are spaced across the available width.
7. **Simple table page.** A table built with `tableSimple`, reusing the header
   styles for each column.
8. **Article page.** Styled paragraph fragments wrap at the terminal width.
9. **Replace.** The article body is replaced with a showcase of the composite
   block builders, preserving the header and reprinting the rest.

## Source

The executable lives in `examples/Demo.hs`. It uses only the public API and
defines its version in `demoVersion`, next to the package version in
`vis.cabal`.
