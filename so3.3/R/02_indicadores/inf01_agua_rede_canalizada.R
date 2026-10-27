# ============================================================================
# PRAIS4 / SO3.3 / INF01 - Formula comum e estimador domiciliar de 2000
# ============================================================================
# Condicao positiva: rede geral E agua canalizada em >= 1 comodo.
# Numerador/denominador: moradores expandidos, NA se denominador = 0.
# O resultado bruto representa ACESSO; a orientacao de vulnerabilidade sera
# tratada somente nas etapas posteriores do DVI.
# ============================================================================

.infra_inf01_grupos <- c("Total", "Masculino", "Feminino")
.infra_inf01_id <- "INF01_REDE_CANALIZADA"

# Aceita componentes municipais construidos por diferentes adaptadores.
# Essa funcao podera ser reutilizada pelos adaptadores 2010 e 2022.
montar_inf01_municipal <- function(componentes, ano) {
  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("INF01: pacote data.table requerido.")
  }
  ano <- as.integer(ano)
  if (length(ano) != 1L || is.na(ano) ||
      !ano %in% c(2000L, 2010L, 2022L)) {
    stop("INF01: ano invalido.")
  }
  d <- data.table::as.data.table(data.table::copy(componentes))
  campos <- c("uf", "cod_mun", paste0("denominador_", c(
    "total", "masculino", "feminino")), paste0("numerador_", c(
    "total", "masculino", "feminino")))
  faltam <- setdiff(campos, names(d))
  if (length(faltam)) {
    stop("INF01: componentes ausentes: ", paste(faltam, collapse = ", "))
  }
  if (!nrow(d) || anyNA(d[, .(uf, cod_mun)]) ||
      anyDuplicated(d$cod_mun)) {
    stop("INF01: geografia ausente ou municipalidade duplicada.")
  }
  resultados <- data.table::rbindlist(lapply(seq_along(.infra_inf01_grupos),
    function(i) {
      grupo <- .infra_inf01_grupos[[i]]
      sufixo <- tolower(grupo)
      den <- as.numeric(d[[paste0("denominador_", sufixo)]])
      num <- as.numeric(d[[paste0("numerador_", sufixo)]])
      if (anyNA(den) || anyNA(num) ||
          any(!is.finite(den) | !is.finite(num)) ||
          any(den < 0 | num < 0) ||
          any(num > den + 1e-9 * pmax(1, den))) {
        stop("INF01: componentes invalidos para grupo ", grupo)
      }
      valor <- rep(NA_real_, length(den))
      pos <- den > 0
      valor[pos] <- 100 * num[pos] / den[pos]
      if (any(!is.finite(valor[pos])) ||
          any(valor[pos] < -1e-9 | valor[pos] > 100 + 1e-9)) {
        stop("INF01: valor percentual fora do dominio em ", grupo)
      }
      data.table::data.table(
        ano = ano,
        uf = as.character(d$uf),
        cod_mun = as.character(d$cod_mun),
        dimensao = "Infraestrutural",
        indicador = .infra_inf01_id,
        grupo = grupo,
        valor = valor,
        numerador = num,
        denominador = den
      )
    }
  ), use.names = TRUE)
  resultados[, ordem_grupo := match(grupo, .infra_inf01_grupos)]
  data.table::setorder(resultados, cod_mun, ordem_grupo)
  resultados[, ordem_grupo := NULL]
  resultados[]
}

calcular_inf01_domicilios <- function(canonico_dpp) {
  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("INF01: pacote data.table requerido.")
  }
  d <- data.table::as.data.table(data.table::copy(canonico_dpp))
  campos <- c("ano", "uf", "cod_mun", "peso", "moradores_total",
              "moradores_masculino", "moradores_feminino", "rede_geral",
              "atendimento")
  faltam <- setdiff(campos, names(d))
  if (length(faltam)) {
    stop("INF01: canonico domiciliar incompleto: ",
         paste(faltam, collapse = ", "))
  }
  if (!nrow(d) || data.table::uniqueN(d$ano) != 1L ||
      data.table::uniqueN(d$uf) != 1L ||
      anyNA(d[, ..campos])) {
    stop("INF01: canonico vazio, misto ou contendo NA.")
  }
  if (any(!is.finite(d$peso) | d$peso <= 0) ||
      any(!is.finite(d$moradores_total)) ||
      any(d$moradores_total <= 0) ||
      any(d$moradores_total != d$moradores_masculino +
          d$moradores_feminino) ||
      any(!d$atendimento %in% c(TRUE, FALSE)) ||
      any(!d$rede_geral %in% c(TRUE, FALSE)) ||
      any(d$atendimento & !d$rede_geral)) {
    stop("INF01: canonico domiciliar inconsistente.")
  }
  for (campo in c("moradores_total", "moradores_masculino",
                  "moradores_feminino")) {
    v <- d[[campo]]
    if (any(!is.finite(v) | v < 0 | v != floor(v))) {
      stop("INF01: contagem invalida em ", campo)
    }
  }
  if (any(!grepl("^[0-9]{7}$", d$cod_mun)) ||
      any(substr(d$cod_mun, 1L, 2L) != d$uf)) {
    stop("INF01: municipio/UF do canonico invalidos.")
  }

  # Reproduz literalmente os seis estimadores aprovados no Teste 03.
  municipal <- d[, .(
    n_dpp_amostra = .N,
    n_rede_geral_amostra = sum(rede_geral),
    n_rede_canalizada_amostra = sum(atendimento),
    soma_pesos_domiciliares = sum(peso),
    denominador_total = sum(peso * moradores_total),
    numerador_total = sum(peso * moradores_total * atendimento),
    denominador_masculino = sum(peso * moradores_masculino),
    numerador_masculino = sum(peso * moradores_masculino * atendimento),
    denominador_feminino = sum(peso * moradores_feminino),
    numerador_feminino = sum(peso * moradores_feminino * atendimento)
  ), by = .(uf, cod_mun)]
  municipal[, ano := as.integer(d$ano[[1L]])]
  data.table::setcolorder(municipal, c("ano", "uf", "cod_mun",
    setdiff(names(municipal), c("ano", "uf", "cod_mun"))))
  data.table::setorder(municipal, cod_mun)
  resultado <- montar_inf01_municipal(municipal, ano = d$ano[[1L]])
  list(resultados = resultado[], auditoria = municipal[])
}
