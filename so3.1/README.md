# SO3.1 — Ameaça associada à seca

Este diretório reúne os procedimentos e produtos desenvolvidos para caracterizar a **ameaça associada à seca** no âmbito do **SO3.1 do PRAIS4**, considerando o território brasileiro.

A análise é baseada no **Standardized Precipitation Evapotranspiration Index (SPEI)** acumulado em 12 meses (**SPEI-12**). Para cada ano do período de **2000 a 2023**, é utilizado o valor correspondente ao mês de **dezembro**, representando as condições acumuladas ao longo dos 12 meses anteriores.

Os valores contínuos de SPEI são classificados em cinco categorias de intensidade de seca:

| Classe | Condição | Intervalo de SPEI |
|---:|---|---|
| 1 | Seca extrema | SPEI ≤ -2,0 |
| 2 | Seca severa | -2,0 < SPEI ≤ -1,5 |
| 3 | Seca moderada | -1,5 < SPEI ≤ -1,0 |
| 4 | Seca fraca | -1,0 < SPEI < 0 |
| 5 | Normal | SPEI ≥ 0 |

O valor `0` é reservado para células sem dados (`NoData`).

## Fluxo de processamento

O processamento é realizado em duas etapas principais.

### 1. Produtos anuais

O script [`gerar_mapas_spei12.py`](./gerar_mapas_spei12.py) processa os dados anuais de SPEI-12 entre 2000 e 2023.

Para cada ano, o procedimento:

1. lê o arquivo NetCDF correspondente;
2. seleciona o valor de SPEI-12 referente ao mês de dezembro;
3. converte os valores contínuos de SPEI para as cinco classes de intensidade;
4. gera um GeoTIFF classificado;
5. recorta o produto para o território brasileiro;
6. produz uma representação cartográfica em PNG;
7. calcula a área ocupada por cada classe e a proporção do território brasileiro submetida a alguma classe de seca.

Para o cálculo das áreas, o raster é reprojetado para o sistema de referência de área equivalente **EPSG:6933**, utilizando resolução de **10 km**, e posteriormente limitado ao contorno nacional.

Os resultados tabulares anuais estão sintetizados em:

- [`T1_area_por_classe_km2.csv`](./T1_area_por_classe_km2.csv): área, em km², correspondente a cada uma das cinco classes;
- [`T2_percentual_terra_em_seca.csv`](./T2_percentual_terra_em_seca.csv): área total considerada, área submetida às classes de seca (1 a 4), número de células e percentual do território sob condições de seca.

## Síntese em períodos de quatro anos

O script [`gerar_mapas_spei12_maximos_4anos.py`](./gerar_mapas_spei12_maximos_4anos.py) combina os produtos anuais em seis períodos de quatro anos:

- 2000–2003
- 2004–2007
- 2008–2011
- 2012–2015
- 2016–2019
- 2020–2023

Para cada pixel, é mantida a **classe correspondente à maior intensidade de seca observada durante o período**.

Como as classes são ordenadas de `1 = seca extrema` a `5 = normal`, essa operação corresponde matematicamente à seleção do **menor valor de classe** entre os quatro anos.

Assim, o produto quadrianual não representa uma média das condições observadas nem a condição predominante durante os quatro anos. Ele representa a **maior intensidade de seca registrada em cada célula espacial no período considerado**.

Os produtos finais são disponibilizados em:

- **GeoTIFF (`.tif`)**, para utilização em análises espaciais;
- **PNG (`.png`)**, para visualização cartográfica.

Os arquivos seguem o padrão:

```text
spei12_maximo_<ano_inicial>_<ano_final>_brasil.tif
spei12_maximo_<ano_inicial>_<ano_final>_brasil.png
```

Por exemplo:

```text
spei12_maximo_2000_2003_brasil.tif
spei12_maximo_2000_2003_brasil.png
```

## Estrutura principal

```text
so3.1/
├── README.md
├── gerar_mapas_spei12.py
├── gerar_mapas_spei12_maximos_4anos.py
├── T1_area_por_classe_km2.csv
├── T2_percentual_terra_em_seca.csv
├── spei12_maximo_2000_2003_brasil.*
├── spei12_maximo_2004_2007_brasil.*
├── spei12_maximo_2008_2011_brasil.*
├── spei12_maximo_2012_2015_brasil.*
├── spei12_maximo_2016_2019_brasil.*
└── spei12_maximo_2020_2023_brasil.*
```

## Dependências

Os scripts utilizam principalmente as bibliotecas Python:

- `xarray`
- `numpy`
- `pandas`
- `rasterio`
- `geopandas`
- `shapely`
- `pyproj`
- `matplotlib`

Os caminhos para os dados de entrada e para o arquivo vetorial dos limites estaduais brasileiros utilizados durante o processamento devem ser ajustados de acordo com o ambiente local de execução.

## Observações

Os mapas quadrianuais devem ser interpretados como uma síntese espacial da **maior intensidade de seca observada em cada célula**, e não como representação de um único ano ou como média do período.

As tabelas anuais, por sua vez, permitem acompanhar a extensão territorial das diferentes classes de seca entre 2000 e 2023 e fornecem uma síntese da parcela do território brasileiro submetida a SPEI negativo em dezembro de cada ano.
