-- | Convert JSON values into documents that can be laid out by 'Prettify'.
module PrettyJSON
    ( renderJValue
    , string
    ) where

import Prelude hiding ((<>))

import Data.Bits (shiftR, (.&.))
import Data.Char (ord)
import Numeric (showHex)

import Prettify
    ( Doc, (<>), char, double, enclose, fsep, group, hcat, nest
    , punctuate, softline, text
    )
import SimpleJSON (JValue(..))

renderJValue :: JValue -> Doc
renderJValue (JBool True)  = text "true"
renderJValue (JBool False) = text "false"
renderJValue JNull         = text "null"
renderJValue (JNumber n)   = double n
renderJValue (JString s)   = string s
renderJValue (JArray xs)   = series '[' ']' renderJValue xs
renderJValue (JObject xs)  = series '{' '}' field xs
  where
    field (name, value) = string name <> text ": " <> renderJValue value

string :: String -> Doc
string = enclose '"' '"' . hcat . map oneChar

oneChar :: Char -> Doc
oneChar c = case lookup c simpleEscapes of
    Just escaped -> text escaped
    Nothing
        | mustEscape c -> hexEscape c
        | otherwise    -> char c
  where
    mustEscape ch = ch < ' ' || ch == '\x7f' || ch > '\xff'

simpleEscapes :: [(Char, String)]
simpleEscapes = zipWith escape "\b\n\f\r\t\\\"/" "bnfrt\\\"/"
  where
    escape source target = (source, ['\\', target])

smallHex :: Int -> Doc
smallHex n = text "\\u" <> text (replicate (4 - length digits) '0') <> text digits
  where
    digits = showHex n ""

astral :: Int -> Doc
astral n = smallHex (high + 0xd800) <> smallHex (low + 0xdc00)
  where
    high = (n `shiftR` 10) .&. 0x3ff
    low  = n .&. 0x3ff

hexEscape :: Char -> Doc
hexEscape c
    | codePoint < 0x10000 = smallHex codePoint
    | otherwise           = astral (codePoint - 0x10000)
  where
    codePoint = ord c

series :: Char -> Char -> (a -> Doc) -> [a] -> Doc
series open close _ [] = char open <> char close
series open close item values =
    group (char open
        <> nest 2 (softline <> contents)
        <> softline
        <> char close)
  where
    contents = fsep (punctuate (char ',') (map item values))
