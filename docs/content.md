# Content

Content values describe what should appear on screen. They carry no terminal state and can be built, compared and reused freely.

## Types

| Type | Meaning |
| --- | --- |
| `VisItem` | A piece of text with a single `VisStyle`. |
| `VisBlock` | A sequence of items printed without breaks. It contains no empty items. |
| `VisGroup` | A header block followed by body blocks. |
| `VisTable` | A list of groups that all have the same number of blocks. |
| `VisParagraph` | A list of blocks that flow as one wrapped paragraph. |
| `VisArticle` | A list of paragraphs. |
| `VisRule` | A character and a style used to draw a horizontal rule. |

`VisItem` removes non-printable characters when it is built. `VisBlock` removes empty items, so styles are never applied to empty strings.

## Basic builders

```haskell
item :: String -> VisStyle -> VisItem
block :: [VisItem] -> VisBlock
blockSimple :: String -> VisStyle -> VisBlock
blockEmpty :: VisBlock
```

```haskell
greeting :: VisBlock
greeting = blockSimple "Hello" (bold cyan)
```

Use `block` when different parts of the same block need different styles:

```haskell
mixed :: VisBlock
mixed = block [ item "Ansiform" (bold cyan)
              , item " is " styleDefault
              , item "pure" (bold green) ]
```

## Composite block builders

These builders cover common line shapes.

| Builder | Result |
| --- | --- |
| `blockCycle [(text, style)]` | Items in the given order. |
| `blockSeq texts style separator separatorStyle` | `A sep B sep C`. |
| `blockMark char text markedStyle textStyle` | `text` with the first `char` styled differently. |
| `blockMarked char text markedStyle` | Like `blockMark`, with the default style for the rest. |
| `blockEnum index text color` | `index text`, both styled. |
| `blockSlash left right color` | `left / right`. |
| `blockMenu key text color` | `key: text`, used for menus. |
| `blockVal name value color` | `name -> value`. |
| `blockAssoc values style arrowStyle` | `A -> B -> C`. |
| `blockAssoc' values style arrowStyle` | `A <- B <- C`. |
| `blockBars values style barStyle` | Values separated by a bar. |

```haskell
menu :: [VisBlock]
menu =
  [ blockMenu "S" "Search" cyan
  , blockMenu "D" "Display" cyan
  , blockMenu "X" "Exit" red
  ]

flight :: VisBlock
flight = blockAssoc ["Paris", "London"] styleDefault (normal magenta)
```

## Groups

A group is a header plus body blocks:

```haskell
groupSimple :: VisBlock -> [VisBlock] -> VisGroup
```

```haskell
greek :: VisGroup
greek = groupSimple (blockSimple "Greek" (normal yellow))
  [ blockEnum "01" "Socrates" black
  , blockEnum "02" "Plato" black
  , blockEnum "03" "Aristotle" black ]
```

Groups are the building block of side-by-side layouts and tables.

## Tables

A table is a list of equally sized groups. Each group becomes a column.

### Rich tables

Every cell is a `VisBlock`, so each cell can have its own styles:

```haskell
tableBlocks :: [VisBlock] -> [[VisBlock]] -> Maybe VisTable
```

```haskell
flights :: Maybe VisTable
flights = tableBlocks
  [ blockSimple "Flight" (bold yellow)
  , blockSimple "Route" (normal yellow) ]
  [ [ blockSimple "1929" (bold green)
    , blockAssoc ["Portland", "Charlotte"] styleDefault (normal magenta) ]
  , [ blockSimple "710" (bold green)
    , blockAssoc ["Lagos", "Abuja"] styleDefault (normal magenta) ] ]
```

### Simple tables

Every cell is a plain string. The header blocks are rewritten with the given header style, while the first item of each header block supplies the style for that column in the body:

```haskell
tableSimple :: [VisBlock] -> VisStyle -> [[String]] -> Maybe VisTable
```

```haskell
people :: Maybe VisTable
people = tableSimple
  [ blockSimple "Name" (bold green)
  , blockSimple "Age" (bold cyan) ]
  (bold white)
  [ ["Ada", "36"]
  , ["Alan", "41"] ]
```

Here the header is printed in bold white, the name column in bold green and the age column in bold cyan.

### Prebuilt groups

```haskell
tableGroups :: [VisGroup] -> Maybe VisTable
```

Use this when the columns are already groups and only the rectangular check is needed.

### Validation

All three builders return `Nothing` when the table is not rectangular:

```haskell
tableBlocks [blockSimple "A" styleDefault] []          -- Just (empty table)
tableBlocks [blockSimple "A" styleDefault]
            [[blockSimple "1" styleDefault]]            -- Just (one column)
tableBlocks [blockSimple "A" styleDefault]
            [[blockSimple "1" styleDefault, blockSimple "2" styleDefault]]
                                                        -- Nothing
```

The result is an ADT, not an exception. Callers decide how to report invalid input to the user.

## Paragraphs and articles

A `VisParagraph` is a list of blocks that are wrapped as one continuous paragraph. A `VisArticle` is a list of paragraphs. Builders only describe the content; wrapping happens in `printerParagraph` and `printerArticle`.

```haskell
paragraph :: VisParagraph
paragraph =
  [ blockSimple "Ansiform " textBold
  , blockSimple "wraps styled fragments without losing their formatting."
      textRegular
  ]

article :: VisArticle
article = [paragraph, paragraph]
```

## Rules

```haskell
rule :: Char -> VisStyle -> VisRule
ruleDefault :: VisStyle -> VisRule   -- uses '.'
ruleSolid :: VisColor -> VisRule     -- solid spaces with a background
```

```haskell
sectionRule (rule '=' (bold black'))
sectionRule (ruleDefault (bold black'))
sectionRule (ruleSolid blue)
```
