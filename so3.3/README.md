# DVI-Brasil | Vulnerabilidade à seca em escala municipal (SO3.3)

> **O que este módulo apresenta:** a proposta, as escolhas metodológicas e os resultados iniciais do **Drought Vulnerability Index (DVI-Brasil)**, desenvolvido para representar diferenças nas condições de vulnerabilidade à seca dos municípios brasileiros. Os detalhes de produção de cada indicador e os comandos de execução encontram-se na documentação técnica vinculada ao final.

## 1. Por que construir um índice de vulnerabilidade à seca?

Duas localidades podem experimentar condições de seca semelhantes e, ainda assim, apresentar possibilidades muito diferentes de enfrentá-las. Características sociodemográficas, condições econômicas, acesso a serviços e disponibilidade de recursos ajudam a compreender parte dessas diferenças. Uma avaliação da seca que considere apenas sua intensidade climática deixa de representar esse contexto.

O **SO3.3 do PRAIS4**, no âmbito da **UNCCD**, propõe sintetizar fatores de vulnerabilidade em três dimensões — **social, econômica e infraestrutural** — por meio do DVI. Para o Brasil, optou-se por produzir uma representação **subnacional, municipal**, apoiada em fontes nacionais e com desagregação populacional onde possível.

O índice permite perguntar **quais municípios apresentam condições relativamente mais vulneráveis segundo os fatores selecionados**, de que maneira essas condições se distribuem pelo território e como os valores obtidos se apresentam nos diferentes recortes censitários. Trata-se de uma aproximação multidimensional: a vulnerabilidade real é dinâmica, contextual e não se esgota nos nove indicadores aqui reunidos.

**O DVI não mede a intensidade da seca, o número de pessoas expostas, os danos sofridos ou a probabilidade de um desastre.** Esses objetos devem permanecer separados do SO3.3 e, quando pertinente, ser analisados conjuntamente em estudos posteriores.

## 2. Objetivos, recorte e alcance

O objetivo central é **construir um índice municipal contínuo, transparente e reproduzível**, capaz de sintetizar condições selecionadas de vulnerabilidade à seca e permitir sua leitura em diferentes momentos da história recente brasileira.

Foram definidos três recortes analíticos: **2000, 2010 e 2022**, correspondentes aos Censos Demográficos. Eles não formam uma série anual: algumas variáveis são estimadas indiretamente, e certas referências econômicas e hidrológicas possuem anos-fonte ou bases territoriais diferentes do Censo de associação. Essa organização temporal busca tornar possível a leitura conjunta de informações que não são produzidas anualmente, **sem afirmar que todas representem o mesmo instante**.

Os produtos são apresentados para **Total, Masculino e Feminino**. Parte dos indicadores é efetivamente desagregada por sexo; **PIB per capita, participação agropecuária e recursos hídricos per capita são atributos do município**, utilizados igualmente nos três grupos. Assim, a desagregação do DVI não significa que todas as suas variáveis sejam específicas de cada população.

A escala municipal e a desagregação populacional aproximam esta implementação da lógica de avaliação **Tier 3** descrita pela UNCCD. Contudo, a existência de **apenas três recortes censitários** não equivale à produção de uma série anual ou quase anual de DVI para todo o período de referência do manual. A abrangência temporal deve ser explicitada em qualquer apresentação de resultados ou proposta de reporte.

A avaliação é municipal. Um valor atribuído a um município **não descreve a situação de todas as pessoas, comunidades ou bairros** que nele residem e não permite inferir automaticamente desigualdades internas.

## 3. O que compõe a vulnerabilidade representada pelo índice?

### Dimensão Social — características das populações

Reúne atributos relacionados a educação, distribuição territorial, mortalidade e estrutura etária. Seu papel é representar aspectos distintos das condições sociodemográficas, sem supor que sejam causas isoladas de impactos da seca. São quatro indicadores:

| Indicador | O que acrescenta à representação | Relação adotada com a vulnerabilidade |
| --- | --- | --- |
| **SOC01 — Alfabetização (15+)** | Condição educacional básica declarada. | Inversa |
| **SOC02 — População rural** | Distribuição da residência entre áreas rurais e urbanas. | Direta |
| **SOC03 — Expectativa de vida ao nascer** | Síntese demográfica de condições de mortalidade, estimada indiretamente. | Inversa |
| **SOC04 — População de 15 a 64 anos** | Estrutura etária da população, sem equivaler à população economicamente ativa. | Inversa |

A relação direta atribuída à ruralidade é **uma hipótese do modelo**, não uma afirmação de que residir em área rural torna toda pessoa vulnerável. Da mesma maneira, a alfabetização não mede qualidade da educação, e a expectativa de vida não é uma observação direta do tempo vivido por cada habitante.

### Dimensão Econômica — condições e estrutura da economia municipal

Considera pobreza monetária, produção econômica por habitante e peso relativo da agropecuária. Essas variáveis se complementam, mas não são intercambiáveis:

| Indicador | O que acrescenta à representação | Relação adotada |
| --- | --- | --- |
| **ECO01 — Pobreza internacional (US$ 3/dia, PPC 2021)** | Incidência de pobreza monetária segundo a linha definida para a análise. | Direta |
| **ECO02 — PIB per capita** | Produção econômica municipal em relação à população. | Inversa |
| **ECO03 — Participação agropecuária no PIB** | Peso relativo da agricultura, silvicultura e pesca na estrutura produtiva. | Direta |

O PIB per capita **não equivale à renda individual**, nem descreve sua distribuição. A participação agropecuária, por sua vez, não mede diretamente dependência hídrica ou perdas agrícolas: sua orientação expressa uma **hipótese de sensibilidade econômica** incorporada à versão atual.

### Dimensão Infraestrutural — acesso à água e disponibilidade hídrica estimada

Organiza duas condições materiais relacionadas à água, com naturezas informacionais distintas:

| Indicador | O que acrescenta à representação | Relação adotada |
| --- | --- | --- |
| **INF01 — Rede geral e água canalizada** | Condição de abastecimento e canalização domiciliar, estimada para a população. | Inversa |
| **INF02 — Recursos hídricos renováveis per capita** | Contribuição hídrica superficial estimada por habitante, associada ao território. | Inversa |

O **INF01 é uma proxy censitária**: não demonstra continuidade, potabilidade ou segurança do fornecimento. O **INF02 não mede água efetivamente disponível em torneiras ou sistemas de abastecimento**, nem um balanço completo entre oferta e demanda. Sua referência hidrológica e sua base territorial precisam ser consideradas na interpretação de diferenças temporais.

A escolha dos nove indicadores decorre da orientação FAO/UNCCD, adaptada às fontes brasileiras e às possibilidades de cálculo municipal. **Eficiência governamental, população refugiada, consumo de energia per capita e área equipada para irrigação não foram operacionalizados nesta versão.** Essa delimitação é uma característica do modelo, não evidência de irrelevância dos fatores excluídos.

## 4. Como os indicadores se tornam um DVI?

As fontes originais utilizam escalas incompatíveis: percentuais, anos de vida, valores econômicos e estimativas hídricas por habitante. Por isso, sua reunião exige uma sequência explícita de operações.

**Primeiro,** os indicadores municipais brutos são diagnosticados e submetidos apenas aos tratamentos estatísticos aprovados. Nesta versão, **não foi aplicada winsorização**; os indicadores **ECO02 e INF02** receberam transformação **Yeo–Johnson**, enquanto os demais permaneceram em suas escalas originais. Esse procedimento busca lidar com distribuições muito assimétricas, mas não corrige problemas de comparabilidade das fontes nem transforma estimativas em observações diretas.

**Depois,** cada indicador é normalizado em **[0,1]** utilizando uma referência única construída com os valores dos **três recortes reunidos (2000, 2010 e 2022)**. Os parâmetros são próprios de cada indicador e grupo populacional; para atributos territoriais compartilhados utiliza-se uma única série. **Não existem mínimos e máximos recalculados a cada ano**, preservando-se a régua histórica de cada série.

**Em seguida,** os indicadores são orientados segundo sua relação adotada com a vulnerabilidade. Quando a relação é direta, o valor normalizado é preservado; quando é inversa, aplica-se **`1 − valor_normalizado`**. Após essa operação, valores maiores significam **maior contribuição para a vulnerabilidade segundo o modelo**, e não maior magnitude da variável original.

**Por fim,** os indicadores orientados são agregados por **média aritmética simples** dentro de cada dimensão. As três componentes recebem, então, **o mesmo peso na composição final**:

$$
C_{SOC}=\frac{SOC01+SOC02+SOC03+SOC04}{4},\qquad
C_{ECO}=\frac{ECO01+ECO02+ECO03}{3},\qquad
C_{INF}=\frac{INF01+INF02}{2}.
$$

$$
\boxed{DVI=\frac{C_{SOC}+C_{ECO}+C_{INF}}{3}}
$$

Essa arquitetura evita que uma dimensão tenha maior peso no índice apenas porque contém mais indicadores. A média é calculada **somente quando todos os indicadores obrigatórios estão disponíveis**: a ausência de qualquer indicador torna sua componente ausente, e a ausência de qualquer componente torna o DVI ausente. **Não há imputação, média parcial ou redistribuição de pesos.**

As componentes e o DVI permanecem no **intervalo teórico [0,1]**, mas seus valores observados **não precisam atingir exatamente 0 ou 1**. Não se realiza um segundo reescalonamento após a agregação.

## 5. O que encontramos até aqui?

A versão contínua do DVI-Brasil foi calculada para os três anos e grupos populacionais, com as seguintes coberturas:

| Recorte | Municípios na base | Com DVI válido, por grupo | Sem DVI, por grupo |
| --- | ---: | ---: | ---: |
| **2000** | 5.507 | 5.493 | 14 |
| **2010** | 5.565 | 5.551 | 14 |
| **2022** | 5.570 | 5.556 | 14 |

As dimensões **Social e Econômica** apresentam cobertura completa. As **14 ausências por recorte e grupo** decorrem da indisponibilidade de valores necessários à componente **Infraestrutural**, especialmente no INF02. A igualdade das contagens não significa que os mesmos municípios estejam ausentes em todos os anos. Nenhuma ausência foi substituída por zero.

Os valores extremos observados do **grupo Total**, apresentados apenas para situar a amplitude dos resultados, foram:

| Recorte | Mínimo observado | Máximo observado |
| --- | ---: | ---: |
| 2000 | 0,1987543 | 0,7720955 |
| 2010 | 0,1696766 | 0,6414747 |
| 2022 | 0,1729995 | 0,5670885 |

Os resultados de Masculino e Feminino, assim como as estatísticas completas de cobertura, estão registrados em `metadata/dvi_cobertura.csv`.

**Como interpretar esses números?** Um DVI maior representa, dentro da referência estatística utilizada, uma combinação de condições consideradas mais vulneráveis. Os máximos observados em cada recorte **não são categorias de vulnerabilidade**; tampouco sua redução, isoladamente, comprova melhora nacional ou explica os processos que a produziram. Para avaliar mudanças ao longo do tempo, é necessário examinar a distribuição completa, a cobertura territorial e a contribuição das componentes.

Como a normalização dos fatores populacionais é específica de cada grupo, **a principal leitura comparável é a trajetória temporal dentro do mesmo grupo**, e não a interpretação de uma mesma pontuação como posição idêntica nas distribuições Masculina e Feminina.

## 6. O que o DVI poderá ajudar a identificar?

A disponibilidade de um indicador municipal contínuo permite examinar **contrastes espaciais**, investigar quais condições contribuem para valores relativamente altos ou baixos e observar **mudanças entre os recortes de 2000, 2010 e 2022**. Também permite elaborar perfis das dimensões social, econômica e infraestrutural, em vez de reduzir a interpretação apenas à pontuação final.

Uma classificação cartográfica em cinco categorias poderá facilitar a comunicação dos resultados e o acompanhamento de transições de classe entre períodos. **Os limites ainda não foram definidos**. Sua escolha precisará explicitar se as classes representam posições relativas à distribuição histórica ou faixas fixas da escala teórica. A avaliação de estabilidade de classificações constitui um trabalho posterior e **não equivale à estimação da incerteza de todos os indicadores que formam o DVI**.

Outra aplicação possível é associar o DVI às informações de **exposição à seca do SO3.2**, para discutir onde condições de maior exposição e maior vulnerabilidade coincidem. Essa integração será um **produto analítico derivado do Cemaden**, posterior e independente do indicador formal SO3.3. Ela não transforma automaticamente a associação em medida observada de impactos ou em modelo completo de risco.

## 7. Limitações e cuidados de uso

O DVI é uma representação **parcial e metodologicamente condicionada**. Em particular, sua interpretação requer atenção à seleção e à orientação dos indicadores; à hipótese de pesos iguais; às diferenças entre valores censitários observados e estimativas demográficas indiretas; às referências econômicas de anos-fonte distintos; e ao fato de o INF02 utilizar referência hidrológica e territorial que **não foi harmonizada historicamente** para cada recorte municipal.

A associação computacional entre indicadores emprega **`ano + cod_mun + grupo`**. Isso garante a correspondência das chaves disponíveis, **não demonstra que os limites geográficos tenham permanecido invariáveis**. Comparações envolvendo municípios criados, desmembrados ou alterados territorialmente exigem cuidado adicional.

O índice também não descreve diretamente capacidade adaptativa, resiliência, segurança hídrica, impactos da seca ou condições internas de todas as comunidades do município. Os resultados dependem da disponibilidade e da qualidade das bases utilizadas. A análise de sensibilidade de pesos e de alternativas de composição é uma possibilidade futura, **não um procedimento aplicado na versão contínua aqui documentada**.

## 8. Onde estão os resultados e a documentação técnica?

Este README apresenta **o significado e o alcance do DVI-Brasil**. A documentação detalhada está organizada por assunto, permitindo examinar fontes, hipóteses, decisões e validações sem sobrecarregar esta apresentação:

| Para compreender... | Consultar... |
| --- | --- |
| Conceito, fontes e produção dos indicadores sociais | [`docs/social/README.md`](docs/social/README.md) |
| Conceito, fontes e produção dos indicadores econômicos | [`docs/economica/README.md`](docs/economica/README.md) |
| Fontes hidrológicas, abastecimento e limitações territoriais | [`docs/infraestrutural/README.md`](docs/infraestrutural/README.md) |
| Triagem estatística e decisões de tratamento | [`docs/estatistica/README.md`](docs/estatistica/README.md) |
| Referências históricas de normalização e regras de orientação | `metadata/normalizacao_parametros.csv` e `metadata/orientacao_regras.csv` |
| Pesos, completude e rastreabilidade das componentes | `metadata/componentes_*.csv` |
| Cobertura, proveniência e ausências do DVI | `metadata/dvi_*.csv` |
| Resultados contínuos municipais | `outputs/dvi/<ano>/DVI_BRASIL_<ano>.csv` |

A produção está separada em resultados **brutos**, produtos **tratados**, **normalizados**, **orientados**, **componentes** e **DVI**. O `main.R` organiza a produção dos indicadores municipais por dimensão e ano; as etapas de síntese posteriores são independentes e não devem ser confundidas com a etapa censitária de origem.

**Microdados censitários de acesso controlado não são distribuídos neste repositório.** A divulgação de resultados derivados e das referências utilizadas deve respeitar as restrições aplicáveis às respectivas fontes.

**Referências centrais:** UNCCD, *PRAIS4 Reporting Manual*, seção SO 3-3 (normalização, agregação e cálculo do DVI); orientações técnicas da UNCCD sobre vulnerabilidade à seca; FAO, *Drought Vulnerability and Impact Assessment Compendium*. As adaptações, os parâmetros e as limitações de cada indicador são detalhados nos documentos específicos.
