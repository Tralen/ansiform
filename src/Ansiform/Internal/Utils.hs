module Ansiform.Internal.Utils where

--------------------------------------------------------------------------------
import Data.Maybe (fromMaybe)

-- Numbers
--------------------------------------------------------------------------------
-- Version of maximum that takes a default, so it doesn't fail.
maximum' :: (Ord a) => a -> [a] -> a
maximum' = foldr max

-- Calculates the average value from a list of Ints.
average :: [Int] -> Int
average xs = case xs of [] -> 0; _ -> div (sum xs) (length xs)

-- Lists
--------------------------------------------------------------------------------
-- Version of head that returns a maybe.
headMaybe :: [a] -> Maybe a
headMaybe [] = Nothing
headMaybe (x : _) = Just x

-- Version of indexing that returns a maybe.
atMay :: [a] -> Int -> Maybe a
atMay xs n
    | n < 0 = Nothing
    | otherwise = headMaybe (drop n xs)

-- Version of head that takes a default.
head' :: a -> [a] -> a
head' d [] = d
head' _ (x : _) = x

-- Version of last that returns a maybe. Still doesn't work for infinite lists.
lastMaybe :: [a] -> Maybe a
lastMaybe [] = Nothing
lastMaybe (x : xs) = Just (last' x xs)

-- Version of last that takes a default.
last' :: a -> [a] -> a
last' d [] = d
last' _ (x : xs) = last' x xs

-- Reverses and concats a list simultaneously, used to avoid appending.
concatRev :: [[a]] -> [a]
concatRev = foldr (flip (++)) []

-- Function to find the point to split a list of Ints
--    when their sum overflows an Int threshold.
splitPoint :: [Int] -> Int -> Int
splitPoint wl w = sumTest 0 0 wl
  where
    sumTest s i cs
        | curSum <= w && not (null cs) = sumTest curSum (i + 1) (drop 1 cs)
        | otherwise = i
      where
        c = fromMaybe 0 $ headMaybe cs
        curSum = s + c

-- Monads
--------------------------------------------------------------------------------

-- Shorthand for returning unit.
return_ :: (Monad m) => m ()
return_ = return ()
