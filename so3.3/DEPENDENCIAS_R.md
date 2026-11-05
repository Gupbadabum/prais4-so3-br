# SO3.3 — Dependencias do ambiente R

**Estado:** inventario obtido pela leitura dos scripts R versionados. Nao e um `renv.lock` e nao comprova que as versoes mais recentes dos pacotes reproduzam exatamente os resultados existentes.

## Pacotes identificados

| Pacote | Utilizacao no codigo |
| --- | --- |
| `data.table` | Leitura, transformacao e agregacao de tabelas |
| `censobr` | Leitura dos dados censitarios acessiveis pela biblioteca |
| `dplyr` | Operacoes sobre os dados provenientes de `censobr` |
| `readxl` | Leitura de planilhas de referencias |
| `jsonlite` | Leitura de fontes JSON |
| `sf` | Operacoes geograficas na municipalizacao de INF02 |
| `DBI`, `RSQLite` | Consulta ao GeoPackage na cadeia INF02 |
| `COINr` | **Opcional**: comparacao auxiliar no teste `tests/testar_estatistica_brutos.R`, quando instalado |

Os pacotes `stats`, `utils` e `tools` sao distribuidos com o R e nao precisam ser instalados separadamente.

## Preparacao exploratoria

A partir de uma instalacao de R com acesso aos repositorios de pacotes:

```r
install.packages(c(
  "data.table", "censobr", "dplyr", "readxl", "jsonlite",
  "sf", "DBI", "RSQLite"
))
# Somente se for executar os testes auxiliares pertinentes:
install.packages("COINr")
```

**Atencao:** esta instalacao resolve pacotes disponiveis no momento da execucao; nao restaura as versoes originais. O pacote `sf` depende de bibliotecas geoespaciais nativas (GDAL, GEOS e PROJ), cuja compatibilidade deve ser verificada. A leitura via `censobr` pode depender de acesso as fontes externas e de seus mecanismos de cache.

## Registro do ambiente utilizado

Na maquina em que um fluxo tenha sido efetivamente validado, registrar:

```r
sessionInfo()
sapply(
  c("data.table", "censobr", "dplyr", "readxl", "jsonlite",
    "sf", "DBI", "RSQLite"),
  function(p) if (requireNamespace(p, quietly = TRUE))
    as.character(packageVersion(p)) else NA_character_
)
if (requireNamespace("sf", quietly = TRUE)) sf::sf_extSoftVersion()
```

O registro das versoes deve acompanhar o commit, a data, o sistema operacional e as fontes utilizadas. Apenas apos recuperar e testar o ambiente original sera adequado gerar um `renv.lock`.

## Configuracao e execucao

- Executar os scripts a partir da **raiz do repositorio** (`prais4-so3-br/`).
- Manter `so3.3/config/config.R` como configuracao versionada.
- Para caminhos locais, partir de `so3.3/config/config_local.R.example` e criar `config_local.R` na propria maquina; esse arquivo esta excluido do Git.
- `so3.3/main.R` exige que `DIMENSAO_ATIVA` e `ANO_ATIVO` sejam definidos antes da chamada, conforme o cabecalho do proprio script.
- A execucao completa demanda os insumos aplicaveis e, em certas etapas, arquivos locais de processamento intermediario. Nao equivale apenas a instalar bibliotecas.

Consulte tambem [REPRODUCIBILITY.md](../REPRODUCIBILITY.md) para os limites da reproducibilidade do projeto.
