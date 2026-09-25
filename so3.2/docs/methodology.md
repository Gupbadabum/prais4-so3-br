# SO3.2 — Metodologia para exposição da população à seca

Este documento registra as decisões metodológicas e operacionais adotadas
para o cálculo da exposição da população à seca no âmbito do PRAIS 4 —
Brasil, incluindo as regras de harmonização espacial, tratamento temporal,
controle de qualidade e geração dos produtos derivados.

O SO3.2 combina os produtos de ameaça climática desenvolvidos no SO3.1 com
dados populacionais do WorldPop, preservando a resolução espacial da grade
populacional como referência para os produtos raster.

## Objetivo

Quantificar a população exposta às diferentes classes de intensidade de seca,
considerando separadamente:

- população total;
- população feminina;
- população masculina.

O processamento contempla resultados anuais para o período 2000–2023 e sua
consolidação nos quadriênios definidos para o PRAIS 4:

- 2000–2003;
- 2004–2007;
- 2008–2011;
- 2012–2015;
- 2016–2019;
- 2020–2023.

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

Valores sem informação são preservados como NoData e não são interpretados
como condição normal.

### População

A base populacional é derivada do WorldPop em resolução aproximada de 100 m.

São mantidos três recortes populacionais:

- população total;
- população feminina;
- população masculina.

A população total é tratada como produto independente.

As populações feminina e masculina são obtidas a partir da agregação das
classes etárias correspondentes dos produtos WorldPop desagregados por sexo.

A soma das populações feminina e masculina constitui um controle de
consistência em relação ao produto de população total, mas não é utilizada
para substituí-lo.

A série WorldPop utilizada possui dados anuais entre 2000 e 2020. Para os
anos analíticos de 2021, 2022 e 2023 é reutilizada a população referente ao
ano-fonte 2020, conforme a metodologia adotada para o SO3.2.

## Grade espacial de referência

A grade nativa do WorldPop constitui a grade espacial de referência do SO3.2.

Para o Brasil, a grade validada utilizada no processamento possui:

- CRS: EPSG:4326;
- dimensões: 54.172 × 46.814 pixels;
- resolução aproximada: 0,00083333333°;
- resolução nominal aproximada: 100 m.

Os produtos de seca, originalmente em resolução de 0,1°, são avaliados sobre
essa grade populacional.

Por se tratar de uma variável categórica, a reamostragem da ameaça utiliza
exclusivamente o método de vizinho mais próximo (*Nearest Neighbour*).

Nenhuma interpolação contínua é aplicada às classes de seca.

A transformação afim validada da grade WorldPop utilizada como referência é:

```text
[ 0.0008333333300044304,  0,                     -73.989583022,
  0,                    -0.0008333333300081173,   5.264583514 ]
```

Essa transformação corresponde a:

- origem X: `-73.989583022`;
- origem Y: `5.264583514`;
- resolução X: `0.0008333333300044304°`;
- resolução Y: `-0.0008333333300081173°`;
- largura: `54172` pixels;
- altura: `46814` pixels.

A preservação dessa grade é obrigatória nos produtos raster finais. Nas
exportações realizadas pelo Google Earth Engine, a configuração validada
utiliza explicitamente as dimensões, o CRS e a transformação afim da grade
WorldPop.

A definição explícita de uma região de exportação (`region`) não é utilizada
nos produtos finais, pois os testes de alinhamento demonstraram que essa
abordagem pode alterar a extensão e as dimensões da grade. A configuração
validada utiliza, portanto, `dimensions`, `crs` e `crsTransform`, sem
especificação de `region`.

## Tratamento de NoData

Ausência de informação é conceitualmente distinta tanto de população igual a
zero quanto da classe 5 de seca, correspondente à condição Normal.

Nos produtos raster persistidos são utilizados:

- `0` como código NoData para a seca categórica;
- `-9999` como NoData para população e população exposta.

Durante o processamento, valores ausentes permanecem mascarados sempre que o
ambiente computacional oferece suporte nativo a máscaras.

A ausência de informação climática não é preenchida, interpolada ou
reinterpretada como classe Normal.

## Exposição anual

São consideradas expostas à seca as populações localizadas em células
classificadas nas classes:

- 1 — seca extrema;
- 2 — seca severa;
- 3 — seca moderada;
- 4 — seca fraca.

A classe 5 — Normal — não integra a população exposta.

Para cada ano, a população é associada à classe de seca correspondente à
mesma localização espacial e ao mesmo ano analítico.

Os cálculos são realizados separadamente para população total, feminina e
masculina.

Além dos valores absolutos de população exposta, são calculadas as
participações percentuais correspondentes às classes de seca e à exposição
total.

## Consolidação quadrianual

Para cada célula da grade WorldPop é identificada a maior intensidade de seca
observada durante cada quadriênio.

Como os códigos são ordenados de 1, correspondente à seca extrema, a 5,
correspondente à condição Normal, a situação mais crítica corresponde ao
menor código válido observado no período.

Anos com NoData climático são excluídos da determinação da classe crítica.

### Empates da classe crítica

Quando a classe crítica ocorre em apenas um ano, utiliza-se a população
correspondente àquele ano.

Quando a mesma classe crítica ocorre em dois ou mais anos do quadriênio,
utiliza-se a média da população correspondente aos anos empatados.

A mesma seleção temporal é aplicada aos três recortes populacionais:

- total;
- feminino;
- masculino.

Esse tratamento constitui uma decisão metodológica adotada no processamento
do SO3.2 desenvolvido pelo Cemaden.

## Informações auxiliares de QA/QC

Os produtos quadrianuais incluem informações destinadas à auditoria e ao
controle de qualidade, entre elas:

- número de anos com informação climática válida;
- indicação da ocorrência de pelo menos um ano sem informação climática;
- número de anos associados à classe crítica.

Também são realizadas verificações de:

- integridade das classes de seca;
- cobertura espacial;
- correspondência temporal entre ameaça e população;
- alinhamento da grade;
- transformação espacial;
- dimensões dos produtos raster;
- consistência das somas por classe;
- consistência da população exposta.

## Produtos PRAIS e produtos derivados

O produto espacial principal do SO3.2 é mantido em formato raster sobre a
grade WorldPop.

A representação espacial destinada ao PRAIS é derivada diretamente desses
produtos raster e não da agregação municipal.

Adicionalmente, o Cemaden produz uma agregação municipal dos resultados para
fins analíticos e de apoio à interpretação.

Essa agregação utiliza uma malha territorial fixa correspondente ao
`IBGE/MUNICIPIOS/V2025`.

As duas unidades operacionais de água presentes nessa base:

- `4300001` — Área Operacional "Lagoa Mirim";
- `4300002` — Área Operacional "Lagoa dos Patos";

são excluídas da agregação municipal.

A base resultante contém 5.571 municípios ou unidades territoriais
equivalentes.

A agregação municipal é um produto derivado do Cemaden e não substitui os
produtos raster utilizados no reporte espacial do PRAIS.

## Validação do primeiro bloco

O quadriênio 2000–2003 foi utilizado como primeiro bloco de validação integral
do fluxo computacional.

Para a população total foram validadas as etapas de:

- ingestão e QA dos dados de seca;
- ingestão e QA da população;
- cálculo anual da exposição;
- consolidação quadrianual;
- tratamento de empates da classe crítica;
- preservação do NoData;
- alinhamento exato à grade WorldPop;
- geração dos produtos de QA/QC;
- agregação municipal sobre a malha IBGE 2025;
- exportação dos produtos raster e tabulares.

A validação da grade demonstrou a necessidade de definir explicitamente as
dimensões, o CRS e a transformação espacial nas exportações realizadas pelo
Google Earth Engine.

A arquitetura validada para 2000–2003 será utilizada como referência para o
processamento dos demais quadriênios e dos recortes feminino e masculino.

## Ambientes de processamento e armazenamento

O fluxo utiliza principalmente:

- Python;
- Jupyter Notebook;
- Google Earth Engine;
- Google Drive;
- GDAL;
- Git/GitHub.

O processamento pesado e os dados raster não são mantidos diretamente no
repositório Git.

O repositório é destinado principalmente a:

- código-fonte;
- notebooks;
- scripts do Google Earth Engine;
- documentação metodológica;
- metadados;
- produtos de controle de tamanho compatível;
- rastreabilidade do processamento.

Os produtos raster de grande volume são mantidos nos ambientes operacionais
de processamento e nos diretórios destinados à entrega.

## Organização do repositório

```text
so3.2/
├── README.md
├── docs/
│   └── methodology.md
├── metadata/
├── notebooks/
├── outputs/
│   ├── maps/
│   ├── rasters/
│   └── tables/
├── scripts/
│   ├── 05_build_population.py
│   └── gee/
└── src/
    └── prais_so32/

```
