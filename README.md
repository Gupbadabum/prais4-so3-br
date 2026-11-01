# PRAIS4 — Brasil | Objetivo Estratégico 3: seca, exposição e vulnerabilidade

> **Apresentação do projeto.** Este repositório reúne o desenvolvimento técnico e metodológico dos indicadores brasileiros do Objetivo Estratégico 3 (SO3) do PRAIS4, no âmbito da Convenção das Nações Unidas de Combate à Desertificação (UNCCD). Seu propósito é tornar explícito **o que está sendo medido, por que essas medidas importam e quais conclusões podem — ou não — ser extraídas delas**.

## 1. Por que estudar a seca a partir de três perspectivas?

A ocorrência de uma seca não produz as mesmas consequências em todos os lugares. Territórios submetidos a condições climáticas semelhantes podem abrigar populações de tamanhos diferentes e apresentar condições sociais, econômicas e de acesso à infraestrutura bastante distintas. Por isso, conhecer apenas a intensidade da seca não é suficiente para compreender quem pode ser afetado nem quais condições podem ampliar a vulnerabilidade.

O **Objetivo Estratégico 3 da UNCCD** trata da mitigação, adaptação e gestão dos efeitos da seca, com vistas ao fortalecimento da resiliência de populações e ecossistemas vulneráveis. O PRAIS4 organiza parte desse acompanhamento em três indicadores complementares. No projeto brasileiro, eles são tratados como **objetos analíticos distintos**, com escalas, fontes e limitações próprias:

| Indicador | Pergunta orientadora | O que representa |
| --- | --- | --- |
| **SO3.1 — Ameaça de seca** | Onde e com que intensidade ocorreram condições de seca? | Condições climáticas associadas à seca, segundo uma medida padronizada. |
| **SO3.2 — Exposição da população** | Quantas pessoas se encontravam nas áreas submetidas à seca? | População espacialmente associada às classes de intensidade da seca. |
| **SO3.3 — Vulnerabilidade à seca** | Que condições dos municípios podem torná-los relativamente mais vulneráveis? | Síntese de características sociais, econômicas e infraestruturais da população e do território. |

**Ameaça, exposição e vulnerabilidade não são sinônimos.** Tampouco qualquer um desses indicadores, isoladamente, mede impactos observados, perdas econômicas ou o risco total de um desastre.

## 2. Como cada parte é construída

### SO3.1 — Caracterizar a ameaça

O SO3.1 utiliza o **Standardized Precipitation Evapotranspiration Index (SPEI)**, na escala acumulada de 12 meses (**SPEI-12**). O valor de dezembro representa, em cada ano, as condições acumuladas ao longo dos 12 meses anteriores. A análise contempla **2000–2023**, com dados climáticos em grade de aproximadamente **0,1°**.

Os valores são organizados em classes de intensidade da seca. Além dos produtos anuais, mapas de períodos de quatro anos registram, em cada célula, **a maior intensidade observada durante o quadriênio** — não a condição média ou predominante. Isso permite identificar áreas submetidas a condições mais severas em diferentes períodos.

[Conhecer a definição da ameaça e seus produtos](so3.1/README.md).

### SO3.2 — Identificar a população exposta

A exposição é estimada pela combinação dos produtos de seca do SO3.1 com informações populacionais do **WorldPop**, em grade de aproximadamente **100 m**. O objetivo é quantificar a população associada às diferentes classes de seca, distinguindo **Total, Masculino e Feminino**.

O SO3.2 produz resultados anuais e sínteses quadrianuais. Em cada quadriênio, a classe mais intensa observada na célula é a referência para a síntese espacial. A exposição descreve a **coincidência espacial entre população e condição de seca**; não demonstra que todas as pessoas expostas tenham sofrido danos. Para 2021–2023, o fluxo documentado utiliza a população de referência de 2020, dada a cobertura temporal da fonte empregada.

[Conhecer o cálculo da exposição e suas ressalvas](so3.2/README.md).

### SO3.3 — Representar a vulnerabilidade

O SO3.3 desenvolve o **Drought Vulnerability Index (DVI-Brasil)** em escala municipal, para os recortes censitários **2000, 2010 e 2022**. O índice reúne **nove indicadores nacionais** em três dimensões: **Social, Econômica e Infraestrutural**. Onde a informação permite, os resultados são apresentados para Total, Masculino e Feminino.

O DVI é uma **representação sintética, parcial e condicionada por escolhas metodológicas**. Ele não equivale a observar diretamente a vulnerabilidade de cada pessoa ou a ocorrência de impactos de uma seca. Sua utilidade está em evidenciar diferenças nas condições estruturais consideradas e oferecer uma base transparente para comparações territoriais e temporais.

[Entender o DVI-Brasil, os indicadores e a interpretação dos resultados](so3.3/README.md).

## 3. O que se espera compreender com esses produtos?

A proposta não se resume à produção de mapas ou tabelas. Ela busca construir uma leitura coerente de **onde a seca ocorre, quem está exposto e em quais condições sociais e materiais essa exposição se insere**.

Entre as perguntas que os produtos podem apoiar estão: como a distribuição territorial da ameaça se modifica entre períodos; como varia a população exposta por intensidade de seca e grupo populacional; quais municípios apresentam maiores valores relativos de vulnerabilidade; e como os componentes sociais, econômicos e infraestruturais contribuem para essas diferenças.

Uma integração posterior, de interesse analítico do **Cemaden**, poderá associar os resultados de exposição à vulnerabilidade municipal. Para esse exercício foram considerados os quadriênios **2000–2003, 2008–2011 e 2020–2023** como janelas correspondentes, respectivamente, aos recortes censitários **2000, 2010 e 2022**. Essa correspondência é **aproximativa e metodológica**, não uma afirmação de simultaneidade dos dados. A integração será um **produto derivado**, distinto dos indicadores formais de reporte SO3.1, SO3.2 e SO3.3.

## 4. Escalas, comparabilidade e interpretação responsável

Os três indicadores combinam fontes e unidades espaciais diferentes: células climáticas, grades populacionais e municípios. Também possuem referências temporais distintas: o SO3.1 e o SO3.2 tratam de anos e quadriênios, enquanto o DVI-Brasil está disponível para três recortes censitários. **Não é correto apresentar os três módulos como séries anuais equivalentes ou combinar suas saídas sem explicitar essas diferenças.**

O uso de dados nacionais melhora a aderência ao contexto brasileiro, mas introduz desafios de correspondência entre censos, estimativas, mudanças nos limites municipais e indicadores provenientes de anos-fonte diferentes. O projeto procura registrar essas escolhas, as ausências e a proveniência dos resultados, evitando preencher lacunas sem justificativa.

A desagregação por sexo também exige cuidado: alguns indicadores descrevem condições próprias de grupos populacionais, enquanto outros são atributos territoriais compartilhados. Diferenças entre índices não devem ser interpretadas automaticamente como medidas individuais de desigualdade ou como efeitos causais da seca.

## 5. Situação do desenvolvimento e produtos disponíveis

Em **novembro de 2026**, o **DVI-Brasil contínuo** encontra-se calculado para 2000, 2010 e 2022, com seus componentes e metadados de cobertura. Os fluxos de ameaça e exposição possuem metodologias e produtos próprios, com processamento e validação distribuídos por período e recorte populacional; a documentação de cada módulo identifica seu estágio efetivo.

A eventual classificação do DVI em cinco categorias, a avaliação de estabilidade dessas classes e a associação entre exposição e vulnerabilidade são **análises posteriores**. Não modificam retroativamente o índice contínuo e não devem ser confundidas com resultados já validados.

## 6. Como consultar e reproduzir

O repositório está dividido em [`so3.1/`](so3.1/README.md), [`so3.2/`](so3.2/README.md) e [`so3.3/`](so3.3/README.md). **Cada README apresenta o objeto de estudo e indica a documentação metodológica específica**; os diretórios de código, referências, metadados e produtos documentam as etapas computacionais correspondentes.

A reprodução pressupõe respeitar as fontes, as versões, as regras de tratamento e as condições de acesso aos dados. Em particular, **microdados censitários de acesso controlado não são distribuídos publicamente**. Os resultados municipais e demais produtos derivados devem ser compartilhados observando as condições aplicáveis às fontes utilizadas.

**Referências centrais:** UNCCD, *PRAIS4 Reporting Manual* (Objetivo Estratégico 3); orientações técnicas da UNCCD para avaliação de seca; FAO, *Drought Vulnerability and Impact Assessment Compendium*. As adaptações brasileiras e suas limitações estão discriminadas nos módulos específicos.
