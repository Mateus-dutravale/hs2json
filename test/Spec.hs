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

-- Aqui estão algumas propriedades adicionais para testar as funções de extração de valores do tipo JValue:

prop_getString :: String -> Bool
prop_getString s = getString (JString s) == Just s
-- prop_getString é uma propriedade que verifica se a função getString retorna o valor correto quando aplicada a um JValue do tipo JString. Ela recebe uma string s como entrada e cria um JValue usando o construtor JString. Em seguida, ela chama a função getString com esse JValue e compara o resultado com Just s, que é o valor esperado. Se a função getString funcionar corretamente, a propriedade deve retornar True.

prop_getInt :: Int -> Bool
prop_getInt n = getInt (JNumber (fromIntegral n)) == Just n
-- prop_getInt é uma propriedade que verifica se a função getInt retorna o valor correto quando aplicada a um JValue do tipo JNumber. Ela recebe um inteiro n como entrada e cria um JValue usando o construtor JNumber, convertendo n para Double usando fromIntegral. Em seguida, ela chama a função getInt com esse JValue e compara o resultado com Just n, que é o valor esperado. Se a função getInt funcionar corretamente, a propriedade deve retornar True.

prop_getDouble :: Double -> Bool
prop_getDouble d = getDouble (JNumber d) == Just d
-- prop_getDouble é uma propriedade que verifica se a função getDouble retorna o valor correto quando aplicada a um JValue do tipo JNumber. Ela recebe um número de ponto flutuante d como entrada e cria um JValue usando o construtor JNumber. Em seguida, ela chama a função getDouble com esse JValue e compara o resultado com Just d, que é o valor esperado. Se a função getDouble funcionar corretamente, a propriedade deve retornar True.

prop_getBool :: Bool -> Bool
prop_getBool b = getBool (JBool b) == Just b
-- prop_getBool é uma propriedade que verifica se a função getBool retorna o valor correto quando aplicada a um JValue do tipo JBool. Ela recebe um valor booleano b como entrada e cria um JValue usando o construtor JBool. Em seguida, ela chama a função getBool com esse JValue e compara o resultado com Just b, que é o valor esperado. Se a função getBool funcionar corretamente, a propriedade deve retornar True.

prop_isNull :: JValue -> Bool
prop_isNull v = case v of
    JNull -> isNull v
    _     -> not (isNull v)
-- prop_isNull é uma propriedade que verifica se a função isNull retorna o valor correto quando aplicada a um JValue do tipo JNull. Ela recebe um JValue v como entrada e usa pattern matching para verificar se v é do tipo JNull. Se for, ela chama a função isNull com v e compara o resultado com True. Se não for, ela compara o resultado com False. Se a função isNull funcionar corretamente, a propriedade deve retornar True.

prop_getObject :: String -> JValue -> Bool
prop_getObject k v = getObject (JObject [(k, v)]) == Just [(k, v)]
-- prop_getObject é uma propriedade que verifica se a função getObject retorna o valor correto quando aplicada a um JValue do tipo JObject. Ela recebe uma string k e um JValue v como entrada e cria um JValue usando o construtor JObject, que contém uma lista de pares chave-valor com apenas um elemento (k, v). Em seguida, ela chama a função getObject com esse JValue e compara o resultado com Just [(k, v)], que é o valor esperado. Se a função getObject funcionar corretamente, a propriedade deve retornar True.

prop_getArray :: JValue -> Bool
prop_getArray v = getArray (JArray [v]) == Just [v]
-- prop_getArray é uma propriedade que verifica se a função getArray retorna o valor correto quando aplicada a um JValue do tipo JArray. Ela recebe um JValue v como entrada e cria um JValue usando o construtor JArray, que contém uma lista com apenas um elemento v. Em seguida, ela chama a função getArray com esse JValue e compara o resultado com Just [v], que é o valor esperado. Se a função getArray funcionar corretamente, a propriedade deve retornar True.


prop_accessors_exclusivity :: JValue -> Bool
prop_accessors_exclusivity v = case v of
    JString s -> getString v == Just s && getInt v == Nothing    && getObject v == Nothing
    JNumber d -> getDouble v == Just d && getString v == Nothing && getArray v == Nothing
    JBool b   -> getBool v == Just b   && getString v == Nothing && getDouble v == Nothing
    JNull     -> isNull v              && getString v == Nothing && getBool v == Nothing
    JObject o -> getObject v == Just o && getArray v == Nothing  && getString v == Nothing
    JArray a  -> getArray v == Just a  && getObject v == Nothing && getBool v == Nothing

-- prop_accessors_exclusivity é uma propriedade que verifica se as funções de extração de valores do tipo JValue são mutuamente exclusivas. Ela recebe um JValue v como entrada e usa pattern matching para verificar o tipo de v. Para cada tipo, ela chama a função correspondente e compara o resultado com o valor esperado, enquanto garante que as outras funções retornem Nothing. Se todas as funções funcionarem corretamente, a propriedade deve retornar True.


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