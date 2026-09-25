# SO3.2 — Exposição da população à seca

Este diretório reúne o código, a documentação, os metadados e os produtos de controle utilizados no cálculo da exposição da população à seca no âmbito do PRAIS 4 — Brasil.
O SO3.2 combina os produtos de ameaça climática desenvolvidos no SO3.1 com dados populacionais do WorldPop, utilizando a grade populacional como referência espacial para os produtos raster.

## Objetivo

Quantificar a população exposta às diferentes classes de intensidade de seca, considerando separadamente:
- população total;
- população feminina;
- população masculina.
O período analítico compreende 2000–2023.
Além dos resultados anuais, são produzidas consolidações para os seguintes quadriênios:
- 2000–2003;
- 2004–2007;
- 2008–2011;
- 2012–2015;
- 2016–2019;
- 2020–2023.

## Dados de entrada

### Ameaça

A ameaça é derivada dos produtos anuais do SO3.1, baseados no SPEI-12 de dezembro e previamente classificados.
A resolução espacial original é de 0,1°.
As classes utilizadas são:
| Valor | Classe |
|---:|---|
| 1 | Seca extrema |
| 2 | Seca severa |
| 3 | Seca moderada |
| 4 | Seca fraca |
| 5 | Normal |


As classes 1 a 4 representam condições de exposição à seca.
Valores sem informação permanecem como NoData e não são reinterpretados como condição normal.

### População

A população é derivada do WorldPop em resolução aproximada de 100 m.
São utilizados três recortes:
- total;
- feminino;
- masculino.

A população total constitui um produto independente.
As populações feminina e masculina são construídas pela agregação das classes etárias correspondentes do produto WorldPop desagregado por sexo.
A soma entre feminino e masculino é utilizada apenas como controle de consistência e não substitui o produto de população total.
A série populacional disponível compreende 2000–2020. Para os anos analíticos de 2021–2023 é reutilizada a população do ano-fonte 2020.

## Grade espacial de referência

A grade nativa do WorldPop constitui a referência espacial do SO3.2.
A grade validada para o Brasil possui:
- CRS: EPSG:4326;
- dimensões: 54.172 × 46.814 pixels;
- resolução aproximada: 0,00083333333°;
- resolução nominal aproximada: 100 m.
Os dados categóricos de seca são avaliados nessa grade utilizando vizinho mais próximo (Nearest Neighbour).
Os parâmetros completos de transformação espacial e as regras de exportação são registrados em [`docs/methodology.md`](docs/methodology.md).

## Exposição

A exposição anual é calculada associando a população de cada célula à classe de seca correspondente ao mesmo ano.
São consideradas expostas as populações associadas às classes:
- 1 — extrema;
- 2 — severa;
- 3 — moderada;
- 4 — fraca.
A classe 5 — Normal — não integra a população exposta.
Os cálculos são realizados separadamente para população total, feminina e masculina.

## Consolidação quadrianual

Para cada célula é identificada a maior intensidade de seca observada no quadriênio.
Como as classes são ordenadas de 1, correspondente à seca extrema, até 5, correspondente à condição Normal, a condição crítica corresponde ao menor código válido observado.
Quando a mesma classe crítica ocorre em mais de um ano, a população de referência corresponde à média das populações dos anos empatados.
Anos sem informação climática não participam da determinação da classe crítica e são registrados por variáveis auxiliares de QA/QC.

## Produtos
O produto espacial principal do SO3.2 é mantido em formato raster sobre a grade WorldPop.
Os produtos destinados ao reporte espacial do PRAIS são derivados diretamente desses rasters.
Adicionalmente, é produzida uma agregação municipal dos resultados utilizando a malha IBGE/MUNICIPIOS/V2025. Essa agregação constitui um produto analítico derivado do Cemaden e não substitui o produto raster do PRAIS.

## Estado atual do processamento

O quadriênio 2000–2003 foi utilizado como primeiro bloco de validação integral da cadeia de processamento.
Para a população total já foram validadas as etapas de:
- QA dos dados de seca;
- QA da população;
- cálculo anual da exposição;
- consolidação quadrianual;
- tratamento de empates da classe crítica;
- preservação de NoData;
- alinhamento exato à grade WorldPop;
- QA/QC dos produtos;
- agregação municipal utilizando a malha IBGE 2025;
- exportação dos produtos raster e tabulares.
Essa arquitetura constitui a referência para o processamento dos demais quadriênios e dos recortes feminino e masculino.
A conclusão do primeiro bloco não implica que toda a série 2000–2023 ou todos os recortes populacionais estejam concluídos.

## Processamento

O fluxo utiliza principalmente:
- Python;
- Jupyter Notebook;
- Google Earth Engine;
- GDAL;
- Google Drive;
- Git/GitHub.
Os dados raster de grande volume e os arquivos intermediários de processamento são mantidos fora do repositório Git.
O Git é utilizado para versionar:
- código-fonte;
- notebooks;
- scripts do Google Earth Engine;
- documentação;
- metadados;
- controles de QA/QC;
- produtos leves adequados ao versionamento.

## Organização

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

### `docs/`
Documentação conceitual, metodológica e operacional.

### `metadata/`
Inventários, estatísticas e registros destinados à rastreabilidade e ao controle de qualidade.

### `notebooks/`
Procedimentos exploratórios, inventários e etapas documentadas de validação.

### `scripts/`
Rotinas executáveis de processamento.
Os scripts utilizados no Google Earth Engine são mantidos em scripts/gee/.

### `src/prais_so32/`
Funções Python reutilizáveis utilizadas pelos scripts e notebooks.

### `outputs/`
Estrutura lógica destinada aos produtos finais:
- tables/ — resultados tabulares;
- rasters/ — produtos raster;
- maps/ — representações cartográficas finais.
Arquivos raster de grande volume não são versionados diretamente pelo Git.
