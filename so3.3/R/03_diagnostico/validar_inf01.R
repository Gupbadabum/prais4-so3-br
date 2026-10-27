# ============================================================================
# PRAIS4 / SO3.3 / INF01 - Validacao de produtos agregados
# ============================================================================
# Nenhuma correcao, recodificacao, imputacao ou sobrescrita neste modulo.
# O QA de 2000 exige os resultados previamente aprovados nos testes 05-07.
# ============================================================================

.infra_inf01_aprox <- function(x, y, tol = 1e-9) {
  length(x) == length(y) &&
    all(is.finite(x) & is.finite(y) &
          abs(x - y) <= tol * pmax(1, abs(x), abs(y)))
}

validar_inf01_uf <- function(resultado, auditoria, ano, uf) {
  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("INF01: pacote data.table requerido.")
  }
  r <- data.table::as.data.table(data.table::copy(resultado))
  a <- data.table::as.data.table(data.table::copy(auditoria))
  uf_chr <- sprintf("%02d", as.integer(uf))
  campos <- c("ano", "uf", "cod_mun", "dimensao", "indicador", "grupo",
              "valor", "numerador", "denominador")
  audit_cols <- c("ano", "uf", "cod_mun", "n_dpp_amostra",
    "n_rede_geral_amostra", "n_rede_canalizada_amostra",
    "denominador_total", "numerador_total", "denominador_masculino",
    "numerador_masculino", "denominador_feminino", "numerador_feminino")
  if (length(setdiff(campos, names(r))) ||
      length(setdiff(audit_cols, names(a))) ||
      !nrow(a) || nrow(r) != 3L * nrow(a)) {
    stop("INF01: produto/auditoria incompleto para UF ", uf_chr)
  }
  if (anyNA(r[, .(ano, uf, cod_mun, dimensao, indicador, grupo,
                   numerador, denominador)]) ||
      anyNA(a[, ..audit_cols]) ||
      any(r$ano != ano) || any(a$ano != ano) ||
      any(r$uf != uf_chr) || any(a$uf != uf_chr) ||
      any(!grepl("^[0-9]{7}$", a$cod_mun)) ||
      any(substr(a$cod_mun, 1L, 2L) != uf_chr) ||
      any(r$dimensao != "Infraestrutural") ||
      any(r$indicador != "INF01_REDE_CANALIZADA") ||
      any(!r$grupo %in% c("Total", "Masculino", "Feminino")) ||
      anyDuplicated(a$cod_mun) ||
      anyDuplicated(r, by = c("cod_mun", "grupo")) ||
      !setequal(r$cod_mun, a$cod_mun)) {
    stop("INF01: identificadores, grupos ou chaves invalidos UF ", uf_chr)
  }
  for (grupo in c("Total", "Masculino", "Feminino")) {
    sufixo <- tolower(grupo)
    idx_grupo <- which(r$grupo == grupo)
    x <- r[idx_grupo][order(cod_mun)]
    y <- a[order(cod_mun)]
    if (nrow(x) != nrow(y) || !identical(x$cod_mun, y$cod_mun) ||
        !.infra_check_numeric(x$denominador, x$numerador, x$valor) ||
        !.infra_inf01_aprox(x$denominador,
                             y[[paste0("denominador_", sufixo)]]) ||
        !.infra_inf01_aprox(x$numerador,
                             y[[paste0("numerador_", sufixo)]])) {
      stop("INF01: componentes divergentes no grupo ", grupo,
           " UF ", uf_chr)
    }
  }
  if (any(a$n_dpp_amostra <= 0) ||
      any(a$n_rede_geral_amostra < 0) ||
      any(a$n_rede_canalizada_amostra < 0) ||
      any(a$n_rede_canalizada_amostra > a$n_rede_geral_amostra) ||
      any(a$n_rede_geral_amostra > a$n_dpp_amostra) ||
      any(a$denominador_total <= 0) ||
      !.infra_inf01_aprox(a$denominador_total,
        a$denominador_masculino + a$denominador_feminino) ||
      !.infra_inf01_aprox(a$numerador_total,
        a$numerador_masculino + a$numerador_feminino)) {
    stop("INF01: conservacao/contagens invalidas UF ", uf_chr)
  }
  invisible(TRUE)
}

# Checa um vetor de denominadores, numeradores e percentuais sem 
# modificar valores. Ausencia de grupo com denominador zero e NA legitimo.
.infra_check_numeric <- function(den, num, val) {
  if (anyNA(den) || anyNA(num) || any(!is.finite(den) | !is.finite(num)) ||
      any(den < 0 | num < 0) ||
      any(num > den + 1e-9 * pmax(1, den))) return(FALSE)
  pos <- den > 0
  all(is.na(val[!pos])) &&
    all(is.finite(val[pos])) &&
    all(val[pos] >= 0 & val[pos] <= 100) &&
    all(abs(val[pos] - 100 * num[pos] / den[pos]) <= 1e-8)
}

validar_inf01_2000_nacional <- function(
  resultados, auditoria,
  dir_testes = file.path("so3.3", "outputs", "intermediario",
                         "infraestrutural", "testes", "inf01_2000",
                         "varredura_nacional")
) {
  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("INF01: pacote data.table requerido.")
  }
  r <- data.table::as.data.table(data.table::copy(resultados))
  a <- data.table::as.data.table(data.table::copy(auditoria))
  ufs <- sprintf("%02d", c(11:17, 21:29, 31:33, 35, 41:43, 50:53))
  if (!setequal(unique(a$uf), ufs) || nrow(a) != 5507L ||
      nrow(r) != 16521L || anyDuplicated(a$cod_mun) ||
      anyDuplicated(r, by = c("cod_mun", "grupo"))) {
    stop("INF01/2000: cobertura nacional inesperada.")
  }
  for (uf in ufs) {
    idx_r <- which(r$uf == uf)
    idx_a <- which(a$uf == uf)
    validar_inf01_uf(r[idx_r], a[idx_a], 2000L, uf)
  }
  if (!all(r$denominador > 0) ||
      sum(a$numerador_total == 0) != 87L) {
    stop("INF01/2000: denominadores ou zeros divergiram da referencia.")
  }

  fontes <- c(
    piloto = file.path(dir_testes, "inf01_2000_municipal_preliminar.csv"),
    qa06 = file.path(dir_testes, "validacao_nacional", "qa_nacional.csv"),
    qa07 = file.path(dir_testes, "validacao_sidra2420_municipal",
                     "qa_sidra2420_municipal.csv"),
    sidra = file.path(dir_testes, "validacao_sidra2420_municipal",
                      "comparacao_sidra2420_municipios.csv")
  )
  if (any(!file.exists(fontes))) {
    stop("INF01/2000: faltam referencias aprovadas dos Testes 05-07: ",
         paste(names(fontes)[!file.exists(fontes)], collapse = ", "))
  }
  qa06 <- data.table::fread(fontes[["qa06"]], showProgress = FALSE)
  qa07 <- data.table::fread(fontes[["qa07"]], showProgress = FALSE)
  for (q in list(qa06, qa07)) {
    if (!all(c("controle", "aprovado") %in% names(q)) || !nrow(q) ||
        anyNA(q$aprovado) || !all(as.character(q$aprovado) == "TRUE")) {
      stop("INF01/2000: arquivo de QA dos testes nao esta aprovado.")
    }
  }
  piloto <- data.table::fread(
    fontes[["piloto"]], showProgress = FALSE,
    colClasses = list(character = c("uf", "cod_mun"))
  )
  sidra <- data.table::fread(
    fontes[["sidra"]], showProgress = FALSE,
    colClasses = list(character = c("uf", "cod_mun"))
  )
  if (nrow(piloto) != 5507L || nrow(sidra) != 5507L ||
      anyDuplicated(piloto$cod_mun) || anyDuplicated(sidra$cod_mun) ||
      !setequal(a$cod_mun, piloto$cod_mun) ||
      !setequal(a$cod_mun, sidra$cod_mun)) {
    stop("INF01/2000: municipios diferentes entre calculo, piloto e SIDRA.")
  }
  piloto <- piloto[match(a$cod_mun, piloto$cod_mun)]
  sidra <- sidra[match(a$cod_mun, sidra$cod_mun)]
  nums <- c("n_dpp_amostra", "n_rede_geral_amostra",
    "n_rede_canalizada_amostra", "denominador_total", "numerador_total",
    "denominador_masculino", "numerador_masculino",
    "denominador_feminino", "numerador_feminino")
  if (length(setdiff(nums, names(piloto))) ||
      length(setdiff(c("den_sidra", "num_sidra"), names(sidra)))) {
    stop("INF01/2000: referencias sem componentes necessarios.")
  }
  deltas <- vapply(nums, function(campo) {
    x <- as.numeric(a[[campo]])
    y <- as.numeric(piloto[[campo]])
    if (!.infra_inf01_aprox(x, y, tol = 1e-9)) {
      stop("INF01/2000: divergencia contra Teste 05 em ", campo)
    }
    max(abs(x - y))
  }, numeric(1))
  # Todos os grupos e respectivos valores, alem dos componentes.
  delta_pct <- setNames(numeric(3), c("Total", "Masculino", "Feminino"))
  for (g in names(delta_pct)) {
    n <- tolower(g)
    x <- r[grupo == g][order(cod_mun)]
    y <- piloto[order(cod_mun)][[paste0("inf01_", n)]]
    if (!.infra_inf01_aprox(x$valor, y, tol = 1e-9)) {
      stop("INF01/2000: percentual diverge do Teste 05 em ", g)
    }
    delta_pct[[g]] <- max(abs(x$valor - y))
  }
  delta_sidra_den <- max(abs(a$denominador_total - sidra$den_sidra))
  delta_sidra_num <- max(abs(a$numerador_total - sidra$num_sidra))
  if (anyNA(sidra[, .(den_sidra, num_sidra)]) ||
      delta_sidra_den > 0.500001 || delta_sidra_num > 0.500001 ||
      any((a$numerador_total == 0) != (sidra$num_sidra == 0))) {
    stop("INF01/2000: divergencia municipal contra SIDRA 2420.")
  }
  den_br <- sum(a$denominador_total)
  num_br <- sum(a$numerador_total)
  if (abs(den_br - 168450492) > 2 ||
      abs(num_br - 118433801) > 2) {
    stop("INF01/2000: totais nacionais divergem do IBGE 1.9.3.")
  }
  data.table::data.table(
    ano = 2000L,
    n_ufs = 27L,
    n_municipios = 5507L,
    n_grupos = 3L,
    n_municipios_numerador_zero = sum(a$numerador_total == 0),
    denominador_brasil = den_br,
    numerador_brasil = num_br,
    inf01_brasil = 100 * num_br / den_br,
    max_delta_piloto_componentes = max(deltas),
    max_delta_piloto_percentuais = max(delta_pct),
    max_delta_sidra_den = delta_sidra_den,
    max_delta_sidra_num = delta_sidra_num,
    qa_piloto_sidra = "APROVADO"
  )
}
