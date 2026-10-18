# SO3.3 — Dimensão Social

**PRAIS_BRASIL | Documentação conceitual e metodológica dos indicadores municipais**  
**Referência do projeto:** *Performance Review and Assessment of Implementation System* (PRAIS), Objetivo Estratégico 3 (SO3), produto SO3.3.  
**Estado do documento:** versão aprovada para inclusão no repositório — outubro de 2026.  
**Localização no repositório:** `so3.3/docs/social/README.md`.

> **Delimitação:** este documento descreve a dimensão Social e os procedimentos de produção dos seus indicadores municipais **brutos**. Não documenta nem antecipa regras de tratamento estatístico, normalização, ponderação ou composição dos índices dimensionais e do DVI, ainda não implementadas nesta etapa. A dimensão Social, individualmente, **não é uma medida de vulnerabilidade à seca**.

## 1. Apresentação

### 1.1. A dimensão Social no contexto da vulnerabilidade à seca

A dimensão Social reúne indicadores relacionados às características sociodemográficas da população, contemplando aspectos educacionais, demográficos e de distribuição territorial.

Esses indicadores permitem caracterizar diferenças nas condições sociodemográficas dos municípios brasileiros. Sua contribuição deve ser interpretada em conjunto com as demais dimensões previstas para a construção do índice, sem atribuir à dimensão Social, isoladamente, a condição de medida de vulnerabilidade.

### 1.2. Objetivo e abrangência da dimensão

O objetivo da dimensão Social é caracterizar, em escala municipal, condições sociodemográficas potencialmente associadas à vulnerabilidade à seca no território brasileiro.

A análise contempla os recortes censitários de **2000, 2010 e 2022**, considerando a população total e sua desagregação entre os grupos **Masculino** e **Feminino**.

A utilização desses recortes permite examinar diferentes momentos da estrutura sociodemográfica municipal, respeitando as particularidades das fontes e as limitações de comparabilidade temporal.

### 1.3. Relação com o DVI

Seus indicadores constituem um dos conjuntos de informações previstos para a construção do **Índice de Vulnerabilidade à Seca** (*Drought Vulnerability Index* — **DVI**).

## 2. Fundamentação conceitual da dimensão Social

### 2.1. Caracterização da dimensão Social

A dimensão Social organiza características sociodemográficas municipais selecionadas a partir do referencial da Organização das Nações Unidas para a Alimentação e a Agricultura (**FAO**) e da Convenção das Nações Unidas de Combate à Desertificação (**UNCCD**), adequadas às fontes e aos recortes definidos para o PRAIS_BRASIL.

**A dimensão não corresponde a uma categoria autônoma de vulnerabilidade.** A composição futura de seus indicadores permitirá sintetizar as condições sociais contempladas no conjunto, mas não medir a vulnerabilidade real das pessoas ou dos municípios. A representação calculada da vulnerabilidade à seca é atribuída à integração das três dimensões no DVI, observadas suas limitações.

### 2.2. Características sociodemográficas e diferenciação territorial

A educação básica, a distribuição urbano-rural, a estrutura por idade e as condições de mortalidade sintetizadas pela expectativa de vida ao nascer descrevem propriedades distintas da população. Essas propriedades possibilitam comparar perfis municipais, sem pressupor que estejam relacionadas entre si por uma única cadeia causal.

Uma taxa de alfabetização informa a frequência da condição declarada de saber ler e escrever; não mede diretamente a qualidade da educação. A proporção de residentes rurais descreve a localização administrativa dos domicílios; não identifica, por si, dependência econômica da agricultura ou disponibilidade de água. A proporção de pessoas entre 15 e 64 anos caracteriza a estrutura etária; não equivale à população economicamente ativa. A expectativa de vida ao nascer sintetiza condições de mortalidade **estimadas**, segundo pressupostos demográficos específicos; não corresponde à observação direta do tempo de vida de uma coorte municipal.

Essas distinções delimitam o conteúdo informacional dos indicadores e orientam sua leitura conjunta.

### 2.3. Alcance e limites da representação das condições sociais

As estimativas são organizadas por município e por recorte censitário. Por essa razão, diferenças entre municípios não permitem identificar automaticamente desigualdades existentes entre pessoas, famílias ou comunidades dentro de cada município.

Da mesma forma, a disponibilidade de indicadores para três recortes temporais não garante comparabilidade irrestrita. Alterações de conceitos, classificações, instrumentos censitários, procedimentos de expansão amostral e limites administrativos precisam ser consideradas.

**Nenhum indicador, nem a dimensão Social isoladamente, constitui uma medida direta de vulnerabilidade, de capacidade adaptativa, de resiliência ou de impactos decorrentes da seca.** A documentação de cada indicador deve permanecer vinculada ao atributo efetivamente estimado.

## 3. Composição da dimensão

### 3.1. Seleção e delimitação

A seleção operacional considera os indicadores de referência apresentados para o SO3.3 no material de orientação FAO/UNCCD, adaptados à disponibilidade e às particularidades dos dados brasileiros. A adequação das bases à escala municipal, a possibilidade de descrição dos três recortes temporais e a consistência das definições foram aspectos centrais para sua implementação.

O conjunto atualmente operacionalizado contém quatro indicadores:

| Código | Indicador | Unidade | Natureza da informação | Grupos |
|---|---|---|---|---|
| `SOC01_ALF15` | Alfabetização da população de 15 anos ou mais | % | Condição educacional declarada | Total, Masculino, Feminino |
| `SOC02_RURAL` | População residente em área rural | % | Situação territorial do domicílio | Total, Masculino, Feminino |
| `SOC03_EV0` | Expectativa de vida ao nascer | anos | Estimativa demográfica indireta, com modelagem | Total, Masculino, Feminino |
| `SOC04_POP1564` | População de 15 a 64 anos | % | Composição etária | Total, Masculino, Feminino |

Os três indicadores percentuais são proporções ponderadas obtidas a partir das informações censitárias. O `SOC03_EV0` difere dos demais porque requer uma cadeia de estimação indireta da mortalidade, estabilização estatística, conversão por tábuas-modelo e calibração.

### 3.2. Indicadores não operacionalizados nesta versão

**Eficácia governamental** e **população de refugiados** integram o conjunto de indicadores sociais considerado no referencial de partida, mas **não integram a versão operacional atual** do SO3.3 brasileiro. Sua menção documenta a delimitação do escopo e não antecipa avaliação de viabilidade ou inclusão futura.

### 3.3. Complementaridade dos indicadores

Os quatro indicadores caracterizam aspectos diferentes da população. Sua coexistência na dimensão não implica equivalência conceitual, independência estatística demonstrada ou capacidade de explicar, isoladamente, a ocorrência de impactos da seca.

A avaliação de direção, transformação, normalização e composição dos indicadores será realizada em etapa metodológica própria, posterior à conclusão das dimensões. Não se atribui neste documento uma pontuação de vulnerabilidade aos valores brutos.

## 4. Fontes de dados e harmonização

### 4.1. Base censitária

Os indicadores utilizam microdados da **amostra dos Censos Demográficos de 2000, 2010 e 2022**, produzidos pelo Instituto Brasileiro de Geografia e Estatística (**IBGE**).

Para 2000 e 2010, os dados são acessados por meio do pacote R [`censobr`](https://github.com/ipeaGIT/censobr), com leitura baseada em estruturas `Arrow` e processamento por unidade da Federação (**UF**). Para 2022, são utilizados os **microdados da amostra em modalidade de acesso controlado**, conforme o protocolo de disponibilização e os documentos metodológicos do IBGE. Os arquivos individuais de microdados não integram os produtos públicos do repositório.

Os anos **2000, 2010 e 2022 são recortes de análise**. Essa convenção não autoriza pressupor que toda informação derivada do Censo represente exatamente as condições observadas na data censitária — atenção especialmente importante para `SOC03_EV0`.

### 4.2. Correspondência das variáveis

As variáveis originais são convertidas, por adaptadores específicos de cada Censo, em uma estrutura operacional comum. A tabela identifica os campos efetivamente consultados pelos adaptadores sociais:

| Informação | Censo 2000 | Censo 2010 | Censo 2022 |
|---|---|---|---|
| Município | `code_muni` / `V0103`; UF `V0102` | `code_muni` / `V0002`; UF `V0001` | `P0080` |
| Peso amostral | `P001` | `V0010` | `P0111` |
| Sexo da pessoa | `V0401` | `V0601` | `P0160` |
| Idade | `V4752` | `V6036` | `P0181` |
| Situação urbano-rural | `V1006` | `V1006` | `P0140` |
| Alfabetização | `V0428` | `V0627` | `P0640` |
| Filhos nascidos vivos — total | `V4620` | `V6633` | `P0340` |
| Filhos nascidos vivos — masculinos | `V4621` | `V6631` | `P0320` |
| Filhos nascidos vivos — femininos | `V4622` | `V6632` | `P0330` |
| Filhos sobreviventes — total | `V0463` | `V6643` | `P0370` |
| Filhos sobreviventes — masculinos | `V4631` | `V6641` | `P0350` |
| Filhos sobreviventes — femininos | `V4632` | `V6642` | `P0360` |

No Censo 2010, os controles de fecundidade `V0663` e de sobrevivência `V0664` também são lidos pelo adaptador. Os códigos apresentados identificam **variáveis utilizadas pela implementação** e não substituem os dicionários oficiais dos Censos para a interpretação completa das categorias e universos.

Na estrutura comum, as variáveis principais recebem as denominações `ano`, `uf`, `cod_mun`, `peso`, `sexo`, `idade`, `rural` e `alfabetizado`. O `SOC03_EV0` utiliza adicionalmente as contagens declaradas de filhos nascidos vivos e de filhos sobreviventes, totais e segundo o sexo dos filhos.

**Precisão terminológica para o SOC03:** as informações de fecundidade e sobrevivência são declaradas **pelas mulheres entrevistadas**; a classificação Masculino/Feminino utilizada nas contagens refere-se ao **sexo dos filhos**. A distinção é fundamental para interpretar a estimação posterior da expectativa de vida por sexo.

### 4.3. Pesos, universos e informações ausentes

São empregados os pesos amostrais compatíveis com cada arquivo censitário. Somente registros com identificação municipal e peso válido e positivo integram a estrutura de processamento. Informações ausentes nas demais variáveis são preservadas nessa etapa e tratadas de acordo com o universo de cada indicador.

Nos indicadores proporcionais, o denominador corresponde à soma dos pesos **dos registros elegíveis e com informação válida para a característica pertinente**. Portanto, os denominadores de alfabetização, situação rural e estrutura etária não precisam ser numericamente idênticos.

Para as informações de fecundidade, os adaptadores distinguem **ausência estrutural** de **informação faltante**. Em situações explicitamente identificadas como ausência de filhos nascidos vivos, determinados campos de sobrevivência originalmente vazios são interpretados como zero estrutural. Uma ausência de informação sobre sobrevivência com filhos nascidos vivos declarados **não é preenchida automaticamente**.

### 4.4. Unidade territorial e referência municipal

Os produtos são organizados em escala municipal, preservando os códigos dos municípios correspondentes aos recortes de análise. As quantidades esperadas são **5.507 municípios para 2000, 5.565 para 2010 e 5.570 para 2022**.

A exportação pública acrescenta nomes obtidos de uma referência de municípios do IBGE de 2025, associados pelo código. **Essa associação destina-se à identificação nominal e não representa uma reconstrução retroativa das malhas e dos limites municipais** dos Censos anteriores.

A interpretação de mudanças entre recortes deve considerar a alteração do universo territorial e eventuais diferenças na delimitação das unidades municipais.

## 5. Metodologia dos indicadores

### 5.1. `SOC01_ALF15` — Alfabetização da população de 15 anos ou mais

**Definição operacional.** Percentual ponderado de pessoas com **15 anos ou mais** que foram classificadas como alfabetizadas, entre aquelas da mesma faixa etária com informação de alfabetização válida.

Para município \(m\), grupo populacional \(g\) e recorte \(t\):

$$
SOC01_{m,g,t}=100\times
\frac{\sum_{i\in U_{m,g,t}} w_i\,I(\mathrm{alfabetizado}_i=1)}
{\sum_{i\in U_{m,g,t}}w_i},
$$

em que \(w_i\) é o peso da pessoa, \(I(\cdot)\) é a função indicadora e \(U\) contém exclusivamente registros com idade conhecida, idade igual ou superior a 15 anos e condição de alfabetização conhecida.

A classificação segue as respostas e categorias operacionais dos respectivos microdados. O resultado não mede anos de estudo, proficiência em leitura, qualidade da educação ou acesso efetivo à informação sobre secas.

### 5.2. `SOC02_RURAL` — População residente em área rural

**Definição operacional.** Percentual ponderado de residentes em domicílios classificados como rurais, no conjunto de pessoas com classificação urbano-rural válida.

$$
SOC02_{m,g,t}=100\times
\frac{\sum_{i\in U_{m,g,t}} w_i\,I(\mathrm{rural}_i=1)}
{\sum_{i\in U_{m,g,t}}w_i}.
$$

Não há restrição etária adicional. A classificação corresponde à situação territorial registrada pelo levantamento censitário, não a uma determinação independente de ruralidade baseada em uso da terra, produção agrícola ou densidade demográfica.

**Atenção à comparabilidade:** a leitura de mudanças entre 2000, 2010 e 2022 deve considerar as regras e os critérios empregados pelo IBGE para classificação urbano-rural em cada período. Uma diferença observada pode combinar mudança populacional efetiva com alterações classificatórias ou administrativas.

### 5.3. `SOC03_EV0` — Expectativa de vida ao nascer

#### 5.3.1. Natureza do indicador

A expectativa de vida ao nascer, usualmente representada por \(e_0\), sintetiza a duração média da vida correspondente a um padrão de mortalidade expresso por uma tábua de vida de período. Neste projeto, **não se dispõe de tábuas de mortalidade municipal observadas diretamente para todos os recortes**. O valor municipal é produzido por **estimação indireta e procedimentos de modelagem**, utilizando informações censitárias retrospectivas sobre sobrevivência dos filhos, referências demográficas externas e calibração.

Consequentemente, `SOC03_EV0` **não deve ser descrito como uma expectativa de vida municipal observada pelo Censo ou publicada diretamente pelo IBGE**.

#### 5.3.2. Informações censitárias e preparação dos insumos

O universo de preparação compreende mulheres de **15 a 49 anos**, distribuídas nos grupos quinquenais 15–19, 20–24, 25–29, 30–34, 35–39, 40–44 e 45–49 anos.

Para cada município, grupo etário materno e grupo de sexo dos filhos, são agregados:

- número de mulheres na amostra e soma dos respectivos pesos;
- número declarado de filhos nascidos vivos e número de filhos ainda vivos;
- contagens originais da amostra e totais expandidos pelos pesos;
- proporção de filhos falecidos.

Essa proporção é calculada **após a agregação** das contagens ponderadas, e não como média simples das proporções individuais:

$$
D_{m,g,a}=
\frac{B_{m,g,a}-S_{m,g,a}}{B_{m,g,a}},
$$

em que \(B\) corresponde aos filhos nascidos vivos ponderados, \(S\) aos filhos sobreviventes ponderados, \(a\) à faixa etária da mãe e \(g\) ao grupo de sexo dos filhos.

As contagens originais, sem expansão, são preservadas para reconhecer eventos efetivamente ausentes na amostra e apoiar o diagnóstico de estimativas instáveis.

#### 5.3.3. Estimação indireta pelo método Brass–Trussell

A implementação utiliza a **variante de Trussell do método de Brass**, com coeficientes associados à família de tábuas-modelo Coale–Demeny West. Essa abordagem está documentada nas orientações demográficas das Nações Unidas, especialmente no *Manual X* (1983) e no *Step-by-Step Guide to the Estimation of Child Mortality* (1990).

Calcula-se a paridade média de cada grupo etário materno como a razão entre filhos nascidos vivos ponderados e mulheres ponderadas. As razões das paridades dos três primeiros grupos (15–19, 20–24 e 25–29 anos) alimentam as expressões para o multiplicador \(k(a)\) e o tempo retrospectivo \(t(a)\):

$$
\begin{aligned}
k(a) &= a_k+b_k(P_1/P_2)+c_k(P_2/P_3),\\
t(a) &= a_t+b_t(P_1/P_2)+c_t(P_2/P_3),\\
q(x) &= k(a)\,D(a).
\end{aligned}
$$

Os coeficientes dependem do grupo etário materno e da idade \(x\) associada à probabilidade estimada. Para o grupo de **30–34 anos**, a probabilidade estimada corresponde a \(q(5)\): morrer antes de completar cinco anos de idade.

A estimativa possui um **período retrospectivo de referência**, dado pelo tempo \(t\) subtraído da data censitária expressa em ano decimal. A implementação utiliza **1º de agosto** como data de referência dos três Censos. Assim, **o ano do arquivo censitário e o ano estimado de referência da mortalidade não são, necessariamente, coincidentes**.

Estimativas matematicamente fora do intervalo admissível de probabilidades são sinalizadas e não passam como valores operacionais válidos. Os valores originais são mantidos para auditoria, sem correção arbitrária ou truncamento silencioso.

#### 5.3.4. Escolha de \(q(5)\) e referencial estadual

O processamento principal seleciona as informações associadas a mulheres de **30–34 anos**. Isso não significa que as demais faixas sejam descartadas de toda a metodologia: as paridades dos grupos mais jovens são necessárias à estimação dos multiplicadores e dos tempos de referência.

No caminho operacional, o multiplicador \(k\) e o tempo retrospectivo \(t\) aplicados à estimativa estabilizada são calculados **no nível da UF**, a partir de paridades agregadas. Essa escolha evita transferir diretamente para a estimativa municipal o ruído das razões de paridade calculadas em amostras locais reduzidas.

Para cada UF, ano e grupo, estabelece-se também uma proporção de filhos falecidos de referência, \(D_{UF}\), calculada com os dados ponderados válidos do grupo materno selecionado. A quantidade \(q(5)_{UF}=k_{UF}D_{UF}\) serve como referência à etapa posterior.

#### 5.3.5. Justificativa e especificação da estabilização Empirical Bayes

Em municípios com poucos filhos observados na amostra, a proporção de filhos falecidos pode apresentar alta instabilidade. A ocorrência de nenhum óbito observado não equivale, necessariamente, à ausência de risco de mortalidade. Por essa razão, o processamento utiliza **Empirical Bayes (EB)** para estabilizar as estimativas municipais.

**A especificação efetivamente utilizada no processamento principal** é:

| Elemento | Implementação |
|---|---|
| Modelo | Gama-Poisson |
| Parâmetro modelado | Risco relativo municipal de mortalidade em relação à referência da UF |
| Ancoragem | Proporção \(D_{UF}\) específica do ano, UF e grupo |
| Estratificação do ajuste | Nacional, separadamente por ano e grupo |
| Covariáveis | Nenhuma |
| Pseudocontagens | Pesos normalizados ao número observado de mulheres na amostra |
| Multiplicador e tempo do método indireto | Referência da UF (\(k_{UF}\), \(t_{UF}\)) |
| Intervalos | Intervalos posteriores de 90%, condicionais ao modelo |

As quantidades ponderadas de filhos nascidos vivos e de filhos falecidos são convertidas em pseudocontagens por um fator comum:

$$
f_{m,g}=\frac{n_{\mathrm{mulheres},m,g}}{\sum_i w_i},
\qquad B^{ef}_{m,g}=B_{m,g}\,f_{m,g},
\qquad d^{ef}_{m,g}=d_{m,g}\,f_{m,g}.
$$

Essa operação **preserva a proporção ponderada de filhos falecidos** e ajusta a escala das contagens à dimensão da amostra observada. Não se trata de uma reprodução integral do desenho amostral complexo do Censo.

O modelo principal pode ser sintetizado por:

$$
\begin{aligned}
E_m&=B^{ef}_mD_{UF},\\
d^{ef}_m\mid\theta_m&\sim \mathrm{Poisson}(E_m\theta_m),\\
\theta_m&\sim\mathrm{Gama}(a,\,\text{taxa}=a).
\end{aligned}
$$

Nessa parametrização, a média a priori do risco relativo \(\theta_m\) é igual a 1. O hiperparâmetro \(a\) é estimado por **máxima verossimilhança marginal** para cada ano e grupo, utilizando o conjunto nacional de municípios com informação válida. Como as pseudocontagens podem assumir valores fracionários, o ajuste deve ser interpretado como **aproximação estatística sobre contagens efetivas**, e não como observação literal de contagens de óbitos inteiras em um experimento Poisson. A média posterior é:

$$
\widehat\theta_m=\frac{a+d^{ef}_m}{a+E_m}.
$$

Logo, a estimativa da probabilidade de morrer antes dos cinco anos é obtida por:

$$
\widehat q(5)_{m,g}=
 k_{UF,g}\,D_{UF,g}\,\widehat\theta_{m,g}.
$$

A retração em direção à referência estadual é maior onde a informação municipal tem menor peso estatístico segundo o modelo. Os intervalos de 90% resultam da distribuição posterior Gama do risco relativo e são propagados para \(q(5)\).

**Limite de interpretação:** a escala das pseudocontagens e os intervalos posteriores não incorporam automaticamente todos os efeitos do plano amostral — como conglomerados e dependências entre filhos de uma mesma mãe. Portanto, esses intervalos não devem ser tratados como intervalos oficiais de erro amostral do IBGE.

O código também contém uma alternativa **Beta-binomial**, outras opções de estratificação, covariáveis e comparação de especificações. Esses recursos não devem ser confundidos com o fluxo principal descrito acima. A escolha operacional documentada é Gama-Poisson sem covariáveis e com ajuste nacional por ano e grupo.

#### 5.3.6. Consistência entre os grupos Total, Masculino e Feminino

A etapa EB calcula estimativas para os três grupos. Entretanto, a **conversão operacional final para expectativa de vida** toma o \(q(5)\) estabilizado do grupo **Total** como referência municipal e utiliza as razões entre as âncoras estaduais masculina, feminina e total para construir os valores por sexo.

Sejam:

$$
\rho_M=\frac{q(5)_{UF,M}}{q(5)_{UF,T}},
\qquad
\rho_F=\frac{q(5)_{UF,F}}{q(5)_{UF,T}},
\qquad p_M=\frac{105}{205}.
$$

As probabilidades municipais por sexo são obtidas por:

$$
\widehat q(5)_{m,s}=
\widehat q(5)_{m,T}\,
\frac{\rho_s}{p_M\rho_M+(1-p_M)\rho_F},
\quad s\in\{M,F\}.
$$

A parametrização preserva a identidade de composição:

$$
p_M\,\widehat q(5)_{m,M}+(1-p_M)\,\widehat q(5)_{m,F}
=\widehat q(5)_{m,T}.
$$

**O valor \(105/205\) é um parâmetro fixo da implementação**, não uma proporção calculada separadamente a partir da população de cada município. A decomposição pressupõe que os diferenciais por sexo definidos pelas referências estaduais sejam aplicáveis à representação municipal; ela não identifica uma mortalidade municipal independente para cada sexo com base em eventos locais suficientes.

Os grupos finais Masculino e Feminino referem-se à **mortalidade dos filhos de cada sexo**, e não a diferenças entre homens e mulheres respondentes à entrevista censitária.

#### 5.3.7. Tábuas-modelo West e conversão de \(q(5)\) para \(e_0\)

A conversão utiliza a família **West** das tábuas-modelo de vida **Coale–Demeny**, na versão estendida disponibilizada pela Divisão de População do Departamento de Assuntos Econômicos e Sociais das Nações Unidas (**UN DESA**).

A fonte operacional incorporada ao projeto contém tábuas completas por sexo para expectativas de vida ao nascer entre **20 e 100 anos**, em incrementos de um ano, com idades de **0 a 130 anos**. Para cada tábua, calcula-se:

$$
q(5)=1-\frac{l(5)}{l(0)},
$$

em que \(l(x)\) representa os sobreviventes da tábua na idade exata \(x\).

A correspondência entre uma probabilidade municipal \(q(5)\) e \(e_0\) é obtida por **interpolação linear em \(\log q(5)\)**, separadamente para os sexos Masculino e Feminino. Entre dois níveis adjacentes \(j\) e \(j+1\):

$$
\widehat e_0^{West}(q)=e_{0,j}+
\frac{\log q-\log q_j}{\log q_{j+1}-\log q_j}
(e_{0,j+1}-e_{0,j}).
$$

Não é permitida extrapolação fora do domínio da tábua. Valores fora desse intervalo recebem sinalização explícita. Como a relação entre \(q(5)\) e \(e_0\) é inversa, os limites inferior e superior dos intervalos são **invertidos** na conversão.

A rotina histórica que convertia \(q(5)\) por interpolação diretamente na escala de probabilidade **não corresponde ao procedimento operacional final**. A especificação vigente utiliza interpolação em escala logarítmica na referência West estendida.

#### 5.3.8. Calibração estadual com as tábuas do IBGE

A estimativa inicial obtida da West é ajustada por uma referência estadual construída com as **Projeções da População do IBGE — Revisão 2024**, para as 27 UFs, os três recortes temporais e os sexos Masculino e Feminino.

Para cada UF, ano e sexo, a probabilidade \(q(5)\) de referência é calculada com a razão entre os sobreviventes nas idades 5 e 0. Obtém-se então a diferença:

$$
\Delta_{UF,s,t}=
 e^{IBGE}_{0,UF,s,t}-
 e^{West}_{0}\!\left(q(5)^{IBGE}_{UF,s,t}\right).
$$

A correção aditiva é aplicada ao município pertencente à mesma UF:

$$
\widehat e_{0,m,s,t}=
 e^{West}_0\!\left(\widehat q(5)_{m,s,t}\right)
 +\Delta_{UF,s,t}.
$$

Quando as referências estaduais esperadas não estão disponíveis, o procedimento interrompe a execução; **não há substituição automática por uma calibração nacional**.

Por fim, o grupo Total é calculado como uma composição dos resultados masculino e feminino:

$$
\widehat e_{0,m,T,t}=
 p_M\,\widehat e_{0,m,M,t}+
 (1-p_M)\,\widehat e_{0,m,F,t},
 \qquad p_M=\frac{105}{205}.
$$

Esse resultado Total é, portanto, uma **combinação ponderada das expectativas de vida estimadas por sexo**, não uma tábua municipal total calculada de forma independente. A calibração por UF tampouco elimina outras fontes de incerteza das estimativas municipais.

#### 5.3.9. Referência temporal e limites da estimativa

O `SOC03_EV0` exige distinguir três referências: **(i)** o ano do Censo que fornece os dados retrospectivos; **(ii)** o período estimado de referência da mortalidade infantojuvenil pelo método Trussell; e **(iii)** o ano das tábuas estaduais do IBGE utilizadas na calibração. A combinação desses elementos é uma decisão metodológica específica do projeto e deve ser explicitada ao comparar os recortes.

O procedimento permite gerar uma série municipal modelada para os grupos previstos, mas **não equivale à reconstrução integral das taxas municipais de mortalidade por idade**. A conversão de \(q(5)\) em \(e_0\) depende das relações assumidas pela família West, da decomposição por sexo e da calibração estadual. Sua interpretação deve preservar esse caráter indireto e modelado.

### 5.4. `SOC04_POP1564` — População de 15 a 64 anos

**Definição operacional.** Percentual ponderado de pessoas com idade entre **15 e 64 anos, inclusive**, em relação à população com idade válida e não negativa.

$$
SOC04_{m,g,t}=100\times
\frac{\sum_{i\in U_{m,g,t}} w_i\,I(15\leq\mathrm{idade}_i\leq64)}
{\sum_{i\in U_{m,g,t}}w_i}.
$$

O universo do denominador compreende pessoas com idade válida igual ou superior a zero. O indicador expressa a **parcela da estrutura etária situada nessa faixa**, e não a taxa de participação na força de trabalho, o percentual de pessoas ocupadas ou a razão de dependência demográfica.

Embora a estrutura etária também integre referenciais internacionais, a medida operacional empregada aqui é **a proporção entre 15 e 64 anos**, e não a razão de dependência etária; essas variáveis não são intercambiáveis.

## 6. Controle de qualidade e validação

### 6.1. Verificações comuns

Os controles implementados verificam identificação e unicidade dos registros por município, ano, grupo e indicador, integridade dos pesos, compatibilidade das estruturas produzidas pelos três adaptadores e presença dos grupos Total, Masculino e Feminino.

Para `SOC01_ALF15`, `SOC02_RURAL` e `SOC04_POP1564`, os valores percentuais devem pertencer ao intervalo **[0, 100]**. São preservados, quando disponíveis, numerador, denominador, número de registros amostrais e tamanho amostral efetivo associado à distribuição dos pesos:

$$
n_{ef}=\frac{\left(\sum_i w_i\right)^2}{\sum_i w_i^2}.
$$

Essa quantidade é útil ao diagnóstico de diferenças de precisão, mas **não é uma estimativa completa da variância sob o plano amostral complexo** e não define, isoladamente, exclusão automática de municípios.

### 6.2. Auditorias específicas do `SOC03_EV0`

Os produtos intermediários permitem examinar a consistência entre filhos nascidos vivos, sobreviventes e falecidos; os zeros realmente observados na amostra; a validade dos multiplicadores e dos tempos retrospectivos; as condições de convergência e retração do modelo EB; os intervalos posteriores; a permanência de \(q(5)\) no domínio das tábuas-modelo; a disponibilidade da calibração UF/ano/sexo; e a coerência algébrica entre os resultados Total, Masculino e Feminino.

Os procedimentos preservam sinalizações de valores fora do domínio e outras situações de diagnóstico, em vez de atribuir automaticamente valores substitutos. A existência de estimativas por município não elimina a necessidade de avaliação de suas incertezas e pressupostos.

### 6.3. Cobertura territorial dos produtos

A estrutura de exportação prevê **um registro por município e grupo em cada indicador e ano**:

| Ano | Municípios do recorte | Registros por indicador (3 grupos) | Indicadores sociais |
|---|---:|---:|---:|
| 2000 | 5.507 | 16.521 | 4 |
| 2010 | 5.565 | 16.695 | 4 |
| 2022 | 5.570 | 16.710 | 4 |

Essas são as coberturas esperadas e adotadas nas verificações. A conferência conclusiva de uma execução deve utilizar os resultados efetivamente produzidos e os respectivos registros de auditoria; a tabela não substitui tal conferência.

## 7. Limitações e cuidados de interpretação

A documentação dos indicadores deve preservar as limitações específicas das fontes e dos procedimentos empregados:

| Aspecto | Implicação |
|---|---|
| Abrangência conceitual | Os quatro indicadores descrevem atributos distintos; não medem isoladamente a vulnerabilidade à seca. |
| Agregação municipal | Médias ou proporções municipais podem ocultar desigualdades internas. |
| Comparabilidade territorial | O conjunto de municípios e seus limites podem diferir entre 2000, 2010 e 2022. |
| Comparabilidade censitária | Instrumentos, categorias e tratamentos dos dados podem mudar entre Censos. |
| Indicadores proporcionais | Universos com informação válida podem diferir, mesmo dentro do mesmo município. |
| Amostragem | Pesos e diagnósticos de tamanho efetivo não reproduzem sozinhos o desenho completo da amostra. |
| `SOC02_RURAL` | A classificação censitária de rural não equivale a ocupação agrícola nem a escassez de água. |
| `SOC04_POP1564` | A faixa 15–64 não informa diretamente emprego, renda ou dependência econômica. |
| `SOC03_EV0` | Estimativa indireta, dependente de modelo, hipótese de decomposição por sexo, tábua West e calibração estadual. |
| Referência temporal do `SOC03` | O período retrospectivo da mortalidade não coincide necessariamente com o ano censitário. |

Em particular, a dimensão Social **não identifica quais pessoas efetivamente sofreram impactos da seca**. Essa inferência exigiria informações de outra natureza e procedimentos analíticos adicionais.

## 8. Produtos, rastreabilidade e reprodutibilidade

### 8.1. Produtos municipais

Os resultados brutos individuais são organizados em `so3.3/outputs/bruto/social/<ano>/`, com um arquivo RDS e um arquivo CSV para cada um dos quatro indicadores. Os CSVs públicos seguem a estrutura:

`ano;uf;cod_mun;nm_mun;indicador;grupo;valor`

Os nomes dos municípios são empregados para identificação e não alteram o universo territorial do recorte. Produtos metodológicos intermediários — particularmente as etapas de estimação do `SOC03_EV0` — são armazenados em `so3.3/outputs/intermediario/social/<ano>/`.

Os dados individuais do Censo Demográfico 2022 sujeitos a acesso controlado **não são redistribuídos** como parte desses produtos.

### 8.2. Organização do processamento

A unidade operacional do projeto é **uma dimensão e um ano por execução**. O arquivo [`main.R`](../../main.R) seleciona a dimensão Social e o ano; os processadores executam os procedimentos correspondentes, utilizando resultados intermediários previamente disponíveis quando aplicável.

As seguintes rotinas constituem pontos de rastreabilidade, **sem necessidade de reproduzir o código neste documento**:

| Função metodológica | Módulo do repositório |
|---|---|
| Harmonização dos três Censos | [`adaptar_censo_2000.R`](../../R/01_leitura/adaptar_censo_2000.R), [`adaptar_censo_2010.R`](../../R/01_leitura/adaptar_censo_2010.R), [`adaptar_censo_2022.R`](../../R/01_leitura/adaptar_censo_2022.R) |
| Cálculo de SOC01, SOC02 e SOC04; preparação de insumos demográficos | [`social.R`](../../R/02_indicadores/social.R) |
| Método Brass–Trussell e funções demográficas | [`expectativa_vida_indireta.R`](../../R/02_indicadores/expectativa_vida_indireta.R) |
| Preparação dos insumos e estabilização EB | [`estabilizacao_q5_eb.R`](../../R/02_indicadores/estabilizacao_q5_eb.R) |
| Preparação da West estendida e calibração IBGE | [`preparar_referencias_soc03.R`](../../R/02_indicadores/preparar_referencias_soc03.R) |
| Conversão operacional para expectativa de vida ao nascer | [`converter_soc03_ev0.R`](../../R/02_indicadores/converter_soc03_ev0.R) |
| Orquestração da dimensão Social | [`processar_social.R`](../../R/04_execucao/processar_social.R) |
| Exportação municipal bruta | [`exportar_resultados_csv.R`](../../R/05_exportacao/exportar_resultados_csv.R) |

### 8.3. Referências operacionais vinculadas aos resultados

A tábua West estendida é preparada a partir do arquivo `inputs/referencias/undesa/model_life_tables_2011/undesa_pd_2026_mlt_un2011_130_1y_complete.xlsx`; a referência estadual utiliza `inputs/referencias/ibge/projecoes_2024_tab5_tabuas_mortalidade.xlsx`. Os derivados necessários às conversões e a auditoria da sua origem são mantidos nos diretórios intermediários.

A referência histórica da família West também está documentada em [`inputs/referencias/coale_demeny/README.md`](../../inputs/referencias/coale_demeny/README.md), mas **não deve ser confundida** com a grade estendida utilizada na conversão operacional final.

A reprodução integral pressupõe o acesso legítimo às bases originais, às versões corretas das referências e às condições de utilização aplicáveis aos microdados de acesso controlado.

## 9. Referências bibliográficas e documentais

### 9.1. Referências institucionais e fontes de dados

- **PRAIS_BRASIL / Centro Nacional de Monitoramento e Alertas de Desastres Naturais (CEMADEN).** *Nota Técnica — Bases de dados, procedimentos metodológicos e limitações na caracterização da ameaça, exposição e vulnerabilidade à seca no Brasil.* Versão preliminar revisada para discussão técnica, outubro de 2026. **Referência de enquadramento e terminologia**; não substitui a documentação das etapas computacionais concluídas posteriormente.
- **FAO — Food and Agriculture Organization of the United Nations.** *Drought Portal — Vulnerability and Impact Assessment Compendium: Context; Guidelines; Indicators and Data Sources.* Fonte de referência conceitual e de seleção de indicadores. [Contexto dos indicadores](https://www.fao.org/in-action/drought-portal/preparedness/vulnerability-and-impact-assessment/vulnerability-and-impact-assessment-compendium-intro/en) · [Orientações](https://www.fao.org/in-action/drought-portal/preparedness/vulnerability-and-impact-assessment/compendium---chapter-2/en) · [Indicadores e fontes](https://www.fao.org/in-action/drought-portal/preparedness/vulnerability-and-impact-assessment/compendium---chapter-3/en).
- **UNCCD — United Nations Convention to Combat Desertification.** *PRAIS4 Reporting Manual.* Documento de orientação do SO3.3, edição utilizada no PRAIS_BRASIL.
- **Crossman, N. D.; Tsegai, D. / UNCCD.** (2019). *Drought Resilience, Adaptation and Management Policy Framework: Supporting Technical Guidelines.* Referência complementar de enquadramento sobre avaliação de vulnerabilidade e risco à seca. [Publicação UNCCD](https://www.unccd.int/publications/drought-resilience-adaptation-and-management-policy-framework-supporting-technical).
- **IBGE — Instituto Brasileiro de Geografia e Estatística.** *Censos Demográficos de 2000, 2010 e 2022: microdados da amostra, dicionários de variáveis e documentação metodológica pertinente a cada recorte.* Fontes primárias dos indicadores sociais.
- **IBGE.** *Censo Demográfico 2022 — Notas metodológicas n. 02/2026, 03/2026, 04/2026 e 05/2026.* Documentação sobre áreas de ponderação, confidencialidade, expansão da amostra e microdados. [Página institucional do Censo 2022](https://www.ibge.gov.br/estatisticas/sociais/populacao/22827-censo-demografico-2022.html).
- **IBGE.** *Projeções da População — Revisão 2024: tábuas de mortalidade, Tabela 5.* Fonte estadual da calibração do `SOC03_EV0`; arquivo operacional especificado na seção 8.3.
- **UN DESA — United Nations Department of Economic and Social Affairs, Population Division.** *Model Life Tables.* Fonte da família Coale–Demeny West estendida. [Repositório oficial de tábuas-modelo](https://www.un.org/development/desa/pd/data/model-life-tables).

### 9.2. Referências demográficas e de modelagem

- **United Nations.** (1983). *Manual X: Indirect Techniques for Demographic Estimation.* Population Studies, No. 81. New York: United Nations. [Catálogo da Divisão de Estatística](https://unstats.un.org/unsd/demographic-social/standards-and-methods/).
- **United Nations, Department of International Economic and Social Affairs.** (1990). *Step-by-Step Guide to the Estimation of Child Mortality.* Population Studies, No. 107. ST/ESA/SER.A/107. New York: United Nations. [Biblioteca Digital das Nações Unidas](https://digitallibrary.un.org/record/129922/).

**Bibliografia complementar sobre estimação em pequenas áreas e Empirical Bayes — incluída como apoio conceitual a discutir, não como atribuição automática de autoria das decisões específicas do projeto:**

- **Rao, J. N. K.; Molina, I.** (2015). *Small Area Estimation.* 2ª ed. Wiley. [DOI: 10.1002/9781118735855](https://doi.org/10.1002/9781118735855).
- **Clayton, D.; Kaldor, J.** (1987). *Empirical Bayes estimates of age-standardized relative risks for use in disease mapping.* **Biometrics**, 43(3), 671–681. [PubMed](https://pubmed.ncbi.nlm.nih.gov/3663823/).

### 9.3. Pontos de verificação documental

Esta versão registra pontos que **permanecem para conferência documental posterior**, sem preencher lacunas por suposição:

1. **Brass–Trussell:** conferir a tabela e as páginas exatas das referências originais que fundamentam os coeficientes numéricos de \(k\) e \(t\) inseridos no módulo demográfico.
2. **Parâmetro \(p_M=105/205\):** registrar formalmente sua justificativa e sua natureza de hipótese fixa de composição entre os sexos.
3. **Empirical Bayes:** vincular a decisão pelo modelo Gama-Poisson aos diagnósticos comparativos que efetivamente tenham sido produzidos, evitando apresentar superioridade empírica não demonstrada no documento.
4. **Bases e variáveis censitárias:** confrontar a tabela de correspondência com os dicionários oficiais das versões efetivamente utilizadas, particularmente para os casos de ausência estrutural nas variáveis de filhos sobreviventes.
5. **Resultados finais:** incorporar números auditados de cobertura, ausências, intervalos e alertas do `SOC03_EV0` a partir dos registros de processamento, em vez de estimá-los pelo código ou inferi-los apenas pela existência dos CSVs.
6. **Comparabilidade:** registrar quaisquer decisões adicionais de harmonização territorial e temporal que sejam formalmente estabelecidas para as análises comparativas dos três recortes.

---

**Situação editorial:** versão aprovada para inclusão no repositório, preservando os pontos de conferência documental da seção 9.3 e a distinção rigorosa entre indicadores, dimensões e DVI.