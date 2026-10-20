-- | A small document algebra for composing and laying out text.
module Prettify
    ( Doc
    , empty
    , char
    , text
    , double
    , line
    , (<>)
    , (</>)
    , hcat
    , fcat
    , fsep
    , punctuate
    , enclose
    , group
    , softline
    , fill
    , nest
    , compact
    , pretty
    ) where

import Prelude hiding ((<>))

data Doc
    = Empty
    | Chr Char
    | Txt String
    | Line
    | Concat Doc Doc
    | Union Doc Doc
    | Nest Int Doc
    deriving (Eq, Show)

infixr 6 <>
(<>) :: Doc -> Doc -> Doc
Empty <> y = y
x <> Empty = x
x <> y     = Concat x y

infixr 5 </>
(</>) :: Doc -> Doc -> Doc
x </> y = x <> softline <> y

empty :: Doc
empty = Empty

char :: Char -> Doc
char '\n' = line
char c    = Chr c

text :: String -> Doc
text "" = Empty
text s  = Txt s

double :: Double -> Doc
double = text . show

line :: Doc
line = Line

group :: Doc -> Doc
group doc = flatten doc `Union` doc

softline :: Doc
softline = group line

fill :: Int -> Doc -> Doc
fill width doc = doc <> text (replicate padding ' ')
  where
    padding = max 0 (width - length (compact doc))

nest :: Int -> Doc -> Doc
nest amount doc = Nest (max 0 amount) doc

flatten :: Doc -> Doc
flatten (Concat x y) = Concat (flatten x) (flatten y)
flatten (Nest amount doc) = Nest amount (flatten doc)
flatten Line         = Chr ' '
flatten (Union x _)  = flatten x
flatten other        = other

hcat :: [Doc] -> Doc
hcat = foldDocs (<>)

fcat :: [Doc] -> Doc
fcat = foldDocs (</>)

fsep :: [Doc] -> Doc
fsep = foldDocs (</>)

foldDocs :: (Doc -> Doc -> Doc) -> [Doc] -> Doc
foldDocs combine = foldr combine empty

punctuate :: Doc -> [Doc] -> [Doc]
punctuate _ []     = []
punctuate _ [doc]  = [doc]
punctuate p (d:ds) = (d <> p) : punctuate p ds

enclose :: Char -> Char -> Doc -> Doc
enclose left right doc = char left <> doc <> char right

compact :: Doc -> String
compact doc = render [(0, doc)]
  where
    render [] = ""
    render ((currentIndent, current):docs) = case current of
        Empty       -> render docs
        Chr c       -> c : render docs
        Txt s       -> s ++ render docs
        Line        -> '\n' : replicate currentIndent ' '
                           ++ render docs
        Concat x y  -> render ((currentIndent, x) : (currentIndent, y) : docs)
        Union x _   -> render ((currentIndent, x) : docs)
        Nest amount nested -> render ((currentIndent + amount, nested) : docs)


pretty :: Int -> Doc -> String
pretty width doc = best 0 [(0, doc)]
  where
    best _ [] = ""
    best column ((indentation, current):docs) = case current of
        Empty      -> best column docs
        Chr c      -> c : best (column + 1) docs
        Txt s      -> s ++ best (column + length s) docs
        Line       -> '\n' : replicate indentation ' '
                           ++ best indentation docs
        Concat x y -> best column ((indentation, x) : (indentation, y) : docs)
        Union x y  -> nicest column (best column ((indentation, x) : docs))
                                    (best column ((indentation, y) : docs))
        Nest amount nested -> best column ((indentation + amount, nested) : docs)

    nicest column first second
        | fits (width - column) first = first
        | otherwise                   = second

    fits remaining _ | remaining < 0 = False
    fits _ ""        = True
    fits _ ('\n':_)  = True
    fits remaining (_:cs) = fits (remaining - 1) cs