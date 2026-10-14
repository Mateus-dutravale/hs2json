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

softline :: Doc
softline = group line

group :: Doc -> Doc
group doc = flatten doc `Union` doc

flatten :: Doc -> Doc
flatten (Concat x y) = Concat (flatten x) (flatten y)
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
compact = render . (: [])
  where
    render [] = ""
    render (doc:docs) = case doc of
        Empty       -> render docs
        Chr c       -> c : render docs
        Txt s       -> s ++ render docs
        Line        -> '\n' : render docs
        Concat x y  -> render (x : y : docs)
        Union x _   -> render (x : docs)


pretty :: Int -> Doc -> String
pretty width = compact . best 0 . (: [])
  where
    best _ [] = Empty
    best column (doc:docs) = case doc of
        Empty      -> best column docs
        Chr c      -> Chr c <> best (column + 1) docs
        Txt s      -> Txt s <> best (column + length s) docs
        Line       -> Line <> best 0 docs
        Concat x y -> best column (x : y : docs)
        Union x y  -> nicest column (best column (x : docs))
                                      (best column (y : docs))

    nicest column first second
        | fits (width - column) first = first
        | otherwise                  = second

    fits remaining _ | remaining < 0 = False
    fits _ Empty = True
    fits remaining (Chr _) = fits (remaining - 1) Empty
    fits remaining (Txt s) = fits (remaining - length s) Empty
    fits _ Line = True
    fits remaining (Concat x y) = fits remaining x && fits remaining y
    fits remaining (Union x _) = fits remaining x
