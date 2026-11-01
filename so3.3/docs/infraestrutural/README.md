# SO3.3 — Dimensão Infraestrutural

**PRAIS_BRASIL | Documentação conceitual e metodológica dos indicadores municipais**  
**Referência do projeto:** *Performance Review and Assessment of Implementation System* (PRAIS), Objetivo Estratégico 3 (SO3), produto SO3.3.  
**Estado do documento:** versão aprovada para inclusão no repositório — novembro de 2026.  
**Localização no repositório:** `so3.3/docs/infraestrutural/README.md`.

> **Delimitação:** este documento descreve a dimensão Infraestrutural e os procedimentos de produção e validação dos seus indicadores municipais **brutos**, `INF01_REDE_CANALIZADA` e `INF02_RECURSOS_HIDRICOS_PC`. Não estabelece regras de tratamento estatístico, orientação, normalização, ponderação, agregação dimensional ou composição do DVI. **A dimensão Infraestrutural compõe a representação multidimensional da vulnerabilidade à seca; isoladamente, não constitui uma medida de vulnerabilidade à seca.** Sua interpretação também não deve ser confundida com segurança hídrica, exposição à seca, risco ou impactos observados.

## 1. Apresentação

### 1.1. A dimensão Infraestrutural no contexto da vulnerabilidade à seca

A dimensão Infraestrutural reúne informações selecionadas sobre **condições de acesso à infraestrutura de abastecimento de água** e **disponibilidade hídrica superficial estimada em base territorial**. Essas propriedades podem contribuir para caracterizar circunstâncias materiais e ambientais que participam da vulnerabilidade à seca, mas não são manifestações diretas nem medidas suficientes dessa vulnerabilidade.

As duas propriedades não devem ser confundidas: a existência de rede geral e canalização interna não demonstra continuidade, qualidade ou suficiência do abastecimento; uma estimativa de contribuição hídrica superficial por habitante tampouco informa o volume efetivamente captável, distribuído ou disponível para cada pessoa. A denominação da dimensão é uma **convenção de organização do DVI**, e não uma afirmação de que a contribuição hídrica superficial seja, por si, infraestrutura instalada.

### 1.2. Objetivo e abrangência da dimensão

O objetivo é **caracterizar, em escala municipal, condições selecionadas de acesso à água e de disponibilidade hídrica superficial estimada** relevantes à descrição das condições que podem participar da vulnerabilidade à seca no Brasil.

O projeto adota os recortes analíticos de **2000, 2010 e 2022**. Essa convenção não significa que todas as fontes sejam contemporâneas aos respectivos Censos nem que os valores correspondam a uma série homogênea de observações anuais. As referências efetivamente utilizadas são discriminadas por indicador.

Os produtos seguem a organização **Total, Masculino e Feminino**, respeitando a natureza da informação. Para o `INF01`, existe desagregação populacional efetiva. Para o `INF02`, o mesmo atributo municipal é compartilhado entre os três grupos; não se calculam recursos hídricos específicos por sexo.

### 1.3. Relação com o DVI

A dimensão Infraestrutural constitui **um dos conjuntos de indicadores previstos para a construção posterior do Índice de Vulnerabilidade à Seca** (*Drought Vulnerability Index* — **DVI**), juntamente com as dimensões [Social](../social/README.md) e [Econômica](../economica/README.md).

**Nenhum indicador, nem a dimensão Infraestrutural considerada isoladamente, constitui uma medida direta da vulnerabilidade à seca.** A representação sintética pretendida para o DVI dependerá da integração metodologicamente condicionada das três dimensões, de decisões posteriores sobre tratamento e agregação e da explicitação das limitações de cada componente. Mesmo o DVI resultante não deve ser confundido com uma observação direta de impactos ou com uma medida exaustiva da vulnerabilidade real.

## 2. Fundamentação conceitual da dimensão Infraestrutural

### 2.1. Caracterização da dimensão

A seleção dos indicadores parte do referencial FAO/UNCCD adotado para o SO3.3, adaptado às bases brasileiras e aos recortes municipais disponíveis. Seu propósito é organizar **atributos observáveis ou estimáveis**, e não estabelecer uma hierarquia prévia de vulnerabilidade entre municípios.

No âmbito da dimensão, distinguem-se duas naturezas de informação:

- **Condição de infraestrutura atribuída às pessoas:** proporção de moradores de domicílios particulares permanentes ocupados atendidos pela combinação de rede geral como fonte principal e canalização interna (`INF01`).
- **Atributo hidrológico territorial referido à população:** contribuição incremental superficial estimada, municipalizada a partir de dados ANA/BHO 50K e dividida pela população residente total do recorte censitário (`INF02`).

Essa distinção é decisiva porque os dois indicadores têm universos, fontes, referências temporais e limitações diferentes.

### 2.2. Acesso à água e disponibilidade hídrica territorial

A cobertura por rede geral com canalização interna descreve uma **condição de infraestrutura de abastecimento**. Ela não informa o desempenho do serviço durante uma seca nem caracteriza, sozinha, a capacidade de resposta de domicílios ou sistemas de abastecimento.

A contribuição hídrica superficial por habitante descreve uma **razão hidrológico-demográfica territorial**. Sua magnitude depende da estimativa de vazão incremental superficial atribuída à unidade territorial e do denominador populacional utilizado. Não equivale à disponibilidade efetiva para consumo humano, à oferta operacional dos sistemas, à vazão regularizada, à água subterrânea, à demanda ou ao balanço entre usos concorrentes.

### 2.3. Alcance e limites da representação

A presença dos dois indicadores na mesma dimensão **não demonstra equivalência conceitual, independência estatística ou uma relação causal direta com impactos da seca**. Também não permite, na etapa de produção bruta, atribuir classes ou pontuações de vulnerabilidade a seus valores.

A interpretação exige considerar conjuntamente as particularidades censitárias do `INF01`, a cobertura e as lacunas hidrológicas do `INF02` e, sobretudo, a ausência de harmonização dos limites territoriais utilizada no segundo indicador.

## 3. Composição da dimensão

### 3.1. Seleção e delimitação

A versão operacional da dimensão contém **dois indicadores**:

| Código | Indicador | Unidade | Natureza da informação | Grupos |
|---|---|---|---|---|
| `INF01_REDE_CANALIZADA` | População residente em DPP com abastecimento principal pela rede geral e canalização interna | % | Condição domiciliar atribuída à população residente | Total, Masculino, Feminino; desagregação efetiva |
| `INF02_RECURSOS_HIDRICOS_PC` | Recursos hídricos renováveis per capita — operacionalizados como contribuição incremental superficial estimada por habitante | m³/habitante/ano | Estimativa hidrológico-demográfica territorial | Mesmo valor nos três grupos; atributo compartilhado |

Ambos têm produção bruta e integração computacional validadas para 2000, 2010 e 2022. Essa situação **não** significa que seus valores tenham sido harmonizados territorialmente entre os períodos ou que um índice dimensional já tenha sido calculado.

### 3.2. Indicadores não operacionalizados nesta versão

A **irrigação** foi considerada durante a delimitação da dimensão, mas **não integra a versão operacional atual** em razão de inconsistências e limitações de correspondência entre as bases e os recortes de interesse identificadas na avaliação das fontes nacionais. Não foi substituída por valores aproximados nem incorporada implicitamente ao `INF02`.

A delimitação a dois indicadores deve ser apresentada como uma decisão operacional da versão brasileira, não como evidência de que o conjunto esgota as condições infraestruturais relevantes à vulnerabilidade à seca.

### 3.3. Complementaridade dos indicadores

Os indicadores expressam propriedades distintas: **cobertura de uma condição de abastecimento** (`INF01`) e **contribuição hídrica superficial estimada por habitante** (`INF02`). A coexistência desses atributos pode contribuir para uma caracterização multidimensional, sem autorizar sua soma direta, sua comparação em unidades originais ou a inferência de um valor de vulnerabilidade.

Direção, transformações, normalização, ponderação, agregação e sensibilidade dos componentes pertencem a uma etapa metodológica posterior, após a aprovação das três dimensões brutas e de suas documentações.

## 4. Fontes de dados e referências territorial e temporal

### 4.1. Fontes utilizadas

| Indicador / etapa | Instituição e fonte | Informação efetivamente utilizada |
|---|---|---|
| `INF01` — 2000 e 2010 | IBGE, microdados da amostra dos Censos Demográficos, acessados por meio do pacote R `censobr` | Domicílios particulares permanentes, forma principal de abastecimento, canalização, moradores, sexo e pesos de expansão |
| `INF01` — 2022 | IBGE, microdados da amostra do Censo Demográfico 2022, **acesso controlado** | Registros de Domicílios e Pessoas, vinculação domiciliar, variáveis de abastecimento, moradores, sexo e pesos |
| `INF01` — auditoria externa | IBGE/SIDRA, tabelas 2420 e 6909 | Referências de comparação, com alcance e ressalvas específicos por recorte |
| `INF02` — E01 | Agência Nacional de Águas e Saneamento Básico (ANA), BHO 50K e bases hidrológicas previamente preparadas | Contribuição de vazão incremental superficial `Qmltinc` estimada e geometria das unidades hidrográficas |
| `INF02` — E01 | IBGE, malha territorial municipal de 2025 | Geometrias, áreas e códigos utilizados na municipalização hidrológica |
| `INF02` — E02 | IBGE/SIDRA, tabela 202 (2000 e 2010) e tabela 4709 (2022) | População **total** residente do universo censitário, por código municipal |
| `INF02` — E03 | Produtos validados das etapas E01 e E02 | Vazão superficial incremental municipalizada e população censitária associada por código |

Os dados de população utilizados no `INF02` são **totais censitários**, não estimativas expandidas de microdados amostrais e não populações desagregadas por sexo. Essa escolha é distinta do procedimento de apuração do `INF01`.

### 4.2. Correspondência temporal

| Recorte PRAIS | Referência do `INF01` | Referência hidrológica do `INF02` | Denominador do `INF02` | Base territorial do `INF02` |
|---|---|---|---|---|
| 2000 | Censo 2000 | ANA/BHO 50K — referência hidrológica fixa do processamento | População total censitária 2000 | IBGE 2025 |
| 2010 | Censo 2010 | A mesma referência ANA/BHO 50K | População total censitária 2010 | IBGE 2025 |
| 2022 | Censo 2022 | A mesma referência ANA/BHO 50K | População total censitária 2022 | IBGE 2025 |

**Consequência interpretativa:** as diferenças de `INF02` entre os recortes **não representam, por si, mudanças observadas na disponibilidade hídrica superficial**. O numerador hidrológico e a referência espacial permanecem fixos; o denominador muda conforme o Censo e sua associação por código. Portanto, não se deve interpretar a série como uma evolução hidrológica homogênea entre 2000 e 2022.

### 4.3. Unidade territorial e correspondência municipal

O `INF01` adota o universo de municípios pertinente a cada recorte censitário. Já o `INF02` parte de uma **base territorial de 2025**, que contém **5.571 unidades municipais ou equivalentes** para a série final, além de **duas áreas operacionais do Rio Grande do Sul** mantidas em registros separados para conciliação territorial e hidrológica.

| Recorte | Municípios do `INF01` | Unidades de referência no `INF02` | Situação da comparabilidade |
|---|---:|---:|---|
| 2000 | 5.507 | 5.571 | Não harmonizados; universos e limites diferentes |
| 2010 | 5.565 | 5.571 | Não harmonizados; universos e limites diferentes |
| 2022 | 5.570 | 5.571 | Não harmonizados; alteração territorial conhecida em 2025 |

No `INF02`, os dados censitários são associados à referência de 2025 **por coincidência de geocódigo municipal**, sem reconstrução histórica das geometrias. O processamento identifica explicitamente a alteração territorial ligada à criação de **Boa Esperança do Norte** a partir de áreas de Sorriso e Nova Ubiratã e não disponibiliza valores para uso nos dois municípios de origem afetados, mesmo quando o cálculo algébrico seria possível.

A preservação de códigos ou nomes não demonstra invariância dos limites ao longo do tempo. **A integração computacional dos indicadores do mesmo recorte não executa harmonização geográfica**, nem elimina a incompatibilidade entre suas referências territoriais.

### 4.4. Grupos populacionais e natureza da desagregação

No `INF01`, os percentuais Total, Masculino e Feminino são calculados sobre os respectivos moradores do universo elegível, com numeradores e denominadores próprios.

No `INF02`, a população **total** do município compõe o denominador de um único valor territorial, posteriormente replicado de maneira idêntica nos três grupos, com `tipo_desagregacao = "compartilhada"`. **Essa replicação atende ao formato de integração do DVI, não representa disponibilidade hídrica distinta para homens e mulheres.**

## 5. Metodologia dos indicadores

### 5.1. `INF01_REDE_CANALIZADA` — Acesso à rede geral com canalização interna

#### 5.1.1. Definição operacional

O `INF01` corresponde ao percentual de moradores de **domicílios particulares permanentes ocupados (DPP)** cujo abastecimento **principal** provém da **rede geral de distribuição** e que apresentam **canalização de água no interior da habitação**, conforme a correspondência operacional adotada para cada Censo.

A condição de atendimento exige simultaneamente os dois atributos. Não entram no numerador os domicílios cuja fonte principal é outra, ainda que haja acesso adicional à rede, nem aqueles sem a condição de canalização prevista. Domicílios improvisados e coletivos ficam fora do denominador.

#### 5.1.2. Formulação matemática e universos de cálculo

Para o município \(m\), recorte censitário \(t\) e grupo \(g\in\{Total,Masculino,Feminino\}\), o estimador domiciliar utilizado em 2000 é:

$$
INF01_{m,t,g}=100\times\frac{\sum_{d\in DPP_{m,t}}w_d\,N_{d,g}\,I_d}{\sum_{d\in DPP_{m,t}}w_d\,N_{d,g}},
$$

em que \(w_d\) é o peso do domicílio, \(N_{d,g}\) é a quantidade de moradores do grupo \(g\), e \(I_d=1\) se o domicílio satisfaz conjuntamente os critérios de rede geral como fonte principal e canalização, ou zero caso contrário.

Em 2010 e 2022, após vinculação dos registros de Pessoas aos respectivos Domicílios, a apuração principal é realizada individualmente:

$$
INF01_{m,t,g}=100\times\frac{\sum_{i\in P^{DPP}_{m,t}}w_i\,G_{i,g}\,I_{d(i)}}{\sum_{i\in P^{DPP}_{m,t}}w_i\,G_{i,g}},
$$

em que \(w_i\) é o peso da pessoa \(i\), \(G_{i,g}\) identifica seu grupo e \(d(i)\) é seu domicílio. O resultado nacional é uma **razão de somas ponderadas**, e não a média simples dos percentuais municipais. O resultado Total também não é a média aritmética entre Masculino e Feminino.

#### 5.1.3. Correspondência operacional das variáveis censitárias

| Informação | Censo 2000 — Domicílios | Censo 2010 — Domicílios/Pessoas | Censo 2022 — Domicílios/Pessoas |
|---|---|---|---|
| DPP | `V0201 = 1` | `V4001 = 1` | `D0130 = 1` |
| Rede geral como forma principal de abastecimento | `V0207 = 1` | `V0208 = 1` | `D0260 = 1` |
| Canalização conforme o critério operacional | `V0208 = 1` | `V0209 = 1` | `D0300 = 1` |
| Total de moradores — cálculo/auditoria | `V7100` | `V0401` | `D0150` |
| Sexo / desagregação | `V0110`, `V0111` | `V0601` | `P0160` |
| Peso principal | `P001` | `V0010` | `P0111` |
| Chave domiciliar para vinculação | Não necessária | Município + `V0300` | `D0080`/`P0080` + `D0100`/`P0100` |
| Município de agregação | `code_muni` (controle `V0103`) | `code_muni` (controle `V0002`) | `D0080`/`P0080` |

**Particularidade de 2022:** a variável `D0290` registra situações de acesso à rede geral que não constituem abastecimento principal e **não entra no numerador**. A categoria `D0300 = 1` pode incluir canalização até banheiro externo de uso exclusivo, segundo a classificação censitária de 2022. A equivalência entre recortes é, portanto, **operacional**, não identidade literal dos questionários.

#### 5.1.4. Estimadores, verificações e valores ausentes

- **2000:** apuração domiciliar com peso `P001`, total `V7100` e contagens por sexo `V0110`/`V0111`.
- **2010:** apuração por Pessoas e conciliação com os componentes domiciliares, mediante conferência de chaves, pesos e moradores.
- **2022:** apuração por Pessoas vinculadas aos Domicílios, com conciliação dos pesos `P0111`/`D0111`, das contagens `D0150` e dos seis componentes municipais.

São preservados `numerador_total`, `denominador_total`, `numerador_masculino`, `denominador_masculino`, `numerador_feminino` e `denominador_feminino`. Os controles de consistência exigem, dentro das tolerâncias dos pesos expandidos:

$$
D_{Total}=D_{Masculino}+D_{Feminino},\qquad
N_{Total}=N_{Masculino}+N_{Feminino}.
$$

Não se imputam condições de abastecimento nem se recalculam arbitrariamente os fatores de expansão. Denominador inválido ou nulo implica `NA`; numerador igual a zero é preservado quando o denominador é positivo. Os percentuais definidos devem pertencer ao intervalo **[0, 100]**.

### 5.2. `INF02_RECURSOS_HIDRICOS_PC` — Recursos hídricos renováveis per capita

#### 5.2.1. Definição operacional e alcance hidrológico

Embora conserve a denominação de referência **recursos hídricos renováveis per capita**, o `INF02` implementado no PRAIS_BRASIL corresponde, mais precisamente, à **contribuição incremental superficial estimada a partir de dados ANA/BHO 50K, redistribuída à unidade territorial de 2025 e expressa por habitante do recorte censitário**.

A estimativa é **parcial e condicionada à cobertura dos dados**: não representa automaticamente o volume total renovável disponível em cada município, a água subterrânea, a oferta regularizada, a infraestrutura efetivamente instalada ou a disponibilidade utilizável durante um evento de seca. Essas restrições devem acompanhar qualquer utilização posterior do indicador.

#### 5.2.2. Etapa E01 — Municipalização da contribuição hidrológica

A E01 é uma operação territorial única, independente do ano censitário. Sua entrada hidrológica é a contribuição incremental superficial `Qmltinc` estimada pela ANA, em m³/s, associada às unidades da BHO 50K previamente preparadas e verificadas.

A municipalização atribui a cada unidade municipal ou equivalente \(m\) uma parcela de vazão incremental proporcional à área de interseção com cada unidade hidrográfica \(j\):

$$
Q^{inc,parcial}_{m}=\sum_{j\in\mathcal{J}_{est}}
Q^{inc}_{j}\,\frac{A(BHO_j\cap m)}{A(BHO_j)},
$$

onde \(\mathcal{J}_{est}\) inclui as contribuições com estimativa ANA utilizável, \(Q^{inc}_{j}\) é a contribuição incremental atribuída à unidade \(j\), e \(A(BHO_j)\) é sua **área geométrica integral**, inclusive a parcela fora do território brasileiro quando existente. A área de interseção com a unidade municipal constitui o numerador da fração espacial.

As operações espaciais utilizam `sf`, cálculo de áreas em **EPSG:6933** e `sf_use_s2(FALSE)`. O processamento por UF e blocos registra checkpoints, reconcilia áreas e contribuições e mantém **duas áreas operacionais do Rio Grande do Sul separadas** das 5.571 unidades utilizadas no indicador.

Contribuições marcadas como não estimadas pela ANA **não são imputadas como zero**. A vazão parcial municipal resulta apenas das parcelas com contribuição válida; caso não haja estimativa utilizável, o valor hidrológico municipal permanece ausente. Quando existe contribuição parcial, mas a cobertura é incompleta ou há fontes não estimadas, o valor é conservado com ressalva em `situacao_qualidade`.

O processamento gera a base `INF02_E01_contribuicao_incremental_municipal_IBGE2025`, as correspondências espaciais, os registros das áreas operacionais e os relatórios de controle por UF e nacional.

#### 5.2.3. Etapa E02 — Associação da população censitária

A E02 associa à base hidrológica de 2025 a **população total residente** obtida por município no IBGE/SIDRA:

| Recorte | Tabela SIDRA | Populações municipais válidas na origem | Referência demográfica |
|---|---:|---:|---|
| 2000 | 202 | 5.507 | População total residente do Censo 2000 |
| 2010 | 202 | 5.565 | População total residente do Censo 2010 |
| 2022 | 4709 | 5.570 | População total residente do Censo 2022 |

Para 2000, a resposta da Tabela 202 também contém registros sem informação referente ao recorte; eles não são transformados em população zero. Os JSONs da API são preservados localmente, e a leitura verifica códigos municipais, período, quantidades válidas e totais nacionais.

A associação é realizada por **coincidência de geocódigo**, mantendo os registros sem correspondência e informando os códigos existentes apenas em uma das duas referências. **Não é efetuada harmonização geográfica ou redistribuição retrospectiva da população** em função das alterações de limites.

#### 5.2.4. Etapa E03 — Cálculo per capita e disponibilização

Para município ou equivalente \(m\) e recorte censitário \(t\), calcula-se:

$$
INF02_{m,t}=\frac{Q^{inc,parcial}_{m}\times31\,536\,000}{P^{censo}_{m,t}},
$$

em que \(Q^{inc,parcial}_{m}\) é a vazão incremental superficial municipalizada em m³/s, \(31\,536\,000\) corresponde aos segundos de um ano de 365 dias e \(P^{censo}_{m,t}\) é a população residente **total** associada por código municipal. A unidade é **m³/habitante/ano**.

Um valor é disponibilizado quando há população finita e positiva, contribuição incremental estimada finita e não negativa e ausência de alteração territorial conhecida que impeça sua utilização. Vazão negativa, contribuição não estimada, população ausente e as incompatibilidades territoriais explicitamente bloqueadas **não são corrigidas por imputação, truncamento ou redistribuição**.

O indicador é replicado, sem alteração do valor ou dos metadados, nos registros Total, Masculino e Feminino. Assim, \(INF02_{m,t,Total}=INF02_{m,t,Masculino}=INF02_{m,t,Feminino}\) por construção, **não por igualdade observada entre grupos**.

#### 5.2.5. Qualidade, status de cálculo e ressalvas territoriais

A E03 mantém no produto municipal o `status_calculo`, `situacao_qualidade` e `compatibilidade_territorial`. Os **cinco estados efetivamente produzidos** em `status_calculo` são:

| `status_calculo` | Interpretação operacional |
|---|---|
| `CALCULADO_SEM_HARMONIZACAO_TERRITORIAL` | Valor disponível, calculado sob associação por código e com ressalva territorial |
| `DIVISAO_TERRITORIAL_ALTERADA_2025` | Cálculo não disponibilizado em município de origem afetado por alteração territorial conhecida |
| `Q_NEGATIVA_NAO_INTERPRETAVEL` | Contribuição municipal estimada negativa, não convertida artificialmente em zero |
| `SEM_CONTRIBUICAO_ESTIMADA` | Ausência de contribuição hidrológica utilizável |
| `SEM_POPULACAO_CENSITARIA` | Denominador censitário ausente ou inválido para o código na referência utilizada |

O campo `situacao_qualidade` diferencia, entre outras condições, estimativas sem ressalva espacial, estimativas com fontes ANA não estimadas e estimativas com cobertura espacial incompleta. **Ter um valor numérico de `INF02` não implica ausência dessas ressalvas.** O campo `compatibilidade_territorial` explicita a coincidência de códigos sem harmonização, a alteração territorial conhecida ou a ausência de população no recorte.

A expressão `CALCULADO_COM_RESSALVA_NAO_HARMONIZADO`, utilizada no **QA geral da E03**, sintetiza a situação do produto e **não substitui** `CALCULADO_SEM_HARMONIZACAO_TERRITORIAL`, que é o status dos registros municipais com valor disponível.

#### 5.2.6. Produtos intermediários e promoção ao bruto

A E03 preserva, separadamente, a tabela municipal detalhada, a tabela longa dos três grupos e o QA por ano. A promoção aos produtos brutos é **explícita** e não reprocessa as etapas E01 e E02. O sistema verifica produtos preexistentes e interrompe a execução em caso de divergência, evitando sobrescrita silenciosa.

O processador integrado do `main.R` **não recalcula nem promove a E03**: ele exige os pares RDS/CSV já promovidos, verifica seu contrato e reutiliza os valores e metadados existentes.

## 6. Controle de qualidade e validação

### 6.1. Verificações comuns

As rotinas conferem identificadores, unicidade das chaves `ano`–`cod_mun`–`grupo`–`indicador`, integridade das unidades, ausência de infinitos e compatibilidade dos valores com as respectivas definições. A avaliação é feita sobre os **produtos brutos**, não sobre índices ou classificações de vulnerabilidade.

Os arquivos são preservados quando já existem e coincidem com os produtos de referência; divergências devem gerar diagnóstico, não substituição automática.

### 6.2. Verificações específicas do `INF01_REDE_CANALIZADA`

Foram realizados inventários de variáveis, testes de vinculação de Pessoas e Domicílios, conciliação de pesos e moradores, pilotos ponderados, conferência dos seis componentes, validação dos percentuais e produção nacional para os três recortes.

| Recorte | UFs | Municípios | Registros município–grupo | Situação da comparação externa |
|---|---:|---:|---:|---|
| 2000 | 27 | 5.507 | 16.521 | Confronto municipal com a Tabela SIDRA 2420 aprovado para Total |
| 2010 | 27 | 5.565 | 16.695 | Não realizada; aprovação computacional sem comparação externa integral |
| 2022 | 27 | 5.570 | 16.710 | Confronto exploratório com SIDRA 6909, com ressalva nos valores absolutos extraídos |

Os resultados nacionais Total documentados são **70,30778% em 2000** e **81,84727% em 2022**. O percentual nacional de 2010 deve ser recuperado do QA aprovado antes de eventual transcrição; não é estimado neste README.

Em 2000 e 2022, foram mantidos, respectivamente, **87** e **9** municípios com numerador Total igual a zero, sem exclusão automática.

**Ressalva de 2022:** a consulta exploratória à SIDRA 6909 apresentou erro absoluto médio municipal de **0,7368 ponto percentual** e correlação de Pearson de **0,998789** frente ao indicador calculado. Contudo, a soma dos denominadores da extração foi **404.166.040**, exatamente o dobro da referência publicada de **202.083.020**. Como a origem da duplicação não foi esclarecida, os totais absolutos extraídos **não foram validados** e não sofreram correção automática. O QA de produção conserva `validacao_externa = "PENDENTE"`. Esse diagnóstico não invalida a aprovação computacional do INF01.

### 6.3. Verificações específicas do `INF02_RECURSOS_HIDRICOS_PC`

**E01 — Hidrologia e território.** São controlados geometria, áreas de interseção, identificação de trechos, segregação de fontes não estimadas, repartição de vazões, presença de 27 UFs, conservação da contribuição entre pares espaciais e unidades territoriais, conciliação nacional e integridade dos checkpoints. As duas áreas operacionais do RS não são confundidas com municípios. Os relatórios `INF02_E01_qa_ufs.csv` e `INF02_E01_qa_nacional.csv` documentam esses controles.

**E02 — População.** São verificados a cardinalidade municipal, a soma das populações da fonte, a associação por código, os códigos sem correspondência e os MD5 da base hidrológica e das respostas SIDRA preservadas.

**E03 — Cálculo e produtos.** São verificados os pré-requisitos da E01 e E02, a consistência dos valores de vazão e população, as regras de `NA`, a igualdade do valor territorial nos três grupos, a unicidade de chaves, os estados de cálculo e a identidade dos produtos promovidos. Os pares RDS/CSV são comparados pelo processador de integração, que registra MD5, cobertura e justificativas das ausências. A verificação é **de integridade computacional e consistência com a E03**, não uma nova validação hidrológica independente.

### 6.4. Cobertura territorial e estados da E03

A validação isolada e a integração `INF01` + `INF02` pelo `main.R` foram aprovadas para 2000, 2010 e 2022. Para o `INF02`, cada recorte apresenta **5.571 unidades territoriais de referência** e **16.713 registros município–grupo**.

| Estado municipal do `INF02` (por grupo, sem triplicar as contagens) | 2000 | 2010 | 2022 |
|---|---:|---:|---:|
| `CALCULADO_SEM_HARMONIZACAO_TERRITORIAL` | 5.493 | 5.551 | 5.556 |
| `DIVISAO_TERRITORIAL_ALTERADA_2025` | 2 | 2 | 2 |
| `Q_NEGATIVA_NAO_INTERPRETAVEL` | 2 | 2 | 2 |
| `SEM_CONTRIBUICAO_ESTIMADA` | 10 | 10 | 10 |
| `SEM_POPULACAO_CENSITARIA` | 64 | 6 | 1 |
| **Total de unidades** | **5.571** | **5.571** | **5.571** |
| **Valores ausentes (`NA`)** | **78** | **20** | **15** |

Essas contagens descrevem **disponibilidade e situação do produto bruto**, não frequências de municípios classificados como vulneráveis ou não vulneráveis.

### 6.5. Integridade dos arquivos e limites da validação

O inventário e a validação local confirmaram a presença dos pares brutos RDS/CSV da E03, sua estrutura de **12 colunas**, as quantidades previstas, os três grupos e a preservação de metadados territoriais e de qualidade. Os MD5 coincidiram entre o inventário e a verificação posterior para cada ano.

A aprovação de consistência entre arquivos **não** soluciona a ausência de harmonização territorial; tampouco constitui validação independente das estimativas hidrológicas ou demonstra precisão amostral completa do `INF01`.

## 7. Limitações e cuidados de interpretação

| Aspecto | Implicação |
|---|---|
| **Alcance conceitual** | A dimensão reúne condições relevantes à caracterização da vulnerabilidade; **não é medida autônoma de vulnerabilidade à seca**, risco, resiliência ou impacto. |
| **Cobertura por rede (`INF01`)** | Rede geral e canalização não demonstram potabilidade, continuidade, qualidade, disponibilidade efetiva ou desempenho do abastecimento sob seca. |
| **Universo amostral (`INF01`)** | As proporções derivam de microdados amostrais ponderados; controles de pesos e componentes não equivalem a intervalos de confiança municipais. |
| **Diferenças censitárias (`INF01`)** | Questionários e categorias de abastecimento possuem particularidades entre 2000, 2010 e 2022. |
| **Valores nulos (`INF01`)** | Numerador zero não demonstra inexistência física de rede e canalização em todas as localidades do município. |
| **Contribuição superficial (`INF02`)** | A vazão incremental superficial estimada não é o volume total renovável disponível, a água captável, a oferta regularizada ou a disponibilidade por usuário. |
| **Cobertura hidrológica (`INF02`)** | Parte dos valores utilizáveis possui ressalvas por lacunas de estimativa ou cobertura; o valor numérico não significa cobertura integral. |
| **Referência temporal (`INF02`)** | A hidrologia ANA/BHO e a malha 2025 são fixas nos três recortes; mudanças no resultado não comprovam mudanças observadas na vazão. |
| **Associação territorial (`INF02`)** | Coincidência de códigos municipais não implica equivalência dos limites de 2000, 2010, 2022 e 2025. |
| **Confronto entre indicadores** | O `INF01` opera na referência de cada Censo, enquanto o `INF02` usa 2025; combinar tabelas por código não garante equivalência espacial. |
| **Grupos populacionais** | `INF02` é compartilhado entre Total, Masculino e Feminino; a igualdade entre registros é estrutural, não uma observação por sexo. |
| **Ausências** | `NA` deve preservar sua justificativa; não equivale a vazão zero, ausência de população ou classificação automática de vulnerabilidade. |
| **Agregação municipal** | Valores municipais podem ocultar desigualdades intramunicipais de acesso, gestão e distribuição da água. |
| **Dados restritos** | Microdados censitários de acesso controlado, checkpoints e resultados derivados sujeitos a restrições não podem ser redistribuídos automaticamente. |
| **Integração ao DVI** | Orientação, escalas, normalização, pesos, agregação e sensibilidade serão definidos em etapa posterior; nenhum deles é aplicado aqui. |

## 8. Produtos, rastreabilidade e reprodutibilidade

### 8.1. Produtos municipais brutos e contratos

Os resultados individuais estão organizados em `so3.3/outputs/bruto/infraestrutural/<ano>/`, com um arquivo **RDS** e um arquivo **CSV** para cada indicador e recorte:

- `INF01_REDE_CANALIZADA_<ano>.rds` e `.csv`;
- `INF02_RECURSOS_HIDRICOS_PC_<ano>.rds` e `.csv`.

O contrato CSV básico do `INF01` contém:

```text
ano;uf;cod_mun;nm_mun;indicador;grupo;valor
```

O contrato CSV/RDS **longo** promovido da E03 para o `INF02` contém 12 campos:

```text
ano;uf;cod_mun;nm_mun;indicador;grupo;valor;unidade;tipo_desagregacao;status_calculo;situacao_qualidade;compatibilidade_territorial
```

O RDS do `INF01` preserva adicionalmente componentes de cálculo, como numerador e denominador por registro. A tabela municipal detalhada do `INF02`, anterior à promoção, mantém também contribuições, população e outras informações de controle. **Os contratos dos dois indicadores não devem ser apresentados como idênticos**: a posterior integração estatística deverá reconhecer os campos compartilhados e preservar os metadados adicionais.

### 8.2. Organização do processamento e dos módulos

A unidade operacional do `main.R` é **uma dimensão e um ano por execução**. Os dois indicadores infraestruturais são processados ou validados conjuntamente, preservando suas responsabilidades próprias.

| Responsabilidade | Módulo do repositório |
|---|---|
| Leitura/adaptação INF01 | [`adaptar_censo_2000_infraestrutural.R`](../../R/01_leitura/adaptar_censo_2000_infraestrutural.R), [`adaptar_censo_2010_infraestrutural.R`](../../R/01_leitura/adaptar_censo_2010_infraestrutural.R) |
| Definição/cálculo INF01 | [`inf01_agua_rede_canalizada.R`](../../R/02_indicadores/inf01_agua_rede_canalizada.R), [`inf01_2010_pessoas.R`](../../R/02_indicadores/inf01_2010_pessoas.R) |
| Validação INF01 | [`validar_inf01.R`](../../R/03_diagnostico/validar_inf01.R), [`validar_inf01_2010.R`](../../R/03_diagnostico/validar_inf01_2010.R), [`validar_inf01_2022.R`](../../R/03_diagnostico/validar_inf01_2022.R) |
| Produção e promoção INF01 | [`processar_inf01.R`](../../R/04_execucao/processar_inf01.R), [`processar_inf01_2010.R`](../../R/04_execucao/processar_inf01_2010.R), [`processar_inf01_2022.R`](../../R/04_execucao/processar_inf01_2022.R) |
| Leitura populacional INF02/E02 | [`ler_populacao_censitaria_inf02.R`](../../R/01_leitura/ler_populacao_censitaria_inf02.R) |
| Municipalização INF02/E01 | [`processar_inf02_municipalizacao.R`](../../R/04_execucao/processar_inf02_municipalizacao.R) |
| Associação INF02/E02 | [`processar_inf02_etapa02.R`](../../R/04_execucao/processar_inf02_etapa02.R) |
| Cálculo/promocão INF02/E03 | [`processar_inf02_etapa03.R`](../../R/04_execucao/processar_inf02_etapa03.R) |
| Reutilização/validação INF02 | [`processar_inf02.R`](../../R/04_execucao/processar_inf02.R) |
| Executores da cadeia INF02 | [`executar_inf02_etapa01.R`](../../executar_inf02_etapa01.R), [`executar_inf02_etapa02.R`](../../executar_inf02_etapa02.R), [`executar_inf02_etapa03.R`](../../executar_inf02_etapa03.R) |
| Integração da dimensão | [`main.R`](../../main.R) |
| Inventário local da E03 | [`diagnosticar_inf02_e03.R`](../../tests/diagnosticar_inf02_e03.R) |

### 8.3. Sequência operacional e salvaguardas

Os produtos **já aprovados** devem ser reutilizados. Os comandos abaixo descrevem a sequência de reprodução **quando necessária e quando os insumos autorizados estiverem disponíveis**, e não uma instrução para recalcular ou sobrescrever os resultados existentes.

**Preparação e municipalização hidrológica (E01):** são necessários os insumos espaciais ANA/BHO previamente preparados e a malha IBGE 2025. Os caminhos podem ser passados como argumentos ou declarados em `so3.3/config/config_local.R`, cujo [exemplo versionado](../../config/config_local.R.example) não contém dados locais.

```bash
Rscript so3.3/executar_inf02_etapa01.R "/CAMINHO/INFO2" "/CAMINHO/BR_Municipios_2025.shp" completo
```

**Associação populacional e cálculo (E02/E03):**

```bash
Rscript so3.3/executar_inf02_etapa02.R completo
Rscript so3.3/executar_inf02_etapa03.R completo
# Promocao aos pares brutos somente apos validar os produtos intermediarios:
Rscript so3.3/executar_inf02_etapa03.R completo promover
```

**Integração para um recorte (INF01 + INF02):** executar na raiz do repositório, em sessão R com os produtos brutos e dependências disponíveis:

```r
DIMENSAO_ATIVA <- "infraestrutural"
ANO_ATIVO <- 2022L  # ou 2000L / 2010L
FORCAR_RECALCULO <- FALSE
source("so3.3/main.R")

stopifnot(isTRUE(resultado_execucao$integral))
resultado_execucao$indicadores$INF01$status
resultado_execucao$indicadores$INF02$status
resultado_execucao$indicadores$INF02$qa
```

O `main.R` exige que os pares brutos da E03 já existam e valida o `INF02` **antes de executar o processador do INF01**. A integração não aplica transformação estatística nem harmonização geográfica. Os processadores bloqueiam sobrescritas divergentes e o `main.R` rejeita `FORCAR_RECALCULO = TRUE` nessa dimensão.

**Particularidade da E01:** os checkpoints preservam uma identidade dependente do conteúdo do módulo e de metadados e caminhos dos insumos. Alterações no processador, movimentação de arquivos ou mudanças de ambiente podem invalidar a possibilidade de retomada automática; não se deve modificar o processador aprovado apenas para ajustes editoriais.

### 8.4. Proveniência, ambiente e reprodução condicionada

A reprodução dos valores brutos exige acesso legítimo às fontes e ao ambiente adequados:

- **INF01:** microdados censitários, versões corretas das variáveis e dos pesos e, em 2022, autorização específica para dados de acesso controlado.
- **INF02/E01:** malha IBGE 2025, BHO 50K integrada e **insumos hidrológicos anteriormente preparados**, incluindo tabelas de correspondência e balanço. Os sete scripts E01–E03 versionados **não reconstituem, por si, toda a preparação anterior a E01 a partir das fontes primárias ANA**.
- **INF02/E02:** respostas da API SIDRA e seus JSONs locais correspondentes à versão efetivamente utilizada; as referências de código e de população são verificadas na leitura.
- **Ambiente:** R e bibliotecas pertinentes, incluindo `data.table`, `sf`, `DBI`, `RSQLite`, `jsonlite`, além das dependências censitárias e da pilha espacial GDAL/GEOS/PROJ. A execução em ambiente distinto requer nova conferência de compatibilidade espacial e de checkpoints.

A procedência dos insumos preparados da E01, as respectivas assinaturas e as condições de acesso devem ser preservadas em manifesto ou registro técnico associado, **sem publicar automaticamente arquivos binários, insumos restritos ou produtos intermediários**. A auditoria de implementação está registrada em [`AUDITORIA_ESTATICA_INF02_E01_E03.md`](AUDITORIA_ESTATICA_INF02_E01_E03.md).

Essa distinção separa **transparência metodológica**, **reprodução condicionada ao acesso autorizado** e **uso dos resultados municipais já produzidos**. A integração dos indicadores brutos não autoriza, por si só, a divulgação de microdados ou de qualquer derivado submetido a restrições.

## 9. Referências bibliográficas e documentais

### 9.1. Enquadramento institucional e conceitual

- **PRAIS_BRASIL / CEMADEN.** *Nota Técnica — Bases de dados, procedimentos metodológicos e limitações na caracterização da ameaça, exposição e vulnerabilidade à seca no Brasil.* Versão preliminar revisada para discussão técnica, outubro de 2026. Referência de enquadramento; não substitui os registros de produção posteriores.
- **FAO — Food and Agriculture Organization of the United Nations.** *Drought Portal — Vulnerability and Impact Assessment Compendium: Context; Guidelines; Indicators and Data Sources.* Referência para a seleção e a contextualização dos indicadores de vulnerabilidade à seca.
- **UNCCD — United Nations Convention to Combat Desertification.** *PRAIS4 Reporting Manual.* Referência institucional de orientação ao reporte do SO3.3, edição empregada no projeto.
- **Crossman, N. D.; Tsegai, D. / UNCCD.** (2019). *Drought Resilience, Adaptation and Management Policy Framework: Supporting Technical Guidelines.* Referência complementar de enquadramento conceitual da avaliação de seca.

### 9.2. Fontes estatísticas, censitárias e hidrológicas

- **IBGE.** *Censos Demográficos de 2000, 2010 e 2022:* microdados da amostra, questionários, dicionários e notas metodológicas correspondentes.
- **IBGE/SIDRA.** Tabelas **2420** e **6909** (comparações relacionadas ao `INF01`, segundo as ressalvas documentadas); tabelas **202** (2000 e 2010) e **4709** (2022), população residente total do `INF02`.
- **IBGE.** Malha municipal de **2025**, referência geométrica e cadastral utilizada na E01 do `INF02`.
- **ANA — Agência Nacional de Águas e Saneamento Básico.** Base Hidrográfica Ottocodificada (**BHO 50K**) e informações de contribuição incremental superficial `Qmltinc` utilizadas na cadeia de preparação hidrológica do projeto.
- **`censobr`.** Pacote R utilizado para leitura das bases censitárias de 2000 e 2010 nos procedimentos do `INF01`.

### 9.3. Documentos e registros internos de rastreabilidade

- [`so3.3/docs/social/README.md`](../social/README.md) — convenções conceituais e metodológicas da dimensão Social.
- [`so3.3/docs/economica/README.md`](../economica/README.md) — convenções conceituais e metodológicas da dimensão Econômica.
- [`AUDITORIA_ESTATICA_INF02_E01_E03.md`](AUDITORIA_ESTATICA_INF02_E01_E03.md) — auditoria estática, procedência da cadeia e salvaguardas de versionamento do `INF02`.
- [`INVENTARIO_VERSIONAMENTO.md`](INVENTARIO_VERSIONAMENTO.md) — inventário histórico de versionamento da dimensão.
- Documentação operacional de produção do `INF01` (2010 e 2022) e das etapas E01/E02 do `INF02`, mantida nos registros locais do projeto até sua incorporação seletiva ao repositório.

---

*Documentação conceitual e metodológica aprovada para a dimensão Infraestrutural em novembro de 2026. Este documento não estabelece orientação, transformação, normalização, ponderação ou agregação dos indicadores e **não atribui à dimensão o significado de vulnerabilidade à seca isoladamente**.*