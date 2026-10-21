# Numbers

`Number` is a newtype over `Int` that never holds a negative value. It is used for widths, offsets, padding, row limits and counts.

```haskell
formNumber :: Int -> Number
unNumber :: Number -> Int

addNumber :: Number -> Number -> Number
subtractNumber :: Number -> Number -> Number
subtractNumberMaybe :: Number -> Number -> Maybe Number
```

`formNumber` caps negative input at zero. `unNumber` returns the underlying value.

## Literals and arithmetic

`Number` has a `Num` instance so numeric literals and addition remain convenient:

```haskell
printerLeft 0 (blockSimple "Hello" styleDefault)
```

Subtraction through `(-)` also caps at zero:

```haskell
2 - 5 :: Number  -- 0
```

This keeps the non-negative invariant, but it hides the difference between a real zero and a result that would have been negative. When callers must distinguish those cases, use checked subtraction:

```haskell
subtractNumberMaybe 2 5  -- Nothing
subtractNumberMaybe 5 2  -- Just 3
```

`subtractNumber` names the saturating behavior explicitly, and `addNumber` names addition, so layout code can state which arithmetic it relies on. Errors are values: a negative result is reported as `Nothing`, never as an exception.
