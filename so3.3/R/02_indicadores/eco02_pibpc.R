# ============================================================
# PRAIS4 / SO3.3 / ECO02_PIBPC
# PIB PER CAPITA MUNICIPAL A PRECOS CONSTANTES DE 2010
#
# Ano PRAIS -> fonte: 2000 -> 2002; 2010 -> 2010;
#                    2022 -> 2022.
# Valor original: PIB per capita oficial IBGE (R$/habitante).
# Fatores nacionais: SIDRA 6784, variacao anual do deflator PIB.
# A serie das Contas Nacionais "Referencia 2010" e diferente
# da escolha MONETARIA de apresentar valores a precos de 2010.
#
# Fator 2002 -> 2010 = prod(1 + d_2003:2010 / 100)
# Fator 2010 -> 2010 = 1
# Fator 2022 -> 2010 = 1/prod(1 + d_2011:2022 / 100)
# Os fatores sao derivados da fonte; nao sao constantes fixas.
#
# Escopo comum_municipal: repete o mesmo valor em T/M/F, sem
# desagregacao economica por sexo. Nenhuma escrita em disco.
# ============================================================

if (!requireNamespace("data.table", quietly = TRUE)) {
  stop("ECO02 calculo: pacote data.table necessario.")
}

ECO02_ID <- "ECO02_PIBPC"
ECO02_GRUPOS <- c("Total", "Masculino", "Feminino")
ECO02_BASE_MONETARIA <- 2010L
ECO02_FONTE_POR_PRAIS <- c("2000" = 2002L, "2010" = 2010L,
                          "2022" = 2022L)
ECO02_MUNICIPIOS_PRAIS <- c("2000" = 5507L, "2010" = 5565L,
                            "2022" = 5570L)
ECO02_MUNICIPIOS_FONTE <- c("2000" = 5560L, "2010" = 5565L,
                            "2022" = 5570L)

.validar_ano_eco02 <- function(ano) {
  if (length(ano) != 1L || !is.numeric(ano) || is.na(ano) ||
      !is.finite(ano) || !ano %in% c(2000L, 2010L, 2022L)) {
    stop("ECO02: ano PRAIS invalido. Use 2000, 2010 ou 2022.")
  }
  as.integer(ano)
}

calcular_fatores_deflator_eco02 <- function(deflator_anual) {
  d <- data.table::copy(data.table::as.data.table(deflator_anual))
  campos <- c("ano_fonte", "variacao_deflator_pct")
  if (length(setdiff(campos, names(d))) ||
      anyNA(d[, ..campos]) ||
      anyDuplicated(d, by = "ano_fonte") ||
      !is.numeric(d$variacao_deflator_pct)) {
    stop("ECO02: serie anual do deflator SIDRA 6784 invalida.")
  }
  d <- d[ano_fonte %in% 2002:2022]
  data.table::setorder(d, ano_fonte)
  if (nrow(d) != 21L ||
      !identical(d$ano_fonte, 2002:2022) ||
      any(!is.finite(d$variacao_deflator_pct)) ||
      any(d$variacao_deflator_pct <= -100)) {
    stop("ECO02: deflator 2002-2022 incompleto ou invalido.")
  }

  taxas <- data.table::copy(d)
  taxas[, multiplicador_anual := 1 + variacao_deflator_pct / 100]
  if (any(!is.finite(taxas$multiplicador_anual) |
          taxas$multiplicador_anual <= 0)) {
    stop("ECO02: multiplicadores anuais invalidos.")
  }

  atualizacao_2002_2010 <- prod(
    taxas[ano_fonte %in% 2003:2010]$multiplicador_anual
  )
  deflacao_2022_2010 <- 1 / prod(
    taxas[ano_fonte %in% 2011:2022]$multiplicador_anual
  )
  fatores <- data.table::data.table(
    ano_prais = c(2000L, 2010L, 2022L),
    ano_fonte = c(2002L, 2010L, 2022L),
    ano_base_monetaria = rep.int(2010L, 3L),
    fator_para_2010 = c(
      atualizacao_2002_2010, 1, deflacao_2022_2010
    ),
    periodo_deflator = c("2003-2010", "base_2010", "2011-2022"),
    operacao = c("atualizar", "sem_correcao", "deflacionar"),
    unidade_saida = "R$ de 2010 por habitante"
  )

  # Conferencia independente: a razao entre os dois fatores
  # extremos deve reproduzir o acumulado de 2003 a 2022.
  acumulado_2002_2022 <- prod(
    taxas[ano_fonte %in% 2003:2022]$multiplicador_anual
  )
  if (any(!is.finite(fatores$fator_para_2010) |
          fatores$fator_para_2010 <= 0) ||
      !isTRUE(all.equal(
        fatores$fator_para_2010[[1L]] /
          fatores$fator_para_2010[[3L]],
        acumulado_2002_2022,
        tolerance = 1e-12
      )) ||
      fatores$fator_para_2010[[2L]] != 1) {
    stop("ECO02: fatores acumulados nao passaram na validacao.")
  }

  # A serie anual usada no produto acompanha os tres fatores
  # para a auditoria do calculo monetario.
  list(fatores = fatores[], serie_anual = taxas[])
}

validar_resultados_eco02 <- function(
  bruto, auditoria, ano, codigos_prais, fatores
) {
  ano <- .validar_ano_eco02(ano)
  ano_fonte <- unname(ECO02_FONTE_POR_PRAIS[as.character(ano)])
  n_prais <- unname(ECO02_MUNICIPIOS_PRAIS[as.character(ano)])
  a <- data.table::copy(data.table::as.data.table(auditoria))
  b <- data.table::copy(data.table::as.data.table(bruto))
  f <- data.table::copy(data.table::as.data.table(fatores))

  campos_aud <- c(
    "ano", "ano_fonte", "ano_base_monetaria", "uf", "cod_mun",
    "nome_mun_ibge", "indicador", "escopo", "pib_mil_reais",
    "pib_pc_corrente_reais", "fator_deflator_2010",
    "pib_pc_reais_2010", "referencia_populacional",
    "revisao_pendente", "periodo_arquivo", "md5_ibge_2002_2009",
    "md5_ibge_2010_2023", "md5_sidra_6784"
  )
  campos_bruto <- c(
    "ano", "ano_fonte", "ano_base_monetaria", "uf", "cod_mun",
    "dimensao", "indicador", "grupo", "escopo", "valor"
  )
  campos_fator <- c(
    "ano_prais", "ano_fonte", "ano_base_monetaria", "fator_para_2010"
  )
  if (length(setdiff(campos_aud, names(a))) ||
      length(setdiff(campos_bruto, names(b))) ||
      length(setdiff(campos_fator, names(f)))) {
    stop("ECO02: estrutura do bruto, auditoria ou fatores incompleta.")
  }
  if (length(codigos_prais) != n_prais ||
      !is.character(codigos_prais) ||
      anyNA(codigos_prais) ||
      any(!grepl("^[0-9]{7}$", codigos_prais)) ||
      anyDuplicated(codigos_prais) ||
      nrow(a) != n_prais ||
      nrow(b) != 3L * n_prais ||
      anyNA(a[, ..campos_aud]) ||
      anyNA(b[, ..campos_bruto]) ||
      anyDuplicated(a, by = c("ano", "cod_mun")) ||
      anyDuplicated(b, by = c("ano", "cod_mun", "grupo")) ||
      !setequal(a$cod_mun, codigos_prais) ||
      !setequal(unique(b$cod_mun), codigos_prais) ||
      !setequal(unique(b$grupo), ECO02_GRUPOS)) {
    stop("ECO02: cobertura municipal, grupos ou chaves inconsistentes.")
  }
  if (nrow(f) != 3L ||
      anyNA(f[, ..campos_fator]) ||
      anyDuplicated(f, by = "ano_prais") ||
      !identical(sort(f$ano_prais), c(2000L, 2010L, 2022L)) ||
      any(f$ano_fonte != unname(
        ECO02_FONTE_POR_PRAIS[as.character(f$ano_prais)]
      )) ||
      any(f$ano_base_monetaria != 2010L) ||
      any(!is.finite(f$fator_para_2010) |
          f$fator_para_2010 <= 0)) {
    stop("ECO02: fatores por recorte invalidos.")
  }
  fator <- f[ano_prais == ano]$fator_para_2010
  if (length(fator) != 1L ||
      any(a$ano != ano) || any(b$ano != ano) ||
      any(a$ano_fonte != ano_fonte) ||
      any(b$ano_fonte != ano_fonte) ||
      any(a$ano_base_monetaria != 2010L) ||
      any(b$ano_base_monetaria != 2010L) ||
      any(a$uf != substr(a$cod_mun, 1L, 2L)) ||
      any(b$uf != substr(b$cod_mun, 1L, 2L)) ||
      any(a$indicador != ECO02_ID) ||
      any(b$indicador != ECO02_ID) ||
      any(a$escopo != "comum_municipal") ||
      any(b$escopo != "comum_municipal") ||
      any(b$dimensao != "Economica")) {
    stop("ECO02: identificadores ou ano-base inconsistentes.")
  }

  numericos <- c(
    "pib_mil_reais", "pib_pc_corrente_reais",
    "fator_deflator_2010", "pib_pc_reais_2010"
  )
  if (!all(vapply(a[, ..numericos], is.numeric, logical(1L))) ||
      !is.numeric(b$valor) ||
      any(!is.finite(as.matrix(a[, ..numericos]))) ||
      any(as.matrix(a[, ..numericos]) <= 0) ||
      any(!is.finite(b$valor) | b$valor <= 0)) {
    stop("ECO02: valores economicos nao finitos ou nao positivos.")
  }
  if (!is.logical(a$revisao_pendente) ||
      any(a$revisao_pendente != (ano_fonte == 2022L)) ||
      any(a$referencia_populacional != if (ano_fonte == 2022L) {
        "primeira_apuracao_censo2022"
      } else {
        "estimativa_populacional_1_julho_TCU"
      }) ||
      any(a$periodo_arquivo != if (ano_fonte == 2002L) {
        "2002_2009"
      } else {
        "2010_2023"
      })) {
    stop("ECO02: metadados da fonte/populacao inconsistentes.")
  }

  esperado <- a$pib_pc_corrente_reais * fator
  if (!isTRUE(all.equal(
        a$fator_deflator_2010, rep.int(fator, n_prais),
        tolerance = 1e-12, check.attributes = FALSE
      )) ||
      !isTRUE(all.equal(
        a$pib_pc_reais_2010, esperado,
        tolerance = 1e-12, check.attributes = FALSE
      ))) {
    stop("ECO02: conversao monetaria nao reproduz a fonte e o fator.")
  }
  if (ano == 2010L &&
      !identical(a$pib_pc_corrente_reais, a$pib_pc_reais_2010)) {
    stop("ECO02: ano-base 2010 deve permanecer sem correcao.")
  }

  hashes <- unique(a[, .(
    md5_ibge_2002_2009, md5_ibge_2010_2023, md5_sidra_6784
  )])
  if (nrow(hashes) != 1L ||
      any(!grepl(
        "^[0-9a-f]{32}$", unlist(hashes, use.names = FALSE)
      ))) {
    stop("ECO02: assinaturas de origem ausentes ou inconsistentes.")
  }
  data.table::setorder(a, cod_mun)
  for (g in ECO02_GRUPOS) {
    parte <- b[grupo == g]
    data.table::setorder(parte, cod_mun)
    if (nrow(parte) != n_prais ||
        !identical(parte$cod_mun, a$cod_mun) ||
        !identical(parte$uf, a$uf) ||
        !isTRUE(all.equal(
          parte$valor, a$pib_pc_reais_2010,
          tolerance = 1e-12, check.attributes = FALSE
        ))) {
      stop("ECO02: valor municipal difere entre T/M/F ou auditoria.")
    }
  }
  invisible(TRUE)
}

calcular_eco02_pibpc <- function(
  dados_recorte, ano, codigos_prais, fatores, fontes_md5
) {
  ano <- .validar_ano_eco02(ano)
  ano_fonte <- unname(ECO02_FONTE_POR_PRAIS[as.character(ano)])
  n_prais <- unname(ECO02_MUNICIPIOS_PRAIS[as.character(ano)])
  n_fonte <- unname(ECO02_MUNICIPIOS_FONTE[as.character(ano)])
  if (!is.character(fontes_md5) ||
      length(fontes_md5) != 3L ||
      !setequal(names(fontes_md5), c(
        "2002_2009", "2010_2023", "6784"
      )) ||
      anyNA(fontes_md5) ||
      any(!grepl("^[0-9a-f]{32}$", fontes_md5))) {
    stop("ECO02: hashes das duas bases IBGE e SIDRA 6784 invalidos.")
  }
  if (!is.character(codigos_prais) ||
      length(codigos_prais) != n_prais ||
      anyNA(codigos_prais) ||
      any(!grepl("^[0-9]{7}$", codigos_prais)) ||
      anyDuplicated(codigos_prais)) {
    stop("ECO02: referencia territorial PRAIS invalida.")
  }
  f <- data.table::as.data.table(fatores)
  if (nrow(f) != 3L ||
      length(setdiff(c("ano_prais", "ano_fonte", "ano_base_monetaria",
                       "fator_para_2010"), names(f))) ||
      anyDuplicated(f, by = "ano_prais")) {
    stop("ECO02: tabela de fatores incompleta.")
  }
  ativo <- f[ano_prais == ano]
  if (nrow(ativo) != 1L ||
      ativo$ano_fonte[[1L]] != ano_fonte ||
      ativo$ano_base_monetaria[[1L]] != 2010L ||
      !is.finite(ativo$fator_para_2010[[1L]]) ||
      ativo$fator_para_2010[[1L]] <= 0) {
    stop("ECO02: fator monetario para recorte invalido.")
  }
  fator <- ativo$fator_para_2010[[1L]]

  d <- data.table::copy(data.table::as.data.table(dados_recorte))
  obrigatorias <- c(
    "ano_prais", "ano_fonte", "uf", "cod_mun", "nome_mun_ibge",
    "pib_mil_reais", "pib_pc_reais", "referencia_populacional",
    "revisao_pendente", "periodo_arquivo"
  )
  if (length(setdiff(obrigatorias, names(d))) ||
      nrow(d) != n_fonte ||
      anyNA(d[, ..obrigatorias]) ||
      anyDuplicated(d, by = "cod_mun") ||
      any(d$ano_prais != ano) ||
      any(d$ano_fonte != ano_fonte) ||
      any(!grepl("^[0-9]{7}$", d$cod_mun)) ||
      any(d$uf != substr(d$cod_mun, 1L, 2L)) ||
      any(!is.finite(d$pib_mil_reais) | d$pib_mil_reais <= 0) ||
      any(!is.finite(d$pib_pc_reais) | d$pib_pc_reais <= 0)) {
    stop("ECO02: recorte municipal ou temporal IBGE inconsistente.")
  }
  indice <- match(codigos_prais, d$cod_mun)
  if (anyNA(indice)) {
    stop("ECO02: municipios PRAIS ausentes na fonte: ",
         paste(head(codigos_prais[is.na(indice)], 12L),
               collapse = ", "))
  }
  selecionados <- d[indice]
  valor_2010 <- selecionados$pib_pc_reais * fator
  if (any(!is.finite(valor_2010) | valor_2010 <= 0)) {
    stop("ECO02: PIB per capita corrigido nao finito/positivo.")
  }
  auditoria <- data.table::data.table(
    ano = rep.int(ano, n_prais),
    ano_fonte = selecionados$ano_fonte,
    ano_base_monetaria = rep.int(2010L, n_prais),
    uf = selecionados$uf,
    cod_mun = selecionados$cod_mun,
    nome_mun_ibge = selecionados$nome_mun_ibge,
    indicador = ECO02_ID,
    escopo = "comum_municipal",
    pib_mil_reais = selecionados$pib_mil_reais,
    pib_pc_corrente_reais = selecionados$pib_pc_reais,
    fator_deflator_2010 = rep.int(fator, n_prais),
    pib_pc_reais_2010 = valor_2010,
    referencia_populacional = selecionados$referencia_populacional,
    revisao_pendente = selecionados$revisao_pendente,
    periodo_arquivo = selecionados$periodo_arquivo,
    md5_ibge_2002_2009 = unname(fontes_md5[["2002_2009"]]),
    md5_ibge_2010_2023 = unname(fontes_md5[["2010_2023"]]),
    md5_sidra_6784 = unname(fontes_md5[["6784"]])
  )
  data.table::setorder(auditoria, cod_mun)
  bruto <- data.table::rbindlist(lapply(ECO02_GRUPOS, function(g) {
    data.table::data.table(
      ano = auditoria$ano,
      ano_fonte = auditoria$ano_fonte,
      ano_base_monetaria = auditoria$ano_base_monetaria,
      uf = auditoria$uf,
      cod_mun = auditoria$cod_mun,
      dimensao = "Economica",
      indicador = ECO02_ID,
      grupo = g,
      escopo = "comum_municipal",
      valor = auditoria$pib_pc_reais_2010
    )
  }), use.names = TRUE)
  bruto[, ordem_grupo := match(grupo, ECO02_GRUPOS)]
  data.table::setorder(bruto, ano, cod_mun, ordem_grupo)
  bruto[, ordem_grupo := NULL]

  validar_resultados_eco02(
    bruto, auditoria, ano, codigos_prais, f
  )
  list(bruto = bruto[], auditoria = auditoria[])
}
