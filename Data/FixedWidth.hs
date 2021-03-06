module Data.FixedWidth where

import Control.Applicative
import Control.Monad
import Data.Attoparsec.Text as StrictText
import Data.Attoparsec.Text.Lazy as LazyText
import qualified Data.ByteString.Lazy.Char8 as BL
import qualified Data.Text as T
import qualified Data.Text.Lazy as TL
import Data.Text.Lazy.Encoding (decodeUtf8)

fileToLazyText :: String -> IO TL.Text
fileToLazyText filename = fmap decodeUtf8 $ BL.readFile filename

strictLine :: Parser T.Text
strictLine = (StrictText.takeTill isEndOfLine) <* endOfLine

withFile :: String -> (Parser a) -> (a -> IO ()) -> IO ()
withFile filename parser action = do
  text <- fileToLazyText filename
  let loop rest = if (TL.null rest)
                  then return ()
                  else
                    case (LazyText.parse parser rest) of
                    LazyText.Done rest' a -> (action a >> loop rest')
                    _ -> error "failed parse"
  loop text

lineIterator :: Parser a -> IO () -> (a -> IO ()) -> T.Text -> IO ()
lineIterator parser fail succeed text =
  case (parseOnly parser text) of
    Left _ -> fail
    Right a -> succeed a
