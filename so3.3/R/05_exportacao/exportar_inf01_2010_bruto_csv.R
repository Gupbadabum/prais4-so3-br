# =============================================================================
# PRAIS4 / SO3.3 / INF01 - Exportacao bruta 2010
# =============================================================================
# Reutiliza a referencia municipal e contrato publico ja usados em Social/ECO.
# Nao reler microdados; nao grava por conta propria.
# =============================================================================

preparar_inf01_2010_bruto_csv <- function(
  resultados,
  arquivo_municipios = file.path("so3.3", "inputs", "referencias",
                                 "ibge", "municipios_ibge_2025.csv")
) {
  if (!exists(".ler_municipios_ibge_2025", mode = "function",
              inherits = TRUE)) {
    stop("INF01/2010 CSV: carregue exportar_resultados_csv.R.")
  }
  r <- data.table::as.data.table(data.table::copy(resultados))
  campos <- c("ano", "uf", "cod_mun", "indicador", "grupo", "valor")
  if (length(setdiff(campos, names(r))) || nrow(r) != 16695L ||
      anyNA(r[, ..campos]) || any(!is.finite(r$valor)) ||
      any(r$valor < 0 | r$valor > 100) ||
      any(r$ano != 2010L) ||
      any(r$indicador != "INF01_REDE_CANALIZADA") ||
      data.table::uniqueN(r$cod_mun) != 5565L ||
      anyDuplicated(r, by = c("cod_mun", "grupo")) ||
      !setequal(unique(r$grupo), c("Total", "Masculino", "Feminino")) ||
      any(!grepl("^[0-9]{7}$", r$cod_mun)) ||
      any(substr(r$cod_mun, 1L, 2L) != r$uf)) {
    stop("INF01/2010 CSV: produto nacional invalido.")
  }
  nomes <- .ler_municipios_ibge_2025(arquivo_municipios)
  idx <- match(r$cod_mun, nomes$CD_MUN)
  if (anyNA(idx)) {
    stop("INF01/2010 CSV: geocodigos sem nome municipal na referencia IBGE.")
  }
  saida <- data.table::data.table(
    ano = as.integer(r$ano),
    uf = as.character(r$uf),
    cod_mun = as.character(r$cod_mun),
    nm_mun = as.character(nomes$NM_MUN[idx]),
    indicador = as.character(r$indicador),
    grupo = as.character(r$grupo),
    valor = as.numeric(r$valor)
  )
  saida[, ord := match(grupo, c("Total", "Masculino", "Feminino"))]
  data.table::setorder(saida, cod_mun, ord)
  saida[, ord := NULL]
  saida[]
}
