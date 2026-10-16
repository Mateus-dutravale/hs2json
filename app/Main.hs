module Main (main) where

import Prettify ( pretty )
import PrettyJSON ( renderJValue )
import SimpleJSON ( JValue(..) )

sampleJSON :: JValue
sampleJSON = JObject
    [ ("projeto", JString "hs2json")
    , ("versao", JNumber 1.0)
    , ("ativo", JBool True)
    , ("erros", JNull)
    , ("mensagem", JString "Linha 1\nLinha 2\tCom tab e aspas: \"ok\"")
    , ("integrantes", JArray
        [ JString "Emerson Muniz"
        , JString "Mateus Dutra"
        ])
    , ("metricas", JObject
        [ ("testesQuickCheck", JNumber 12)
        , ("cobertura", JString "alta")
        ])
    ]

main :: IO ()
main = do
    putStrLn "=== JSON Formatado (largura 40) ==="
    putStrLn (pretty 40 (renderJValue sampleJSON))
    putStrLn "\n=== JSON Formatado (largura 80) ==="
    putStrLn (pretty 80 (renderJValue sampleJSON))


