# PRAIS4 / SO3.3 - Diagnostico estatistico dos indicadores municipais brutos
# Bloco A: somente leitura e diagnostico. Nenhum tratamento e aplicado.
# Independencia: (indicador, grupo) e a unidade estatistica; anos 2000/2010/2022
# sao reunidos exclusivamente dentro dessa unidade. Atributos territoriais
# compartilhados usam uma unica serie, sem triplicar municipios.
# Funcoes publicas: estat_so33_catalogo(), estat_so33_ler_bruto(),
# estat_so33_series(), estat_so33_resumir(), estat_so33_diagnosticar().
# Dependencias: R base (utils, stats e tools).

estat_so33_exigir <- function(condicao, mensagem) {
  if (!isTRUE(condicao)) stop(paste0("SO3.3/Estatistica: ", mensagem), call. = FALSE)
  invisible(TRUE)
}

estat_so33_catalogo <- function() {
  data.frame(
    dimensao = c(rep("social", 4L), rep("economica", 3L),
                 rep("infraestrutural", 2L)),
    indicador = c("SOC01_ALF15", "SOC02_RURAL", "SOC03_EV0",
                  "SOC04_POP1564", "ECO01_POV3_PPC21", "ECO02_PIBPC",
                  "ECO03_AGROPIB", "INF01_REDE_CANALIZADA",
                  "INF02_RECURSOS_HIDRICOS_PC"),
    natureza = c(rep("populacional", 5L), rep("territorial_compartilhado", 2L),
                 "populacional", "territorial_compartilhado"),
    stringsAsFactors = FALSE
  )
}

estat_so33_anos <- function() c(2000L, 2010L, 2022L)
estat_so33_grupos <- function() c("Total", "Masculino", "Feminino")

estat_so33_ler_bruto <- function(
    indicador, ano,
    dir_bruto = file.path("so3.3", "outputs", "bruto")) {

  meta <- estat_so33_catalogo()
  meta <- meta[meta$indicador == indicador, , drop = FALSE]
  estat_so33_exigir(nrow(meta) == 1L, paste("Indicador desconhecido:", indicador))
  estat_so33_exigir(length(ano) == 1L && !is.na(ano) &&
                      ano %in% estat_so33_anos(), "Recorte temporal invalido.")

  arquivo <- file.path(dir_bruto, meta$dimensao, as.character(ano),
                        paste0(indicador, "_", ano, ".csv"))
  estat_so33_exigir(file.exists(arquivo), paste("CSV bruto ausente:", arquivo))

  x <- utils::read.csv(
    arquivo, sep = ";", dec = ".", quote = "\"",
    colClasses = "character", na.strings = c("", "NA"),
    fileEncoding = "UTF-8", check.names = FALSE,
    stringsAsFactors = FALSE
  )
  campos <- c("ano", "uf", "cod_mun", "nm_mun",
              "indicador", "grupo", "valor")
  estat_so33_exigir(all(campos %in% names(x)) && !anyDuplicated(names(x)),
                    paste("Contrato de colunas invalido:", arquivo))

  esperado <- if (identical(indicador, "INF02_RECURSOS_HIDRICOS_PC")) {
    5571L
  } else {
    switch(as.character(ano), "2000" = 5507L,
           "2010" = 5565L, "2022" = 5570L)
  }
  grupos <- estat_so33_grupos()
  estat_so33_exigir(
    nrow(x) == 3L * esperado &&
      !anyNA(x[c("ano", "uf", "cod_mun", "nm_mun", "indicador", "grupo")]) &&
      all(nzchar(x$uf)) && all(nzchar(x$nm_mun)) &&
      all(grepl("^[0-9]{7}$", x$cod_mun)) &&
      all(x$ano == as.character(ano)) &&
      all(x$indicador == indicador) &&
      setequal(unique(x$grupo), grupos) &&
      length(unique(x$cod_mun)) == esperado &&
      all(as.integer(table(factor(x$grupo, levels = grupos))) == esperado) &&
      !anyDuplicated(paste(x$cod_mun, x$grupo, sep = "::")) &&
      all(as.integer(table(x$cod_mun)) == 3L),
    paste("Chaves, grupos, ano ou cardinalidade invalidos:", arquivo)
  )

  texto <- trimws(x$valor)
  texto[!is.na(texto) & texto %in% c("", "NA")] <- NA_character_
  valor <- suppressWarnings(as.numeric(texto))
  invalido <- !is.na(texto) & (is.na(valor) | !is.finite(valor))
  estat_so33_exigir(!any(invalido),
                    paste("Valores nao numericos/infinitos:", arquivo))
  x$valor <- valor
  x$ano <- as.integer(x$ano)

  percentuais <- c("SOC01_ALF15", "SOC02_RURAL",
                   "SOC04_POP1564", "ECO01_POV3_PPC21",
                   "INF01_REDE_CANALIZADA")
  if (indicador %in% percentuais) {
    estat_so33_exigir(all(is.na(valor) | (valor >= 0 & valor <= 100)),
                      paste("Percentual fora de [0,100]:", arquivo))
  }
  # ECO03 pode ultrapassar 100%; nao truncar. INF02 conserva NA/status.
  if (indicador == "INF02_RECURSOS_HIDRICOS_PC") {
    campos_status <- c("status_calculo", "situacao_qualidade",
                       "compatibilidade_territorial")
    estat_so33_exigir(all(campos_status %in% names(x)),
                      paste("Status INF02 ausentes:", arquivo))
    total <- x[x$grupo == "Total", , drop = FALSE]
    ausencias_validas <- c(
      "DIVISAO_TERRITORIAL_ALTERADA_2025",
      "Q_NEGATIVA_NAO_INTERPRETAVEL",
      "SEM_CONTRIBUICAO_ESTIMADA",
      "SEM_POPULACAO_CENSITARIA"
    )
    coerente <- (!is.na(total$valor) &
                 total$status_calculo == "CALCULADO_SEM_HARMONIZACAO_TERRITORIAL") |
                (is.na(total$valor) &
                 total$status_calculo %in% ausencias_validas)
    estat_so33_exigir(!anyNA(coerente) && all(coerente),
                      paste("Status de calculo INF02 inconsistente:", arquivo))
  }

  inventario <- data.frame(
    dimensao = meta$dimensao, indicador = indicador, ano = as.integer(ano),
    natureza = meta$natureza, arquivo = arquivo,
    md5 = unname(tools::md5sum(arquivo)), municipios = esperado,
    registros = nrow(x),
    validos_total = sum(!is.na(x$valor[x$grupo == "Total"])),
    ausentes_total = sum(is.na(x$valor[x$grupo == "Total"])),
    stringsAsFactors = FALSE
  )
  list(dados = x, inventario = inventario)
}

estat_so33_series <- function(base, natureza) {
  grupos <- estat_so33_grupos()
  estat_so33_exigir(all(c("ano", "cod_mun", "grupo", "valor") %in% names(base)),
                    "Serie sem colunas obrigatorias.")
  estat_so33_exigir(setequal(unique(base$grupo), grupos),
                    "Os tres grupos devem estar presentes.")
  if (identical(natureza, "territorial_compartilhado")) {
    referencia <- base[base$grupo == "Total", , drop = FALSE]
    referencia <- referencia[order(referencia$ano, referencia$cod_mun), ]
    for (grupo in grupos[-1L]) {
      outro <- base[base$grupo == grupo, , drop = FALSE]
      outro <- outro[order(outro$ano, outro$cod_mun), ]
      estat_so33_exigir(
        identical(referencia$ano, outro$ano) &&
          identical(referencia$cod_mun, outro$cod_mun) &&
          identical(referencia$valor, outro$valor),
        paste("Atributo compartilhado diverge entre Total e", grupo)
      )
    }
    return(list(Compartilhado = referencia))
  }
  estat_so33_exigir(identical(natureza, "populacional"),
                    paste("Natureza de indicador invalida:", natureza))
  resultado <- lapply(grupos, function(grupo) {
    base[base$grupo == grupo, , drop = FALSE]
  })
  names(resultado) <- grupos
  resultado
}

estat_so33_quantil <- function(x, p) {
  if (!length(x)) return(NA_real_)
  as.numeric(stats::quantile(x, probs = p, names = FALSE,
                             na.rm = TRUE, type = 7L))
}


# ============================================================
# Triagem JRC/COINr - momentos corrigidos (e1071 type = 2)
#
# As duas formulas seguem COINr::skew() e COINr::kurt().
# Curtose e excedente (normal = 0).
# check_SkewKurt: PASSA quando |assimetria| < 2 OU curtose < 3.5;
# caso contrario, INVESTIGAR (ambos os limites atingidos).
# NA/constante/N insuficiente => INDETERMINADO, sem decisao automatica.
# Nao executa winsorizacao.
# Fonte: https://github.com/bluefoxr/COINr/blob/master/R/treat.R
# ============================================================

estat_so33_momentos_coinr <- function(
    x, limite_assimetria = 2, limite_curtose = 3.5) {
  estat_so33_exigir(is.numeric(x), "Valores para momentos devem ser numericos.")
  estat_so33_exigir(all(is.finite(x[!is.na(x)])),
                    "Momentos COINr nao aceitam infinitos.")
  estat_so33_exigir(is.numeric(limite_assimetria) &&
                      length(limite_assimetria) == 1L &&
                      is.finite(limite_assimetria) && limite_assimetria > 0,
                    "Limite de assimetria invalido.")
  estat_so33_exigir(is.numeric(limite_curtose) &&
                      length(limite_curtose) == 1L &&
                      is.finite(limite_curtose),
                    "Limite de curtose invalido.")
  x <- x[!is.na(x)]
  n <- length(x)

  indefinido <- function(motivo) {
    list(assimetria = NA_real_, curtose_excesso = NA_real_,
         status = motivo, investigar = NA, cauda_assimetria = NA_character_)
  }
  if (n < 4L) return(indefinido("INDETERMINADO_N_INSUFICIENTE"))

  z <- x - mean(x)
  s2 <- sum(z^2)
  if (!is.finite(s2) || s2 <= 0) {
    return(indefinido("INDETERMINADO_DISPERSAO_ZERO"))
  }

  # Formula e1071 type = 2 utilizada pelo COINr (skew/kurt).
  assimetria <- sqrt(n) * sum(z^3) / (s2^(3/2))
  assimetria <- assimetria * sqrt(n * (n - 1)) / (n - 2)
  r <- n * sum(z^4) / (s2^2)
  curtose <- ((n + 1) * (r - 3) + 6) * (n - 1) / ((n - 2) * (n - 3))
  if (!is.finite(assimetria) || !is.finite(curtose)) {
    return(indefinido("INDETERMINADO_MOMENTOS_NAO_FINITOS"))
  }

  passa <- abs(assimetria) < limite_assimetria ||
           curtose < limite_curtose
  list(
    assimetria = as.numeric(assimetria),
    curtose_excesso = as.numeric(curtose),
    status = if (passa) "PASSA" else "INVESTIGAR",
    investigar = !passa,
    cauda_assimetria = if (assimetria > 0) "superior" else
      if (assimetria < 0) "inferior" else "sem_predominio"
  )
}

# Tetos de POSSIVEIS intervencoes sobre observacoes validas, NAO
# limites percentilicos, parametros estimados ou tratamento.
# Empates podem demandar regras adicionais para nao exceder o teto.
estat_so33_orcamentos_winsor <- function(n_validos, proporcao_max = 0.05) {
  estat_so33_exigir(
    is.numeric(n_validos) && length(n_validos) == 1L &&
      is.finite(n_validos) && n_validos >= 0 &&
      n_validos == floor(n_validos),
    "Numero de observacoes validas invalido."
  )
  estat_so33_exigir(
    is.numeric(proporcao_max) && length(proporcao_max) == 1L &&
      is.finite(proporcao_max) &&
      proporcao_max >= 0 && proporcao_max <= 0.05,
    "O teto por serie nao pode superar 5%."
  )
  n_max <- as.integer(floor(n_validos * proporcao_max))
  n_metade <- as.integer(floor(n_validos * proporcao_max / 2))
  data.frame(
    regime = c("sem_winsorizacao", "bilateral_2p5_2p5",
               "unilateral_inferior_5", "unilateral_superior_5"),
    limite_percentual_total = rep(100 * proporcao_max, 4L),
    max_modificacoes_inferior = c(0L, n_metade, n_max, 0L),
    max_modificacoes_superior = c(0L, n_metade, 0L, n_max),
    max_modificacoes_total = c(0L, 2L * n_metade, n_max, n_max),
    stringsAsFactors = FALSE
  )
}

estat_so33_resumir <- function(
    base, dimensao, indicador, grupo_referencia,
    escopo = "conjunto_2000_2010_2022", ano_descritivo = NA_integer_) {

  estat_so33_exigir("valor" %in% names(base), "Coluna valor ausente.")
  observado <- base$valor
  x <- observado[!is.na(observado)]
  estat_so33_exigir(all(is.finite(x)), "Serie contem valores infinitos.")
  n <- length(x)
  media <- if (n) mean(x) else NA_real_
  desvio <- if (n > 1L) stats::sd(x) else NA_real_
  momentos_coinr <- estat_so33_momentos_coinr(observado)
  conjunto_tres_anos <- identical(escopo, "conjunto_2000_2010_2022")
  teto_conjunto <- if (conjunto_tres_anos) {
    estat_so33_orcamentos_winsor(n)
  } else NULL
  assimetria <- if (n > 2L && is.finite(desvio) && desvio > 0) {
    mean(((x - media) / desvio)^3)
  } else {
    NA_real_
  }
  q <- vapply(c(0, .01, .025, .05, .25, .5, .75,
                .95, .975, .99, 1), function(p) estat_so33_quantil(x, p),
              numeric(1))
  names(q) <- c("min", "p01", "p025", "p05", "p25", "p50",
                "p75", "p95", "p975", "p99", "max")
  iqr <- if (n) q[["p75"]] - q[["p25"]] else NA_real_
  cerca_inf <- if (n) q[["p25"]] - 1.5 * iqr else NA_real_
  cerca_sup <- if (n) q[["p75"]] + 1.5 * iqr else NA_real_

  data.frame(
    dimensao = dimensao, indicador = indicador,
    grupo_referencia = grupo_referencia,
    escopo = escopo, ano_descritivo = ano_descritivo,
    n_observacoes = length(observado), n_validos = n,
    n_ausentes = sum(is.na(observado)), n_zeros = sum(x == 0),
    n_negativos = sum(x < 0), n_iguais_100 = sum(x == 100),
    n_acima_100 = sum(x > 100),
    boxcox_sem_deslocamento_admissivel = n > 0L && all(x > 0),
    media = media, desvio_padrao = desvio,
    coeficiente_variacao = if (n > 1L && media != 0) {
      desvio / abs(media)
    } else NA_real_,
    assimetria_momento = assimetria,
    assimetria_coinr_type2 = momentos_coinr$assimetria,
    curtose_excesso_coinr_type2 = momentos_coinr$curtose_excesso,
    triagem_coinr = if (conjunto_tres_anos) momentos_coinr$status
                   else "APENAS_DESCRITIVO_ANUAL",
    investigar_winsorizacao = if (conjunto_tres_anos) {
      momentos_coinr$investigar
    } else NA,
    cauda_por_assimetria_apenas_diagnostico = if (conjunto_tres_anos) {
      momentos_coinr$cauda_assimetria
    } else NA_character_,
    teto_modificacoes_5pct = if (conjunto_tres_anos) {
      teto_conjunto$max_modificacoes_total[[3L]]
    } else NA_integer_,
    teto_por_cauda_bilateral_2p5pct = if (conjunto_tres_anos) {
      teto_conjunto$max_modificacoes_superior[[2L]]
    } else NA_integer_,
    iqr = iqr,
    min = q[["min"]], p01 = q[["p01"]], p025 = q[["p025"]],
    p05 = q[["p05"]], p25 = q[["p25"]], mediana = q[["p50"]],
    p75 = q[["p75"]], p95 = q[["p95"]], p975 = q[["p975"]],
    p99 = q[["p99"]], max = q[["max"]],
    cerca_inferior_tukey_apenas_diagnostico = cerca_inf,
    cerca_superior_tukey_apenas_diagnostico = cerca_sup,
    n_abaixo_cerca_tukey = if (n) sum(x < cerca_inf) else 0L,
    n_acima_cerca_tukey = if (n) sum(x > cerca_sup) else 0L,
    stringsAsFactors = FALSE
  )
}

estat_so33_extremos <- function(base, indicador, grupo, n = 10L) {
  x <- base[!is.na(base$valor),
            c("ano", "uf", "cod_mun", "nm_mun", "valor"), drop = FALSE]
  if (!nrow(x)) return(NULL)
  inferiores <- x[order(x$valor, x$ano, x$cod_mun), , drop = FALSE]
  superiores <- x[order(-x$valor, x$ano, x$cod_mun), , drop = FALSE]
  inferiores <- utils::head(inferiores, n)
  superiores <- utils::head(superiores, n)
  out <- rbind(transform(inferiores, cauda = "inferior"),
               transform(superiores, cauda = "superior"))
  out$indicador <- indicador
  out$grupo_referencia <- grupo
  out[c("indicador", "grupo_referencia", "cauda", "ano", "uf",
        "cod_mun", "nm_mun", "valor")]
}

estat_so33_gravar_csv <- function(x, destino) {
  utils::write.table(x, file = destino, sep = ";", dec = ".",
                     row.names = FALSE, col.names = TRUE,
                     quote = TRUE, na = "", fileEncoding = "UTF-8")
}

estat_so33_diagnosticar <- function(
    indicador,
    dir_bruto = file.path("so3.3", "outputs", "bruto"),
    dir_saida = NULL) {

  meta <- estat_so33_catalogo()
  meta <- meta[meta$indicador == indicador, , drop = FALSE]
  estat_so33_exigir(nrow(meta) == 1L,
                    paste("Indicador nao cadastrado:", indicador))
  anos <- estat_so33_anos()

  insumos <- lapply(anos, function(ano) {
    estat_so33_ler_bruto(indicador, ano, dir_bruto = dir_bruto)
  })
  base <- do.call(rbind, lapply(insumos, function(x) x$dados))
  inventario <- do.call(rbind, lapply(insumos, function(x) x$inventario))
  series <- estat_so33_series(base, meta$natureza)
  conjuntas <- list()
  anuais <- list()
  extremos <- list()

  for (grupo in names(series)) {
    x <- series[[grupo]]
    conjuntas[[grupo]] <- estat_so33_resumir(
      x, meta$dimensao, indicador, grupo)
    extremos[[grupo]] <- estat_so33_extremos(x, indicador, grupo)
    for (ano in anos) {
      chave <- paste(grupo, ano, sep = "_")
      anuais[[chave]] <- estat_so33_resumir(
        x[x$ano == ano, , drop = FALSE],
        meta$dimensao, indicador, grupo,
        escopo = "descritivo_anual_sem_limiares",
        ano_descritivo = ano
      )
    }
  }

  conjunto <- do.call(rbind, conjuntas)
  descricao_anual <- do.call(rbind, anuais)
  registros_extremos <- do.call(rbind, extremos)
  rownames(conjunto) <- NULL
  rownames(descricao_anual) <- NULL
  rownames(registros_extremos) <- NULL

  orcamentos <- do.call(rbind, lapply(seq_len(nrow(conjunto)), function(i) {
    x <- conjunto[i, , drop = FALSE]
    tabela <- estat_so33_orcamentos_winsor(x$n_validos)
    cbind(
      data.frame(
        dimensao = x$dimensao, indicador = x$indicador,
        grupo_referencia = x$grupo_referencia,
        n_validos = x$n_validos,
        triagem_coinr = x$triagem_coinr,
        assimetria_coinr_type2 = x$assimetria_coinr_type2,
        curtose_excesso_coinr_type2 = x$curtose_excesso_coinr_type2,
        cauda_por_assimetria_apenas_diagnostico =
          x$cauda_por_assimetria_apenas_diagnostico,
        stringsAsFactors = FALSE
      ),
      tabela
    )
  }))
  rownames(orcamentos) <- NULL

  n_series <- if (meta$natureza == "populacional") 3L else 1L
  estat_so33_exigir(nrow(conjunto) == n_series &&
                      nrow(descricao_anual) == n_series * length(anos),
                    "Quantidade de series estatisticas inconsistente.")

  status <- NULL
  if (indicador == "INF02_RECURSOS_HIDRICOS_PC") {
    total <- base[base$grupo == "Total", , drop = FALSE]
    partes <- list()
    i <- 0L
    for (ano in anos) {
      d <- total[total$ano == ano, , drop = FALSE]
      for (campo in c("status_calculo", "situacao_qualidade",
                      "compatibilidade_territorial")) {
        i <- i + 1L
        tab <- table(d[[campo]], useNA = "ifany")
        partes[[i]] <- data.frame(
          ano = ano, indicador = indicador, campo = campo,
          categoria = names(tab), frequencia = as.integer(tab),
          stringsAsFactors = FALSE
        )
      }
    }
    status <- do.call(rbind, partes)
  }

  resultado <- list(
    inventario = inventario,
    estatisticas_conjuntas = conjunto,
    estatisticas_anuais_descritivas = descricao_anual,
    extremos_para_inspecao = registros_extremos,
    status_inf02 = status,
    orcamentos_winsorizacao = orcamentos
  )

  if (!is.null(dir_saida)) {
    estat_so33_exigir(is.character(dir_saida) && length(dir_saida) == 1L &&
                        nzchar(dir_saida) && !dir.exists(dir_saida),
                      "Diretorio de saida ja existe ou e invalido; nao sobrescrever.")
    estat_so33_exigir(dir.create(dir_saida, recursive = TRUE, showWarnings = FALSE),
                      paste("Nao foi possivel criar saida:", dir_saida))
    estat_so33_gravar_csv(inventario, file.path(dir_saida, "01_inventario.csv"))
    estat_so33_gravar_csv(conjunto,
                         file.path(dir_saida, "02_estatisticas_conjuntas.csv"))
    estat_so33_gravar_csv(descricao_anual,
                         file.path(dir_saida, "03_descritivas_anuais.csv"))
    estat_so33_gravar_csv(registros_extremos,
                         file.path(dir_saida, "04_extremos_inspecao.csv"))
    if (!is.null(status)) {
      estat_so33_gravar_csv(status,
                           file.path(dir_saida, "05_status_INF02.csv"))
    }
    estat_so33_gravar_csv(orcamentos,
                         file.path(dir_saida, "06_orcamentos_winsorizacao.csv"))
    manifest <- c(
      "PRAIS4/SO3.3 - Diagnostico estatistico; SEM tratamento.",
      paste("Indicador:", indicador),
      paste("Dimensao:", meta$dimensao),
      paste("Natureza:", meta$natureza),
      paste("Anos reunidos:", paste(anos, collapse = ", ")),
      paste("Series:", paste(names(series), collapse = ", ")),
      "Parametros determinados por indicador/grupo; este diagnostico nao define nenhum.",
      "Estatisticas anuais sao descritivas e nao fornecem limiares anuais.",
      "Cercas de Tukey nao sao limites aprovados para winsorizacao.",
      "COINr: assimetria e curtose excedente e1071 type=2; triagem: |skew|>=2 E kurt>=3.5.",
      "Sinal COINr de investigacao NAO e autorizacao de tratamento.",
      "Orcamento por serie conjunta: ate 5% de registros validos; 2.5% por cauda ou 5% unilateral.",
      "Regimes sao apenas tetos; nenhuma observacao foi modificada.",
      "Empates e revisao das observacoes deverao ser contemplados na futura implementacao.",
      "NA nao foi imputado; nenhum CSV bruto foi alterado.",
      paste("R:", R.version.string),
      paste("Data UTC:", format(Sys.time(), tz = "UTC", usetz = TRUE))
    )
    writeLines(manifest, file.path(dir_saida, "LEIA_ME.txt"),
               useBytes = TRUE)
    writeLines(capture.output(utils::sessionInfo()),
               file.path(dir_saida, "sessao_R.txt"), useBytes = TRUE)
  }

  resultado
}
