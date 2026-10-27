# =============================================================================
# PRAIS4 / SO3.3 / INF01 2022 - Preparacao do CSV municipal de producao
# Nao grava, nao recalcula, nao acessa microdados.
# =============================================================================

preparar_inf01_2022_bruto_csv <- function(
    resultados,
    arquivo_municipios = file.path(
      "so3.3", "inputs", "referencias", "ibge",
      "municipios_ibge_2025.csv")) {
  if (!exists(".ler_municipios_ibge_2025", mode = "function",
              inherits = TRUE)) {
    stop("INF01/2022 CSV: carregue exportar_resultados_csv.R.")
  }
  r <- data.table::as.data.table(data.table::copy(resultados))
  campos <- c("ano", "uf", "cod_mun", "indicador", "grupo", "valor")
  if (length(setdiff(campos, names(r))) ||
      nrow(r) != 16710L ||
      anyNA(r[, ..campos]) ||
      !is.numeric(r$valor) ||
      any(!is.finite(r$valor)) ||
      any(r$valor < -1e-8 | r$valor > 100 + 1e-8) ||
      any(r$ano != 2022L) ||
      any(r$indicador != "INF01_REDE_CANALIZADA") ||
      data.table::uniqueN(r$cod_mun) != 5570L ||
      anyDuplicated(r, by = c("cod_mun", "grupo")) ||
      !setequal(unique(r$grupo), c("Total", "Masculino", "Feminino")) ||
      any(!grepl("^[0-9]{7}$", r$cod_mun)) ||
      any(substr(r$cod_mun, 1L, 2L) != r$uf)) {
    stop("INF01/2022 CSV: resultado nacional incompleto ou invalido.")
  }
  ref <- .ler_municipios_ibge_2025(arquivo_municipios)
  idx <- match(r$cod_mun, ref$CD_MUN)
  if (anyNA(idx)) {
    stop("INF01/2022 CSV: codigos municipais sem nome na referencia IBGE.")
  }
  saida <- data.table::data.table(
    ano = as.integer(r$ano),
    uf = as.character(r$uf),
    cod_mun = as.character(r$cod_mun),
    nm_mun = as.character(ref$NM_MUN[idx]),
    indicador = as.character(r$indicador),
    grupo = as.character(r$grupo),
    valor = as.numeric(r$valor)
  )
  saida[, ordem := match(grupo, c("Total", "Masculino", "Feminino"))]
  data.table::setorder(saida, cod_mun, ordem)
  saida[, ordem := NULL]
  saida[]
}
