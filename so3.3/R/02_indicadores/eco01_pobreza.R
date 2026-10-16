# ============================================================
# PRAIS4 / SO3.3 / ECO01_POV3_PPC21
# CALCULO MUNICIPAL E AUDITORIA DA POBREZA
#
# Regra aprovada em pobreza_2010.R:
#   pessoa pobre: RDPC < linha internacional em R$/mes;
#   estimativa central: soma ponderada dos pobres dividida
#     pela soma ponderada da populacao com RDPC valida;
#   RDPC = 0 e informacao valida;
#   RDPC ausente nao e classificada como pobre ou nao pobre.
#
# Estimativas e auditorias por municipio e por grupo:
#   Total, Masculino, Feminino.
# Nenhuma regra de elegibilidade adicional e introduzida.
# ============================================================

if (!requireNamespace("data.table", quietly = TRUE)) {
  stop("O pacote data.table e necessario.")
}

validar_entrada_eco01 <- function(dados, linha_pobreza) {
  campos <- c("ano", "uf", "cod_mun", "peso", "sexo", "rdpc")
  ausentes <- setdiff(campos, names(dados))
  if (length(ausentes)) {
    stop("ECO01: campos canonicos ausentes: ",
         paste(ausentes, collapse = ", "))
  }
  if (nrow(dados) == 0L ||
      length(linha_pobreza) != 1L ||
      !is.finite(linha_pobreza) || linha_pobreza <= 0) {
    stop("ECO01: dados vazios ou linha de pobreza invalida.")
  }
  if (anyNA(dados[, .(ano, uf, cod_mun, peso, sexo)]) ||
      any(!is.finite(dados$peso) | dados$peso <= 0) ||
      any(!dados$sexo %in% c("Masculino", "Feminino")) ||
      any(!is.na(dados$rdpc) &
          (!is.finite(dados$rdpc) | dados$rdpc < 0))) {
    stop("ECO01: dados canonicos invalidos (peso, sexo, renda ou geografia).")
  }
  invisible(TRUE)
}

calcular_eco01_pobreza <- function(dados, linha_pobreza, md5_fonte_ipca) {
  d <- data.table::copy(data.table::as.data.table(dados))
  validar_entrada_eco01(d, linha_pobreza)
  if (length(md5_fonte_ipca) != 1L || is.na(md5_fonte_ipca) ||
      !nzchar(as.character(md5_fonte_ipca))) {
    stop("ECO01: hash da fonte IPCA obrigatorio para auditoria.")
  }

  d[, `:=`(
    rdpc_valido = !is.na(rdpc),
    pobre = !is.na(rdpc) & rdpc < linha_pobreza
  )]

  agregar_grupo <- function(x, grupo_nome) {
    if (!nrow(x)) {
      return(data.table::data.table())
    }
    a <- x[, .(
      n_registros = .N,
      n_rdpc_valido = sum(rdpc_valido),
      n_rdpc_na = sum(!rdpc_valido),
      n_rdpc_zero = sum(rdpc_valido & rdpc == 0, na.rm = TRUE),
      n_pobres_amostra = sum(pobre),
      populacao_total = sum(peso),
      populacao_rdpc_valido = sum(peso[rdpc_valido]),
      populacao_rdpc_na = sum(peso[!rdpc_valido]),
      populacao_rdpc_zero = sum(peso[rdpc_valido & rdpc == 0], na.rm = TRUE),
      populacao_pobre = sum(peso[pobre]),
      soma_pesos2_validos = sum(peso[rdpc_valido]^2)
    ), by = .(ano, uf, cod_mun)]
    a[, grupo := grupo_nome]
    a[]
  }

  auditoria <- data.table::rbindlist(list(
    agregar_grupo(d, "Total"),
    agregar_grupo(d[sexo == "Masculino"], "Masculino"),
    agregar_grupo(d[sexo == "Feminino"], "Feminino")
  ), use.names = TRUE, fill = FALSE)

  auditoria[, `:=`(
    cobertura_rdpc = 100 * populacao_rdpc_valido / populacao_total,
    pct_rdpc_na = 100 * populacao_rdpc_na / populacao_total,
    pct_rdpc_zero_validos = data.table::fifelse(
      populacao_rdpc_valido > 0,
      100 * populacao_rdpc_zero / populacao_rdpc_valido,
      NA_real_
    ),
    pobreza_entre_validos = data.table::fifelse(
      populacao_rdpc_valido > 0,
      100 * populacao_pobre / populacao_rdpc_valido,
      NA_real_
    ),
    pobreza_limite_inferior = 100 * populacao_pobre / populacao_total,
    pobreza_limite_superior =
      100 * (populacao_pobre + populacao_rdpc_na) / populacao_total,
    n_efetivo_validos = data.table::fifelse(
      soma_pesos2_validos > 0,
      populacao_rdpc_valido^2 / soma_pesos2_validos,
      NA_real_
    ),
    linha_pobreza_mes = linha_pobreza,
    md5_fonte_ipca = as.character(md5_fonte_ipca)
  )]
  auditoria[, amplitude_na := pobreza_limite_superior - pobreza_limite_inferior]

  bruto <- auditoria[, .(
    ano, uf, cod_mun, grupo,
    dimensao = "Economica",
    indicador = "ECO01_POV3_PPC21",
    valor = pobreza_entre_validos,
    numerador = populacao_pobre,
    denominador = populacao_rdpc_valido,
    n_amostra = n_rdpc_valido,
    n_efetivo = n_efetivo_validos,
    soma_pesos2 = soma_pesos2_validos
  )]

  data.table::setcolorder(auditoria, c(
    "ano", "uf", "cod_mun", "grupo",
    setdiff(names(auditoria), c("ano", "uf", "cod_mun", "grupo"))
  ))
  data.table::setorder(bruto, ano, cod_mun, grupo)
  data.table::setorder(auditoria, ano, cod_mun, grupo)
  list(bruto = bruto[], auditoria = auditoria[])
}

# Valida cobertura, consistencia de grupos e regra dos limites.
# Nao corrige automaticamente observacoes nem resultados.
validar_resultados_eco01 <- function(bruto, auditoria, ano = 2010L,
                                     municipios_esperados = NULL) {
  b <- data.table::as.data.table(bruto)
  a <- data.table::as.data.table(auditoria)
  req_b <- c("ano", "uf", "cod_mun", "grupo", "dimensao", "indicador",
             "valor", "numerador", "denominador", "n_amostra",
             "n_efetivo", "soma_pesos2")
  req_a <- c("ano", "uf", "cod_mun", "grupo", "n_registros",
             "n_rdpc_valido", "n_rdpc_na", "populacao_total",
             "populacao_rdpc_valido", "populacao_rdpc_na", "populacao_pobre",
             "pobreza_limite_inferior", "pobreza_limite_superior",
             "pobreza_entre_validos", "linha_pobreza_mes", "md5_fonte_ipca")
  if (length(setdiff(req_b, names(b))) ||
      length(setdiff(req_a, names(a)))) {
    stop("ECO01: estrutura incompleta dos resultados municipais.")
  }
  if (!nrow(b) || nrow(b) != nrow(a) ||
      anyNA(b[, .(ano, uf, cod_mun, grupo, indicador)]) ||
      anyNA(a[, .(ano, uf, cod_mun, grupo)]) ||
      any(b$ano != ano) || any(a$ano != ano) ||
      any(b$dimensao != "Economica") ||
      any(b$indicador != "ECO01_POV3_PPC21") ||
      anyDuplicated(b[, .(ano, cod_mun, grupo)]) ||
      anyDuplicated(a[, .(ano, cod_mun, grupo)])) {
    stop("ECO01: registros vazios, inesperados ou duplicados.")
  }
  n_mun <- data.table::uniqueN(b$cod_mun)
  if ((!is.null(municipios_esperados) && n_mun != municipios_esperados) ||
      nrow(b) != n_mun * 3L ||
      any(!b$grupo %in% c("Total", "Masculino", "Feminino"))) {
    stop("ECO01: cobertura de municipios/grupos incompleta. ",
         "Municipios=", n_mun, "; registros=", nrow(b))
  }

  # Mesmos identificadores nas bases bruta e de auditoria.
  chaves_b <- b[, paste(ano, uf, cod_mun, grupo, sep="|")]
  chaves_a <- a[, paste(ano, uf, cod_mun, grupo, sep="|")]
  if (!setequal(chaves_b, chaves_a)) {
    stop("ECO01: chaves inconsistentes entre bruto e auditoria.")
  }

  if (anyNA(b$valor) || any(!is.finite(b$valor)) ||
      any(b$valor < 0 | b$valor > 100) ||
      any(!is.finite(b$denominador) | b$denominador <= 0) ||
      any(b$numerador < 0 | b$numerador > b$denominador + 1e-6) ||
      any(b$n_amostra <= 0) || anyNA(b$n_efetivo)) {
    stop("ECO01: pobreza indefinida, fora de [0,100] ou universo invalido.")
  }
  if (any(a$n_registros != a$n_rdpc_valido + a$n_rdpc_na) ||
      any(a$populacao_pobre > a$populacao_rdpc_valido + 1e-6) ||
      any(a$pobreza_limite_inferior > a$pobreza_entre_validos + 1e-8) ||
      any(a$pobreza_entre_validos > a$pobreza_limite_superior + 1e-8)) {
    stop("ECO01: inconsistencia na auditoria de renda/limites.")
  }

  # Conferir aditividade dos pesos entre os grupos.
  tab <- a[, .(ano, uf, cod_mun, grupo,
               populacao_total, populacao_rdpc_valido, populacao_pobre)]
  t <- tab[grupo == "Total"]
  mf <- tab[grupo != "Total", .(
    populacao_total = sum(populacao_total),
    populacao_rdpc_valido = sum(populacao_rdpc_valido),
    populacao_pobre = sum(populacao_pobre)
  ), by = .(ano, uf, cod_mun)]
  comp <- merge(
    t[, .(ano, uf, cod_mun, populacao_total, populacao_rdpc_valido,
           populacao_pobre)],
    mf, by = c("ano", "uf", "cod_mun"), suffixes = c("_total", "_mf")
  )
  if (nrow(comp) != n_mun) {
    stop("ECO01: nem todos os municipios possuem ambos os sexos.")
  }
  for (campo in c("populacao_total", "populacao_rdpc_valido", "populacao_pobre")) {
    total <- comp[[paste0(campo, "_total")]]
    mf_sum <- comp[[paste0(campo, "_mf")]]
    if (any(abs(total - mf_sum) > pmax(1e-6, 1e-8 * abs(total)))) {
      stop("ECO01: Total != Masculino + Feminino no campo ", campo)
    }
  }
  invisible(TRUE)
}
