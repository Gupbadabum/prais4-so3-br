# ============================================================================
# PRAIS4 / SO3.3 / INF01 - Preparacao de CSV publico, sem acesso a microdados
# ============================================================================
# Esta rotina retorna uma tabela validada para exportacao. A escrita e
# controlada pelo processador, que impede sobrescritas silenciosas.
# ============================================================================

preparar_inf01_bruto_csv <- function(
  resultados,
  arquivo_municipios = file.path("so3.3", "inputs", "referencias",
                                 "ibge", "municipios_ibge_2025.csv")
) {
  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("INF01 CSV: pacote data.table requerido.")
  }
  if (!file.exists(arquivo_municipios)) {
    stop("INF01 CSV: referencia IBGE municipal ausente: ", arquivo_municipios)
  }
  ref <- data.table::fread(
    arquivo_municipios, sep = ";", encoding = "UTF-8",
    colClasses = list(character = "CD_MUN"), showProgress = FALSE
  )
  if (!setequal(names(ref), c("CD_MUN", "NM_MUN")) ||
      nrow(ref) != 5573L || anyNA(ref[, .(CD_MUN, NM_MUN)]) ||
      anyDuplicated(ref$CD_MUN)) {
    stop("INF01 CSV: referencia de nomes municipais invalida.")
  }
  ref[, `:=`(CD_MUN = trimws(as.character(CD_MUN)),
             NM_MUN = trimws(as.character(NM_MUN)))]
  if (any(!grepl("^[0-9]{7}$", ref$CD_MUN)) ||
      any(!nzchar(ref$NM_MUN))) {
    stop("INF01 CSV: codigos/nomes municipais invalidos.")
  }
  ref <- ref[!CD_MUN %in% c("4300001", "4300002")]
  if (nrow(ref) != 5571L) {
    stop("INF01 CSV: contagem de municipios na referencia inesperada.")
  }

  r <- data.table::as.data.table(data.table::copy(resultados))
  campos <- c("ano", "uf", "cod_mun", "indicador", "grupo", "valor")
  if (length(setdiff(campos, names(r))) ||
      anyNA(r[, ..campos]) ||
      nrow(r) != 16521L ||
      any(r$ano != 2000L) ||
      any(r$indicador != "INF01_REDE_CANALIZADA") ||
      anyDuplicated(r, by = c("cod_mun", "grupo"))) {
    stop("INF01 CSV: resultado nacional invalido para 2000.")
  }
  idx <- match(r$cod_mun, ref$CD_MUN)
  if (anyNA(idx)) {
    stop("INF01 CSV: municipios sem nome na referencia: ",
         paste(utils::head(unique(r$cod_mun[is.na(idx)]), 10L),
               collapse = ", "))
  }
  saida <- data.table::data.table(
    ano = as.integer(r$ano),
    uf = as.character(r$uf),
    cod_mun = as.character(r$cod_mun),
    nm_mun = ref$NM_MUN[idx],
    indicador = as.character(r$indicador),
    grupo = as.character(r$grupo),
    valor = as.numeric(r$valor)
  )
  saida[, ord_grupo := match(grupo, c("Total", "Masculino", "Feminino"))]
  if (anyNA(saida$ord_grupo)) {
    stop("INF01 CSV: grupo nao reconhecido.")
  }
  data.table::setorder(saida, cod_mun, ord_grupo)
  saida[, ord_grupo := NULL]
  saida[]
}
