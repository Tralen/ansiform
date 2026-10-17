# Sections

A `Section` groups printers and reserves a minimum number of lines. A page is a list of sections; the index of a section is the unit used by `amend` and `replace`.

```haskell
newtype Section  -- opaque

section :: [Printer] -> Section
section' :: Number -> [Printer] -> Section
runSection :: Settings -> Section -> IO Number
runSectionDefault :: Section -> IO Number
runSectionDefault' :: Number -> Number -> Section -> IO Number
```

`section` prints the printers in order. `section' n` also guarantees at least `n` lines: if the printers print fewer, the section is padded with empty lines.

```haskell
simple :: Section
simple = section
  [ printerLeft 2 (blockSimple "Hello" (bold cyan))
  , printerEmpty 1
  , printerLeft 2 (blockSimple "World" (bold green))
  ]
```

## Padding above and below

```haskell
sectionBody :: Number -> [Printer] -> Section
sectionBody' :: Number -> Number -> [Printer] -> Section
```

`sectionBody n ps` prints `n` empty lines before and after `ps`. `sectionBody' m n ps` is the same with a minimum of `m` lines.

## Padding below only

```haskell
sectionTop :: Number -> [Printer] -> Section
sectionTop' :: Number -> Number -> [Printer] -> Section
```

`sectionTop n ps` prints `ps` followed by `n` empty lines. Use it for headers.

## Rules

```haskell
sectionRule :: Rule -> Section

sectionBodyRule :: Number -> Rule -> [Printer] -> Section
sectionBodyRule' :: Number -> Number -> Rule -> [Printer] -> Section

sectionTopRule :: Number -> Rule -> [Printer] -> Section
sectionTopRule' :: Number -> Number -> Rule -> [Printer] -> Section
```

- `sectionRule r` is a rule alone.
- `sectionBodyRule n r ps` prints a rule, `n` empty lines, `ps`, then `n` empty lines. The primed version adds a minimum line count.
- `sectionTopRule n r ps` prints a rule, `ps`, then `n` empty lines.

The usual page skeleton is:

```haskell
header :: Section
header = sectionTopRule 1 (rule '=' (bold black'))
  [ printerSolidLineCenter 0 1 blue
      [ blockSimple "My Program" (bold white') ]
  ]

body :: Section
body = sectionBodyRule 1 (rule ':' (bold black'))
  [ printerLeft 2 (blockSimple "Content goes here." styleDefault) ]

footer :: Section
footer = sectionBodyRule 1 (rule ':' (bold black'))
  [ printerLeft 2 (blockSimple "Press Enter to continue." styleDefault) ]
```

Keeping `header`, `body` and `footer` as reusable top-level values keeps every screen consistent in spacing and theming.
