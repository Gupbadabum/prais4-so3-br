# =============================================================================
# PRAIS4 / SO3.3 / INF01 - Censo 2010, estimadores por Pessoas e Domicilios
# =============================================================================
# Recebe estruturas canonicas em RAM do adaptador e entrega somente agregados.
# A funcao montar_inf01_municipal() e a MESMA ja aprovada em 2000.
# =============================================================================

calcular_inf01_2010_pessoas <- function(canonico) {
  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("INF01/2010: pacote data.table necessario.")
  }
  p <- data.table::as.data.table(data.table::copy(canonico$pessoas))
  d <- data.table::as.data.table(data.table::copy(canonico$domicilios))
  if (!nrow(p) || !nrow(d)) stop("INF01/2010: UF vazia.")
  a_p <- p[, .(
    n_pessoas_dpp_amostra = .N,
    n_pessoas_rede_canalizada_amostra = sum(atendimento),
    denominador_total = sum(peso),
    numerador_total = sum(peso[atendimento]),
    denominador_masculino = sum(peso[sexo == 1]),
    numerador_masculino = sum(peso[sexo == 1 & atendimento]),
    denominador_feminino = sum(peso[sexo == 2]),
    numerador_feminino = sum(peso[sexo == 2 & atendimento])
  ), by = .(uf, cod_mun)]
  a_d <- d[, .(
    n_dpp_amostra = .N,
    n_rede_geral_amostra = sum(rede_geral),
    n_rede_canalizada_amostra = sum(atendimento),
    denominador_total = sum(peso * moradores),
    numerador_total = sum(peso * moradores * atendimento),
    denominador_masculino = sum(peso * homens),
    numerador_masculino = sum(peso * homens * atendimento),
    denominador_feminino = sum(peso * mulheres),
    numerador_feminino = sum(peso * mulheres * atendimento)
  ), by = .(uf, cod_mun)]
  if (anyDuplicated(a_p, by = c("uf", "cod_mun")) ||
      anyDuplicated(a_d, by = c("uf", "cod_mun")) ||
      !setequal(a_p$cod_mun, a_d$cod_mun)) {
    stop("INF01/2010: municipios diferentes entre os estimadores.")
  }
  data.table::setorder(a_p, cod_mun)
  data.table::setorder(a_d, cod_mun)
  if (!identical(a_p$cod_mun, a_d$cod_mun)) {
    stop("INF01/2010: ordem territorial inconsistente.")
  }
  comp <- c("denominador_total", "numerador_total",
            "denominador_masculino", "numerador_masculino",
            "denominador_feminino", "numerador_feminino")
  maior_delta <- 0
  for (nm in comp) {
    v1 <- a_p[[nm]]
    v2 <- a_d[[nm]]
    delta <- abs(v1 - v2)
    if (any(!is.finite(delta)) ||
        any(delta > 1e-9 * pmax(1, abs(v1), abs(v2)))) {
      stop("INF01/2010: Pessoas e Domicilios divergentes em ", nm)
    }
    maior_delta <- max(maior_delta, delta)
  }
  if (any(abs(a_p$denominador_total -
              a_p$denominador_masculino - a_p$denominador_feminino) >
          1e-9 * pmax(1, a_p$denominador_total)) ||
      any(abs(a_p$numerador_total -
              a_p$numerador_masculino - a_p$numerador_feminino) >
          1e-9 * pmax(1, a_p$numerador_total))) {
    stop("INF01/2010: conservacao T=M+F divergente.")
  }
  auditoria <- a_d[, .(uf, cod_mun,
    n_dpp_amostra, n_rede_geral_amostra, n_rede_canalizada_amostra)]
  auditoria[, `:=`(
    ano = 2010L,
    n_pessoas_dpp_amostra = a_p$n_pessoas_dpp_amostra,
    n_pessoas_rede_canalizada_amostra =
      a_p$n_pessoas_rede_canalizada_amostra
  )]
  for (nm in comp) auditoria[, (nm) := a_p[[nm]]]
  data.table::setcolorder(auditoria, c("ano", "uf", "cod_mun",
    setdiff(names(auditoria), c("ano", "uf", "cod_mun"))))
  resultados <- montar_inf01_municipal(auditoria, ano = 2010L)
  list(resultados = resultados[], auditoria = auditoria[],
       maior_delta_pessoas_domicilios = maior_delta)
}
