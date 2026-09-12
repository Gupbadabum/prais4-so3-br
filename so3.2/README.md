```markdown
# SO3.2 — Exposição da população à seca

Este diretório reúne os procedimentos computacionais, produtos de controle
e documentação referentes ao cálculo da exposição da população à seca no
âmbito do PRAIS 4 — Brasil.

## Objetivo

Quantificar a população exposta às diferentes classes de intensidade de seca,
considerando separadamente:

- população total;
- população feminina;
- população masculina.

O processamento contempla resultados anuais para o período 2000–2023 e sua
consolidação nos quadriênios definidos pelo PRAIS 4.

## Dados principais

### Ameaça

Os dados de ameaça são provenientes do SO3.1 e consistem em GeoTIFFs anuais
do SPEI-12 de dezembro, previamente classificados.

Período:

- 2000–2023.

Resolução espacial original:

- 0,1° × 0,1°.

Classes:

| Valor | Classe |
|---:|---|
| 1 | Seca extrema |
| 2 | Seca severa |
| 3 | Seca moderada |
| 4 | Seca fraca |
| 5 | Normal |

O SO3.2 utiliza esses produtos como entrada e não recalcula ou reclassifica
o SPEI-12.

Valores sem informação são mantidos como NoData e não são interpretados como
condição normal.

### População

A base populacional é derivada do WorldPop em resolução aproximada de 100 m.

São mantidas três informações populacionais anuais:

- população total;
- população feminina;
- população masculina.

A população total é preservada como produto independente. As populações
feminina e masculina são obtidas a partir da agregação das classes etárias
correspondentes do produto WorldPop desagregado por sexo.

A soma das populações feminina e masculina é utilizada como controle de
consistência em relação ao produto de população total, sem substituí-lo.

A série WorldPop utilizada possui dados anuais entre 2000 e 2020. Para
2021–2023 são utilizados os valores populacionais de 2020, conforme o
procedimento adotado no PRAIS 4.

## Harmonização espacial

A grade WorldPop constitui a grade espacial de referência do SO3.2.

Os produtos classificados de seca, originalmente em resolução de 0,1°, são
reamostrados para a grade populacional.

Por se tratar de uma variável categórica, a reamostragem da ameaça utiliza
exclusivamente o método de vizinho mais próximo (*Nearest Neighbour*).

A grade de destino deve reproduzir as propriedades espaciais do WorldPop,
incluindo:

- sistema de referência;
- resolução;
- transformação espacial;
- origem da grade;
- dimensões;
- extensão espacial.

Nenhuma interpolação contínua é aplicada às classes de seca.

## Tratamento de NoData

Ausência de informação é conceitualmente distinta tanto de população igual a
zero quanto da classe 5 (Normal).

Nos produtos persistidos, o valor adotado para NoData é:

`-9999`

Durante o processamento, valores ausentes permanecem mascarados sempre que a
biblioteca ou ambiente computacional utilizado oferecer suporte nativo a
máscaras.

## Resultados anuais

Para cada ano são preservadas as superfícies de:

- população total;
- população feminina;
- população masculina.

Esses produtos constituem entradas reutilizáveis para o cálculo da exposição
e para análises posteriores.

A exposição anual é calculada associando cada célula populacional à classe de
seca correspondente ao mesmo ano.

## Consolidação quadrianual

São considerados os seguintes períodos:

- 2000–2003;
- 2004–2007;
- 2008–2011;
- 2012–2015;
- 2016–2019;
- 2020–2023.

Para cada célula é identificada a maior intensidade de seca observada no
quadriênio.

Como os códigos de seca são ordenados de 1 (extrema) a 5 (normal), a condição
mais crítica corresponde ao menor código válido observado.

Quando a classe crítica ocorre em apenas um ano, utiliza-se a população
correspondente àquele ano.

Quando a mesma classe crítica ocorre em dois ou mais anos do quadriênio,
utiliza-se a média da população correspondente aos anos empatados. A mesma
seleção temporal é aplicada às populações total, feminina e masculina.

Anos classificados como NoData não participam da determinação da classe
crítica. Entretanto, sua ocorrência é registrada nos produtos de controle,
permitindo identificar quadriênios com cobertura climática incompleta.

Entre as informações auxiliares previstas estão:

- número de anos com informação climática válida;
- indicação da ocorrência de pelo menos um ano sem informação;
- número de anos associados à classe crítica.

## Estratégia de desenvolvimento

O quadriênio 2000–2003 constitui o primeiro bloco de validação integral do
fluxo computacional.

Esse período será utilizado para testar conjuntamente:

- construção dos produtos populacionais anuais;
- correspondência correta entre população e ameaça por ano;
- alinhamento espacial das grades;
- reamostragem categórica da ameaça;
- tratamento de NoData;
- cálculo da exposição anual;
- tratamento de empates da classe crítica;
- consolidação quadrianual;
- produtos de QA/QC.

Somente após a validação desse bloco o processamento será escalonado para os
demais períodos.

## Ambiente computacional

O desenvolvimento utiliza principalmente:

- Python;
- Google Colab;
- Google Earth Engine;
- Google Drive;
- Git/GitHub.

O uso do Google Earth Engine e do processamento local/Colab será avaliado
conforme as características de cada etapa, buscando reduzir transferência,
armazenamento e processamento desnecessários.

## Organização do repositório

A organização do SO3.2 separa documentação, processamento e produtos de
controle:

```text
so3.2/
├── README.md
├── docs/
├── notebooks/
├── scripts/
├── src/
└── metadata/
