module Ansiform.Internal.Settings where

--------------------------------------------------------------------------------
import qualified Data.List as List
import           System.Environment (lookupEnv)
import           System.IO (Handle, hIsTerminalDevice, stdout)
import           Ansiform.Internal.Number
import           Ansiform.Internal.Sample
import           Ansiform.Internal.Terminal


-- Config type
--------------------------------------------------------------------------------

-- | A list of configuration modifiers.
newtype Settings = Settings [Config -> Config]

instance Sample Settings where
    sample vs = sample =<< runSettings vs
    sampleShow _ (Settings _) = ""

formSettings :: [Config -> Config] -> Settings
formSettings = Settings

unSettings :: Settings -> [Config -> Config]
unSettings (Settings fs) = fs


-- Function to build the settings in a declarative style.
runSettings :: Settings -> IO Config
runSettings = runSettingsOn stdout

-- Function to build the settings for a given output handle.
runSettingsOn :: Handle -> Settings -> IO Config
runSettingsOn h stgs = initialConfigOn h >>= \dft ->
                  resolveColorsOn h $ List.foldl' (\sets f -> f sets) dft $ unSettings stgs

-- Settings type
--------------------------------------------------------------------------------

-- | Controls whether ANSI style sequences are written to the terminal.
data ColorMode
    = ColorAuto    -- ^ Detect from the environment and from stdout.
    | ColorAlways  -- ^ Always emit ANSI styling.
    | ColorNever   -- ^ Never emit ANSI styling.
    deriving (Eq, Show)

instance Sample ColorMode where
    sampleShow _ ColorAuto = "Auto"
    sampleShow _ ColorAlways = "Always"
    sampleShow _ ColorNever = "Never"

-- | The resolved configuration used by the printers.
newtype Config = Config 
            ( Width       -- Current screen width
            , Width       -- Minimum space to be used bettwen blocks.
            , Number      -- Percentage that groups are allowed to overflow.
            , ColorMode   -- Whether ANSI styles are enabled.
            ) deriving (Eq, Show)

instance Sample Config where
    sampleShow _ (Config (w,m,g,c)) = "Settings"
                               ++ "\n  Screen Width: " ++ show w
                               ++ "\n  Minimum Space: " ++ show m
                               ++ "\n  Group Overflow: " ++ show g ++ "%"
                               ++ "\n  Color Mode: " ++ sampleShow 0 c

-- Wrapper
formConfig :: Width -> Width -> Number -> ColorMode -> Config
formConfig w m g c = Config (w, m, g, c)


-- Unwrappers
unConfig :: Config -> (Width, Width, Number, ColorMode)
unConfig (Config s) = s

unWidth :: Config -> Width
unWidth (Config (w,_,_,_)) = w

unMinSpace :: Config -> Width
unMinSpace (Config (_,m,_,_)) = m

unGroupOverflow :: Config -> Number
unGroupOverflow (Config (_,_,g,_)) = g

unColorMode :: Config -> ColorMode
unColorMode (Config (_,_,_,c)) = c

-- Reports whether ANSI style sequences should be emitted.
--   Only an explicitly resolved 'ColorAlways' enables them.
colorsEnabled :: Config -> Bool
colorsEnabled v = unColorMode v == ColorAlways


-- Generates the base settings to be configured.
initialConfig :: IO Config
initialConfig = initialConfigOn stdout

-- Generates the base settings for a given output handle.
initialConfigOn :: Handle -> IO Config
initialConfigOn h = termWOn h >>= \w -> resolveColorsOn h $ formConfig (formNumber w) 2 25 ColorAuto

-- Replaces 'ColorAuto' with the mode supported by the current output.
resolveColors :: Config -> IO Config
resolveColors = resolveColorsOn stdout

-- Replaces 'ColorAuto' with the mode supported by the given handle.
resolveColorsOn :: Handle -> Config -> IO Config
resolveColorsOn h v = case unColorMode v of
                    ColorAuto -> do
                        supported <- colorsSupportedOn h
                        return $ setColorMode (if supported then ColorAlways else ColorNever) v
                    _ -> return v

-- Checks whether the given output can safely receive ANSI styles.
colorsSupported :: IO Bool
colorsSupported = colorsSupportedOn stdout

-- Checks whether a handle can safely receive ANSI styles.
colorsSupportedOn :: Handle -> IO Bool
colorsSupportedOn h = do
    noColor <- lookupEnv "NO_COLOR"
    term <- lookupEnv "TERM"
    terminal <- hIsTerminalDevice h
    return $ terminal
          && not (maybe False (not . null) noColor)
          && term /= Just "dumb"

-- Support Functions
--------------------------------------------------------------------------------

-- Maximum allowed for groups to exceed the average length, 
--    Converts the percentage to the divisor.
groupOverflowRatio :: Number -> Int
groupOverflowRatio n | n <= 0 = 0 | n >= 100 = 1 | otherwise = div 100 (unn n)


setWidth :: Width -> Config -> Config
setWidth n (Config (_,m,g,c)) = formConfig n m g c

setMinSpace :: Width -> Config -> Config
setMinSpace n (Config (w,_,g,c)) = formConfig w n g c

setGroupOverflow :: Number -> Config -> Config
setGroupOverflow n (Config (w,m,_,c)) = formConfig w m n c

setColorMode :: ColorMode -> Config -> Config
setColorMode n (Config (w,m,g,_)) = formConfig w m g n



