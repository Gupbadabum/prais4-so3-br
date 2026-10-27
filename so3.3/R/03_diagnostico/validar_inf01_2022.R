# =============================================================================
# PRAIS4 / SO3.3 / INF01 2022 - QA nacional de producao (acesso controlado)
# Origem autorizada nesta versao: agregados nacionais aprovados no Teste 18.
# Nao le microdados, nao corrige valores e nao grava resultados.
# =============================================================================

.infra_2022_t18_dir <- function() file.path(
  "so3.3", "outputs", "intermediario", "infraestrutural", "testes",
  "inf01_2022", "varredura_nacional"
)

.infra_2022_aprox <- function(x, y, tol = 1e-9) {
  length(x) == length(y) &&
    all(is.finite(x) & is.finite(y) &
          abs(x - y) <= tol * pmax(1, abs(x), abs(y)))
}

.infra_2022_ler <- function(caminho) {
  if (!file.exists(caminho)) {
    stop("INF01/2022: referencia do Teste 18 ausente: ", caminho)
  }
  colunas <- names(data.table::fread(caminho, sep = ";", nrows = 0L,
                                       showProgress = FALSE))
  ids <- intersect(c("uf", "cod_mun"), colunas)
  data.table::fread(
    caminho, sep = ";", na.strings = "NA", showProgress = FALSE,
    colClasses = if (length(ids)) list(character = ids) else NULL
  )
}

.infra_2022_referencias <- function(dir_t18 = .infra_2022_t18_dir()) {
  nomes <- c(
    municipal = "inf01_2022_municipal_preliminar.csv",
    componentes = "inf01_2022_componentes_municipais.csv",
    estados = "inf01_2022_resumo_ufs.csv",
    brasil = "inf01_2022_resumo_brasil.csv",
    zeros = "inf01_2022_municipios_numerador_zero.csv",
    qa = "inf01_2022_qa_consolidacao.csv"
  )
  arquivos <- file.path(dir_t18, nomes)
  names(arquivos) <- names(nomes)
  if (!all(file.exists(arquivos))) {
    stop("INF01/2022: Teste 18 incompleto. Faltam: ",
         paste(arquivos[!file.exists(arquivos)], collapse = ", "))
  }
  dados <- lapply(arquivos, .infra_2022_ler)
  q <- dados$qa
  if (!all(c("controle", "aprovado", "detalhe") %in% names(q)) ||
      nrow(q) != 7L || anyNA(q$aprovado) ||
      !all(as.character(q$aprovado) == "TRUE")) {
    stop("INF01/2022: controles nacionais do Teste 18 nao aprovados.")
  }
  dados$arquivos <- arquivos
  dados$md5 <- unname(tools::md5sum(arquivos))
  names(dados$md5) <- names(arquivos)
  dados
}

.infra_2022_montar_auditoria <- function(ref) {
  x <- data.table::copy(ref$componentes)
  seis <- c("denominador_total", "numerador_total",
            "denominador_masculino", "numerador_masculino",
            "denominador_feminino", "numerador_feminino")
  outros <- c("ano", "uf", "cod_mun", "n_dpp_amostra",
              "n_rede_geral_amostra", "n_rede_canalizada_amostra",
              "n_pessoas_dpp_amostra", "n_pessoas_rede_canalizada_amostra")
  faltantes <- setdiff(c(outros, paste0(seis, "_pessoas")), names(x))
  if (length(faltantes)) {
    stop("INF01/2022: componentes T18 incompletos: ",
         paste(faltantes, collapse = ", "))
  }
  a <- x[, ..outros]
  for (nm in seis) {
    a[, (nm) := as.numeric(x[[paste0(nm, "_pessoas")]])]
  }
  data.table::setorder(a, cod_mun)
  a[]
}

.infra_2022_validar_uf <- function(resultados, auditoria, uf_alvo) {
  r <- data.table::as.data.table(data.table::copy(resultados))
  a <- data.table::as.data.table(data.table::copy(auditoria))
  obrig_r <- c("ano", "uf", "cod_mun", "dimensao", "indicador", "grupo",
                "valor", "numerador", "denominador")
  obrig_a <- c("ano", "uf", "cod_mun", "n_dpp_amostra",
                "n_rede_geral_amostra", "n_rede_canalizada_amostra",
                "n_pessoas_dpp_amostra", "n_pessoas_rede_canalizada_amostra",
                "denominador_total", "numerador_total",
                "denominador_masculino", "numerador_masculino",
                "denominador_feminino", "numerador_feminino")
  if (length(setdiff(obrig_r, names(r))) ||
      length(setdiff(obrig_a, names(a))) ||
      !nrow(a) || nrow(r) != 3L * nrow(a)) {
    stop("INF01/2022: esquema ou cardinalidade incorreta UF ", uf_alvo)
  }
  obrig_r_sem_valor <- setdiff(obrig_r, "valor")
  if (anyNA(r[, ..obrig_r_sem_valor]) ||
      anyNA(a[, ..obrig_a]) ||
      any(r$ano != 2022L) || any(a$ano != 2022L) ||
      any(r$uf != uf_alvo) || any(a$uf != uf_alvo) ||
      any(!grepl("^[0-9]{7}$", r$cod_mun)) ||
      any(!grepl("^[0-9]{7}$", a$cod_mun)) ||
      any(substr(r$cod_mun, 1L, 2L) != uf_alvo) ||
      any(substr(a$cod_mun, 1L, 2L) != uf_alvo) ||
      any(r$dimensao != "Infraestrutural") ||
      any(r$indicador != "INF01_REDE_CANALIZADA") ||
      !setequal(unique(r$grupo), c("Total", "Masculino", "Feminino")) ||
      anyDuplicated(a$cod_mun) ||
      anyDuplicated(r, by = c("cod_mun", "grupo")) ||
      !setequal(r$cod_mun, a$cod_mun)) {
    stop("INF01/2022: identificadores, grupos ou municipios invalidos UF ",
         uf_alvo)
  }
  if (any(a$n_dpp_amostra <= 0) ||
      any(a$n_rede_geral_amostra < 0) ||
      any(a$n_rede_geral_amostra > a$n_dpp_amostra) ||
      any(a$n_rede_canalizada_amostra < 0) ||
      any(a$n_rede_canalizada_amostra > a$n_rede_geral_amostra) ||
      any(a$n_pessoas_dpp_amostra <= 0) ||
      any(a$n_pessoas_rede_canalizada_amostra < 0) ||
      any(a$n_pessoas_rede_canalizada_amostra > a$n_pessoas_dpp_amostra) ||
      any(a$denominador_total <= 0) ||
      !.infra_2022_aprox(a$denominador_total,
                         a$denominador_masculino + a$denominador_feminino) ||
      !.infra_2022_aprox(a$numerador_total,
                         a$numerador_masculino + a$numerador_feminino)) {
    stop("INF01/2022: conservacao ou contagens invalidas UF ", uf_alvo)
  }
  data.table::setorder(a, cod_mun)
  for (grp in c("Total", "Masculino", "Feminino")) {
    idx <- which(r[["grupo"]] == grp)
    y <- data.table::copy(r[idx])
    data.table::setorder(y, cod_mun)
    suf <- tolower(grp)
    den <- a[[paste0("denominador_", suf)]]
    num <- a[[paste0("numerador_", suf)]]
    if (nrow(y) != nrow(a) || !identical(y$cod_mun, a$cod_mun) ||
        !is.numeric(y$denominador) || !is.numeric(y$numerador) ||
        !is.numeric(y$valor) || anyNA(y$denominador) ||
        anyNA(y$numerador) ||
        !.infra_2022_aprox(y$denominador, den) ||
        !.infra_2022_aprox(y$numerador, num) ||
        any(y$denominador < 0 | y$numerador < 0) ||
        any(y$numerador > y$denominador +
              1e-9 * pmax(1, y$denominador))) {
      stop("INF01/2022: componentes invalidos UF ", uf_alvo,
           " grupo ", grp)
    }
    positivos <- y$denominador > 0
    esperado <- 100 * y$numerador[positivos] / y$denominador[positivos]
    if (any(!is.na(y$valor[!positivos])) ||
        any(!is.finite(y$valor[positivos])) ||
        any(abs(y$valor[positivos] - esperado) > 1e-8) ||
        any(y$valor[positivos] < -1e-8 |
            y$valor[positivos] > 100 + 1e-8)) {
      stop("INF01/2022: percentual invalido UF ", uf_alvo,
           " grupo ", grp)
    }
  }
  invisible(TRUE)
}

validar_inf01_2022_nacional <- function(
    resultados, auditoria, ref = .infra_2022_referencias()) {
  r <- data.table::as.data.table(data.table::copy(resultados))
  a <- data.table::as.data.table(data.table::copy(auditoria))
  ufs <- sprintf("%02d", c(11:17, 21:29, 31:33, 35, 41:43, 50:53))
  if (nrow(r) != 16710L || nrow(a) != 5570L ||
      !setequal(unique(r$uf), ufs) ||
      !setequal(unique(a$uf), ufs) ||
      anyDuplicated(a$cod_mun) ||
      anyDuplicated(r, by = c("cod_mun", "grupo"))) {
    stop("INF01/2022: cobertura nacional invalida (5570 x 3).")
  }
  for (uf_alvo in ufs) {
    ir <- which(r[["uf"]] == uf_alvo)
    ia <- which(a[["uf"]] == uf_alvo)
    if (!length(ir) || !length(ia)) {
      stop("INF01/2022: UF sem registros: ", uf_alvo)
    }
    .infra_2022_validar_uf(r[ir], a[ia], uf_alvo)
  }
  if (anyNA(r$valor) || any(!is.finite(r$valor))) {
    stop("INF01/2022: o contrato de CSV bruto exige percentuais numericos ",
         "nos tres grupos de todos os municipios.")
  }
  r_ref <- data.table::copy(ref$municipal)
  a_ref <- .infra_2022_montar_auditoria(ref)
  data.table::setorder(r, cod_mun, grupo)
  data.table::setorder(r_ref, cod_mun, grupo)
  data.table::setorder(a, cod_mun)
  data.table::setorder(a_ref, cod_mun)
  if (nrow(r_ref) != 16710L || nrow(a_ref) != 5570L ||
      !identical(r$cod_mun, r_ref$cod_mun) ||
      !identical(r$grupo, r_ref$grupo) ||
      !identical(r$uf, r_ref$uf) ||
      !identical(a$cod_mun, a_ref$cod_mun) ||
      !identical(a$uf, a_ref$uf)) {
    stop("INF01/2022: referencias territoriais T18 divergentes.")
  }
  for (nm in c("numerador", "denominador", "valor")) {
    if (!.infra_2022_aprox(r[[nm]], r_ref[[nm]])) {
      stop("INF01/2022: resultados divergem do Teste 18 em ", nm)
    }
  }
  for (nm in setdiff(names(a_ref), c("ano", "uf", "cod_mun"))) {
    if (!.infra_2022_aprox(as.numeric(a[[nm]]),
                           as.numeric(a_ref[[nm]]))) {
      stop("INF01/2022: auditoria diverge do Teste 18 em ", nm)
    }
  }
  zeros <- ref$zeros
  z <- a[a$numerador_total == 0, .(cod_mun)]
  if (!all(c("cod_mun", "numerador_total") %in% names(zeros)) ||
      nrow(zeros) != nrow(z) ||
      anyDuplicated(zeros$cod_mun) ||
      !setequal(z$cod_mun, zeros$cod_mun) ||
      any(zeros$numerador_total != 0)) {
    stop("INF01/2022: municipios com numerador zero divergem do T18.")
  }
  estados <- ref$estados
  brasil <- ref$brasil
  if (nrow(estados) != 27L || nrow(brasil) != 1L ||
      !setequal(estados$uf, ufs) ||
      brasil$ano[[1L]] != 2022L || brasil$n_ufs[[1L]] != 27L ||
      brasil$n_municipios[[1L]] != 5570L ||
      brasil$n_registros_grupos[[1L]] != 16710L ||
      brasil$n_municipios_numerador_zero[[1L]] != nrow(z)) {
    stop("INF01/2022: resumo territorial do Teste 18 invalido.")
  }
  componentes <- c("denominador_total", "numerador_total",
                  "denominador_masculino", "numerador_masculino",
                  "denominador_feminino", "numerador_feminino")
  for (nm in componentes) {
    if (!.infra_2022_aprox(sum(a[[nm]]), brasil[[nm]]) ||
        !.infra_2022_aprox(sum(estados[[nm]]), brasil[[nm]])) {
      stop("INF01/2022: totais nacionais/estaduais divergentes: ", nm)
    }
  }
  for (uf_alvo in ufs) {
    est <- estados[which(estados[["uf"]] == uf_alvo)]
    mun <- a[which(a[["uf"]] == uf_alvo)]
    if (nrow(est) != 1L ||
        est$n_municipios[[1L]] != nrow(mun) ||
        est$n_dpp_amostra[[1L]] != sum(mun$n_dpp_amostra)) {
      stop("INF01/2022: resumo estadual nao conciliado UF ", uf_alvo)
    }
  }
  den <- sum(a$denominador_total)
  num <- sum(a$numerador_total)
  if (!.infra_2022_aprox(100 * num / den, brasil$inf01_total)) {
    stop("INF01/2022: percentual nacional divergente do Teste 18.")
  }
  data.table::data.table(
    ano = 2022L, n_ufs = 27L, n_municipios = 5570L,
    n_grupos = 3L, n_registros = 16710L,
    n_municipios_numerador_zero = nrow(z),
    denominador_brasil = den, numerador_brasil = num,
    inf01_brasil = 100 * num / den, qa_teste18 = "APROVADO",
    validacao_externa = "PENDENTE"
  )
}
