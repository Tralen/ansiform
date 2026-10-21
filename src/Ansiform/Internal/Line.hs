-- | Pure single-line editing state, keys and width-aware windowing.
module Ansiform.Internal.Line (LineState (..), LineKey (..), applyLineKey,
                               visibleLine) where

--------------------------------------------------------------------------------
import           Data.Char (isPrint)
import           Ansiform.Internal.Width (charWidth, textWidth)


-- Line State
--------------------------------------------------------------------------------

-- | An immutable single-line buffer and its cursor.
--   The cursor is a zero-based code-point index.
data LineState = LineState
    { lineText :: String
      -- ^ Current contents of the buffer.
    , lineCursor :: Int
      -- ^ Cursor position as a code-point index into 'lineText'.
    } deriving (Eq, Show)

-- | Editing keys understood by the line editor.
data LineKey
    = LineInsert Char
      -- ^ Insert a printable character at the cursor.
    | LineBackspace
      -- ^ Delete the character before the cursor.
    | LineDelete
      -- ^ Delete the character at the cursor.
    | LineMoveLeft
      -- ^ Move the cursor one code point to the left.
    | LineMoveRight
      -- ^ Move the cursor one code point to the right.
    | LineMoveHome
      -- ^ Move the cursor to the start of the buffer.
    | LineMoveEnd
      -- ^ Move the cursor to the end of the buffer.
    deriving (Eq, Show)


-- Pure Editing
--------------------------------------------------------------------------------

-- | Applies one key to the buffer, returning a new state.
--   Movement stops at the buffer boundaries, deletion at either boundary is a
--   no-op, and non-printable characters are ignored by 'LineInsert'.
applyLineKey :: LineKey -> LineState -> LineState
applyLineKey key (LineState text cursor) = case key of
    LineInsert c
        | isPrint c ->
            let (before, after) = splitAt position text
            in LineState (before ++ (c : after)) (position + 1)
        | otherwise -> LineState text position
    LineBackspace
        | position <= 0 -> LineState text position
        | otherwise ->
            let (before, after) = splitAt position text
            in LineState (init before ++ after) (position - 1)
    LineDelete
        | position >= length text -> LineState text position
        | otherwise ->
            LineState (take position text ++ drop (position + 1) text) position
    LineMoveLeft -> LineState text (max 0 (position - 1))
    LineMoveRight -> LineState text (min (length text) (position + 1))
    LineMoveHome -> LineState text 0
    LineMoveEnd -> LineState text (length text)
  where
    position = max 0 (min (length text) cursor)

-- | Selects the substring and cursor offset that fit in a terminal width.
--   The first argument is the number of columns available to the editor.
--   One column is reserved for the cursor, so a full window leaves the cursor
--   inside the terminal. When the buffer does not fit, the window scrolls so
--   that the cursor stays visible. Widths come from 'charWidth', so wide
--   characters and combining marks keep the cursor aligned.
visibleLine :: Int -> LineState -> (String, Int)
visibleLine width (LineState text cursor) = (window, windowCursor)
  where
    usable = max 1 (width - 1)
    position = max 0 (min (length text) cursor)
    cursorColumn = textWidth (take position text)
    start = windowStart usable cursorColumn text
    afterStart = drop start text
    window = takeWindow usable afterStart
    windowCursor = textWidth (take (position - start) afterStart)

-- Finds the first code point that leaves at most the usable width before the
-- cursor.
windowStart :: Int -> Int -> String -> Int
windowStart usable = go 0
  where
    go index remaining _
        | remaining <= usable = index
    go index remaining (c:cs) =
        go (index + 1) (remaining - charWidth c) cs
    go index _ [] = index

-- Takes code points from the start while they fit in the usable width.
takeWindow :: Int -> String -> String
takeWindow usable = go 0
  where
    go _ [] = []
    go used (c:cs)
        | used + charWidth c > usable = []
        | otherwise = c : go (used + charWidth c) cs
