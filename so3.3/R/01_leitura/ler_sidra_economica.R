# ============================================================
# PRAIS4 / SO3.3 - LEITURA DOS INSUMOS ECONOMICOS DO SIDRA
# Tabelas 5938 (PIB e VAB agropecuario) e 6784 (deflator).
# Apenas leitura e padronizacao: nao calcula ECO02/ECO03,
# nao grava produtos e nao altera os arquivos originais.
# Executar a partir da raiz do repositorio.
# ============================================================

if (!requireNamespace("data.table", quietly = TRUE)) {
  stop("SIDRA economica: instale o pacote data.table.")
}

.sidra_econ_linhas <- function(arquivo) {
  if (!file.exists(arquivo)) {
    stop("SIDRA economica: arquivo nao encontrado: ", arquivo)
  }
  linhas <- readLines(arquivo, warn = FALSE, encoding = "UTF-8")
  if (!length(linhas)) stop("SIDRA economica: arquivo vazio: ", arquivo)
  linhas[1L] <- sub("^\ufeff", "", linhas[1L])
  linhas
}

.sidra_econ_registros <- function(linhas) {
  if (!length(linhas)) stop("SIDRA economica: bloco sem dados.")
  dados <- utils::read.table(
    text = paste(linhas, collapse = "\n"),
    sep = ";", quote = "\"", header = FALSE,
    colClasses = "character", na.strings = character(0),
    stringsAsFactors = FALSE, check.names = FALSE,
    comment.char = "", fill = FALSE
  )
  data.table::as.data.table(dados)
}

.sidra_econ_valores <- function(x, campo) {
  x <- trimws(as.character(x))
  eh_numero <- grepl("^[+-]?[0-9]+([.,][0-9]+)?$", x)
  zero_absoluto <- x == "-"
  simbolos <- c("...", "..", "X")
  inesperado <- !eh_numero & !zero_absoluto & !x %in% simbolos
  if (any(inesperado)) {
    stop("SIDRA economica: valores inesperados em ", campo, ": ",
         paste(head(unique(x[inesperado]), 8L), collapse = ", "))
  }
  numero <- suppressWarnings(as.numeric(
    gsub(",", ".", ifelse(zero_absoluto, "0", x), fixed = TRUE)
  ))
  numero[!eh_numero & !zero_absoluto] <- NA_real_
  if (any(!is.na(numero) & !is.finite(numero))) {
    stop("SIDRA economica: numeros nao finitos em ", campo)
  }
  status <- rep("disponivel", length(x))
  status[zero_absoluto] <- "zero_absoluto"
  status[x == "..."] <- "nao_disponivel"
  status[x == ".."] <- "nao_se_aplica"
  status[x == "X"] <- "sigilo"
  list(valor = numero, status = status)
}

.sidra_econ_cabecalho_anos <- function(linha, tabela) {
  campos <- strsplit(gsub('"', '', linha, fixed = TRUE), ";",
                      fixed = TRUE)[[1L]]
  pos <- seq.int(3L, length(campos), by = 2L)
  anos <- suppressWarnings(as.integer(campos[pos]))
  if (length(anos) == 0L || anyNA(anos) ||
      anyDuplicated(anos) || any(diff(anos) < 0L) ||
      length(campos) != 2L * length(anos) + 1L) {
    stop("SIDRA economica: cabecalho de anos invalido na ", tabela)
  }
  anos
}

.ler_sidra_5938_blocos <- function(arquivo, tipos_esperados) {
  linhas <- .sidra_econ_linhas(arquivo)
  if (!grepl("Tabela 5938", linhas[1L], fixed = TRUE)) {
    stop("SIDRA economica: arquivo nao corresponde a Tabela 5938: ", arquivo)
  }
  marcadores <- grep('^"Variável - ', linhas)
  nomes <- sub('"$', '', sub('^"Variável - ', '', linhas[marcadores]))
  rotulos <- c(
    pib = "Produto Interno Bruto a preços correntes",
    vab_agro = "Valor adicionado bruto a preços correntes da agropecuária"
  )
  if (length(marcadores) != length(tipos_esperados) ||
      !setequal(nomes, unname(rotulos[tipos_esperados]))) {
    stop("SIDRA economica: variaveis inesperadas na Tabela 5938: ", arquivo)
  }

  blocos <- lapply(seq_along(marcadores), function(i) {
    inicio <- marcadores[[i]]
    fim <- if (i < length(marcadores)) {
      marcadores[[i + 1L]] - 1L
    } else {
      length(linhas)
    }
    tipo <- names(rotulos)[match(nomes[[i]], unname(rotulos))]
    anos <- .sidra_econ_cabecalho_anos(linhas[inicio + 2L], "5938")
    if (!identical(anos, c(2002L, 2010L, 2021L, 2022L))) {
      stop("SIDRA economica: anos inesperados na Tabela 5938.")
    }
    fragmento <- linhas[seq.int(inicio + 3L, fim)]
    registros <- fragmento[grepl('^"[0-9]{7}";', fragmento)]
    d <- .sidra_econ_registros(registros)
    if (nrow(d) != 5570L || ncol(d) != 2L + 2L * length(anos)) {
      stop("SIDRA economica: cobertura ou layout inesperado de ", tipo)
    }
    codigos <- trimws(d[[1L]])
    nomes_mun <- trimws(d[[2L]])
    if (anyNA(codigos) || any(!grepl("^[0-9]{7}$", codigos)) ||
        anyDuplicated(codigos) || anyNA(nomes_mun) ||
        any(!nzchar(nomes_mun))) {
      stop("SIDRA economica: codigos ou nomes municipais invalidos.")
    }
    data.table::rbindlist(lapply(seq_along(anos), function(j) {
      coluna_valor <- 2L * j + 1L
      valores <- .sidra_econ_valores(d[[coluna_valor]],
                                    paste(tipo, anos[[j]]))
      unidade <- trimws(d[[coluna_valor + 1L]])
      disponivel <- !is.na(valores$valor)
      if (
        any(disponivel & unidade != "Mil Reais") ||
        any(!disponivel & !unidade %in% c("", "Mil Reais"))
      ) {
        stop(
          "SIDRA economica: unidade monetaria inesperada em ",
          tipo, "/", anos[[j]]
        )
      }
      data.table::data.table(
        cod_mun = codigos,
        uf = substr(codigos, 1L, 2L),
        nome_mun_sidra = nomes_mun,
        ano_fonte = anos[[j]],
        tipo = tipo,
        valor_mil_reais = valores$valor,
        status_sidra = valores$status
      )
    }), use.names = TRUE)
  })
  saida <- data.table::rbindlist(blocos, use.names = TRUE)
  if (anyDuplicated(saida, by = c("cod_mun", "ano_fonte", "tipo"))) {
    stop("SIDRA economica: municipio/ano/variavel repetido.")
  }
  data.table::setorder(saida, ano_fonte, cod_mun, tipo)
  saida[]
}

ler_tabela5938_economica <- function(arquivo = file.path(
  "so3.3", "inputs", "referencias", "sidra", "tabela5938.csv"
)) {
  .ler_sidra_5938_blocos(arquivo, c("pib", "vab_agro"))
}

ler_tabela6784_deflator <- function(arquivo = file.path(
  "so3.3", "inputs", "referencias", "sidra", "tabela6784.csv"
)) {
  linhas <- .sidra_econ_linhas(arquivo)
  if (!grepl("Tabela 6784", linhas[[1L]], fixed = TRUE) ||
      !any(grepl("Variável - PIB - deflator - variação anual",
                 linhas, fixed = TRUE))) {
    stop("SIDRA economica: variavel do deflator inesperada.")
  }
  cab <- grep('^"Cód[.]";"";"[0-9]{4}";', linhas)
  brasil <- grep('^"1";"Brasil";', linhas)
  if (length(cab) != 1L || length(brasil) != 1L) {
    stop("SIDRA economica: cabecalho ou linha Brasil ausente na 6784.")
  }
  anos <- .sidra_econ_cabecalho_anos(linhas[cab], "6784")
  d <- .sidra_econ_registros(linhas[brasil])
  if (nrow(d) != 1L || ncol(d) != 2L + 2L * length(anos) ||
      d[[1L]][[1L]] != "1" || d[[2L]][[1L]] != "Brasil") {
    stop("SIDRA economica: linha Brasil inconsistente na 6784.")
  }
  valores <- vapply(seq_along(anos), function(j) {
    pos <- 2L * j + 1L
    if (d[[pos + 1L]][[1L]] != "%") {
      stop("SIDRA economica: unidade do deflator diferente de %.")
    }
    convertido <- .sidra_econ_valores(d[[pos]], paste("deflator", anos[[j]]))
    if (!identical(convertido$status, "disponivel")) {
      stop("SIDRA economica: deflator ausente ou censurado em ", anos[[j]])
    }
    convertido$valor[[1L]]
  }, numeric(1L))
  if (!all(2002:2022 %in% anos) ||
      any(!is.finite(valores)) || any(valores <= -100)) {
    stop("SIDRA economica: serie 2002-2022 do deflator incompleta.")
  }
  data.table::data.table(
    ano_fonte = as.integer(anos), variacao_deflator_pct = valores
  )[]
}

ler_sidra_economica <- function(
  arquivo_5938 = file.path(
    "so3.3", "inputs", "referencias", "sidra", "tabela5938.csv"
  ),
  arquivo_5938_vab = file.path(
    "so3.3", "inputs", "referencias", "sidra", "tabela5938_vab.csv"
  ),
  arquivo_6784 = file.path(
    "so3.3", "inputs", "referencias", "sidra", "tabela6784.csv"
  )
) {
  bruto <- ler_tabela5938_economica(arquivo_5938)
  separado <- .ler_sidra_5938_blocos(arquivo_5938_vab, "vab_agro")
  original <- data.table::copy(bruto[tipo == "vab_agro", .(
    cod_mun, ano_fonte, nome_mun_sidra, valor_mil_reais, status_sidra
  )])
  separado <- separado[, .(
    cod_mun, ano_fonte, nome_mun_sidra, valor_mil_reais, status_sidra
  )]
  data.table::setorder(original, cod_mun, ano_fonte)
  data.table::setorder(separado, cod_mun, ano_fonte)
  for (campo in names(original)) {
    if (!identical(original[[campo]], separado[[campo]])) {
      stop("SIDRA economica: tabela5938_vab diverge da 5938 em ", campo)
    }
  }

  pib <- bruto[tipo == "pib", .(
    cod_mun, uf, ano_fonte, nome_mun_sidra,
    pib_mil_reais = valor_mil_reais,
    status_pib = status_sidra
  )]
  vab <- bruto[tipo == "vab_agro", .(
    cod_mun, ano_fonte, nome_mun_vab = nome_mun_sidra,
    vab_agro_mil_reais = valor_mil_reais,
    status_vab_agro = status_sidra
  )]
  municipais <- merge(pib, vab, by = c("cod_mun", "ano_fonte"),
                      all = TRUE, sort = FALSE)
  if (nrow(municipais) != 4L * 5570L ||
      anyNA(municipais[, .(cod_mun, ano_fonte, nome_mun_sidra, nome_mun_vab)]) ||
      any(municipais$nome_mun_sidra != municipais$nome_mun_vab)) {
    stop("SIDRA economica: PIB/VAB possuem municipios divergentes.")
  }
  municipais[, nome_mun_vab := NULL]
  data.table::setcolorder(municipais, c(
    "ano_fonte", "uf", "cod_mun", "nome_mun_sidra",
    "pib_mil_reais", "status_pib",
    "vab_agro_mil_reais", "status_vab_agro"
  ))
  data.table::setorder(municipais, ano_fonte, cod_mun)
  deflator <- ler_tabela6784_deflator(arquivo_6784)
  fontes <- data.table::data.table(
    tabela = c("5938", "5938_VAB", "6784"),
    arquivo = c(arquivo_5938, arquivo_5938_vab, arquivo_6784),
    md5 = unname(as.character(tools::md5sum(c(
      arquivo_5938, arquivo_5938_vab, arquivo_6784
    ))))
  )
  list(dados_municipais = municipais[], deflator_anual = deflator[],
       fontes = fontes[])
}

# O ano da fonte e dependente do indicador: 2021 para ECO03
# associado ao PRAIS 2022; 2022 para ECO02. Nao misturar PIB
# de 2022 com VAB agropecuario de 2021.
selecionar_recortes_sidra_economica <- function(
  dados_municipais, indicador = c("ECO02", "ECO03")
) {
  indicador <- match.arg(indicador)
  referencia <- data.table::data.table(
    ano_prais = c(2000L, 2010L, 2022L),
    ano_fonte = if (indicador == "ECO02") {
      c(2002L, 2010L, 2022L)
    } else {
      c(2002L, 2010L, 2021L)
    }
  )
  d <- data.table::as.data.table(dados_municipais)
  colunas <- c("ano_fonte", "cod_mun", "uf", "nome_mun_sidra",
               "pib_mil_reais", "status_pib",
               "vab_agro_mil_reais", "status_vab_agro")
  if (length(setdiff(colunas, names(d)))) {
    stop("SIDRA economica: estrutura municipal incompleta.")
  }
  saida <- merge(d, referencia, by = "ano_fonte", all = FALSE)
  if (nrow(saida) != 3L * 5570L ||
      anyDuplicated(saida, by = c("ano_prais", "cod_mun"))) {
    stop("SIDRA economica: recortes municipais incompletos.")
  }
  saida[, indicador := indicador]
  data.table::setcolorder(saida, c(
    "indicador", "ano_prais", "ano_fonte", "uf", "cod_mun",
    "nome_mun_sidra", "pib_mil_reais", "status_pib",
    "vab_agro_mil_reais", "status_vab_agro"
  ))
  data.table::setorder(saida, ano_prais, cod_mun)
  saida[]
}
