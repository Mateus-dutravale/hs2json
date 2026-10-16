# hs2json — Biblioteca de Serialização e Pretty Printing JSON em Haskell

🎥 **Vídeo de Apresentação (10–15 min):** [ Assistir à apresentação da dupla (LINK AQUI) ](#)

## Sobre o Projeto
Projeto desenvolvido para a Avaliação da Unidade 2 da disciplina de Programação Funcional. O `hs2json` implementa uma representação algébrica de dados JSON em Haskell, combinadores de *pretty printing* baseados em álgebra de documentos (`Doc`) e uma suíte de testes baseada em propriedades utilizando `QuickCheck`.

### Integrantes da Dupla
- **Emerson Paulo Pinheiro Muniz**
- **Mateus Dutra Vale**

## Arquitetura dos Módulos (`src/`)
- **`SimpleJSON`**: Define o tipo algébrico `JValue` (`JString`, `JNumber`, `JBool`, `JNull`, `JObject`, `JArray`) e funções seguras de extração (*accessors*) utilizando `Maybe` (`getString`, `getInt`, `getDouble`, `getBool`, `getObject`, `getArray`, `isNull`).
- **`Prettify`**: Implementa o tipo abstrato `Doc` e combinadores algébricos de layout (`<>`, `</>`, `hcat`, `fsep`, `punctuate`, `group`, `nest`, `softline`), além dos renderizadores `compact` e `pretty`.
- **`PrettyJSON`**: Converte valores `JValue` em documentos `Doc`, tratando escapes de caracteres especiais, caracteres de controle e pontos de código Unicode (incluindo pares substitutos UTF-16).
- **`PutJSON`**: Serializador direto de `JValue` para `String` e impressão no terminal.

## Pré-requisitos
- **GHC** (Glasgow Haskell Compiler) >= 9.x
- **Cabal** (`cabal-install`) >= 3.0

## Como Compilar, Testar e Executar

1. **Compilar o projeto:**
   ```bash
   cabal build

2. **Executar a suíte de testes QuickCheck:**
    ```Bash
    cabal test
    ```

(Opcional) Gerar relatório de cobertura com HPC:

    ```Bash
    cabal test --enable-coverage
    ```

3. **Executar a demonstração do Pretty Printer:**

    ```Bash

    cabal run hs2json
    
    ```
