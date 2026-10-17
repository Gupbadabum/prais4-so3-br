# ============================================================
# PRAIS4 / SO3.3 / ECO03_AGROPIB
# PARTICIPACAO DO VAB AGROPECUARIO NO PIB MUNICIPAL (%)
#
# Formula: 100 * VAB_agropecuaria / PIB_municipal
# Numerador e denominador: mesmo municipio, mesmo ano-fonte,
# mesma unidade (Mil Reais); nao aplicar deflator.
#
# Ano PRAIS -> ano-fonte: 2000 -> 2002; 2010 -> 2010;
#                          2022 -> 2021.
# Indicador comum_municipal: o mesmo valor e disponibilizado
# para Total, Masculino e Feminino, SEM desagregacao por sexo.
# Valores zero e acima de 100% sao preservados e auditados.
#
# Este modulo nao le arquivos, nao grava resultados e nao
# modifica quaisquer produtos preexistentes.
# ============================================================

if (!requireNamespace("data.table", quietly = TRUE)) {
  stop("ECO03: o pacote data.table e necessario.")
}

ECO03_ID <- "ECO03_AGROPIB"
ECO03_GRUPOS <- c("Total", "Masculino", "Feminino")
ECO03_ANO_FONTE <- c("2000" = 2002L, "2010" = 2010L, "2022" = 2021L)
ECO03_MUNICIPIOS <- c("2000" = 5507L, "2010" = 5565L, "2022" = 5570L)

.validar_ano_eco03 <- function(ano) {
  if (length(ano) != 1L || !is.numeric(ano) || is.na(ano) ||
      !is.finite(ano) || !ano %in% c(2000L, 2010L, 2022L)) {
    stop("ECO03: ano PRAIS invalido. Use 2000, 2010 ou 2022.")
  }
  as.integer(ano)
}

# Verifica integralmente o resultado calculado, inclusive a
# equivalencia dos tres grupos em um indicador comum_municipal.
validar_resultados_eco03 <- function(bruto, auditoria, ano,
                                    codigos_prais) {
  ano <- .validar_ano_eco03(ano)
  ano_fonte <- unname(ECO03_ANO_FONTE[as.character(ano)])
  n_esperado <- unname(ECO03_MUNICIPIOS[as.character(ano)])
  b <- data.table::copy(data.table::as.data.table(bruto))
  a <- data.table::copy(data.table::as.data.table(auditoria))

  campos_bruto <- c("ano", "ano_fonte", "uf", "cod_mun",
                    "dimensao", "indicador", "grupo",
                    "escopo", "valor")
  campos_auditoria <- c(
    "ano", "ano_fonte", "uf", "cod_mun", "nome_mun_sidra",
    "indicador", "escopo", "pib_mil_reais", "vab_agro_mil_reais",
    "participacao_pct", "vab_zero", "vab_acima_100",
    "status_pib", "status_vab_agro",
    "md5_tabela5938", "md5_tabela5938_vab"
  )
  if (length(setdiff(campos_bruto, names(b))) ||
      length(setdiff(campos_auditoria, names(a)))) {
    stop("ECO03: colunas obrigatorias ausentes no bruto ou auditoria.")
  }
  if (!is.character(codigos_prais) ||
      length(codigos_prais) != n_esperado ||
      anyNA(codigos_prais) ||
      any(!grepl("^[0-9]{7}$", codigos_prais)) ||
      anyDuplicated(codigos_prais)) {
    stop("ECO03: referencia municipal PRAIS incompleta ou invalida.")
  }
  if (nrow(a) != n_esperado || nrow(b) != 3L * n_esperado ||
      anyNA(a[, ..campos_auditoria]) ||
      anyNA(b[, ..campos_bruto]) ||
      anyDuplicated(a, by = c("ano", "cod_mun")) ||
      anyDuplicated(b, by = c("ano", "cod_mun", "grupo")) ||
      !setequal(a$cod_mun, codigos_prais) ||
      !setequal(unique(b$cod_mun), codigos_prais) ||
      !setequal(unique(b$grupo), ECO03_GRUPOS)) {
    stop("ECO03: cardinalidade, chaves ou cobertura invalidas.")
  }
  if (any(a$ano != ano) || any(b$ano != ano) ||
      any(a$ano_fonte != ano_fonte) ||
      any(b$ano_fonte != ano_fonte) ||
      any(a$uf != substr(a$cod_mun, 1L, 2L)) ||
      any(b$uf != substr(b$cod_mun, 1L, 2L)) ||
      any(a$indicador != ECO03_ID) ||
      any(b$indicador != ECO03_ID) ||
      any(a$escopo != "comum_municipal") ||
      any(b$escopo != "comum_municipal") ||
      any(b$dimensao != "Economica")) {
    stop("ECO03: identificadores, anos ou escopo inconsistentes.")
  }
  if (!is.numeric(a$pib_mil_reais) ||
      !is.numeric(a$vab_agro_mil_reais) ||
      !is.numeric(a$participacao_pct) ||
      !is.numeric(b$valor) ||
      any(!is.finite(a$pib_mil_reais) | a$pib_mil_reais <= 0) ||
      any(!is.finite(a$vab_agro_mil_reais) |
          a$vab_agro_mil_reais < 0) ||
      any(!is.finite(a$participacao_pct) | a$participacao_pct < 0) ||
      any(!is.finite(b$valor) | b$valor < 0)) {
    stop("ECO03: valores economicos nao finitos ou invalidos.")
  }
  esperado <- 100 * a$vab_agro_mil_reais / a$pib_mil_reais
  if (!isTRUE(all.equal(
        a$participacao_pct, esperado, tolerance = 1e-12,
        check.attributes = FALSE
      )) ||
      !is.logical(a$vab_zero) || !is.logical(a$vab_acima_100) ||
      !identical(a$vab_zero, a$vab_agro_mil_reais == 0) ||
      !identical(a$vab_acima_100, a$participacao_pct > 100) ||
      any(!a$status_pib %in% c("disponivel", "zero_absoluto")) ||
      any(!a$status_vab_agro %in% c("disponivel", "zero_absoluto"))) {
    stop("ECO03: formula, sinalizadores ou status de origem inconsistentes.")
  }
  hashes <- unique(a[, .(md5_tabela5938, md5_tabela5938_vab)])
  if (nrow(hashes) != 1L ||
      any(!grepl("^[0-9a-f]{32}$", unlist(hashes, use.names = FALSE)))) {
    stop("ECO03: assinaturas MD5 das fontes ausentes ou inconsistentes.")
  }

  data.table::setorder(a, cod_mun)
  for (grupo_ativo in ECO03_GRUPOS) {
    g <- b[grupo == grupo_ativo]
    data.table::setorder(g, cod_mun)
    if (nrow(g) != n_esperado ||
        !identical(g$cod_mun, a$cod_mun) ||
        !identical(g$uf, a$uf) ||
        !isTRUE(all.equal(
          g$valor, a$participacao_pct, tolerance = 1e-12,
          check.attributes = FALSE
        ))) {
      stop("ECO03: os tres grupos nao reproduzem o mesmo valor municipal.")
    }
  }
  invisible(TRUE)
}

calcular_eco03_agropib <- function(dados_recorte, ano,
                                  codigos_prais, fontes_md5) {
  ano <- .validar_ano_eco03(ano)
  ano_fonte <- unname(ECO03_ANO_FONTE[as.character(ano)])
  n_esperado <- unname(ECO03_MUNICIPIOS[as.character(ano)])
  if (!is.character(fontes_md5) ||
      length(fontes_md5) != 2L ||
      !setequal(names(fontes_md5), c("5938", "5938_VAB")) ||
      anyNA(fontes_md5) ||
      any(!grepl("^[0-9a-f]{32}$", fontes_md5))) {
    stop("ECO03: MD5 das duas fontes 5938 nao informado corretamente.")
  }
  if (!is.character(codigos_prais) ||
      length(codigos_prais) != n_esperado ||
      anyNA(codigos_prais) ||
      any(!grepl("^[0-9]{7}$", codigos_prais)) ||
      anyDuplicated(codigos_prais)) {
    stop("ECO03: codigos territoriais do PRAIS invalidos.")
  }

  d <- data.table::copy(data.table::as.data.table(dados_recorte))
  obrigatorias <- c(
    "indicador", "ano_prais", "ano_fonte", "uf",
    "cod_mun", "nome_mun_sidra", "pib_mil_reais",
    "status_pib", "vab_agro_mil_reais", "status_vab_agro"
  )
  if (length(setdiff(obrigatorias, names(d)))) {
    stop("ECO03: estrutura da leitura SIDRA incompleta.")
  }
  if (nrow(d) != 5570L ||
      anyDuplicated(d, by = "cod_mun") ||
      anyNA(d[, .(indicador, ano_prais, ano_fonte, uf,
                   cod_mun, nome_mun_sidra, status_pib, status_vab_agro)]) ||
      any(d$indicador != "ECO03") ||
      any(d$ano_prais != ano) ||
      any(d$ano_fonte != ano_fonte) ||
      any(!grepl("^[0-9]{7}$", d$cod_mun)) ||
      any(d$uf != substr(d$cod_mun, 1L, 2L))) {
    stop("ECO03: recorte de entrada municipal ou temporal inconsistente.")
  }
  pos <- match(codigos_prais, d$cod_mun)
  if (anyNA(pos)) {
    stop("ECO03: municipios PRAIS ausentes na fonte: ",
         paste(head(codigos_prais[is.na(pos)], 12L), collapse = ", "))
  }
  selecionados <- d[pos]
  if (anyNA(selecionados[, .(pib_mil_reais, vab_agro_mil_reais)]) ||
      any(!is.finite(selecionados$pib_mil_reais) |
          selecionados$pib_mil_reais <= 0) ||
      any(!is.finite(selecionados$vab_agro_mil_reais) |
          selecionados$vab_agro_mil_reais < 0) ||
      any(!selecionados$status_pib %in% c("disponivel", "zero_absoluto")) ||
      any(!selecionados$status_vab_agro %in%
          c("disponivel", "zero_absoluto"))) {
    stop("ECO03: PIB ou VAB invalido/indisponivel para municipio PRAIS.")
  }

  participacao <- 100 * selecionados$vab_agro_mil_reais /
    selecionados$pib_mil_reais
  if (any(!is.finite(participacao) | participacao < 0)) {
    stop("ECO03: resultado da razao VAB/PIB invalido.")
  }
  auditoria <- data.table::data.table(
    ano = rep.int(ano, n_esperado),
    ano_fonte = selecionados$ano_fonte,
    uf = selecionados$uf,
    cod_mun = selecionados$cod_mun,
    nome_mun_sidra = selecionados$nome_mun_sidra,
    indicador = ECO03_ID,
    escopo = "comum_municipal",
    pib_mil_reais = selecionados$pib_mil_reais,
    vab_agro_mil_reais = selecionados$vab_agro_mil_reais,
    participacao_pct = participacao,
    vab_zero = selecionados$vab_agro_mil_reais == 0,
    vab_acima_100 = participacao > 100,
    status_pib = selecionados$status_pib,
    status_vab_agro = selecionados$status_vab_agro,
    md5_tabela5938 = unname(fontes_md5[["5938"]]),
    md5_tabela5938_vab = unname(fontes_md5[["5938_VAB"]])
  )
  data.table::setorder(auditoria, cod_mun)
  bruto <- data.table::rbindlist(lapply(ECO03_GRUPOS, function(g) {
    data.table::data.table(
      ano = auditoria$ano,
      ano_fonte = auditoria$ano_fonte,
      uf = auditoria$uf,
      cod_mun = auditoria$cod_mun,
      dimensao = "Economica",
      indicador = ECO03_ID,
      grupo = g,
      escopo = "comum_municipal",
      valor = auditoria$participacao_pct
    )
  }), use.names = TRUE)
  bruto[, ordem_grupo := match(grupo, ECO03_GRUPOS)]
  data.table::setorder(bruto, ano, cod_mun, ordem_grupo)
  bruto[, ordem_grupo := NULL]

  validar_resultados_eco03(bruto, auditoria, ano, codigos_prais)
  list(bruto = bruto[], auditoria = auditoria[])
}
