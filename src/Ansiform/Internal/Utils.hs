module Ansiform.Internal.Utils where

--------------------------------------------------------------------------------
import qualified Data.List as List
import           Data.Maybe (fromMaybe)


-- Numbers
--------------------------------------------------------------------------------
-- Version of maximum that takes a default, so it doesn't fail.
maximum' :: Ord a => a -> [a] -> a
maximum' = foldr max

-- Version of minimum that takes a default, so it doesn't fail.
minimum' :: Ord a => a -> [a] -> a
minimum' = foldr min

-- Calculates the average value from a list of Ints.
average :: [Int] -> Int
average xs = case xs of [] -> 0; _ -> div (sum xs) (length xs)


-- Lists
--------------------------------------------------------------------------------
-- Version of head that returns a maybe.
headMaybe :: [a] -> Maybe a
headMaybe [] = Nothing
headMaybe (x:_) = Just x

-- Version of indexing that returns a maybe.
atMay :: [a] -> Int -> Maybe a
atMay xs n
    | n < 0 = Nothing
    | otherwise = headMaybe (drop n xs)

-- Version of head that takes a default.
head' :: a -> [a] -> a
head' d [] = d
head' _ (x:_) = x

-- Version of last that returns a maybe. Still doesn't work for infinite lists.
lastMaybe :: [a] -> Maybe a
lastMaybe [] = Nothing
lastMaybe (x:xs) = Just (last' x xs)

-- Version of last that takes a default.
last' :: a -> [a] -> a
last' d [] = d
last' _ (x:xs) = last' x xs


-- Reverses and concats a list simultaneously, used to avoid appending.
concatRev :: [[a]] -> [a]
concatRev = foldr (flip (++)) []

concatRev' :: [[a]] -> [a]
concatRev' = List.foldl' (flip (++)) []


-- Checks if a List has at least a given number of items or more.
atLeastLength :: Int -> [a] -> Bool
atLeastLength n = not . null . drop (n-1)

-- Checks if a List has exactly a given number of items.
--    Doesn't run the rest of the list if it fails.
exactLength :: Int -> [a] -> Bool
exactLength n as
        | n < 0 = False
        | n == 0 = null as
        | otherwise = lengthTest 0 as
      where  
        lengthTest c as'
            | null as' = c == n
            | c > n = False
            | otherwise = lengthTest (c+1) (drop 1 as')

-- Inserts an element in a list at a given index.
insertAt :: Int -> a -> [a] -> [a]
insertAt n e es = take n es ++ [e] ++ drop n es

-- GroupsBy using any binary operation, not only equality. (Brandon Simmons)
groupBy' :: (a -> a -> Bool) -> [a] -> [[a]]
groupBy' _ [] = []
groupBy' c (a:as) = (a:ys) : groupBy' c zs
    where (ys,zs) = spanC a as
          spanC _ [] = ([], [])
          spanC a' (x:xs)
            | a' `c` x = let (ps,qs) = spanC x xs
                          in (x:ps,qs)
            | otherwise = ([], x:xs)

-- Function to find the point to split a list of Ints 
--    when their sum overflows an Int threshold.
splitPoint :: [Int] -> Int -> Int
splitPoint wl w = sumTest 0 0 wl
        where
          sumTest s i cs
               | curSum <= w && not (null cs) = sumTest curSum (i + 1) (drop 1 cs)
               | otherwise = i
            where c = fromMaybe 0 $ headMaybe cs
                  curSum = s + c

-- Monads
--------------------------------------------------------------------------------

-- Shorthand for returning unit.
return_ :: Monad m => m ()
return_ = return ()
