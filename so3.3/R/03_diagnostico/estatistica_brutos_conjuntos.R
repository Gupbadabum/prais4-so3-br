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
    assimetria_momento = assimetria, iqr = iqr,
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
    status_inf02 = status
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
