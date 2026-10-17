# Sections

A `VisSection` groups printers and reserves a minimum number of lines. A page is a list of sections; the index of a section is the unit used by `amend` and `replace`.

```haskell
newtype VisSection  -- opaque

section :: [VisPrinter] -> VisSection
section' :: VisNumber -> [VisPrinter] -> VisSection
runSection :: VisSettings -> VisSection -> IO VisNumber
runSectionDefault :: VisSection -> IO VisNumber
runSectionDefault' :: VisNumber -> VisNumber -> VisSection -> IO VisNumber
```

`section` prints the printers in order. `section' n` also guarantees at least `n` lines: if the printers print fewer, the section is padded with empty lines.

```haskell
simple :: VisSection
simple = section
  [ printerLeft 2 (blockSimple "Hello" (bold cyan))
  , printerEmpty 1
  , printerLeft 2 (blockSimple "World" (bold green))
  ]
```

## Padding above and below

```haskell
sectionBody :: VisNumber -> [VisPrinter] -> VisSection
sectionBody' :: VisNumber -> VisNumber -> [VisPrinter] -> VisSection
```

`sectionBody n ps` prints `n` empty lines before and after `ps`. `sectionBody' m n ps` is the same with a minimum of `m` lines.

## Padding below only

```haskell
sectionTop :: VisNumber -> [VisPrinter] -> VisSection
sectionTop' :: VisNumber -> VisNumber -> [VisPrinter] -> VisSection
```

`sectionTop n ps` prints `ps` followed by `n` empty lines. Use it for headers.

## Rules

```haskell
sectionRule :: VisRule -> VisSection

sectionBodyRule :: VisNumber -> VisRule -> [VisPrinter] -> VisSection
sectionBodyRule' :: VisNumber -> VisNumber -> VisRule -> [VisPrinter] -> VisSection

sectionTopRule :: VisNumber -> VisRule -> [VisPrinter] -> VisSection
sectionTopRule' :: VisNumber -> VisNumber -> VisRule -> [VisPrinter] -> VisSection
```

- `sectionRule r` is a rule alone.
- `sectionBodyRule n r ps` prints a rule, `n` empty lines, `ps`, then `n` empty lines. The primed version adds a minimum line count.
- `sectionTopRule n r ps` prints a rule, `ps`, then `n` empty lines.

The usual page skeleton is:

```haskell
header :: VisSection
header = sectionTopRule 1 (rule '=' (bold black'))
  [ printerSolidLineCenter 0 1 blue
      [ blockSimple "My Program" (bold white') ]
  ]

body :: VisSection
body = sectionBodyRule 1 (rule ':' (bold black'))
  [ printerLeft 2 (blockSimple "Content goes here." styleDefault) ]

footer :: VisSection
footer = sectionBodyRule 1 (rule ':' (bold black'))
  [ printerLeft 2 (blockSimple "Press Enter to continue." styleDefault) ]
```

Keeping `header`, `body` and `footer` as reusable top-level values keeps every screen consistent in spacing and theming.
