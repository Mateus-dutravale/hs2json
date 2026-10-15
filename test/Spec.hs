{-# LANGUAGE TemplateHaskell #-} 
-- trecho usado para habilitar Template Haskell
{-# OPTIONS_GHC -Wno-orphans #-} 
-- trecho usado para suprimir avisos de instâncias orphan pois 

module Main (main) where         
    -- define o módulo principal do programa

import Control.Monad ( unless )  
-- importa a função unless do módulo Control.Monad usada para executar uma ação condicionalmente
import Data.Char ( ord )         
-- importa a função ord do módulo Data.Char usada para obter o código Unicode de um caractere
import System.Exit ( exitFailure ) 
-- importa a função exitFailure do módulo System.Exit usada para encerrar o programa com um código de falha
import Test.QuickCheck            
-- importa o módulo Test.QuickCheck usado para testes automatizados

import Prettify ( compact, pretty, text )   
-- importa as funções compact, pretty e text do módulo Prettify usadas para formatar e imprimir valores JSON
import PrettyJSON ( renderJValue, string ) 
-- importa as funções renderJValue e string do módulo PrettyJSON usadas para renderizar valores JSON e criar strings
import SimpleJSON
    ( JValue(..)
    , getArray
    , getBool
    , getDouble
    , getInt
    , getObject
    , getString
    , isNull
    )   
    -- importa o módulo SimpleJSON que define o tipo de dados JValue e funções auxiliares para manipular valores JSON

instance Arbitrary JValue where
    arbitrary = sized genJValue    
    -- define uma instância Arbitrary para o tipo JValue, permitindo a geração de valores aleatórios para testes, esse JValue pode ser um objeto, array, string, número, booleano ou nulo.

genJValue :: Int -> Gen JValue
genJValue n
    | n <= 0    = base
    | otherwise = frequency [(4, base), (1, recursive)]
  where
    smaller = genJValue (n `div` 2)
    field   = (,) <$> arbitrary <*> smaller
    base = oneof
        [ JString <$> arbitrary
        , JNumber <$> arbitrary
        , JBool   <$> arbitrary
        , pure JNull
        ]
    recursive = oneof
        [ JObject <$> resize (n `div` 2) (listOf field)
        , JArray  <$> resize (n `div` 2) (listOf smaller)
        ]
-- genJValue é uma função que gera valores aleatórios do tipo JValue dependendo do tamanho n fornecido
    -- Se n for menor ou igual a 0, ele gera apenas valores base, ou seja, valores simples como strings, números, booleanos ou nulos.
    -- Se n for maior que 0, ele gera valores base com maior probabilidade (4 vezes mais provável) e valores recursivos (objetos ou arrays) com menor probabilidade

-- Propriedade inicial de sanidade para validar o runner
prop_jnull_is_null :: Bool
prop_jnull_is_null = isNull JNull
-- prop_jnull_is_null é uma propriedade que verifica se o valor JNull é considerado nulo usando a função isNull. JNull é um construtor do tipo JValue que representa o valor nulo em JSON. A função isNull retorna True se o valor for JNull e False caso contrário. 

return []   
-- retorna uma lista vazia, usada para indicar que não há propriedades adicionais a serem testadas
runTests :: IO Bool
runTests = $quickCheckAll

-- runTests é uma função que executa todos os testes definidos no módulo usando a função quickCheckAll do QuickCheck. Ela retorna um valor booleano indicando se todos os testes passaram ou não.

main :: IO ()
main = do
    passed <- runTests
    unless passed exitFailure

    -- primeiro executa os testes definidos no módulo usando a função runTests. O resultado é armazenado na variável passed, que indica se todos os testes passaram ou não.
    -- Em seguida, ele verifica se passed é False usando a função unless. Se passed for False, ele chama a função exitFailure para encerrar o programa com um código de falha. Se passed for True, o programa continua a execução normalmente. 
    -- Então o programa vai executar até todos os testes passarem, caso contrário, ele vai encerrar com um código de falha.