# ============================================================
# PRAIS4 / SO3.3 / ECO02_PIBPC - BASES HISTORICAS IBGE
#
# Edicao PIB dos Municipios 2022-2023 (referencia SCN 2010).
# Arquivos XLSX originais: periodos 2002-2009 e 2010-2023.
# Apenas extrai os anos-fonte 2002, 2010 e 2022.
#
# Colunas originais: A ano; D UF; G codigo municipal; H nome;
#                   AM PIB corrente (R$ 1.000);
#                   AN PIB per capita corrente (R$/habitante).
# NOTA: a base 2010-2023 contem 43 colunas, mas os seis
# campos selecionados permanecem nas mesmas posicoes.
#
# O PIB per capita e lido diretamente da fonte IBGE:
# nao e recalculado nem deflacionado aqui.
# Leitura apenas: nenhum arquivo e criado ou modificado.
# ============================================================

if (!requireNamespace("data.table", quietly = TRUE)) {
  stop("ECO02 leitura: pacote data.table necessario.")
}
if (!requireNamespace("readxl", quietly = TRUE)) {
  stop("ECO02 leitura: pacote readxl necessario.")
}

ECO02_ANOS_FONTE <- c(2002L, 2010L, 2022L)
ECO02_ANOS_PRAIS <- c(2000L, 2010L, 2022L)
ECO02_QTD_FONTE <- c("2002" = 5560L, "2010" = 5565L, "2022" = 5570L)
ECO02_MD5_ORIGINAIS <- c(
  "2002_2009" = "d2722b114a283044f5818dba75f82349",
  "2010_2023" = "d0866ad94099e5f50b2fe478c73bf908"
)

.ler_planilha_ibge_eco02 <- function(
  arquivo, periodo, aba, anos_base, anos_uso,
  linhas_esperadas, verificar_md5
) {
  if (!file.exists(arquivo)) {
    stop("ECO02 leitura: planilha nao encontrada: ", arquivo,
         ". Copie o XLSX original para inputs/referencias/ibge/",
         "pib_municipios_2022_2023/.")
  }
  md5 <- unname(as.character(tools::md5sum(arquivo)))
  if (!grepl("^[0-9a-f]{32}$", md5)) {
    stop("ECO02 leitura: impossivel identificar a assinatura MD5.")
  }
  if (isTRUE(verificar_md5) &&
      !identical(md5, unname(ECO02_MD5_ORIGINAIS[[periodo]]))) {
    stop("ECO02 leitura: MD5 diferente do XLSX original da edicao ",
         "auditada: ", basename(arquivo),
         ". Preserve o arquivo original ou revise a origem.")
  }

  abas <- readxl::excel_sheets(arquivo)
  if (!aba %in% abas) {
    stop("ECO02 leitura: aba ", aba, " ausente em ", arquivo)
  }

  # readxl permite ignorar 34 colunas sem carregar todas as
  # informacoes socioeconomicas/administrativas da planilha.
  tipos <- rep("skip", 40L)
  tipos[c(1L, 4L, 7L, 39L, 40L)] <- "numeric"
  tipos[8L] <- "text"
  tabela <- readxl::read_excel(
    path = arquivo,
    sheet = aba,
    range = readxl::cell_cols("A:AN"),
    col_types = tipos,
    .name_repair = "minimal"
  )

  colunas <- names(tabela)
  nomes_iniciais <- c(
    "Ano", "Código da Unidade da Federação",
    "Código do Município", "Nome do Município"
  )
  if (ncol(tabela) != 6L ||
      !identical(colunas[1:4], nomes_iniciais) ||
      !grepl("Produto Interno Bruto,", colunas[[5L]], fixed = TRUE) ||
      !grepl("(R$ 1.000)", colunas[[5L]], fixed = TRUE) ||
      !grepl("Produto Interno Bruto per capita", colunas[[6L]],
             fixed = TRUE) ||
      !grepl("(R$ 1,00)", colunas[[6L]], fixed = TRUE)) {
    stop("ECO02 leitura: posicao/unidade dos campos inesperada: ",
         basename(arquivo))
  }
  if (nrow(tabela) != linhas_esperadas) {
    stop("ECO02 leitura: numero de linhas inesperado em ",
         basename(arquivo), ": ", nrow(tabela),
         " (esperado: ", linhas_esperadas, ").")
  }
  ano_original <- tabela[[1L]]
  if (!is.numeric(ano_original) || anyNA(ano_original) ||
      any(!is.finite(ano_original) | ano_original != floor(ano_original)) ||
      !identical(sort(unique(as.integer(ano_original))),
                 as.integer(anos_base))) {
    stop("ECO02 leitura: periodo anual incompleto ou invalido: ",
         basename(arquivo))
  }
  selecionado <- ano_original %in% anos_uso
  ano_fonte <- as.integer(ano_original[selecionado])
  uf_num <- tabela[[2L]][selecionado]
  mun_num <- tabela[[3L]][selecionado]
  nomes <- trimws(as.character(tabela[[4L]][selecionado]))
  pib <- tabela[[5L]][selecionado]
  pib_pc <- tabela[[6L]][selecionado]
  esperado <- sum(unname(ECO02_QTD_FONTE[
    as.character(anos_uso)
  ]))
  if (length(ano_fonte) != esperado ||
      anyNA(c(uf_num, mun_num, nomes, pib, pib_pc)) ||
      any(!is.finite(c(uf_num, mun_num, pib, pib_pc))) ||
      any(uf_num != floor(uf_num)) ||
      any(mun_num != floor(mun_num)) ||
      any(pib <= 0 | pib_pc <= 0) ||
      any(!nzchar(nomes))) {
    stop("ECO02 leitura: linhas municipais invalidas ou incompletas: ",
         basename(arquivo))
  }

  uf <- sprintf("%02.0f", uf_num)
  cod_mun <- sprintf("%07.0f", mun_num)
  ufs_esperadas <- sprintf("%02d", c(
    11:17, 21:29, 31:33, 35, 41:43, 50:53
  ))
  if (any(!uf %in% ufs_esperadas) ||
      any(!grepl("^[0-9]{7}$", cod_mun)) ||
      any(substr(cod_mun, 1L, 2L) != uf)) {
    stop("ECO02 leitura: UF/codigo municipal inconsistente.")
  }

  d <- data.table::data.table(
    ano_prais = data.table::fifelse(
      ano_fonte == 2002L, 2000L, ano_fonte
    ),
    ano_fonte = ano_fonte,
    uf = uf,
    cod_mun = cod_mun,
    nome_mun_ibge = nomes,
    pib_mil_reais = as.numeric(pib),
    pib_pc_reais = as.numeric(pib_pc),
    referencia_populacional = data.table::fifelse(
      ano_fonte == 2022L, "primeira_apuracao_censo2022",
      "estimativa_populacional_1_julho_TCU"
    ),
    revisao_pendente = ano_fonte == 2022L,
    periodo_arquivo = periodo
  )
  contagens <- d[, .N, by = ano_fonte]
  esperado_por_ano <- unname(ECO02_QTD_FONTE[
    as.character(contagens$ano_fonte)
  ])
  if (nrow(contagens) != length(anos_uso) ||
      anyNA(esperado_por_ano) ||
      any(contagens$N != esperado_por_ano) ||
      anyDuplicated(d, by = c("ano_fonte", "cod_mun")) ||
      data.table::uniqueN(d$uf) != 27L) {
    stop("ECO02 leitura: cobertura municipal ou chaves incorretas: ",
         basename(arquivo))
  }
  data.table::setorder(d, ano_fonte, cod_mun)
  fonte <- data.table::data.table(
    periodo = periodo,
    arquivo = arquivo,
    aba = aba,
    anos_utilizados = paste(anos_uso, collapse = ","),
    registros_arquivo = as.integer(nrow(tabela)),
    registros_utilizados = as.integer(nrow(d)),
    md5 = md5
  )
  list(dados = d[], fonte = fonte[])
}

ler_pib_municipios_eco02 <- function(
  arquivo_2002_2009 = file.path(
    "so3.3", "inputs", "referencias", "ibge",
    "pib_municipios_2022_2023", "pib_municipios_2002_2009.xlsx"
  ),
  arquivo_2010_2023 = file.path(
    "so3.3", "inputs", "referencias", "ibge",
    "pib_municipios_2022_2023", "pib_municipios_2010_2023.xlsx"
  ),
  verificar_md5 = TRUE
) {
  if (length(verificar_md5) != 1L ||
      !is.logical(verificar_md5) || is.na(verificar_md5)) {
    stop("ECO02 leitura: verificar_md5 deve ser TRUE ou FALSE.")
  }
  partes <- list(
    .ler_planilha_ibge_eco02(
      arquivo_2002_2009, "2002_2009", "PIB_dos_Municípios",
      2002:2009, 2002L, 44501L, verificar_md5
    ),
    .ler_planilha_ibge_eco02(
      arquivo_2010_2023, "2010_2023", "PIB dos Municípios",
      2010:2023, c(2010L, 2022L), 77965L, verificar_md5
    )
  )
  dados <- data.table::rbindlist(
    lapply(partes, function(x) x$dados), use.names = TRUE
  )
  fontes <- data.table::rbindlist(
    lapply(partes, function(x) x$fonte), use.names = TRUE
  )
  if (nrow(dados) != 16695L ||
      !identical(sort(unique(dados$ano_fonte)), ECO02_ANOS_FONTE) ||
      !identical(sort(unique(dados$ano_prais)), ECO02_ANOS_PRAIS) ||
      anyDuplicated(dados, by = c("ano_fonte", "cod_mun")) ||
      anyNA(dados[, .(ano_prais, ano_fonte, uf, cod_mun,
                      nome_mun_ibge, pib_mil_reais, pib_pc_reais)])) {
    stop("ECO02 leitura: integracao das duas planilhas inconsistente.")
  }
  data.table::setorder(dados, ano_prais, cod_mun)
  message(
    "ECO02 leitura | PIB per capita oficial a precos correntes: ",
    nrow(dados), " municipios/ano-fonte. ",
    "Nenhum deflator aplicado e nenhum arquivo escrito."
  )
  list(dados = dados[], fontes = fontes[])
}
