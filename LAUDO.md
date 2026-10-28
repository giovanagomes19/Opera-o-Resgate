# Laudo Técnico — Operação Resgate: Detetives de Bugs

## Objetivo

Este documento registra os problemas identificados no aplicativo, suas causas, as correções realizadas e os testes necessários para verificar o funcionamento.

### Bug 1 — Validação do cadastro

**Arquivo:** `lib/pages/central_page.dart`

**Sintoma:** O cadastro podia continuar mesmo quando um dos campos obrigatórios estava vazio.

**Causa:** A validação utilizava o operador lógico `&&` (E), exigindo que as duas condições fossem verdadeiras para impedir o cadastro.

**Correção:** Substituição de `&&` por `||` (OU), impedindo o cadastro quando qualquer campo obrigatório estiver vazio.

**Teste:** Tentar cadastrar uma ocorrência deixando cada campo obrigatório vazio, um de cada vez, e confirmar que o cadastro é bloqueado.

### Bug 2 — Alteração do estado da ocorrência

**Arquivo:** `lib/pages/central_page.dart`

**Sintoma:** A alteração do estado de resolução da ocorrência podia apresentar um comportamento incorreto.

**Causa:** O callback `onChanged` utilizava `!value`, invertendo o valor recebido pelo componente.

**Correção:** Utilização de `value` diretamente na chamada responsável por alterar o estado.

**Teste:** Alterar o estado de uma ocorrência e verificar se o valor exibido corresponde à ação realizada.

### Bug 3 — Filtro de ocorrências pendentes

**Arquivo:** `lib/pages/central_page.dart`

**Sintoma:** O filtro podia exibir ocorrências com o estado de resolução incorreto.

**Causa:** A condição utilizava `o.resolvido` quando deveria selecionar ocorrências ainda não resolvidas.

**Correção:** Alteração da condição para `!o.resolvido`.

**Teste:** Criar ou consultar ocorrências resolvidas e pendentes e verificar se o filtro exibe somente as pendentes.

### Bug 4 — Navegação para os detalhes

**Arquivo:** `lib/pages/central_page.dart`

**Sintoma:** A abertura dos detalhes de uma ocorrência podia falhar por falta de um parâmetro obrigatório.

**Causa:** A página `DetalhePage` era chamada sem receber a ocorrência selecionada.

**Correção:** Passagem da ocorrência selecionada para o construtor de `DetalhePage`.

**Teste:** Selecionar uma ocorrência e verificar se a página de detalhes abre com as informações correspondentes.

### Bug 5 — Validação do envio de pistas

**Arquivo:** `lib/pages/detalhe_page.dart`

**Sintoma:** O envio de pistas podia ser interrompido mesmo quando o campo estava preenchido.

**Causa:** A condição de validação verificava incorretamente se o texto estava vazio.

**Correção:** Ajuste da condição para impedir o envio quando o campo estiver vazio e permitir o envio de uma pista válida.

**Teste:** Tentar enviar uma pista vazia e, em seguida, uma pista preenchida. Confirmar que a vazia é bloqueada e que a preenchida é enviada.

### Bug 6 — Caminho da subcoleção de pistas

**Arquivo:** `lib/services/central_service.dart`

**Sintoma:** As pistas podiam ser gravadas ou consultadas no caminho incorreto do Firestore.

**Causa:** O caminho da subcoleção não correspondia à estrutura esperada para cada ocorrência.

**Correção:** Utilização do caminho `ocorrencias/{id}/pistas`, associando cada pista à ocorrência correspondente.

**Teste:** Enviar uma pista e conferir no Firestore se ela aparece na subcoleção `pistas` da ocorrência correta.

### Bug 7 — Autorização para alterar o estado

**Arquivo:** `lib/services/central_service.dart`

**Sintoma:** Um usuário que não criou a ocorrência poderia tentar alterar seu estado.

**Causa:** A operação precisava verificar se o usuário autenticado era o autor da ocorrência.

**Correção:** Inclusão de uma verificação do identificador do usuário antes da alteração do estado.

**Teste:** Tentar alterar o estado com a conta autora e com outra conta. Confirmar que somente a conta autorizada consegue realizar a operação.

### Bug 8 — Registro do autor da ocorrência

**Arquivo:** `lib/services/central_service.dart`

**Sintoma:** A ocorrência poderia ser salva sem as informações necessárias para identificar seu autor.

**Causa:** Os dados do usuário autenticado precisavam ser registrados junto à ocorrência.

**Correção:** Inclusão dos campos `autorId` e `autorNome` no registro da ocorrência.

**Teste:** Cadastrar uma ocorrência autenticado e conferir no Firestore se os campos do autor foram preenchidos corretamente.

### Bug 9 — Estado inicial da ocorrência

**Arquivo:** `lib/services/central_service.dart`

**Sintoma:** Uma nova ocorrência poderia ser criada com um estado inadequado.

**Causa:** O registro precisava definir explicitamente o estado inicial de resolução.

**Correção:** Definição de `resolvido: false` no cadastro de novas ocorrências.

**Teste:** Cadastrar uma ocorrência e conferir se ela aparece inicialmente como não resolvida.

### Bug 10 — Data de criação da ocorrência

**Arquivo:** `lib/services/central_service.dart`

**Sintoma:** A ocorrência poderia ficar sem uma data de criação adequada para ordenação e exibição.

**Causa:** O registro precisava armazenar um horário de criação consistente.

**Correção:** Utilização de `FieldValue.serverTimestamp()` para registrar a data pelo servidor do Firestore.

**Teste:** Cadastrar uma ocorrência e verificar se o campo `criadoEm` é preenchido após a gravação.

### Bug 11 — Proteção das operações no Firestore

**Arquivo:** Regras de segurança do Firestore (`firestore.rules`)

**Sintoma:** As operações no banco poderiam não restringir adequadamente quais usuários podem alterar uma ocorrência.

**Causa:** As regras precisam validar a autenticação e a autorização do usuário, independentemente das verificações feitas no aplicativo.

**Correção:** Revisar as regras para permitir alterações de estado somente ao autor autorizado, além de restringir a leitura e a escrita conforme os requisitos da atividade.

**Teste:** Testar as operações com duas contas diferentes e confirmar que as permissões são aplicadas pelo Firestore. Registrar o resultado após executar os testes.

### Bug 12 — Integração e validação geral do aplicativo

**Arquivo:** Projeto Flutter e arquivos de configuração do Firebase.

**Sintoma:** O aplicativo precisava ser verificado após as correções para garantir que os componentes continuassem funcionando em conjunto.

**Causa:** Alterações em validações, navegação, autenticação e banco de dados podem causar erros de integração.

**Correção:** Revisão dos arquivos alterados, resolução dos erros encontrados durante a análise estática e conferência da configuração do Firebase.

**Teste:** Executar `flutter pub get`, `flutter analyze` e `flutter run`. Depois, testar login, cadastro, detalhes, envio de pistas e sincronização entre duas contas. Registrar os resultados reais de cada teste.

---

## Conclusão

As correções foram organizadas para melhorar a validação dos formulários, a navegação entre páginas, o gerenciamento de ocorrências e a integração com o Firebase.

A conclusão da missão depende da execução dos testes funcionais, da verificação das regras de segurança e da confirmação de que duas contas conseguem visualizar os dados compartilhados conforme as permissões definidas.
