module Ansiform.Internal.Sample where

--------------------------------------------------------------------------------

-- Sample Class
--------------------------------------------------------------------------------
class Sample a where
  sample :: a -> IO ()
  sample x = putStrLn $ sampleShow 0 x

  sampleShow :: Int -> a -> String

sampleFormat :: Sample a => String -> Int -> a -> String
sampleFormat s n c = s ++ "\n" ++ sampleShow n c


-- Basic Instances
--------------------------------------------------------------------------------

instance (Sample a, Show a) => Sample (Maybe a) where
  sampleShow _ Nothing = "Nothing"
  sampleShow _ (Just a) = "Just " ++ sampleShow 0 a

instance Sample a => Sample [a] where
  sample xs = putStrLn $ sampleShow (-1) xs
  sampleShow n xs | n < 0 = showCList 0 | otherwise = showCList (n+2)
                where showCList n' = showContentList (zip xs [0..]) n'

-- Support function to assist in showing list of content types.
showContentList :: Sample a => [(a,Int)] -> Int -> String
showContentList [] _ = ""
showContentList ((i,0):is) n = showSpaces n ++ sampleShow n i ++ showContentList is n
showContentList ((i,_):is) n = "\n" ++ showSpaces n ++ sampleShow n i ++ showContentList is n

showSpaces :: Int -> String
showSpaces n = replicate n ' '
