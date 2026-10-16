# ============================================================
# PRAIS4 / SO3.3 / ECO01_POV3_PPC21
# REFERENCIAS MONETARIAS PARA A LINHA INTERNACIONAL DE POBREZA
#
# Reproduz os parametros aprovados em pobreza_2010.R:
#   - 3 USD internacionais por pessoa/dia (PPC 2021);
#   - conversor PPC Brasil 2021 = 2.44983620 R$/USD int.;
#   - mes medio de 365/12 dias;
#   - IPCA medio de 2021 como referencia;
#   - indice do mes de referencia da renda censitaria.
#
# Nao le microdados. Nao calcula taxas de pobreza.
# A referencia 2000/2022 (julho) deve ser validada contra
# os respectivos metadados de competencia da renda.
#
# Execucao a partir da raiz do repositorio:
#   source("so3.3/config/config.R")
#   source("so3.3/R/02_indicadores/preparar_referencias_eco01.R")
#   parametros_eco01 <- preparar_referencias_eco01()
# ============================================================

.ler_ipca_indice_1737 <- function(arquivo) {
  if (!requireNamespace("data.table", quietly=TRUE)) {
    stop("O pacote data.table e necessario.")
  }
  if (!requireNamespace("readxl", quietly=TRUE)) {
    stop("O pacote readxl e necessario para ler o IPCA original.")
  }
  if (!file.exists(arquivo)) {
    stop("Planilha original do IPCA nao encontrada: ", arquivo)
  }

  # A planilha tem meses nas colunas e apenas uma linha de valores
  # ("Brasil"). n_max=1 evita processar linhas vazias formatadas.
  wide <- readxl::read_excel(
    arquivo,
    sheet = "Tabela",
    n_max = 1L,
    .name_repair = "minimal"
  )

  if (nrow(wide) != 1L ||
      ncol(wide) < 16L ||
      !identical(names(wide)[1L], "cod") ||
      !identical(as.character(wide[[1L]][1L]), "Brasil")) {
    stop("Layout inesperado da Tabela 1737: esperada uma linha Brasil.")
  }

  periodos <- names(wide)[-1L]
  indices <- suppressWarnings(
    as.numeric(unlist(wide[1L, -1L], use.names=FALSE))
  )

  meses_pt <- c(
    "janeiro", "fevereiro", "março", "abril",
    "maio", "junho", "julho", "agosto",
    "setembro", "outubro", "novembro", "dezembro"
  )

  meses_texto <- sub(" [0-9]{4}$", "", periodos)
  anos <- suppressWarnings(
    as.integer(sub("^.* ([0-9]{4})$", "\\1", periodos))
  )

  ipca <- data.table::data.table(
    ano = anos,
    mes = match(meses_texto, meses_pt),
    indice_ipca = indices
  )

  if (nrow(ipca) != length(periodos) ||
      anyNA(ipca) ||
      any(!is.finite(ipca$indice_ipca) | ipca$indice_ipca <= 0) ||
      anyDuplicated(ipca[, .(ano, mes)]) > 0L) {
    stop("IPCA: meses/anos invalidos, indices ausentes ou duplicados.")
  }

  data.table::setorder(ipca, ano, mes)
  ipca[]
}

preparar_referencias_eco01 <- function(
  arquivo_ipca = ARQ_IPCA_1737,
  meses_renda = c("2000" = 7L, "2010" = 7L, "2022" = 7L),
  ppc_brasil_2021 = 2.44983620,
  linha_usd_dia = 3,
  dias_mes_medio = 365 / 12,
  dir_saida = file.path(
    DIR_OUTPUT_INTERMEDIARIO, "economica", "referencias"
  ),
  salvar = TRUE
) {
  anos <- c(2000L, 2010L, 2022L)

  if (length(meses_renda) != 3L ||
      !setequal(names(meses_renda), as.character(anos)) ||
      anyNA(meses_renda) ||
      any(meses_renda != as.integer(meses_renda)) ||
      any(meses_renda < 1L | meses_renda > 12L)) {
    stop("meses_renda deve conter os meses 1..12 para 2000, 2010 e 2022.")
  }
  if (any(!is.finite(c(ppc_brasil_2021, linha_usd_dia, dias_mes_medio))) ||
      any(c(ppc_brasil_2021, linha_usd_dia, dias_mes_medio) <= 0)) {
    stop("Parametros PPC, linha internacional e dias por mes invalidos.")
  }

  ipca <- .ler_ipca_indice_1737(arquivo_ipca)

  ano_base <- ipca[ano == 2021L]
  if (nrow(ano_base) != 12L ||
      !identical(sort(ano_base$mes), 1:12)) {
    stop("IPCA: referencia 2021 nao possui os 12 meses validos.")
  }
  ipca_medio_2021 <- mean(ano_base$indice_ipca)
  linha_reais_mes_2021 <-
    linha_usd_dia * ppc_brasil_2021 * dias_mes_medio

  referencias <- data.table::data.table(
    ano_censo = anos,
    mes_renda = as.integer(meses_renda[as.character(anos)])
  )

  meses_ipca <- ipca[, .(
    ano_censo = ano,
    mes_renda = mes,
    ipca_mes_renda = indice_ipca
  )]

  saida <- merge(
    referencias,
    meses_ipca,
    by = c("ano_censo", "mes_renda"),
    all.x = TRUE,
    sort = FALSE
  )
  if (nrow(saida) != length(anos) ||
      anyNA(saida$ipca_mes_renda) ||
      any(!is.finite(saida$ipca_mes_renda))) {
    stop("Indice IPCA indisponivel no mes de referencia de algum Censo.")
  }

  saida[, `:=`(
    indicador = "ECO01_POV3_PPC21",
    ppc_brasil_2021 = ppc_brasil_2021,
    linha_usd_dia = linha_usd_dia,
    dias_mes_medio = dias_mes_medio,
    ipca_medio_2021 = ipca_medio_2021,
    linha_reais_mes_2021 = linha_reais_mes_2021,
    fator_ipca = ipca_mes_renda / ipca_medio_2021,
    linha_reais_mes_censo =
      linha_reais_mes_2021 * ipca_mes_renda / ipca_medio_2021,
    md5_fonte = unname(tools::md5sum(arquivo_ipca))
  )]
  data.table::setcolorder(saida, c(
    "indicador", "ano_censo", "mes_renda",
    "linha_usd_dia", "ppc_brasil_2021", "dias_mes_medio",
    "ipca_medio_2021", "ipca_mes_renda",
    "linha_reais_mes_2021", "fator_ipca",
    "linha_reais_mes_censo", "md5_fonte"
  ))
  data.table::setorder(saida, ano_censo)

  if (isTRUE(salvar)) {
    dir.create(dir_saida, recursive=TRUE, showWarnings=FALSE)
    destino <- file.path(dir_saida, "limiares_pobreza_ppc21.csv")
    data.table::fwrite(
      saida, destino, sep=";", dec=".", quote=TRUE,
      na="", bom=FALSE
    )
    message("ECO01 | Referencias monetarias: ", destino)
  }
  saida[]
}
