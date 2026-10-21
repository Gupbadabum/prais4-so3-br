# SO3.3 — Dimensão Econômica

**PRAIS_BRASIL | Documentação conceitual e metodológica dos indicadores municipais**  
**Referência do projeto:** *Performance Review and Assessment of Implementation System* (PRAIS), Objetivo Estratégico 3 (SO3), produto SO3.3.  
**Estado do documento:** versão aprovada para inclusão no repositório — outubro de 2026.  
**Localização no repositório:** `so3.3/docs/economica/README.md`.

> **Delimitação:** este documento apresenta a dimensão Econômica e os procedimentos de produção dos seus indicadores municipais **brutos**. Não documenta nem antecipa regras de tratamento estatístico, normalização, ponderação ou composição dos índices dimensionais e do DVI, ainda não implementadas nesta etapa. A dimensão Econômica, isoladamente, **não constitui uma medida de vulnerabilidade à seca**.

## 1. Apresentação

### 1.1. A dimensão Econômica no contexto da vulnerabilidade à seca

A dimensão Econômica reúne indicadores relacionados às condições monetárias da população, à atividade econômica municipal e à participação da agropecuária na composição da economia local.

Essas informações permitem caracterizar diferenças econômicas entre municípios brasileiros. Sua contribuição deve ser interpretada em conjunto com as demais dimensões previstas para a construção do índice, sem atribuir à dimensão Econômica, isoladamente, a condição de medida de vulnerabilidade.

### 1.2. Objetivo e abrangência da dimensão

O objetivo da dimensão Econômica é caracterizar, em escala municipal, aspectos das condições monetárias da população e da estrutura econômica dos municípios brasileiros, considerando os recortes analíticos de **2000, 2010 e 2022** definidos para o PRAIS_BRASIL.

As fontes não apresentam necessariamente informações observadas nesses mesmos anos. As correspondências entre ano PRAIS e ano-fonte são explicitadas para cada indicador.

A desagregação entre os grupos **Total**, **Masculino** e **Feminino** é considerada conforme a natureza da informação, distinguindo atributos populacionais de características econômicas territoriais.

### 1.3. Relação com o DVI

Os indicadores econômicos constituem um dos conjuntos de informações previstos para a construção do **Índice de Vulnerabilidade à Seca** (*Drought Vulnerability Index* — **DVI**). A representação calculada da vulnerabilidade à seca é atribuída à integração posterior das dimensões Social, Econômica e Infraestrutural, observadas as limitações do modelo.

## 2. Fundamentação conceitual da dimensão Econômica

### 2.1. Caracterização da dimensão Econômica

A dimensão Econômica organiza informações sobre condições monetárias da população e características da economia municipal. A seleção parte do referencial FAO/UNCCD adotado no SO3.3, com adaptações à disponibilidade e às definições das fontes brasileiras.

O conjunto operacional contempla três propriedades distintas: incidência da pobreza monetária, produto econômico por habitante e participação agropecuária no produto municipal. Essas propriedades não representam manifestações equivalentes de um único fenômeno e **não constituem medidas independentes de vulnerabilidade**.

### 2.2. Condições monetárias e estrutura econômica municipal

A incidência da pobreza monetária caracteriza a parcela da população situada abaixo de um limiar predefinido de renda domiciliar per capita. A definição não abrange, por si, dimensões não monetárias da pobreza.

O Produto Interno Bruto (PIB) per capita expressa a produção econômica municipal em relação à população de referência. **Não equivale à renda efetivamente recebida pelos moradores nem informa sua distribuição.**

A participação da agropecuária no PIB descreve a composição setorial da economia municipal. Não identifica diretamente dependência hídrica, renda agrícola familiar, área irrigada ou impactos associados à seca.

Assim, os três indicadores oferecem perspectivas complementares de caracterização, sem pressupor relações causais diretas entre suas magnitudes e os efeitos de eventos de seca.

### 2.3. Alcance e limites da representação das condições econômicas

A caracterização municipal combina informações sobre pessoas e domícilios com estatísticas das contas econômicas territoriais. Essa diferença de natureza afeta a interpretação dos grupos populacionais e a comparação entre períodos.

Somente a incidência da pobreza monetária é efetivamente calculada de modo distinto para as populações masculina e feminina. O PIB per capita e a participação agropecuária são atributos municipais comuns aos três grupos.

A agregação municipal não permite identificar automaticamente desigualdades internas entre pessoas, famílias e localidades. Tampouco os indicadores medem diretamente capacidade adaptativa, resiliência ou impactos observados da seca.

## 3. Composição da dimensão

### 3.1. Seleção e delimitação

A composição operacional incorpora três indicadores de referência para o SO3.3, adequados às fontes nacionais e aos recortes territoriais e temporais estabelecidos para o PRAIS_BRASIL.

| Código | Indicador | Unidade | Natureza da informação | Grupos |
|---|---|---|---|---|
| `ECO01_POV3_PPC21` | População abaixo da linha internacional de pobreza | % | Condição monetária atribuída às pessoas | Total, Masculino, Feminino; desagregação efetiva |
| `ECO02_PIBPC` | PIB municipal per capita | R$ de 2010 por habitante | Produção econômica territorial | Mesmo valor nos três grupos |
| `ECO03_AGROPIB` | Participação da agropecuária no PIB | % | Composição econômica territorial | Mesmo valor nos três grupos |

O `ECO01_POV3_PPC21` utiliza a linha de **US$ 3,00 internacionais por pessoa/dia, em PPC de 2021**, convertida para reais da referência monetária censitária. O `ECO02_PIBPC` utiliza PIB per capita oficial do IBGE, convertido para preços de 2010. O `ECO03_AGROPIB` relaciona VAB agropecuário e PIB do mesmo município e ano-fonte.

### 3.2. Indicadores não operacionalizados nesta versão

**Consumo de energia per capita**, considerado entre os indicadores econômicos de referência para o SO3.3, **não integra a versão operacional atual**. Sua menção documenta a delimitação do escopo e não antecipa avaliação de viabilidade ou inclusão futura.

### 3.3. Complementaridade dos indicadores

A pobreza monetária, o PIB per capita e a participação agropecuária descrevem propriedades diferentes. Municípios com produção econômica por habitante semelhante podem apresentar incidências distintas de pobreza; da mesma forma, participações agropecuárias semelhantes não implicam igual distribuição de renda ou dependência hídrica.

A complementaridade do conjunto **não demonstra independência estatística, equivalência conceitual ou direção de efeito sobre a vulnerabilidade à seca**. Essas questões pertencem às etapas posteriores de diagnóstico e composição do índice.

## 4. Fontes de dados e harmonização

### 4.1. Fontes utilizadas

Os indicadores combinam os microdados da amostra dos Censos Demográficos de 2000, 2010 e 2022 com estatísticas econômicas oficiais do IBGE e do Sistema IBGE de Recuperação Automática (SIDRA).

| Indicador | Fonte | Informação utilizada |
|---|---|---|
| `ECO01_POV3_PPC21` | Censos Demográficos IBGE | Rendimento domiciliar per capita, sexo e pesos amostrais |
| `ECO01_POV3_PPC21` | SIDRA, Tabela 1737 | Índices mensais do IPCA para conversão monetária |
| `ECO02_PIBPC` | PIB dos Municípios — IBGE | PIB per capita oficial a preços correntes |
| `ECO02_PIBPC` | SIDRA, Tabela 6784 | Variação anual do deflator implícito do PIB |
| `ECO03_AGROPIB` | SIDRA, Tabela 5938 | PIB municipal e VAB da agropecuária |

As fontes censitárias e as estatísticas econômicas territoriais possuem definições e procedimentos de produção distintos. Sua combinação no SO3.3 **não as converte em observações de mesma natureza**.

### 4.2. Informações censitárias para o ECO01

**Censo 2000.** O adaptador associa os registros de Pessoas e Domicílios por chave domiciliar e constrói a renda domiciliar per capita, para domicílios particulares, a partir do rendimento `V7616` e do número de moradores `V7100`, ajustado pela contagem das categorias `V0402` de códigos 9, 10 e 11 prevista na implementação. Esses registros pessoais não são automaticamente excluídos do universo populacional. Nos domicílios coletivos, a renda domiciliar per capita permanece ausente, sem imputação.

**Censo 2010.** Utiliza a variável `V6531` de rendimento domiciliar per capita, presente nos registros de Pessoas, com o peso amostral individual `V0010` e a identificação do sexo.

**Censo 2022.** Utiliza os microdados de acesso controlado: a renda domiciliar per capita `D0360`, obtida do registro de Domicílios, é associada ao registro de Pessoas por chave de município e controle domiciliar. Os pesos `P0111` e o sexo `P0160` são obtidos dos registros individuais. Não há imputação de renda ausente.

Após essas operações, os dados necessários ao cálculo do `ECO01_POV3_PPC21` seguem uma estrutura canônica comum:

`ano`, `uf`, `cod_mun`, `peso`, `sexo`, `rdpc`.

Rendas iguais a zero permanecem válidas; rendas ausentes não são convertidas em zero. A origem e a competência monetária da informação devem ser consideradas na comparação entre recortes.

### 4.3. Fontes econômicas municipais

O `ECO02_PIBPC` utiliza diretamente valores oficiais de PIB per capita nas planilhas históricas do IBGE `pib_municipios_2002_2009.xlsx` e `pib_municipios_2010_2023.xlsx`. A etapa de leitura preserva os valores correntes originais; a conversão para preços de 2010 é realizada no cálculo do indicador.

O `ECO03_AGROPIB` utiliza as informações de PIB e VAB agropecuário disponibilizadas na Tabela 5938 do SIDRA. Para a razão percentual, numerador e denominador são selecionados no **mesmo ano-fonte e município**, sem aplicar deflator.

A leitura das fontes inclui verificações de estrutura, unidades, anos, identificação municipal e estados de disponibilidade. O tratamento de símbolos do SIDRA distingue valor numérico, zero absoluto, indisponibilidade, não aplicabilidade e sigilo; essas situações não são indiscriminadamente convertidas para zero.

### 4.4. Correspondência temporal

Os recortes PRAIS organizam informações produzidas em diferentes anos-fonte:

| Recorte PRAIS | `ECO01_POV3_PPC21` | `ECO02_PIBPC` | `ECO03_AGROPIB` |
|---|---:|---:|---:|
| 2000 | 2000 | 2002 | 2002 |
| 2010 | 2010 | 2010 | 2010 |
| 2022 | 2022 | 2022 | 2021 |

As correspondências de 2002 e 2021 representam escolhas operacionais de ano-fonte dentro dos recortes analíticos; **não constituem estimativas de variáveis observadas nos anos censitários aos quais foram associadas**.

No recorte de 2022, `ECO02_PIBPC` usa PIB per capita de 2022, enquanto `ECO03_AGROPIB` emprega PIB e VAB de 2021. Esses resultados não devem ser interpretados como grandezas econômicas estritamente simultâneas.

### 4.5. Unidade territorial e grupos populacionais

Os indicadores são organizados por município e recorte temporal, utilizando códigos municipais de sete dígitos, com cobertura operacional de **5.507 municípios em 2000, 5.565 em 2010 e 5.570 em 2022**.

As fontes econômicas são associadas aos universos territoriais definidos para cada recorte PRAIS. Os nomes municipais acrescentados aos CSVs provêm de referência cadastral do IBGE de 2025, apenas para identificação, sem converter os recortes históricos em uma malha municipal constante.

O `ECO01_POV3_PPC21` é efetivamente estimado para os grupos Total, Masculino e Feminino. Em `ECO02_PIBPC` e `ECO03_AGROPIB`, o mesmo atributo territorial é reproduzido para os três grupos, com identificação de escopo `comum_municipal` nos objetos operacionais; isso **não corresponde a uma desagregação econômica por sexo**.

## 5. Metodologia dos indicadores

### 5.1. `ECO01_POV3_PPC21` — População abaixo da linha internacional de pobreza

#### 5.1.1. Definição operacional

**Definição operacional.** Percentual ponderado de pessoas com renda domiciliar per capita inferior à linha internacional de pobreza de **US$ 3,00 internacionais por pessoa/dia, em PPC de 2021**, entre as pessoas com informação de RDPC válida.

Para município \(m\), grupo \(g\) e recorte \(t\):

$$
ECO01_{m,g,t}=100\times
\frac{\sum_{i\in U_{m,g,t}}w_i\,I(RDPC_i<L_t)}
{\sum_{i\in U_{m,g,t}}w_i},
$$

em que \(w_i\) é o peso amostral da pessoa, \(RDPC_i\) é a renda domiciliar per capita atribuída à pessoa, \(L_t\) é a linha convertida para reais do período censitário e \(U\) inclui exclusivamente pessoas com RDPC válida. A função \(I(\cdot)\) assume 1 quando a condição é satisfeita e 0 em caso contrário.

A regra utiliza a desigualdade **estrita** \(RDPC_i<L_t\): renda igual ao limiar não é classificada como pobreza. A RDPC igual a zero constitui informação válida.

A classificação é feita com base na renda **domiciliar per capita**, não na renda individual recebida por cada residente. O indicador não mede privações não monetárias.

#### 5.1.2. Conversão monetária da linha de pobreza

A linha em reais mensais de 2021 é obtida conforme os parâmetros implementados em `preparar_referencias_eco01.R`:

$$
L_{2021}=3,00\times 2,44983620\times\frac{365}{12}.
$$

O fator `2.44983620` é utilizado como conversor Brasil para PPC de 2021, expresso em reais por dólar internacional; \(365/12\) representa a duração média mensal adotada. **Não se utiliza taxa de câmbio comercial.** A procedência documental exata do fator permanece explicitada como verificação na seção 9.3.

A linha é convertida para o período monetário associado a cada Censo por meio dos índices do IPCA da Tabela 1737 do SIDRA:

$$
L_t=L_{2021}\times
\frac{IPCA_{t,7}}{\overline{IPCA}_{2021}},
$$

em que \(IPCA_{t,7}\) é o número-índice de julho do ano censitário e \(\overline{IPCA}_{2021}\) corresponde à média aritmética dos doze números-índice mensais de 2021.

A implementação adota **julho** como referência para 2000, 2010 e 2022. A correspondência dessa escolha com os metadados de competência da renda dos Censos de 2000 e 2022 requer verificação documental, sem substituição por suposição.

#### 5.1.3. Universo válido, informações ausentes e auditoria

O denominador da proporção central é a **população ponderada com RDPC válida**. Pessoas com informação monetária ausente permanecem nos diagnósticos da cobertura, mas não são classificadas como pobres ou não pobres.

As rotinas calculam quantidades amostrais e ponderadas de registros com renda válida, ausente ou zero, cobertura da RDPC, população classificada como pobre e tamanho amostral efetivo associado aos pesos.

Para examinar a sensibilidade à ausência de renda, são calculados limites extremos:

$$
P_{\min}=100\times
\frac{W_{\mathrm{pobres}}}{W_{\mathrm{total}}},
\qquad
P_{\max}=100\times
\frac{W_{\mathrm{pobres}}+W_{\mathrm{sem\ renda}}}{W_{\mathrm{total}}}.
$$

O limite inferior corresponde à hipótese extrema de que toda pessoa sem RDPC informada é não pobre; o superior, à hipótese de que todas são pobres. **Esses limites não são intervalos de confiança** e não substituem informações ausentes.

#### 5.1.4. Desagregação por sexo

A proporção é estimada separadamente para os grupos Total, Masculino e Feminino, com os respectivos pesos individuais.

A distinção entre os grupos refere-se ao **sexo das pessoas classificadas pela RDPC de seu domícilio**, não ao rendimento individual masculino ou feminino. Pessoas de sexos distintos residentes no mesmo domícilio recebem a mesma RDPC.

A proporção do grupo Total é calculada diretamente com os pesos populacionais e não corresponde, em geral, à média simples das duas proporções por sexo.

### 5.2. `ECO02_PIBPC` — Produto Interno Bruto municipal per capita

#### 5.2.1. Definição operacional

**Definição operacional.** Valor oficial do PIB per capita municipal publicado pelo IBGE, convertido para **reais a preços de 2010 por habitante**.

A implementação utiliza diretamente o PIB per capita fornecido pela fonte. O valor não é recalculado por divisão independente do PIB municipal por outra série populacional.

| Recorte PRAIS | Ano-fonte do PIB per capita |
|---|---:|
| 2000 | 2002 |
| 2010 | 2010 |
| 2022 | 2022 |

#### 5.2.2. Conversão para preços de 2010

Para município \(m\) e recorte \(t\):

$$
ECO02_{m,t}=PIBPC^{\mathrm{corrente}}_{m,a(t)}
\times F_{a(t)\rightarrow2010},
$$

em que \(a(t)\) é o ano-fonte e \(F\) é o fator nacional de conversão derivado da variação percentual anual do deflator implícito do PIB, na Tabela 6784 do SIDRA.

Para variação anual \(d_a\), os fatores são:

$$
F_{2002\rightarrow2010}=\prod_{a=2003}^{2010}
\left(1+\frac{d_a}{100}\right),
$$

$$
F_{2010\rightarrow2010}=1,
$$

$$
F_{2022\rightarrow2010}=\left[
\prod_{a=2011}^{2022}\left(1+\frac{d_a}{100}\right)
\right]^{-1}.
$$

Os fatores são recalculados a partir da série da fonte, e a implementação inclui conferência de sua consistência acumulada. Para 2010, o valor corrente permanece inalterado.

A expressão **"a preços de 2010"** identifica uma referência monetária de apresentação e **não deve ser confundida** com a denominação metodológica **"Referência 2010"** das Contas Nacionais. Tampouco corresponde a conversão do PIB per capita por PPC internacional.

#### 5.2.3. Referências populacionais e temporais

A população incorporada ao PIB per capita corresponde àquela utilizada pelo IBGE na publicação original. Os metadados operacionais distinguem a referência populacional dos anos de 2002 e 2010 daquela dos valores publicados para 2022, associada à primeira apuração do Censo Demográfico 2022 e assinalada no processamento como sujeita a revisão.

O resultado vinculado ao recorte PRAIS 2000 corresponde ao PIB per capita do **ano-fonte 2002** expresso a preços de 2010. **Não é uma estimativa retrospectiva do PIB de 2000.**

#### 5.2.4. Grupos populacionais

O `ECO02_PIBPC` é uma estatística territorial. O mesmo valor municipal é disponibilizado para Total, Masculino e Feminino, com escopo operacional `comum_municipal`. Essa organização não constitui três estimativas independentes nem permite inferir distribuição de renda ou produção por sexo.

### 5.3. `ECO03_AGROPIB` — Participação da agropecuária no PIB municipal

#### 5.3.1. Definição operacional

**Definição operacional.** Participação percentual do Valor Adicionado Bruto (VAB) da agropecuária em relação ao PIB municipal, segundo as informações da Tabela 5938 do SIDRA.

$$
ECO03_{m,a}=100\times
\frac{VAB^{\mathrm{agro}}_{m,a}}{PIB_{m,a}}.
$$

Numerador e denominador pertencem ao mesmo município e ano-fonte e são apresentados na mesma unidade monetária. Não é aplicado deflator na construção da razão.

O indicador não representa a participação do agronegócio em sentido amplo, a parcela da população ocupada na agricultura ou a dependência hídrica das atividades locais.

#### 5.3.2. Correspondência temporal

| Recorte PRAIS | Ano-fonte do PIB e do VAB |
|---|---:|
| 2000 | 2002 |
| 2010 | 2010 |
| 2022 | 2021 |

No recorte PRAIS 2022, **PIB e VAB são ambos de 2021**. Não se combina VAB de 2021 com PIB de 2022.

#### 5.3.3. Tratamento dos valores e situações especiais

A leitura dos arquivos do SIDRA diferencia valores disponíveis, **zero absoluto** e situações de indisponibilidade, não aplicabilidade e sigilo. Valores identificados como zero absoluto são preservados numericamente como zero, segundo a convenção da fonte; valores não disponíveis ou sob sigilo não são tratados como zero.

Para os municípios incorporados, o processamento exige PIB finito e estritamente positivo e VAB agropecuário finito e não negativo.

**Resultados superiores a 100% são preservados e sinalizados nos procedimentos de auditoria**, sem truncamento automático. Essas ocorrências exigem conferência de origem e interpretação à luz das definições das contas econômicas, sem serem classificadas automaticamente como erro.

#### 5.3.4. Grupos populacionais

O `ECO03_AGROPIB` representa um atributo da economia municipal e tem seu valor repetido para Total, Masculino e Feminino, com escopo `comum_municipal`. Essa replicação **não caracteriza participação agropecuária diferenciada por sexo**.

## 6. Controle de qualidade e validação

### 6.1. Verificações comuns

Os procedimentos implementados verificam estrutura dos arquivos, presença das variáveis obrigatórias, validade das chaves municipais e temporais, unicidade dos registros, correspondência com os anos-fonte, integridade das unidades e compatibilidade entre os indicadores e seus produtos de auditoria.

Os registros municipais são identificados por códigos de sete dígitos; a UF é confrontada com o prefixo do código municipal. São exigidos os grupos Total, Masculino e Feminino, com uma combinação única por município, ano, grupo e indicador.

As rotinas incorporam assinaturas MD5 das fontes e confrontam produtos preexistentes com as referências e os parâmetros esperados. Divergências identificadas não implicam substituição silenciosa dos resultados.

### 6.2. Verificações específicas do `ECO01_POV3_PPC21`

O processamento verifica a integridade dos pesos, a validade das rendas e do limiar de pobreza, a consistência das proporções e as quantidades ponderadas e não ponderadas relativas à informação de RDPC.

Os resultados devem pertencer a **[0, 100]**, e a soma ponderada dos registros com RDPC válida deve ser positiva. O código verifica que as quantidades ponderadas do grupo Total reproduzam, dentro da tolerância numérica, a soma dos grupos Masculino e Feminino.

O tamanho amostral efetivo é calculado pela expressão:

$$
n_{ef}=\frac{\left(\sum_i w_i\right)^2}{\sum_i w_i^2}.
$$

Esse diagnóstico descreve a concentração relativa dos pesos e **não substitui uma estimação completa da variância segundo o plano amostral complexo**. Tampouco define isoladamente uma regra de exclusão municipal.

A consistência dos limites de pobreza é examinada em relação à estimativa central, sem interpretar tais limites como intervalos de confiança.

### 6.3. Verificações específicas do `ECO02_PIBPC`

São verificados os arquivos históricos do PIB municipal, os anos-fonte selecionados, a série anual do deflator, a positividade e finitude dos valores, os fatores acumulados de conversão e a reprodução dos valores a preços de 2010.

O ano-fonte 2010 permanece sem correção monetária. As rotinas também exigem correspondência entre os valores dos três grupos e os registros territoriais de auditoria, além de preservar a identificação das referências populacionais e das fontes originais.

### 6.4. Verificações específicas do `ECO03_AGROPIB`

A validação confere as fontes de PIB e VAB agropecuário, a identidade dos municípios e anos-fonte, os estados de disponibilidade, a reprodução da relação percentual e a consistência dos sinalizadores de zero e de participação superior a 100%.

Os valores acima de 100% não são automaticamente ajustados. Os resultados devem ser finitos e não negativos, e os três grupos devem reproduzir o mesmo valor municipal.

### 6.5. Cobertura territorial e integridade dos produtos

Para cada indicador e recorte, a estrutura de exportação prevê **um registro por município e grupo**:

| Ano | Municípios | Registros por indicador (3 grupos) | Indicadores econômicos |
|---|---:|---:|---:|
| 2000 | 5.507 | 16.521 | 3 |
| 2010 | 5.565 | 16.695 | 3 |
| 2022 | 5.570 | 16.710 | 3 |

Essas são as coberturas exigidas pelas rotinas implementadas. O processador integrado confronta os três CSVs de um mesmo recorte, verificando equivalência de chaves, grupos, indicadores e faixas numéricas.

**A existência dos arquivos CSV não substitui os procedimentos computacionais de verificação.** Os critérios de teste são inspecionáveis no código; os registros originais de auditoria associados às bases de acesso restrito não constituem produtos destinados à divulgação.

## 7. Limitações e cuidados de interpretação

A documentação dos indicadores deve preservar as limitações específicas das fontes e dos procedimentos de compatibilização:

| Aspecto | Implicação |
|---|---|
| Abrangência conceitual | Os três indicadores descrevem atributos econômicos distintos; nenhum representa isoladamente a vulnerabilidade à seca. |
| Agregação municipal | Valores municipais podem ocultar desigualdades internas entre pessoas, famílias e localidades. |
| Comparabilidade territorial | Os universos e os limites municipais diferem entre os recortes; os nomes de uma referência cadastral posterior não eliminam essa diferença. |
| Pobreza monetária (`ECO01`) | A linha de renda não representa as dimensões não monetárias da pobreza. |
| Desagregação do `ECO01` | A classificação por sexo refere-se às pessoas e à RDPC de seus domicílios, não a rendimentos individuais separados. |
| Renda ausente (`ECO01`) | A estimativa central considera a RDPC válida; os limites extremos de sensibilidade não substituem dados ausentes nem são intervalos de confiança. |
| Comparabilidade censitária | Variáveis, universos e regras de obtenção da RDPC diferem entre os Censos. |
| Referência monetária do `ECO01` | A conversão depende do limiar internacional, do fator PPC, do mês e da série do IPCA adotados. |
| PIB per capita (`ECO02`) | A produção econômica por habitante não informa a renda recebida nem sua distribuição. |
| Deflator e séries do `ECO02` | A conversão por deflator nacional não elimina diferenças metodológicas entre edições das contas econômicas nem equivale a conversão PPC internacional. |
| Revisões das fontes | Atualizações das contas econômicas ou da população de referência podem modificar os valores oficiais. |
| Participação agropecuária (`ECO03`) | A relação VAB/PIB não mede dependência hídrica, exposição da produção à seca ou emprego no setor. |
| Valores excepcionais do `ECO03` | Valores nulos ou superiores a 100% são preservados segundo as regras do processamento e exigem interpretação da fonte. |
| Grupos no `ECO02` e no `ECO03` | Valores iguais para Total, Masculino e Feminino correspondem a atributos territoriais compartilhados, não a estimativas por sexo. |
| Anos-fonte | As informações dos indicadores podem corresponder a anos distintos do recorte PRAIS e distintos entre si. |
| Amostragem | Pesos e tamanho amostral efetivo não constituem, sozinhos, avaliação completa da precisão sob o desenho amostral. |

Em particular, **a dimensão Econômica não identifica quais pessoas, atividades ou municípios sofreram impactos efetivos da seca**. Essa inferência demandaria informações de impactos e procedimentos analíticos adicionais.

A integração futura dos indicadores econômicos às demais dimensões permitirá uma representação calculada e condicionada ao modelo do DVI, sem transformar cada indicador ou dimensão em uma medida direta da vulnerabilidade observada.

## 8. Produtos, rastreabilidade e reprodutibilidade

### 8.1. Produtos municipais

Os resultados brutos são organizados em `so3.3/outputs/bruto/economica/<ano>/`, com um arquivo CSV por indicador e recorte:

- `ECO01_POV3_PPC21_<ano>.csv`;
- `ECO02_PIBPC_<ano>.csv`;
- `ECO03_AGROPIB_<ano>.csv`.

Os nove CSVs municipais presentes no repositório seguem o esquema de colunas:

`ano;uf;cod_mun;nm_mun;indicador;grupo;valor`

| Campo | Significado |
|---|---|
| `ano` | Recorte PRAIS, não necessariamente ano-fonte |
| `uf` | Identificador da Unidade da Federação |
| `cod_mun` | Geocódigo municipal de sete dígitos |
| `nm_mun` | Nome municipal para identificação |
| `indicador` | Código do indicador econômico |
| `grupo` | Total, Masculino ou Feminino |
| `valor` | Resultado bruto na unidade do indicador |

As unidades são **percentual da população** (`ECO01`), **R$ de 2010 por habitante** (`ECO02`) e **percentual do PIB** (`ECO03`). Os arquivos contêm resultados anteriores ao tratamento estatístico, à normalização e à composição dos índices.

Os **CSVs municipais, observadas as condições de divulgação, constituem os produtos de dados previstos para distribuição** nesta etapa.

Arquivos RDS, checkpoints e registros detalhados de auditoria são **produtos intermediários gerados pelas rotinas computacionais**, não arquivos integrantes da distribuição. Sua reprodução pressupõe acesso legítimo às fontes correspondentes. Esses objetos podem conter informações derivadas de microdados sujeitos a restrições, razão pela qual não se presume autorização para sua divulgação.

Os microdados individuais e domiciliares **não são redistribuídos** pelo projeto.

### 8.2. Organização do processamento e procedimentos de verificação

A unidade operacional é **uma dimensão e um ano por execução**. O arquivo [`main.R`](../../main.R) seleciona a dimensão Econômica e o recorte PRAIS; o processador integrado coordena o ECO01, o ECO02 e o ECO03, verifica produtos preexistentes e confronta as saídas do mesmo ano.

As rotinas de cálculo e verificação podem ser localizadas nos seguintes módulos, sem necessidade de transcrever seus códigos nesta documentação:

| Função metodológica | Módulo do repositório |
|---|---|
| Harmonização censitária do `ECO01` | [`adaptar_censo_2000_economica.R`](../../R/01_leitura/adaptar_censo_2000_economica.R), [`adaptar_censo_2010_economica.R`](../../R/01_leitura/adaptar_censo_2010_economica.R), [`adaptar_censo_2022_economica.R`](../../R/01_leitura/adaptar_censo_2022_economica.R) |
| Referência PPC/IPCA para a linha de pobreza | [`preparar_referencias_eco01.R`](../../R/02_indicadores/preparar_referencias_eco01.R) |
| Estimação e validação do `ECO01` | [`eco01_pobreza.R`](../../R/02_indicadores/eco01_pobreza.R) |
| Leitura das planilhas de PIB per capita | [`ler_pib_municipios_eco02.R`](../../R/01_leitura/ler_pib_municipios_eco02.R) |
| Leitura do PIB, VAB e deflator no SIDRA | [`ler_sidra_economica.R`](../../R/01_leitura/ler_sidra_economica.R) |
| Cálculo e validação do `ECO02` | [`eco02_pibpc.R`](../../R/02_indicadores/eco02_pibpc.R) |
| Cálculo e validação do `ECO03` | [`eco03_agropib.R`](../../R/02_indicadores/eco03_agropib.R) |
| Diagnósticos das fontes econômicas | [`diagnosticar_pib_municipios_eco02.R`](../../R/03_diagnostico/diagnosticar_pib_municipios_eco02.R), [`diagnosticar_sidra_economica.R`](../../R/03_diagnostico/diagnosticar_sidra_economica.R) |
| Processadores específicos | [`R/04_execucao/`](../../R/04_execucao/) |
| Processamento integrado | [`processar_dimensao_economica.R`](../../R/04_execucao/processar_dimensao_economica.R) |
| Exportação e conferência dos produtos | [`exportar_resultados_csv.R`](../../R/05_exportacao/exportar_resultados_csv.R) |

**Os critérios de teste, diagnóstico e validação implementados permanecem acessíveis nos processos computacionais disponibilizados.** Isso permite examinar suas condições de execução e suas regras de aceitação ou rejeição de resultados.

Essa disponibilidade **não implica publicar os registros originais nem as saídas detalhadas dos testes efetuados sobre dados de acesso restrito**. A reexecução desses procedimentos por terceiros depende das bases e das autorizações correspondentes. Testes exploratórios não incorporados ao código distribuído não são aqui apresentados como parte do conjunto reproduzível.

### 8.3. Referências operacionais vinculadas aos resultados

Os principais arquivos de referência utilizados pela dimensão estão organizados sob `so3.3/inputs/referencias/`:

| Indicador | Referência operacional |
|---|---|
| `ECO01` | `ibge/tabela_1737_IPCA_para_uso.xlsx` |
| `ECO02` | `ibge/pib_municipios_2022_2023/pib_municipios_2002_2009.xlsx` |
| `ECO02` | `ibge/pib_municipios_2022_2023/pib_municipios_2010_2023.xlsx` |
| `ECO02` | `sidra/tabela6784.csv` |
| `ECO03` | `sidra/tabela5938.csv` e `sidra/tabela5938_vab.csv` |

O arquivo `ibge/municipios_ibge_2025.csv` fornece os nomes utilizados para identificação dos municípios nos CSVs. Essa associação não altera o universo territorial dos respectivos recortes PRAIS.

Os objetos de auditoria produzidos pelos procedimentos incluem assinaturas MD5 das fontes pertinentes, permitindo rastrear a correspondência entre arquivos de entrada e resultados gerados. A presença de uma referência no repositório não substitui o registro de sua edição, procedência e condições de utilização.

### 8.4. Reprodutibilidade e utilização dos produtos

**Reprodução integral.** A reprodução dos indicadores desde suas fontes primárias exige as bases originais e os procedimentos computacionais correspondentes. No caso dos microdados de acesso controlado do Censo 2022, pressupõe-se autorização específica do IBGE. A execução do código pode regenerar objetos RDS e auditorias, desde que as fontes e demais dependências estejam disponíveis.

**Utilização dos produtos municipais.** Os CSVs brutos podem ser lidos como resultados municipais já produzidos para análises independentes ou etapas estatísticas posteriores, sem demandar o reprocessamento dos microdados. Os tratamentos futuros deverão preservar os recortes, grupos, unidades e referências temporais documentados.

No estado atual da implementação, o processador de produção `processar_dimensao_economica.R` exige os objetos intermediários para revalidar os CSVs. Por isso, a **leitura dos CSVs como insumos estatísticos é uma operação distinta da reexecução do processador original**; uma rotina de leitura independente deve ser empregada ou implementada para esse fim.

Essa organização distingue **transparência metodológica**, **reprodutibilidade condicionada ao acesso legítimo aos dados** e **utilização dos produtos municipais autorizados**.

## 9. Referências bibliográficas e documentais

### 9.1. Referências institucionais e enquadramento metodológico

- **PRAIS_BRASIL / Centro Nacional de Monitoramento e Alertas de Desastres Naturais (CEMADEN).** *Nota Técnica — Bases de dados, procedimentos metodológicos e limitações na caracterização da ameaça, exposição e vulnerabilidade à seca no Brasil.* Versão preliminar revisada para discussão técnica, outubro de 2026. Referência de enquadramento e terminologia; não substitui a documentação computacional detalhada.
- **FAO — Food and Agriculture Organization of the United Nations.** *Drought Portal — Vulnerability and Impact Assessment Compendium: Context.* Referência para as dimensões e para o conjunto de indicadores de base considerado no SO3.3. [Contexto e indicadores](https://www.fao.org/in-action/drought-portal/preparedness/vulnerability-and-impact-assessment/vulnerability-and-impact-assessment-compendium-intro/en).
- **FAO.** *Compendium — Indicators and Data Sources.* Referência complementar sobre seleção e utilização de indicadores. [Indicadores e fontes](https://www.fao.org/in-action/drought-portal/preparedness/vulnerability-and-impact-assessment/compendium---chapter-3/en).
- **FAO.** *Compendium — Vulnerability Indicators (Economic).* Relação mais ampla de indicadores econômicos para avaliação de vulnerabilidade, não equivalente à seleção operacional restrita do SO3.3 brasileiro. [Indicadores econômicos](https://www.fao.org/in-action/drought-portal/preparedness/vulnerability-and-impact-assessment/compendium---vulnerability-indicators-%28economic%29/en).
- **UNCCD — United Nations Convention to Combat Desertification.** *PRAIS4 Reporting Manual.* Documento de orientação do Objetivo Estratégico 3 e do reporte SO3.3, na edição empregada no PRAIS_BRASIL.
- **UNCCD.** (2019). *Drought Resilience, Adaptation and Management Policy Framework: Supporting Technical Guidelines.* Referência complementar sobre avaliação de vulnerabilidade e risco à seca. [Publicação](https://www.unccd.int/publications/drought-resilience-adaptation-and-management-policy-framework-supporting-technical).

### 9.2. Referências estatísticas, econômicas e monetárias

**Pobreza internacional e PPC**

- **World Bank.** (2025). *June 2025 Update to Global Poverty Lines.* Atualização da linha internacional para US$ 3,00 por pessoa/dia em PPC de 2021. [Documento institucional](https://www.worldbank.org/en/news/factsheet/2025/06/05/june-2025-update-to-global-poverty-lines).
- **World Bank.** *Poverty and Inequality Platform (PIP).* Referência complementar para definições e indicadores de pobreza monetária. [Plataforma](https://pip.worldbank.org).

**Fontes censitárias**

- **IBGE — Instituto Brasileiro de Geografia e Estatística.** *Censo Demográfico 2000: microdados da amostra, dicionários de variáveis e documentação metodológica.* Fonte primária do `ECO01` em 2000.
- **IBGE.** *Censo Demográfico 2010: microdados da amostra, dicionários de variáveis e documentação metodológica.* Fonte primária do `ECO01` em 2010.
- **IBGE.** *Censo Demográfico 2022: microdados da amostra em modalidade de acesso controlado, dicionários e documentação metodológica.* Fonte primária do `ECO01` em 2022.
- **IBGE.** *Censo Demográfico 2022 — Notas metodológicas n. 02/2026, 03/2026, 04/2026 e 05/2026.* Documentação sobre áreas de ponderação, confidencialidade, expansão da amostra e microdados.

**Contas econômicas e índices de preços**

- **IBGE.** *Produto Interno Bruto dos Municípios: séries históricas e documentação metodológica.* Fonte do PIB per capita oficial para o `ECO02`.
- **IBGE/SIDRA.** *Tabela 5938 — Produto Interno Bruto dos Municípios.* Fonte de PIB e VAB agropecuário utilizados no `ECO03`. [Tabela 5938](https://sidra.ibge.gov.br/tabela/5938).
- **IBGE/SIDRA.** *Tabela 6784 — Produto Interno Bruto, Produto Interno Bruto per capita, População residente e Deflator.* Fonte das variações do deflator implícito do PIB utilizadas no `ECO02`. [Tabela 6784](https://sidra.ibge.gov.br/tabela/6784).
- **IBGE/SIDRA.** *Tabela 1737 — IPCA: série histórica com número-índice e variações mensais e acumuladas.* Fonte para a conversão monetária do `ECO01`. [Tabela 1737](https://sidra.ibge.gov.br/tabela/1737).

### 9.3. Pontos de verificação documental

Esta versão registra questões que permanecem para verificação, **sem preencher lacunas por suposição**:

1. **Competência da renda censitária:** verificar documentalmente a correspondência entre julho, adotado para a conversão monetária, e os períodos de referência da renda nos Censos de 2000 e 2022.
2. **Conversor PPC Brasil 2021:** documentar a origem, série e versão do fator `2.44983620`, sem confundir a fonte do fator com a fonte da linha internacional de US$ 3,00.
3. **Harmonização da RDPC:** confrontar as regras operacionais de 2000, 2010 e 2022 com os dicionários e metadados das versões censitárias efetivamente utilizadas, incluindo as categorias de moradores no divisor de 2000.
4. **Adaptações nacionais:** distinguir as definições de referência FAO/UNCCD dos indicadores operacionalizados no Brasil. O PIB per capita em reais a preços de 2010 não equivale a PIB per capita convertido em PPC internacional.
5. **Versões das contas econômicas:** registrar as edições e eventuais revisões das séries de PIB, VAB e deflator, inclusive a referência populacional do PIB per capita de 2022.
6. **Valores excepcionais do `ECO03`:** documentar, se autorizada sua divulgação, sínteses agregadas da ocorrência de valores zero e superiores a 100%, com base em verificações efetivamente realizadas.
7. **Auditorias do `ECO01`:** distinguir as regras computacionais disponíveis de suas saídas originais, não distribuídas quando dependentes de informações com acesso restrito. Eventuais sínteses para divulgação devem respeitar os controles de confidencialidade aplicáveis.
8. **Comparação territorial:** registrar procedimentos adicionais de harmonização geográfica caso venham a ser formalmente adotados para a comparação dos recortes.
9. **Etapa estatística:** implementar ou identificar a leitura independente dos CSVs municipais como insumos, sem confundi-la com a revalidação do processador original dependente dos RDS.
10. **Condições de divulgação:** confirmar a compatibilidade dos produtos municipais destinados à distribuição com as regras do IBGE e as orientações institucionais aplicáveis.

---

**Situação editorial:** versão aprovada para inclusão no repositório. Mantém os pontos de verificação documental e a distinção entre indicadores, dimensão Econômica e DVI. A transparência das rotinas computacionais não implica distribuição dos microdados nem dos produtos intermediários sujeitos a restrições.