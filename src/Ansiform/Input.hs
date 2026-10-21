-- | Immediate single-key input and line input for interactive interfaces.
module Ansiform.Input
    ( withImmediateInput
    , readKey
    , readKeyPress
    , withLineInput
    , readLine
    , readLineAt
    , readLineAtOn
    , Prompt
    , promptAt
    , promptWithInitial
    , promptSection
    , promptRow
    , promptColumn
    , promptInitial
    , FormError (..)
    , readForm
    , readFormOn
    ) where

--------------------------------------------------------------------------------
import Ansiform.Internal.Input
