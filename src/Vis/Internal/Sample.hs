module Vis.Internal.Sample where

--------------------------------------------------------------------------------
import           Vis.Internal.Utils

class VisSample a where
  sample :: a -> IO ()
  show' :: Int -> a -> String

instance VisSample a => VisSample [a] where
  sample [] = return_
  sample xs = putStrLn $ show' 0 xs

  show' n xs = showContentList (zip xs [0..]) n

-- Support function to assist in showing list of content types.
showContentList :: VisSample a => [(a,Int)] -> Int -> String
showContentList [] _ = ""
showContentList ((i,0):is) n = showSpaces n ++ show' n i ++ showContentList is n
showContentList ((i,_):is) n = "\n" ++ showSpaces n ++ show' n i ++ showContentList is n

showSpaces n = replicate n ' '
