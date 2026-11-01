# SO3.3 — Diagnóstico e tratamento estatístico dos indicadores (Blocos A/B/C)

**Estado em 01/11/2026:** diagnóstico dos nove indicadores realizado; decisões metodológicas de winsorização e transformação concluídas. Sete indicadores permanecem originais; ECO02 e INF02 utilizam Yeo–Johnson; nenhum recebe winsorização. As execuções operacionais de ECO02 e INF02 foram confirmadas localmente. Os arquivos candidatos em `outputs/intermediario` **não equivalem** aos produtos tratados oficiais, à normalização ou ao DVI.

## 1. Escopo e unidade estatística

O tratamento é feito por **indicador × grupo populacional**, reunindo os registros municipais de **2000, 2010 e 2022** em uma única série por unidade de avaliação. Não se compartilham parâmetros entre indicadores ou entre grupos populacionais independentes.

- **Populacionais:** SOC01, SOC02, SOC03, SOC04, ECO01 e INF01 — séries independentes para Total, Masculino e Feminino.
- **Territoriais compartilhados:** ECO02, ECO03 e INF02 — uma série `Compartilhado`; a replicação dos valores nos três grupos não constitui três observações estatísticas independentes.

Cada par município–ano válido tem igual peso na caracterização estatística, sem ponderação pela população. A reunião dos recortes não implica independência espacial ou temporal. As estatísticas anuais são descritivas e não originam parâmetros específicos por ano. As orientações diretas/inversas e a normalização `[0,1]` pertencem à etapa posterior, conforme PRAIS4; nenhum indicador isolado constitui medida de vulnerabilidade à seca.

## 2. Arquitetura e critérios de avaliação

`CSV municipal bruto → Bloco A (diagnóstico) → Bloco B (avaliação de winsorização) → Bloco C (avaliação de Yeo–Johnson) → CSV candidato → validação → orientação/normalização → componentes → DVI`.

Os dados brutos nunca são modificados. As decisões específicas aprovadas para ECO02 e INF02 prevalecem sobre a seleção automática geral. A aproximação de normalidade não é um objetivo obrigatório do DVI, nem critério suficiente, por si só, para aprovar tratamentos.

### 2.1 Bloco A — Estatísticas e triagem COINr

Assimetria corrigida e curtose excedente corrigida seguem as fórmulas equivalentes a `e1071::skewness(type=2)` e `e1071::kurtosis(type=2)`, implementadas em R base e utilizadas pelo COINr. A regra de `check_SkewKurt()` é:

```text
PASSA       se |assimetria| < 2 OU curtose excedente < 3.5
INVESTIGAR caso contrário, quando os dois limites são atingidos
INDETERMINADO quando a dispersão é nula, N < 4 ou momentos não finitos
```

A condição `INVESTIGAR` **não determina automaticamente** a necessidade de intervenção. O sinal da assimetria não constitui, isoladamente, autorização de truncamento. Os limites são estritos; pequenas diferenças de ponto flutuante nas fronteiras podem alterar a classificação. O campo legado `assimetria_momento` não equivale ao estimador tipo 2.

Cercas de Tukey, extremos e quantis do Bloco A são **apenas diagnósticos**. A coluna `boxcox_sem_deslocamento_admissivel` descreve a viabilidade da Box–Cox convencional sem deslocamento, não recomenda seu uso. A transformação avaliada e aprovada nesta etapa é **Yeo–Johnson**, não Box–Cox.

### 2.2 Bloco B — Winsorização

A política própria do PRAIS-Brasil admite, apenas como teto de investigação, no máximo **5% das observações válidas** da série conjunta indicador × grupo. Regimes possíveis: nenhum; bilateral até 2,5% por cauda; unilateral inferior até 5%; unilateral superior até 5%. Os tetos são arredondados com `floor()`; empates não autorizam ultrapassá-los. Esse percentual **não** corresponde ao `winmax=5` do COINr, que representa cinco observações.

O módulo avalia candidatos e a triagem pós-intervenção. Para candidatos aprovados na triagem, também mede mudanças na distribuição normalizada e nas medianas temporais segundo limiares operacionais configuráveis. Uma alteração elevada após min–max pode decorrer da mudança dos extremos de referência e não deve ser confundida com alteração percentual dos valores brutos. A decisão específica sobre ECO02 e INF02 foi **não winsorizar**. Nenhuma das nove séries teve winsorização aprovada.

### 2.3 Bloco C — Yeo–Johnson

A transformação é monotônica crescente para os parâmetros avaliados e permite valores nulos e negativos. A estimação de `lambda` é realizada **uma única vez sobre os três recortes juntos**, por série. Aplicar a mesma função aos três anos conserva a ordenação dos valores, mas **modifica distâncias**; não demonstra por si só comparabilidade das referências originais.

O procedimento automático geral avalia eficácia e mudanças territoriais/temporais. Para ECO02 e INF02, análises específicas fundamentaram decisões documentadas que substituem os vetos automáticos baseados em variação relativa do IQR normalizado. Essas decisões são **particulares aos respectivos indicadores** e não devem ser generalizadas.

## 3. Execução e produtos

Executar a partir da raiz do repositório, no ambiente R configurado localmente:

```bash
RSCRIPT so3.3/tests/testar_estatistica_brutos.R
RSCRIPT so3.3/executar_diagnostico_estatistico.R social SOC01_ALF15
RSCRIPT so3.3/executar_diagnostico_estatistico.R social todos
RSCRIPT so3.3/executar_tratamento_estatistico.R economica ECO02_PIBPC
RSCRIPT so3.3/executar_avaliacao_yeojohnson.R infraestrutural INF02_RECURSOS_HIDRICOS_PC
RSCRIPT so3.3/executar_tratamento_estatistico.R infraestrutural INF02_RECURSOS_HIDRICOS_PC
```

`RSCRIPT` é o alias local do ambiente R; em outros ambientes utilizar `Rscript` diretamente. O diagnóstico usa R base e lê `so3.3/outputs/bruto/<dimensao>/<ano>/<indicador>_<ano>.csv`, separado por `;`. Os CSVs seguem contrato validado de chaves, grupos, cardinalidade e valores. INF02 mantém as ausências e seus status; ECO03 não é artificialmente truncado em 100%.

| Etapa | Diretório | Produtos principais |
| --- | --- | --- |
| Diagnóstico A | `outputs/intermediario/estatistica/diagnostico/<dimensao>/<indicador>/<timestamp>/` | `01_inventario.csv`, `02_estatisticas_conjuntas.csv`, `03_descritivas_anuais.csv`, `04_extremos_inspecao.csv`, `06_orcamentos_winsorizacao.csv`, `05_status_INF02.csv` quando cabível, `LEIA_ME.txt`, `sessao_R.txt` |
| Tratamento B/C | `outputs/intermediario/estatistica/tratamento/<dimensao>/<timestamp>/<indicador>/` | `01_decisoes.csv`, `02_fontes_md5.csv`, CSVs municipais candidatos por ano |
| Avaliação YJ específica | `outputs/intermediario/estatistica/avaliacao_yj/<indicador>/<timestamp>/` | `01_resumo_yj.csv`, `02_diagnosticos_anuais.csv`, `03_comparacao_temporal.csv`, `04_fontes_md5.csv`, `05_valores_candidatos.csv` e, para INF02, `06_status_INF02.csv` |

As funções de leitura, catalogação e estatísticas estão em `so3.3/R/03_diagnostico/estatistica_brutos_conjuntos.R`; a interface do Bloco A está em `so3.3/executar_diagnostico_estatistico.R`. Os scripts específicos de Yeo–Johnson são auxiliares de avaliação; a aplicação aprovada ocorre pelo executor de tratamento. Os diretórios com timestamp são históricos de execução, não parâmetros universais.

## 4. Registro consolidado de decisões

| Dimensão | Indicador | Grupo | Winsorização | Yeo–Johnson | Decisão |
| --- | --- | --- | --- | --- | --- |
| Social | `SOC01_ALF15` | Total/Masculino/Feminino | Não | Não | Manter original |
| Social | `SOC02_RURAL` | Total/Masculino/Feminino | Não | Não | Manter original |
| Social | `SOC03_EV0` | Total/Masculino/Feminino | Não | Não | Manter original* |
| Social | `SOC04_POP1564` | Total/Masculino/Feminino | Não | Não | Manter original |
| Econômica | `ECO01_POV3_PPC21` | Total/Masculino/Feminino | Não | Não | Manter original* |
| Econômica | `ECO02_PIBPC` | Compartilhado | Não | Sim | Aplicar YJ |
| Econômica | `ECO03_AGROPIB` | Compartilhado | Não | Não | Manter original* |
| Infraestrutural | `INF01_REDE_CANALIZADA` | Total/Masculino/Feminino | Não | Não | Manter original* |
| Infraestrutural | `INF02_RECURSOS_HIDRICOS_PC` | Compartilhado | Não | Sim | Aplicar YJ |

*Resultados sem intervenção informados após execução local, sem reapresentação de relatório completo nesta rodada. As decisões ECO02 e INF02 foram também conferidas nas saídas de execução local em 01/11/2026. A validação operacional dos executores não equivale à auditoria integral de cada arquivo municipal candidato.

## 5. Decisão específica — ECO02_PIBPC

**Não winsorizar; aplicar Yeo–Johnson aos valores originais**, com `lambda = -0.239620859028258`, estimado sobre a série territorial conjunta 2000/2010/2022 e utilizado igualmente nos três grupos do DVI.

- Série original: 16.642 observações válidas; assimetria corrigida **7,8366** e curtose excedente **110,1063** (`INVESTIGAR`).
- Candidato de winsorização superior: 332 observações alteradas; elevação aproximada de **680% do IQR normalizado**, e não dos valores monetários originais. A intervenção foi rejeitada por gerar empates artificiais no topo e comprometer distinções entre valores elevados.
- Yeo–Johnson: assimetria **0,0252**, curtose excedente **−0,4699** (`PASSA`), sem novas ausências e preservando a ordenação.
- A variação aproximada de **+744,5% no IQR normalizado** representa redistribuição de distâncias na escala min–max; não corresponde a crescimento econômico real nem foi utilizada isoladamente como veto.

A transformação não é correção de erros nem busca obrigatória de normalidade. Não conserva distâncias monetárias originais. **A comparabilidade monetária entre 2000, 2010 e 2022 precisa estar demonstrada na documentação da fonte**; Yeo–Johnson não corrige inflação ou mudanças de unidade. Orientação e normalização PRAIS4 são etapas posteriores.

Execução operacional registrada em **01/11/2026**, com `decisao_yj = APLICAR_YJ_DECISAO_DOCUMENTADA` e `decisao_winsor = NAO_APLICAR_DECISAO_DOCUMENTADA`.

## 6. Decisão específica — INF02_RECURSOS_HIDRICOS_PC

**Não winsorizar; aplicar Yeo–Johnson aos valores originais** da série territorial compartilhada, com **um único lambda estimado conjuntamente para 2000, 2010 e 2022**.

- Série original: **16.600** observações válidas; assimetria corrigida **21,3965**; curtose excedente **699,2815** (`INVESTIGAR`).
- Nos regimes testados, nenhum candidato de winsorização superou a triagem COINr; a winsorização também foi rejeitada metodologicamente.
- Yeo–Johnson: `lambda` exibido no terminal **0,0177523** (arredondado); assimetria **0,0054**, curtose excedente **0,4919** (`PASSA`), com ausências e monotonicidade preservadas.
- IQR normalizado: **0,001930561 → 0,1471719**, alteração relativa aproximada de **+7.523%**. Os valores brutos de disponibilidade hídrica não aumentaram nessa proporção. A transformação redistribui distâncias entre municípios e diminui a compressão da faixa central causada pelos extremos.
- As diferenças entre medianas normalizadas permaneceram negativas em **2000–2010, 2010–2022 e 2000–2022**. Esse resultado não comprova variação física da oferta hídrica: a interpretação depende das vazões, das populações utilizadas como denominador e da compatibilidade territorial.

**Proveniência do parâmetro:** o executor principal lê o valor integral de `lambda` do relatório local:

```text
so3.3/outputs/intermediario/estatistica/avaliacao_yj/
INF02_RECURSOS_HIDRICOS_PC/20261101T172859/01_resumo_yj.csv
```

Esta opção foi mantida deliberadamente: o parâmetro não é fixado em configuração independente da base, pois uma nova base de referência pode exigir **nova estimação e novo relatório**. **Limitação operacional explícita:** a versão atual do executor depende desse caminho histórico com timestamp. Para reproduzir exatamente a execução, é necessário preservar ou restaurar o relatório correspondente junto das fontes originais; mudar apenas os dados de entrada sem reavaliar e apontar o novo relatório **não constitui nova parametrização válida**. O MD5 e a origem do relatório devem permanecer registrados na trilha de execução.

Os campos `status_calculo`, `situacao_qualidade`, `compatibilidade_territorial`, as chaves município–ano e as ausências devem permanecer inalterados. Nenhum `NA` deve ser substituído por zero. A situação de cálculo e compatibilidade não é sanada por transformação estatística.

Execução operacional registrada em **01/11/2026**, com `decisao_yj = APLICAR_YJ_DECISAO_DOCUMENTADA` e `decisao_winsor = NAO_APLICAR_DECISAO_DOCUMENTADA`.

## 7. Rastreabilidade, limites e próximas etapas

Os parâmetros de cada série são exclusivos e nenhuma decisão dos indicadores territoriais deve ser transferida automaticamente aos populacionais. Os arquivos de referência do IBGE para população censitária do INF02, em `so3.3/inputs/referencias/ibge/populacao_censitaria_inf02/`, **são referências de entrada a versionar**. Já os CSVs/RDS brutos, relatórios intermediários e candidatos são produtos de execução e não são incluídos automaticamente no versionamento de código.

Antes da publicação de dados derivados de microdados sujeitos a controle, verificar as respectivas restrições do IBGE. A publicação de scripts e documentação não implica autorização de publicar todos os produtos municipais.

A conclusão dos Blocos A/B/C não equivale ao encerramento do SO3.3. A sequência seguinte compreende: **promoção validada de candidatos a produtos tratados → orientação dos indicadores → normalização conjunta no intervalo [0,1] com referências fixas para 2000/2010/2022, específicas por indicador/grupo → componentes Social, Econômico e Infraestrutural → DVI**. Sensibilidade e metadados devem acompanhar as etapas subsequentes.

## 8. Referências

- UNCCD, **PRAIS4 Reporting Manual**, seção SO3.3 — orientação, normalização e composição do DVI.
- COINr — código-fonte de `skew()`, `kurt()`, `check_SkewKurt()` e `winsorise()`: https://github.com/bluefoxr/COINr/blob/master/R/treat.R
- COINr — `check_SkewKurt()`: https://search.r-project.org/CRAN/refmans/COINr/help/check_SkewKurt.html
- COINr — `winsorise()`: https://search.r-project.org/CRAN/refmans/COINr/html/winsorise.html
