# SO3.3 — Inventário de versionamento da dimensão Infraestrutural

**Estado:** inventário histórico de pendências; os sete scripts INF02 foram versionados em `2e6a1a8` no PR #2; a dimensão permanece aberta até a documentação final.  
**Data de referência:** 01/11/2026.  
**Fontes do inventário:** árvore do GitHub (`main`, PR #2) e saída do `git status --short` local informada pelo executor.  
**Limitação:** os arquivos locais ainda não versionados não foram lidos nem auditados; sua existência foi informada pelo executor. Este documento não atesta completude ou segurança dos conteúdos.

## 1. Critério de conclusão

O encerramento formal da dimensão Infraestrutural depende, cumulativamente, de:

1. Código-fonte e scripts de execução de INF01 e INF02 (E01/E02/E03), com suas dependências declaradas, revisados e versionados.
2. Rotinas e evidências de QA identificadas, com distinção entre testes reexecutáveis, testes exploratórios e resultados de auditoria.
3. Documentação metodológica final integrada, incluindo especificações, unidades, proveniência, alterações por recorte, ressalvas, ausências, limitações e instruções de reprodução.
4. Separação explícita entre código público, referências publicáveis e arquivos restritos ou intermediários.
5. Aprovação final de integridade e reprodutibilidade antes da incorporação definitiva à `main`.

**Bloqueio de fase:** winsorização, Box-Cox, orientação, normalização e agregação do DVI não serão iniciadas antes de concluídos todos os requisitos acima.

## 2. Componentes identificados no GitHub

### 2.1 INF01 — códigos já presentes na `main`

- Leitura: `R/01_leitura/adaptar_censo_2000_infraestrutural.R`, `adaptar_censo_2010_infraestrutural.R`.
- Indicadores: `R/02_indicadores/inf01_agua_rede_canalizada.R`, `inf01_2010_pessoas.R`.
- Diagnóstico: `R/03_diagnostico/validar_inf01.R`, `validar_inf01_2010.R`, `validar_inf01_2022.R`.
- Execução: `R/04_execucao/processar_inf01.R`, `processar_inf01_2010.R`, `processar_inf01_2022.R`.
- Exportação: `R/05_exportacao/exportar_inf01_bruto_csv.R`, `exportar_inf01_2010_bruto_csv.R`, `exportar_inf01_2022_bruto_csv.R`.
- Documentação inicial: `docs/infraestrutural/README.md`.

Os caminhos acima são relativos a `so3.3/`. O `README.md` ainda descreve INF02 como não concluído e precisará ser atualizado **após** a revisão do código local.

### 2.2 Integração proposta no PR #2 (branch de trabalho)

- `so3.3/main.R` — orquestração conjunta INF01/INF02 por ano.
- `so3.3/R/04_execucao/processar_inf02.R` — leitor e verificador dos produtos E03 já promovidos.
- `so3.3/tests/diagnosticar_inf02_e03.R` — inventário somente-leitura do ambiente local.

A validação isolada e integrada dos três recortes foi informada pelo executor; os resultados seguem com a ressalva de **não harmonização territorial**.

## 3. Componentes locais identificados, ainda não versionados

### 3.1 INF02 — 7 arquivos de código (pendência resolvida no PR #2)

1. `so3.3/R/01_leitura/ler_populacao_censitaria_inf02.R`
2. `so3.3/R/04_execucao/processar_inf02_municipalizacao.R`
3. `so3.3/R/04_execucao/processar_inf02_etapa02.R`
4. `so3.3/R/04_execucao/processar_inf02_etapa03.R`
5. `so3.3/executar_inf02_etapa01.R`
6. `so3.3/executar_inf02_etapa02.R`
7. `so3.3/executar_inf02_etapa03.R`

**Atualização:** auditoria estática registrada em `AUDITORIA_ESTATICA_INF02_E01_E03.md` e sete scripts publicados no commit `2e6a1a8`. Permanecem pendentes apenas a documentação final e as ressalvas de proveniência/ambiente; não são necessárias novas revisões dos testes históricos INF01.

### 3.2 INF01/INF02 — 4 documentos locais (prioridade alta)

- `so3.3/docs/infraestrutural/INF01_2010_producao.md`
- `so3.3/docs/infraestrutural/INF01_2022_producao.md`
- `so3.3/docs/infraestrutural/INF02_etapa01_municipalizacao.md`
- `so3.3/docs/infraestrutural/INF02_etapa02_associacao_populacional.md`

**Lacuna identificada:** não consta no inventário local informado um documento independente para a etapa E03. Verificar se a especificação está incorporada ao código/QA e, se não estiver, elaborá-la para a documentação final.

### 3.3 INF01 — 21 arquivos de teste local (prioridade alta para classificação)

Grupo identificado por `so3.3/tests/infra_*.R`: etapas 01–12, 14–19, incluindo 04a, 19b e 19c. A numeração não contínua não deve ser renumerada ou preenchida artificialmente.

**Auditoria necessária:** identificar testes reexecutáveis, diagnósticos exploratórios, referências externas, requisitos de microdados controlados, argumentos e saídas de cada teste. Nem todo teste histórico precisa ser convertido em uma rotina automatizada, mas a rastreabilidade dos resultados aprovados deve ser mantida.

## 4. Itens locais que NÃO devem ser adicionados indiscriminadamente

| Caminho | Orientação |
|---|---|
| `so3.3/inputs/referencias/ibge/populacao_censitaria_inf02/` | Inspecionar natureza, licença, sensibilidade, origem, tamanho e política de versionamento antes de decidir. |
| `so3.3/outputs/bruto/infraestrutural/` | Não executar `git add` em diretório completo; selecionar apenas produtos explicitamente autorizados após auditoria. |
| `so3.2/scripts/concat_so32_annual_statistics.R` | Fora do escopo da dimensão Infraestrutural. |
| `Nota_tecnica_CP1T2_SO32.docx` | Fora do escopo. |
| `so3.3/tests/diagnostico_mortalidade_adulta_2010.R`, `diagnostico_q5_estrela_2022.R`, `teste_m0101_mortalidade_2022.R` | Fluxo Social; tratar em versionamento próprio. |
| `teste_fumaca.R` | Utilitário geral; classificar em revisão independente. |

## 5. Contrato E03 já verificado (integridade local)

| Ano | Referência territorial | Registros município–grupo | Valor disponível | NA |
|---|---:|---:|---:|---:|
| 2000 | 5571 | 16713 | 5493 | 78 |
| 2010 | 5571 | 16713 | 5551 | 20 |
| 2022 | 5571 | 16713 | 5556 | 15 |

- Unidade: `m3/habitante/ano`.
- `tipo_desagregacao = compartilhada` para Total, Masculino e Feminino.
- Cinco códigos reais da E03: `CALCULADO_SEM_HARMONIZACAO_TERRITORIAL`, `DIVISAO_TERRITORIAL_ALTERADA_2025`, `Q_NEGATIVA_NAO_INTERPRETAVEL`, `SEM_CONTRIBUICAO_ESTIMADA` e `SEM_POPULACAO_CENSITARIA`.
- Os dados estão associados à referência territorial de 2025; isso **não** estabelece comparabilidade territorial automática com as bases censitárias de 2000, 2010 e 2022.
- A verificação computacional não equivale a validação hidrológica independente.

## 6. Próximo procedimento

Obter cópias **somente dos arquivos locais de código, teste e documentação** indicados nas seções 3.1–3.3 para revisão técnica. Não solicitar nem publicar microdados, diretórios `inputs/` ou `outputs/`. Após a revisão, definir um plano de `git add` **seletivo** em branch de trabalho, validar o diff e, por fim, finalizar a documentação da dimensão.

Não usar `git add .`, `git add -A` nem mudar de branch sem verificar o efeito sobre arquivos locais não rastreados.
