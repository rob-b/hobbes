module Main where

import System.Environment
import System.Exit
import System.FilePath
import System.FilePath.GlobPattern (GlobPattern, (~~))
import System.IO

import System.FSNotify

import Control.Monad (forever)
import Control.Concurrent (threadDelay)

import Data.Text (pack)
import Data.Bits ((.&.))


main :: IO ()
main = do
  hSetBuffering stdout NoBuffering
  getArgs >>= parse >>= runWatcher

parse ::  [String] -> IO FilePath
parse ["-h"]   = usage >> exitSuccess
parse []       = return "."
parse (path:_) = return path

usage :: IO ()
usage = putStrLn "Usage: hobbes [path]"

runWatcher :: FilePath -> IO ()
runWatcher path =
  let (dir, glob) = splitFileName path
  in withManager $ \m -> do
       watchTree m dir (globModified glob) printPath
       forever $ threadDelay 1000000

globModified :: GlobPattern -> Event -> Bool
globModified glob evt@(Added _ _)    = matchesGlob glob evt
globModified glob evt@(Modified _ _) = matchesGlob glob evt
globModified _ (Removed _ _)     = False

matchesGlob :: GlobPattern -> Event -> Bool
matchesGlob glob = fileMatchesGlob glob . takeFileName . eventPath

printPath :: Event -> IO ()
printPath = putStrLn . eventPath

fileMatchesGlob :: GlobPattern -> FilePath -> Bool
fileMatchesGlob []   _  = True
fileMatchesGlob "."  _  = True
fileMatchesGlob glob fp = fp ~~ glob
