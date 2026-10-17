-- | Immediate single-key input for interactive interfaces.
module Ansiform.Internal.Input (withImmediateInput, readKey) where

--------------------------------------------------------------------------------
import           Control.Exception (bracket_)
import           Control.Monad (when)
import           System.IO (BufferMode (..), hGetBuffering, hGetEcho,
                            hIsTerminalDevice, hSetBuffering, hSetEcho,
                            isEOF, stdin)


-- Terminal Input
--------------------------------------------------------------------------------

-- | Runs an action with stdin configured for immediate single-key input.
--   Buffering and echo are changed only when stdin is a terminal,
--   and the original settings are restored when the action finishes.
withImmediateInput :: IO a -> IO a
withImmediateInput action = do
    interactive <- hIsTerminalDevice stdin
    oldBuffering <- hGetBuffering stdin
    oldEcho <- if interactive then hGetEcho stdin else return True
    let setup = when interactive $ do
                    hSetBuffering stdin NoBuffering
                    hSetEcho stdin False
        restore = when interactive $ do
                    hSetBuffering stdin oldBuffering
                    hSetEcho stdin oldEcho
    bracket_ setup restore action

-- | Reads one key without waiting for Enter.
--   Returns 'Nothing' at end of input.
readKey :: IO (Maybe Char)
readKey = do
    eof <- isEOF
    if eof then return Nothing else Just <$> getChar
