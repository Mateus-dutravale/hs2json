# Guia de continuidade do `hs2json`

**Para:** Emerson Muniz  
**Projeto:** avaliação da Unidade 2 — `hs2json`  
**Prazo informado no enunciado:** 21/10/2026  
**Estado conferido:** 13/10/2026

Este documento registra o que já está no repositório e organiza o trabalho restante para atender ao enunciado da avaliação. Ele combina o enunciado compartilhado pela dupla com o [tutorial de Haskell](https://lambdageo.github.io/lambdageo-tutorials/haskell/).

## Resumo do estado

A parte principal da biblioteca está implementada: tipo `JValue`, accessors, módulos de formatação, serialização e configuração Cabal. O bloqueio mais importante para a entrega é que **os testes QuickCheck ainda não foram feitos**. `test/Spec.hs` continua sendo um placeholder, e `QuickCheck` não está listado como dependência do projeto.

Também faltam conectar o pretty printer ao executável de demonstração, completar o README com instruções e link do vídeo, gravar o vídeo e preparar o ZIP final para o SIGAA.

## O que já existe

| Parte | Estado observado no repositório |
|---|---|
| `src/SimpleJSON.hs` | `JValue` e os accessors `getString`, `getInt`, `getDouble`, `getBool`, `getObject`, `getArray` e `isNull` estão definidos. |
| `src/Prettify.hs` | Tipo interno `Doc`, combinadores, `compact`, `pretty`, `fill` e suporte a indentação com `nest`. |
| `src/PrettyJSON.hs` | Conversão de `JValue` para `Doc`, strings escapadas, arrays e objetos formatados. |
| `src/PutJSON.hs` | Serializador que produz `String` diretamente. É separado do pretty printer; evite confundir os dois `renderJValue`, que pertencem a módulos diferentes. |
| `hs2json.cabal` | Componentes `library`, `executable` e `test-suite`; os quatro módulos da biblioteca estão em `exposed-modules`. |
| Histórico Git | Há commits incrementais de implementação. Continue com commits pequenos e descritivos; não junte tudo em um único commit final. |

O `Doc` permanece abstrato: `Prettify` exporta `Doc`, mas não seus construtores. Isso é adequado para a biblioteca. O enunciado pede `Arbitrary JValue`; não exige que os testes construam valores `Doc` diretamente.

## Próximas tarefas — nesta ordem

### 1. Implementar a suíte QuickCheck

Este é o requisito técnico mais urgente. Hoje, `test/Spec.hs` apenas imprime que os testes serão adicionados. O `test-suite` do Cabal lista `base` e `hs2json`, mas não `QuickCheck`.

1. Adicione `QuickCheck` ao `build-depends` da seção `test-suite` em `hs2json.cabal`. Como os testes exigidos ficam em `test/Spec.hs`, não é necessário adicionar QuickCheck à biblioteca, a menos que algum módulo em `src/` passe a importá-lo.
2. Implemente `Arbitrary JValue` em `test/Spec.hs`.
3. Escreva pelo menos cinco propriedades relevantes e faça o processo de teste terminar com código de erro se alguma propriedade falhar. Uma suíte que só imprime resultados pode ser marcada pelo Cabal como aprovada mesmo quando uma propriedade falha.
4. Rode `cabal test` e confira que os testes são realmente executados e passam.

#### Cuidado obrigatório no gerador recursivo

`JArray [JValue]` e `JObject [(String, JValue)]` contêm outros valores `JValue`. Limitar apenas a profundidade com `sized` não limita o tamanho das listas: elas podem crescer em largura e consumir muita memória. Redimensione a geração da lista também, por exemplo aplicando ``resize (n `div` 2)`` ao `listOf` de arrays e objetos, e gere os filhos com um orçamento menor. No caso-base, gere valores simples ou listas vazias.

Esse limite com `resize` é uma exigência explícita do enunciado, independentemente de implementar a cobertura HPC. O [tutorial de QuickCheck](https://lambdageo.github.io/lambdageo-tutorials/haskell/07-quickcheck-intro/) explica geradores e propriedades; o [estudo do pretty printer](https://lambdageo.github.io/lambdageo-tutorials/haskell/08-estudo-caso-pretty-printer/) mostra como organizar a suíte e garantir que falhas façam `cabal test` falhar.

#### Ideias para as cinco propriedades mínimas

Transforme estas ideias em propriedades para valores gerados, não apenas em cinco exemplos fixos:

- Para `JString s`, `getString` devolve `Just s`; para outros construtores, devolve `Nothing`.
- Para objetos `JNumber` criados a partir de inteiros em uma faixa segura, `getInt` devolve o inteiro esperado; outros construtores não são extraídos como inteiro.
- `getDouble` devolve o número guardado em `JNumber`; escolha números finitos para evitar casos especiais como `NaN`.
- `getBool`, `getObject` e `getArray` devolvem o conteúdo correto no construtor correspondente e `Nothing` nos demais.
- `isNull` é verdadeiro para `JNull` e falso para os outros construtores.
- Testes de escape: quebras de linha, tabulações, aspas, barras invertidas, caracteres de controle e Unicode são serializados sem caracteres de controle crus.
- Teste de formatação: estruturas JSON longas quebram linhas e indentam o conteúdo; entradas curtas continuam legíveis.

Há mais ideias do que o mínimo: escolha pelo menos cinco, cobrindo accessors e pretty printer. Registre os resultados no próprio relatório de `cabal test` e não declare a propriedade correta só porque ela passou em alguns exemplos manuais.

### 2. Usar o pretty printer na demonstração do executável

No estado conferido, `app/Main.hs` ainda chama `print` sobre um `JValue`. Isso mostra a representação derivada do tipo Haskell (`JObject [...]`), não o JSON formatado. Para a demonstração do projeto, faça `main` chamar `renderJValue` e `pretty` e imprimir o resultado com `putStrLn`.

Mantenha um exemplo com objeto e array, e inclua conteúdo que demonstre escapes ou quebra de linha. Assim `cabal run hs2json` comprova a funcionalidade principal do projeto.

### 3. Validar os comandos do projeto

No diretório `hs2json`, rode:

```bash
cabal build
cabal test
cabal run hs2json
```

Confira que:

- `cabal build` termina sem erro de compilação;
- `cabal test` executa as propriedades e retorna falha se alguma delas falhar;
- `cabal run hs2json` imprime JSON, não a representação `Show` de `JValue`.

Na última tentativa de build feita no ambiente de assistência, os módulos compilaram e o executável foi ligado, mas o Cabal terminou com erro ao tentar gravar `~/.cabal/logs/build.log` em um sistema de arquivos sem permissão de escrita. Emerson deve repetir os comandos em seu terminal e registrar o resultado. Esse erro de permissão do ambiente não demonstra falha no código do projeto.

### 4. Completar o README e gravar o vídeo

O `README.md` atual contém só o título e uma descrição curta. Inclua:

- objetivo do projeto e integrantes da dupla;
- requisitos de instalação (GHC e Cabal) e comandos `cabal build`, `cabal test` e `cabal run hs2json`;
- resumo dos módulos: `SimpleJSON`, `Prettify`, `PrettyJSON` e `PutJSON`;
- link do vídeo de apresentação, destacado no início do README.

Gravem um vídeo de **10 a 15 minutos**, com os dois integrantes participando e aparecendo. O roteiro exigido no enunciado inclui apresentação da dupla, demonstração dos comandos, arquitetura dos módulos e relato das principais dificuldades e de como foram resolvidas. Hospedem no YouTube (público ou não listado) ou Google Drive com acesso por link; depois substituam no README qualquer marcador temporário pelo link real.

### 5. Revisar Git e entregar no SIGAA

O histórico já tem commits incrementais. Antes da entrega, confirmem no GitHub/GitLab que o repositório se chama exatamente `hs2json`, que as alterações finais estão publicadas e que o histórico não foi reduzido a um único commit. Usem mensagens claras, por exemplo `test: add QuickCheck properties for JValue` e `docs: add setup and presentation instructions`.

Uma pessoa da dupla deve enviar ao SIGAA um ZIP do repositório completo, incluindo `.git`, até **21/10/2026**. Não deixem para validar build, testes, vídeo e permissões do link no dia do prazo.

## O que pode ficar fora

O enunciado não dá pontos separados para o relatório HPC. Portanto, a medição de cobertura de `09-cobertura-hpc` é complementar, a menos que o professor tenha pedido isso em outra instrução. O gerador limitado com `resize`, os testes QuickCheck, a demonstração do pretty printer, o README, o vídeo e o ZIP **não** são opcionais: aparecem no enunciado ou na rubrica.

Também não é necessário copiar literalmente exemplos do tutorial que não correspondam ao projeto, como adicionar `QuickTestes` ou renomear o executável. Adapte os exemplos à estrutura e aos nomes que já estão em `hs2json.cabal`.

## Checklist final da dupla

- [ ] `Arbitrary JValue` limita profundidade **e** largura das listas com `resize`.
- [ ] Há pelo menos cinco propriedades relevantes.
- [ ] Uma propriedade falhando faz `cabal test` falhar.
- [ ] `cabal build`, `cabal test` e `cabal run hs2json` foram executados com sucesso no terminal da dupla.
- [ ] `cabal run hs2json` demonstra o JSON formatado.
- [ ] README tem instruções, módulos, integrantes e link real do vídeo.
- [ ] Vídeo tem 10–15 minutos, os dois integrantes participam e as dificuldades são discutidas.
- [ ] Repositório `hs2json` e histórico incremental estão publicados.
- [ ] ZIP contendo `.git` foi preparado para envio por um integrante no SIGAA.
