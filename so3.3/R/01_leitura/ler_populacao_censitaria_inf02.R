# PRAIS4 / SO3.3 / INF02 / E02
# Leitura do TOTAL da populacao residente: IBGE, universo censitario.
# Fonte original: API SIDRA; cada JSON e preservado sem sobrescrita.
# Nao utiliza estimativas anuais nem microdados amostrais.

.inf02_e02_exigir <- function(ok, texto) {
  if (length(ok) != 1L || !isTRUE(ok)) {
    stop("INF02/E02: ", texto, call. = FALSE)
  }
}

.inf02_e02_fontes <- function(ano) {
  switch(as.character(ano),
    "2000" = list(tabela = 202L, esperado = 5507L,
      url = "https://apisidra.ibge.gov.br/values/t/202/n6/all/v/93/p/2000/c1/0/c2/0"),
    "2010" = list(tabela = 202L, esperado = 5565L,
      url = "https://apisidra.ibge.gov.br/values/t/202/n6/all/v/93/p/2010/c1/0/c2/0"),
    "2022" = list(tabela = 4709L, esperado = 5570L,
      url = "https://apisidra.ibge.gov.br/values/t/4709/n6/all/v/93/p/2022"),
    stop("INF02/E02: recorte censitario desconhecido: ", ano))
}

.inf02_e02_coluna_sidra <- function(d, padrao, alternativa = NULL) {
  # A primeira linha da API SIDRA contem os nomes descritivos.
  colunas <- grep("^D[0-9]+C$", names(d), value = TRUE)
  rotulos <- as.character(unlist(d[1L, colunas, drop = FALSE], use.names = FALSE))
  rotulos <- iconv(rotulos, from = "", to = "ASCII//TRANSLIT")
  correspondem <- colunas[!is.na(rotulos) & grepl(padrao, rotulos, ignore.case = TRUE)]
  if (length(correspondem) == 1L) return(correspondem[[1L]])
  if (!is.null(alternativa) && alternativa %in% names(d)) return(alternativa)
  stop("INF02/E02: coluna SIDRA ambigua ou ausente: ", padrao)
}

.inf02_e02_ler_json <- function(arquivo, ano) {
  .inf02_e02_exigir(requireNamespace("jsonlite", quietly = TRUE),
                   "instale o pacote jsonlite")
  d <- tryCatch(jsonlite::fromJSON(arquivo, simplifyDataFrame = TRUE),
    error = function(e) stop("INF02/E02: JSON invalido: ", arquivo,
                             " | ", conditionMessage(e), call. = FALSE))
  .inf02_e02_exigir(is.data.frame(d) && nrow(d) > 2L && "V" %in% names(d),
                   paste0("resposta SIDRA inesperada em ", arquivo))
  # ============================================================
# Identificacao das dimensoes SIDRA
# ============================================================

# Municipio: manter identificacao ja validada
col_mun <- .inf02_e02_coluna_sidra(
  d,
  "municipio.*codigo",
  "D1C"
)

# Remover a primeira linha, que contem os rotulos
x <- d[-1L, , drop = FALSE]

# Identificar dimensoes da resposta SIDRA
colunas_dimensoes <- grep(
  "^D[0-9]+[CN]$",
  names(x),
  value = TRUE
)

# Localizar a coluna temporal pelos valores efetivos,
# independentemente do rotulo textual do cabecalho.

candidatas_ano <- colunas_dimensoes[
  vapply(
    colunas_dimensoes,
    function(coluna) {

      valores <- trimws(
        as.character(x[[coluna]])
      )

      length(valores) == nrow(x) &&
        !anyNA(valores) &&
        all(valores == as.character(ano))
    },
    logical(1)
  )
]

# Se o ano nao for encontrado, apresentar diagnostico
if (length(candidatas_ano) == 0L) {

  cabecalho <- unlist(
    d[1L, colunas_dimensoes, drop = FALSE],
    use.names = TRUE
  )

  stop(
    "INF02/E02: ano ",
    ano,
    " nao identificado nas dimensoes SIDRA.\n",
    "Cabecalho recebido:\n",
    paste(
      names(cabecalho),
      cabecalho,
      sep = " = ",
      collapse = "\n"
    ),
    call. = FALSE
  )
}

# Dar preferencia ao campo de codigo da dimensao
colunas_codigo <- grep(
  "C$",
  candidatas_ano,
  value = TRUE
)

if (length(colunas_codigo) > 0L) {
  candidatas_ano <- colunas_codigo
}

# Impedir selecao ambigua
.inf02_e02_exigir(
  length(candidatas_ano) == 1L,
  paste0(
    "identificacao temporal ambigua: ",
    paste(candidatas_ano, collapse = ", ")
  )
)

col_ano <- candidatas_ano[[1L]]

# Recuperar identificadores e periodo
cod <- as.character(x[[col_mun]])
periodo <- as.character(x[[col_ano]])

message(
  "INF02/E02 | Ano ",
  ano,
  " identificado na coluna ",
  col_ano,
  " | registros = ",
  nrow(x)
)

    # ==========================================================
  # 1. Recuperar os valores originais do SIDRA
  # ==========================================================

  valor_texto <- trimws(
    as.character(x$V)
  )

  ref <- .inf02_e02_fontes(ano)


  # ==========================================================
  # 2. Validar identificadores e periodo censitario
  # ==========================================================

  .inf02_e02_exigir(
    all(!is.na(cod) & grepl("^[0-9]{7}$", cod)) &&
      all(!is.na(periodo) & periodo == as.character(ano)) &&
      anyDuplicated(cod) == 0L,
    paste0(
      "identificadores municipais ou periodo invalidos em ",
      ano
    )
  )


  # ==========================================================
  # 3. Classificar valores numericos e ausencias
  # ==========================================================

  eh_numero <-
    !is.na(valor_texto) &
    grepl("^[0-9]+$", valor_texto)

  marcadores_ausencia <- c(
    "-",
    "..",
    "...",
    "X"
  )

  eh_ausencia <-
    !is.na(valor_texto) &
    valor_texto %in% marcadores_ausencia

  eh_invalido <- !(eh_numero | eh_ausencia)


  # Valores inesperados nao podem ser descartados.

  .inf02_e02_exigir(
    !any(eh_invalido),
    paste0(
      "valores SIDRA nao reconhecidos em ",
      ano,
      ": ",
      paste(
        utils::head(
          unique(valor_texto[eh_invalido]),
          10L
        ),
        collapse = ", "
      )
    )
  )


  # ==========================================================
  # 4. Diagnostico da resposta
  # ==========================================================

  n_origem <- length(valor_texto)
  n_validos <- sum(eh_numero)
  n_ausentes <- sum(eh_ausencia)

  message(
    "INF02/E02 | ",
    ano,
    " | registros SIDRA=",
    n_origem,
    " | numericos=",
    n_validos,
    " | sem informacao=",
    n_ausentes
  )

  if (n_ausentes > 0L) {

    message(
      "INF02/E02 | Marcadores encontrados: ",
      paste(
        capture.output(
          print(table(valor_texto[eh_ausencia]))
        ),
        collapse = " "
      )
    )
  }


  # ==========================================================
  # 5. Validacao especifica por recorte censitario
  # ==========================================================

  if (as.integer(ano) == 2000L) {

    # A consulta pode apresentar municipios sem dados
    # no recorte territorial do Censo 2000.
    #
    # Sao exigidos:
    #   5565 registros na resposta;
    #   5507 populacoes validas;
    #   58 registros sem informacao.

    .inf02_e02_exigir(
      n_origem == 5565L &&
        n_validos == 5507L &&
        n_ausentes == 58L,
      paste0(
        "estrutura inesperada para 2000. ",
        "Origem=", n_origem,
        "; validos=", n_validos,
        "; ausentes=", n_ausentes,
        ". Nenhum registro foi descartado."
      )
    )

  } else {

    # Para 2010 e 2022, nenhuma ausencia e aceita
    # nesta versao do leitor.

    .inf02_e02_exigir(
      n_origem == ref$esperado &&
        n_validos == ref$esperado &&
        n_ausentes == 0L,
      paste0(
        "estrutura inesperada para ",
        ano,
        ". Origem=", n_origem,
        "; validos=", n_validos,
        "; ausentes=", n_ausentes
      )
    )
  }


  # ==========================================================
  # 6. Converter exclusivamente as populacoes observadas
  # ==========================================================

  valor <- suppressWarnings(
    as.numeric(valor_texto[eh_numero])
  )

  .inf02_e02_exigir(
    all(is.finite(valor)) &&
      all(valor > 0) &&
      all(valor == floor(valor)),
    paste0(
      "populacoes invalidas no recorte ",
      ano
    )
  )


  # ==========================================================
  # 7. Construir a base censitaria valida
  # ==========================================================

  populacao <- data.table::data.table(
    ano = as.integer(ano),
    cod_mun = cod[eh_numero],
    populacao_total_censo = valor,
    tabela_sidra = as.integer(ref$tabela)
  )

  data.table::setorder(
    populacao,
    cod_mun
  )


  # ==========================================================
  # 8. Conferir quantidade de municipios
  # ==========================================================

  .inf02_e02_exigir(
    nrow(populacao) == ref$esperado &&
      anyDuplicated(populacao$cod_mun) == 0L,
    paste0(
      "esperados ",
      ref$esperado,
      " municipios validos em ",
      ano,
      "; encontrados ",
      nrow(populacao)
    )
  )


  # ==========================================================
  # 9. Conferencia nacional independente para 2000
  # ==========================================================

  total_brasil <- sum(
    populacao$populacao_total_censo
  )

  if (as.integer(ano) == 2000L) {

    total_ibge_2000 <- 169799170

    .inf02_e02_exigir(
      total_brasil == total_ibge_2000,
      paste0(
        "populacao nacional de 2000 divergente. ",
        "SIDRA=", total_brasil,
        "; IBGE=", total_ibge_2000
      )
    )
  }


  # ==========================================================
  # 10. Resultado validado
  # ==========================================================

  message(
    "INF02/E02 | ",
    ano,
    " | municipios validados=",
    nrow(populacao),
    " | populacao total=",
    format(
      total_brasil,
      big.mark = ".",
      scientific = FALSE,
      trim = TRUE
    )
  )

  populacao[]
}

ler_populacao_censitaria_inf02 <- function(ano, dir_fontes) {
  .inf02_e02_exigir(requireNamespace("data.table", quietly = TRUE),
                   "instale o pacote data.table")
  ref <- .inf02_e02_fontes(ano)
  dir.create(dir_fontes, recursive = TRUE, showWarnings = FALSE)
  destino <- file.path(dir_fontes, sprintf("SIDRA_t%d_pop_total_%d.json",
                                      ref$tabela, ano))
  if (!file.exists(destino)) {
    # So persistir o arquivo bruto apos validar integralmente a resposta.
    tmp <- tempfile(pattern = "sidra_", tmpdir = dir_fontes, fileext = ".json")
    on.exit(if (file.exists(tmp)) unlink(tmp), add = TRUE)
    message("INF02/E02 | Baixando SIDRA ", ref$tabela, " / ", ano, "...")
    ok <- tryCatch({
      utils::download.file(ref$url, destfile = tmp, method = "libcurl",
                           mode = "wb", quiet = TRUE)
      TRUE
    }, error = function(e) {
      stop("INF02/E02: download falhou para ", ano, ": ",
           conditionMessage(e), ". URL: ", ref$url, call. = FALSE)
    })
    .inf02_e02_exigir(isTRUE(ok) && file.exists(tmp) &&
                       file.info(tmp)$size > 100,
                     paste0("download vazio/incompleto para ", ano))
    verificado <- .inf02_e02_ler_json(tmp, ano)
    .inf02_e02_exigir(nrow(verificado) == ref$esperado,
                     "quantidade inesperada de municipios")
    .inf02_e02_exigir(file.rename(tmp, destino),
                     paste0("falha ao preservar fonte: ", destino))
  }
  dados <- .inf02_e02_ler_json(destino, ano)
  list(
    dados = dados,
    arquivo = normalizePath(destino, winslash = "/", mustWork = TRUE),
    md5 = unname(tools::md5sum(destino)),
    url = ref$url,
    tabela = ref$tabela,
    n_origem = nrow(dados),
    populacao_brasil = sum(dados$populacao_total_censo))
}
