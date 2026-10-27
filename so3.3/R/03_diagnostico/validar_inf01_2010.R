# =============================================================================
# PRAIS4 / SO3.3 / INF01 - QA nacional de 2010 e regressao contra Teste 12
# =============================================================================
# Fonte do teste: produtos municipais agregados ja aprovados no Teste 12.
# A confrontacao com SIDRA (Teste 13) nao e exigida para a promocao.
# =============================================================================

.infra_2010_dir_t12 <- function() file.path(
  "so3.3", "outputs", "intermediario", "infraestrutural", "testes",
  "inf01_2010", "varredura_nacional"
)

.infra_2010_ler_csv <- function(caminho) {
  if (!file.exists(caminho)) {
    stop("INF01/2010: referencia aprovada ausente: ", caminho)
  }
  cab <- names(data.table::fread(caminho, sep = ";", nrows = 0L,
                                 showProgress = FALSE))
  cls <- intersect(c("uf", "cod_mun"), cab)
  data.table::fread(caminho, sep = ";", na.strings = "NA",
    colClasses = if (length(cls)) list(character = cls) else NULL,
    showProgress = FALSE)
}

.infra_2010_referencias <- function(dir_t12 = .infra_2010_dir_t12()) {
  arquivos <- file.path(dir_t12, c(
    "inf01_2010_municipal_preliminar.csv",
    "inf01_2010_componentes_municipais.csv",
    "inf01_2010_resumo_brasil.csv",
    "inf01_2010_qa_consolidacao.csv"
  ))
  if (!all(file.exists(arquivos))) {
    stop("INF01/2010: Teste 12 nacional completo nao localizado: ",
         paste(arquivos[!file.exists(arquivos)], collapse = ", "))
  }
  q <- .infra_2010_ler_csv(arquivos[[4L]])
  if (!all(c("controle", "aprovado") %in% names(q)) ||
      nrow(q) != 6L || anyNA(q$aprovado) ||
      !all(as.character(q$aprovado) == "TRUE")) {
    stop("INF01/2010: QA consolidado do Teste 12 nao aprovado.")
  }
  list(
    municipal = .infra_2010_ler_csv(arquivos[[1L]]),
    componentes = .infra_2010_ler_csv(arquivos[[2L]]),
    resumo = .infra_2010_ler_csv(arquivos[[3L]]),
    qa = q,
    md5 = unname(tools::md5sum(arquivos)),
    arquivos = arquivos
  )
}

.infra_2010_aprox <- function(x, y, tol = 1e-9) {
  length(x) == length(y) &&
    all(is.finite(x) & is.finite(y) &
          abs(x - y) <= tol * pmax(1, abs(x), abs(y)))
}

.infra_2010_comparar_referencia <- function(r, a, referencia) {
  ref_r <- data.table::copy(referencia$municipal)
  ref_a <- data.table::copy(referencia$componentes)
  componentes <- c("denominador_total", "numerador_total",
    "denominador_masculino", "numerador_masculino",
    "denominador_feminino", "numerador_feminino")
  faltam_r <- setdiff(c("ano", "uf", "cod_mun", "dimensao", "indicador",
                       "grupo", "valor", "numerador", "denominador"),
                      names(ref_r))
  faltam_a <- setdiff(c("ano", "uf", "cod_mun",
    "n_dpp_amostra", "n_rede_geral_amostra",
    "n_rede_canalizada_amostra", "n_pessoas_dpp_amostra",
    "n_pessoas_rede_canalizada_amostra", paste0(componentes, "_pessoas")),
    names(ref_a))
  if (length(faltam_r) || length(faltam_a) ||
      nrow(ref_r) != 16695L || nrow(ref_a) != 5565L ||
      anyDuplicated(ref_r, by = c("cod_mun", "grupo")) ||
      anyDuplicated(ref_a$cod_mun) ||
      !setequal(ref_r$cod_mun, ref_a$cod_mun) ||
      any(ref_r$ano != 2010L) || any(ref_a$ano != 2010L)) {
    stop("INF01/2010: referencia do Teste 12 incompleta/inconsistente.")
  }
  data.table::setorder(ref_r, cod_mun, grupo)
  data.table::setorder(ref_a, cod_mun)
  rr <- data.table::copy(r)
  aa <- data.table::copy(a)
  data.table::setorder(rr, cod_mun, grupo)
  data.table::setorder(aa, cod_mun)
  if (nrow(rr) != nrow(ref_r) || nrow(aa) != nrow(ref_a) ||
      !identical(rr$cod_mun, ref_r$cod_mun) ||
      !identical(rr$grupo, ref_r$grupo) ||
      !identical(aa$cod_mun, ref_a$cod_mun) ||
      !identical(rr$uf, ref_r$uf) || !identical(aa$uf, ref_a$uf)) {
    stop("INF01/2010: cobertura territorial diverge do Teste 12.")
  }
  for (nm in c("numerador", "denominador")) {
    if (!.infra_2010_aprox(rr[[nm]], ref_r[[nm]])) {
      stop("INF01/2010: resultados divergem do Teste 12 em ", nm)
    }
  }
  mesmos_na <- identical(is.na(rr$valor), is.na(ref_r$valor))
  ok <- !is.na(rr$valor)
  if (!mesmos_na ||
      !.infra_2010_aprox(rr$valor[ok], ref_r$valor[ok], tol = 1e-9)) {
    stop("INF01/2010: percentual diverge do Teste 12.")
  }
  n_amostra <- c("n_dpp_amostra", "n_rede_geral_amostra",
    "n_rede_canalizada_amostra", "n_pessoas_dpp_amostra",
    "n_pessoas_rede_canalizada_amostra")
  for (nm in n_amostra) {
    if (!.infra_2010_aprox(as.numeric(aa[[nm]]),
                            as.numeric(ref_a[[nm]]))) {
      stop("INF01/2010: auditoria amostral diverge em ", nm)
    }
  }
  for (nm in componentes) {
    if (!.infra_2010_aprox(aa[[nm]], ref_a[[paste0(nm, "_pessoas")]])) {
      stop("INF01/2010: componente diverge em ", nm)
    }
  }
  resumo <- referencia$resumo
  if (nrow(resumo) != 1L ||
      !all(c("ano", "n_ufs", "n_municipios", "n_registros_grupos",
             "denominador_total", "numerador_total") %in% names(resumo)) ||
      resumo$ano != 2010L || resumo$n_ufs != 27L ||
      resumo$n_municipios != 5565L ||
      resumo$n_registros_grupos != 16695L ||
      !.infra_2010_aprox(sum(aa$denominador_total),
                          resumo$denominador_total) ||
      !.infra_2010_aprox(sum(aa$numerador_total),
                          resumo$numerador_total)) {
    stop("INF01/2010: consolidacao Brasil do Teste 12 divergente.")
  }
  invisible(TRUE)
}

validar_inf01_2010_nacional <- function(resultados, auditoria,
                                        referencia = .infra_2010_referencias()) {
  r <- data.table::as.data.table(data.table::copy(resultados))
  a <- data.table::as.data.table(data.table::copy(auditoria))
  ufs <- sprintf("%02d", c(11:17, 21:29, 31:33, 35, 41:43, 50:53))
  if (nrow(a) != 5565L || nrow(r) != 16695L ||
      !setequal(unique(a$uf), ufs) ||
      anyDuplicated(a$cod_mun) ||
      anyDuplicated(r, by = c("cod_mun", "grupo"))) {
    stop("INF01/2010: cobertura nacional invalida (5565 municipios/3 grupos).")
  }
  # Usar indice explicito: em data.table, o nome `uf` dentro de i
  # resolve primeiramente a coluna. A expressao r$uf == uf retornava
  # TRUE para todas as linhas, fazendo cada UF receber o Brasil inteiro.
  for (uf_alvo in ufs) {
    idx_r <- which(r[["uf"]] == uf_alvo)
    idx_a <- which(a[["uf"]] == uf_alvo)
    if (!length(idx_r) || !length(idx_a)) {
      stop("INF01/2010: ausencia de dados para UF ", uf_alvo)
    }
    validar_inf01_uf(r[idx_r], a[idx_a], 2010L, uf_alvo)
  }
  # Protecao adicional: nenhuma proporcao ausente podera ser publicada.
  if (anyNA(r$valor) || any(!is.finite(r$valor)) ||
      any(r$valor < 0 | r$valor > 100)) {
    stop("INF01/2010: percentual ausente ou invalido no produto nacional.")
  }
  .infra_2010_comparar_referencia(r, a, referencia)
  den <- sum(a$denominador_total)
  num <- sum(a$numerador_total)
  data.table::data.table(
    ano = 2010L,
    n_ufs = length(ufs),
    n_municipios = nrow(a),
    n_grupos = 3L,
    n_registros = nrow(r),
    n_municipios_numerador_zero = sum(a$numerador_total == 0),
    denominador_brasil = den,
    numerador_brasil = num,
    inf01_brasil = 100 * num / den,
    qa_teste12 = "APROVADO"
  )
}
