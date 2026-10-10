# ============================================================
# PRAIS4 - SO3.3
# LEITURA DAS TABUAS DE MORTALIDADE - IBGE
# PROJECOES DA POPULACAO, REVISAO 2024
# ============================================================


ler_tabuas_mortalidade_ibge <- function(
  arquivo = ARQ_TABUAS_MORTALIDADE_IBGE,
  anos = ANOS_DVI
) {

  # ----------------------------------------------------------
  # 1. Validacoes iniciais
  # ----------------------------------------------------------

  if (!file.exists(arquivo)) {

    stop(
      "Arquivo das tabuas de mortalidade do IBGE nao encontrado: ",
      arquivo
    )
  }


  if (!requireNamespace("readxl", quietly = TRUE)) {

    stop(
      "O pacote 'readxl' e necessario para ler ",
      "as tabuas de mortalidade do IBGE."
    )
  }


  # ----------------------------------------------------------
  # 2. Leitura da planilha original
  #
  # Estrutura do arquivo:
  #
  # linhas 1-5: cabecalho institucional
  # linha 6: nomes das variaveis
  # linha 7+: dados
  # ----------------------------------------------------------

  dados <- readxl::read_excel(
    path = arquivo,
    sheet = "5) TÁBUAS DE MORTALIDADE",
    skip = 5,
    col_types = c(
      "numeric",   # IDADE
      "text",      # INTERVALO DE IDADE
      "text",      # SEXO
      "numeric",   # ANO
      "numeric",   # COD.
      "text",      # SIGLA
      "text",      # LOCAL
      rep("numeric", 9L)
    )
  )


  # ----------------------------------------------------------
  # 3. Confere a estrutura da fonte
  # ----------------------------------------------------------

  nomes_esperados <- c(
    "IDADE",
    "INTERVALO DE IDADE",
    "SEXO",
    "ANO",
    "CÓD.",
    "SIGLA",
    "LOCAL",
    "nMx",
    "nAx",
    "nqx",
    "lx",
    "ndx",
    "nLx",
    "Sx",
    "Tx",
    "ex"
  )


  if (!identical(names(dados), nomes_esperados)) {

    stop(
      "A estrutura da planilha de mortalidade do IBGE ",
      "difere da estrutura esperada."
    )
  }


  # ----------------------------------------------------------
  # 4. Padronizacao
  # ----------------------------------------------------------

  dados <- data.table::as.data.table(dados)


  data.table::setnames(
    dados,
    old = nomes_esperados,
    new = c(
      "idade",
      "intervalo_idade",
      "sexo_ibge",
      "ano",
      "codigo_local",
      "sigla",
      "local",
      "nMx",
      "nAx",
      "nqx",
      "lx",
      "ndx",
      "nLx",
      "Sx",
      "Tx",
      "ex"
    )
  )


  dados[
    ,
    `:=`(
      idade = as.integer(idade),
      ano = as.integer(ano),
      codigo_local = as.integer(codigo_local)
    )
  ]


  # ----------------------------------------------------------
  # 5. Unidades da Federacao
  #
  # Codigo 0 = Brasil
  # Codigos 1-5 = Grandes Regioes
  # Demais codigos abaixo = 27 UFs
  # ----------------------------------------------------------

  codigos_uf <- c(
    11L, 12L, 13L, 14L, 15L, 16L, 17L,
    21L, 22L, 23L, 24L, 25L, 26L, 27L, 28L, 29L,
    31L, 32L, 33L, 35L,
    41L, 42L, 43L,
    50L, 51L, 52L, 53L
  )


  dados <- dados[
    ano %in% anos &
      codigo_local %in% codigos_uf
  ]


  # ----------------------------------------------------------
  # 6. Harmonizacao com os grupos do DVI
  # ----------------------------------------------------------

  dados[
    ,
    grupo := data.table::fcase(
      sexo_ibge == "Ambos",    "Total",
      sexo_ibge == "Homens",   "Masculino",
      sexo_ibge == "Mulheres", "Feminino",
      default = NA_character_
    )
  ]


  if (anyNA(dados$grupo)) {

    stop(
      "Foi encontrado sexo nao reconhecido ",
      "nas tabuas de mortalidade do IBGE."
    )
  }


  # ----------------------------------------------------------
  # 7. QA estrutural
  #
  # Esperado:
  #
  # 27 UFs
  # x 3 anos do DVI
  # x 3 grupos
  # x 20 linhas etarias
  #
  # = 4.860 registros
  # ----------------------------------------------------------

  n_esperado <-
    27L *
    length(anos) *
    3L *
    20L


  if (nrow(dados) != n_esperado) {

    stop(
      "Numero inesperado de registros nas tabuas IBGE. ",
      "Esperado: ",
      n_esperado,
      "; encontrado: ",
      nrow(dados),
      "."
    )
  }


  # ----------------------------------------------------------
  # 8. QA - duplicidades
  # ----------------------------------------------------------

  duplicidades <- dados[
    ,
    .N,
    by = .(
      ano,
      codigo_local,
      grupo,
      idade
    )
  ][
    N != 1L
  ]


  if (nrow(duplicidades) > 0L) {

    stop(
      "Foram encontradas duplicidades nas tabuas ",
      "de mortalidade do IBGE."
    )
  }


  # ----------------------------------------------------------
  # 9. QA - 20 idades por tábua
  # ----------------------------------------------------------

  estrutura_idade <- dados[
    ,
    .(
      n_idades = data.table::uniqueN(idade)
    ),
    by = .(
      ano,
      codigo_local,
      grupo
    )
  ]


  if (any(estrutura_idade$n_idades != 20L)) {

    stop(
      "Alguma tábua IBGE nao possui as 20 linhas ",
      "etarias esperadas."
    )
  }


  # ----------------------------------------------------------
  # 10. QA - probabilidades e sobreviventes
  # ----------------------------------------------------------

  if (
    any(
      dados$nqx < 0 |
        dados$nqx > 1,
      na.rm = TRUE
    )
  ) {

    stop(
      "Existem valores de nqx fora do intervalo [0,1]."
    )
  }


  if (
    any(
      dados$lx < 0,
      na.rm = TRUE
    )
  ) {

    stop(
      "Existem valores negativos de lx."
    )
  }


  # ----------------------------------------------------------
  # 11. Ordenacao canonica
  # ----------------------------------------------------------

  data.table::setorder(
    dados,
    ano,
    codigo_local,
    grupo,
    idade
  )


  data.table::setcolorder(
    dados,
    c(
      "ano",
      "codigo_local",
      "sigla",
      "local",
      "grupo",
      "sexo_ibge",
      "idade",
      "intervalo_idade",
      "nMx",
      "nAx",
      "nqx",
      "lx",
      "ndx",
      "nLx",
      "Sx",
      "Tx",
      "ex"
    )
  )


  dados[]
}
