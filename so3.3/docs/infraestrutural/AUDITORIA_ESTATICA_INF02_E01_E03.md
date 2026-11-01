# INF02 — Auditoria estática dos scripts E01 → E02 → E03

**Projeto:** PRAIS4 / SO3.3 / Dimensão Infraestrutural  
**Data:** 2026-11-01  
**Estado:** auditoria preliminar para versionamento; **não substitui a documentação metodológica final**.  
**Escopo:** sete arquivos R fornecidos em `INF02_codigos_revisao.tar.gz`. Análise de conteúdo e fluxo; sem executar R ou acessar os insumos geoespaciais neste ambiente. O executor já informou validação isolada e integrada do indicador para 2000, 2010 e 2022 em sua máquina.

## 1. Cadeia operacional confirmada

| Fase | Script de execução | Processador/leitor | Produto |
| --- | --- | --- | --- |
| E01 | `so3.3/executar_inf02_etapa01.R` | `R/04_execucao/processar_inf02_municipalizacao.R` | Contribuição incremental superficial ANA/BHO 50K redistribuída pela malha IBGE 2025, municípios e áreas operacionais separadas; QA nacional e UF. |
| E02 | `so3.3/executar_inf02_etapa02.R` | `R/04_execucao/processar_inf02_etapa02.R` + `R/01_leitura/ler_populacao_censitaria_inf02.R` | População total censitária SIDRA associada **nominalmente por código**, com avisos de incompatibilidade territorial. |
| E03 | `so3.3/executar_inf02_etapa03.R` | `R/04_execucao/processar_inf02_etapa03.R` | `Q_incremental_parcial (m³/s) × 31.536.000 / população_total_censo`, em m³/habitante/ano; valores e QA; promoção opcional a bruto. |

A E01 **não** é a origem primária da cadeia de dados: espera insumos `INFO2` já preparados, inclusive GPKG integrado, RDS de hidrologia, RDS de áreas e arquivos CSV de correspondência/balanço. O modo de criação, a proveniência e a disponibilidade controlada desses insumos precisam constar do manifesto e da documentação. Não afirmar que estes sete arquivos reproduzem sozinhos o processamento desde os dados originais ANA.

## 2. Pontos tecnicamente adequados

- **Separação de responsabilidades:** E01 não calcula per capita; E02 não promove o indicador; E03 não refaz municipalização ou obtenção da população.
- **Proteção contra sobrescrita:** E01 reutiliza checkpoints sob verificação; E02/E03 comparam o conteúdo RDS ou hashes de CSV já existentes e interrompem diante de divergência. E03 promove apenas com argumento explícito `promover`.
- **Conciliação:** E01 verifica áreas, vazões e separa duas áreas operacionais do RS; E02 verifica chaves/contagens e conservação da população; E03 concilia contribuições com E01, QA e totais censitários.
- **Sem imputação silenciosa:** fontes ANA não estimadas não são tratadas como vazão nula; vazões negativas não geram valor per capita; municípios sem denominador censitário permanecem sem indicador.
- **Grupos:** a série Total/Masculino/Feminino reproduz o **mesmo atributo territorial**; não simula valores hidrológicos específicos por sexo.
- **Ressalvas preservadas:** `situacao_qualidade` e `compatibilidade_territorial` permanecem nos produtos; a malha 2025 não é declarada harmonizada com os recortes censitários.

## 3. Pendências para o versionamento controlado

### P1 — Linhagem dos insumos que antecedem a E01 — **necessária para a reprodutibilidade**

No módulo de municipalização, linhas ~171–189, os insumos são arquivos preparados previamente (`inf02_bho50k_integrada_v01.gpkg`, `inf02_bho50k_area_brasil_2025_v01.rds`, `inf02_hidrologia_50k_v02.rds`, mapas FID, QA 19A/19B, shapefile IBGE 2025 e componentes). É necessário um **manifesto versionável** com fonte, versão, licença, método de obtenção/preparação, estrutura esperada, checksums e caminho lógico. O manifesto não precisa disponibilizar os arquivos binários.

A reprodutibilidade atual é **condicionada** à existência desses insumos validados. Reproduzir a E01 a partir de produtos previamente preparados é diferente de reconstituir os dados ANA/BHO originais.

### P2 — Identidade dos checkpoints E01 vinculada a caminho e mtime — **cuidado antes de editar**

No processador E01, linhas ~87–123 e ~191–195, a assinatura reúne a versão, o **MD5 do próprio módulo**, os caminhos absolutos normalizados, tamanho e data de modificação dos insumos. Isso impede reutilização acidental em ambiente modificado, mas não é uma assinatura portátil baseada somente em conteúdo. Uma simples cópia dos insumos para outro disco pode impedir a retomada; tamanho/data idênticos também não demonstram, isoladamente, identidade binária.

O módulo declara `INF02_E01_1.0.4` e aceita hashes precisos de 1.0.0–1.0.3 sob condições expressas. **Não alterar este arquivo nem comentários antes de definir política explícita de migração/compatibilidade de checkpoints.** A revisão editorial inicial deve acontecer nos executores e na documentação, conservando os bytes do módulo de cálculo aprovado.

MD5 do arquivo enviado `processar_inf02_municipalizacao.R`: `7b30e82e3e1d810468cc94c6040094cd`.

### P3 — Caminhos de máquina pessoal no executor E01 — **corrigir antes de publicar**

`executar_inf02_etapa01.R`, linhas ~21–41, contém diretórios absolutos de uma máquina específica como fallback. O executor já aceita argumentos e `config_local.R`; portanto, os fallbacks pessoais são dispensáveis na versão pública. **Editar apenas o executor**, não o processador E01 que compõe a identidade dos checkpoints. Não incluir `config_local.R` no versionamento.

A busca textual simples não identificou credenciais ou tokens entre os sete arquivos; isso não equivale a auditoria completa de segurança de dados.

### P4 — Fontes censitárias e ambiente computacional — **documentar**

`ler_populacao_censitaria_inf02.R` utiliza SIDRA 202 (2000 e 2010) e 4709 (2022) e armazena JSON local antes de usá-lo. Registrar no manifesto URLs, datas de consulta ou de criação, hashes dos arquivos retornados e controles de cardinalidade (5507/5565/5570 populações válidas). O código confere totais nacionais no processamento E03.

Declarar versões de R, `sf`, `data.table`, `DBI`, `RSQLite`, `jsonlite` e bibliotecas espaciais GDAL/GEOS/PROJ. A E01 usa `sf_use_s2(FALSE)` e EPSG:6933; resultados espaciais reexecutados em outro ambiente merecem QA, não equivalência presumida.

### P5 — Contrato de status em dois níveis — **manter a diferença**

No E03, o campo **municipal** `status_calculo` usa `CALCULADO_SEM_HARMONIZACAO_TERRITORIAL` para valores calculados e outros quatro motivos de ausência (`DIVISAO_TERRITORIAL_ALTERADA_2025`, `Q_NEGATIVA_NAO_INTERPRETAVEL`, `SEM_CONTRIBUICAO_ESTIMADA`, `SEM_POPULACAO_CENSITARIA`).

Já o **QA geral** guarda `status = "CALCULADO_COM_RESSALVA_NAO_HARMONIZADO"` (E03, linhas ~919–921). Os dois rótulos têm **funções distintas** e não devem ser tratados como inconsistência nem convertidos silenciosamente.

### P6 — Limites de interpretação do indicador — **documentar com precisão**

O numerador é contribuição incremental superficial estimada da ANA (com regras próprias para cobertura e fontes não estimadas); o denominador é a população censitária associada por código à referência IBGE 2025. A hidrologia/malha é fixa ao longo dos três recortes. Logo, diferenças entre 2000/2010/2022 não podem ser interpretadas automaticamente como variação temporal observada na disponibilidade de água renovável. 

A agregação permite valores mesmo em municípios cuja `situacao_qualidade` registra cobertura incompleta. A documentação deve preservar a natureza **parcial/condicionada** da estimativa, sem retirar os valores já aprovados nem definir neste momento regras de tratamento estatístico.

## 4. Situação da validação

O arquivo diagnóstico executado pelo usuário confirmou para 2000/2010/2022, respectivamente: 5.571 unidades por ano, 16.713 linhas município–grupo; 5.493/5.551/5.556 valores disponíveis e 78/20/15 ausentes. O usuário confirmou também testes integrados INF01+INF02 em cada ano.

Esta auditoria é **estática**; os scripts não foram executados aqui porque o ambiente não dispõe de R/Rscript nem das bases espaciais e censitárias locais. A aprovação computacional dos produtos é informação das execuções realizadas pelo usuário, não nova execução independente.

## 5. Decisão de auditoria e sequência

**Parecer:** os sete scripts são aptos a entrar no **processo de versionamento controlado**, com as ressalvas acima; a documentação e o manifesto de insumos ainda precisam ser concluídos. Não declarar a dimensão encerrada.

1. Preservar uma cópia do pacote original e dos MD5 dos sete scripts.
2. Retirar fallbacks de caminhos pessoais do **executor E01**, usando argumentos/`config_local.R`.
3. Versionar **apenas os sete arquivos de código**, em branch de trabalho separada e após inspeção do diff. Não executar `git add .`.
4. Produzir manifesto dos insumos E01/SIDRA e do ambiente, sem armazenar dados restritos no GitHub.
5. Revisar e incorporar documentação INF01/INF02, scripts históricos de validação e evidências; atualizar `docs/infraestrutural/README.md` para refletir a E03 concluída.
6. Verificar reprodutibilidade permitida e encerrar a dimensão formalmente. **Tratamento estatístico permanece bloqueado.**
