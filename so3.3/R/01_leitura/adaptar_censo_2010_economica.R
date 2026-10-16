# ============================================================
# PRAIS4 / SO3.3 / ECO01 - ADAPTADOR ECONOMICO CENSO 2010
#
# Le somente os campos necessarios para a pobreza municipal.
# O conjunto nacional permanece como Arrow Dataset; apenas
# uma UF e coletada de cada vez.
#
# Estrutura canonica: ano, uf, cod_mun, peso, sexo, rdpc.
# Este arquivo nao altera nem importa o adaptador Social.
# ============================================================

for (pacote in c("data.table", "dplyr", "censobr")) {
  if (!requireNamespace(pacote, quietly = TRUE)) {
    stop("Pacote necessario nao instalado: ", pacote)
  }
}

VARIAVEIS_ECONOMICA_CENSO_2010 <- c(
  "code_muni", # identificador municipal harmonizado pelo censobr
  "V0001",    # UF
  "V0010",    # peso amostral da pessoa
  "V0601",    # sexo (1 masculino; 2 feminino)
  "V6531"     # rendimento domiciliar per capita, julho de 2010
)

abrir_censo_2010_economica <- function(showProgress = TRUE) {
  censobr::read_population(
    year = 2010,
    columns = VARIAVEIS_ECONOMICA_CENSO_2010,
    as_data_frame = FALSE,
    showProgress = showProgress
  )
}

listar_ufs_censo_2010_economica <- function(censo_arrow) {
  ufs <- censo_arrow |>
    dplyr::distinct(V0001) |>
    dplyr::collect()

  ufs <- sort(as.integer(ufs$V0001))
  if (length(ufs) != 27L || anyNA(ufs) || anyDuplicated(ufs)) {
    stop("Censo 2010: esperadas 27 UFs distintas; encontradas ",
         length(ufs), ".")
  }
  ufs
}

coletar_uf_censo_2010_economica <- function(censo_arrow, uf) {
  uf <- as.integer(uf)
  censo_arrow |>
    dplyr::filter(V0001 == uf) |>
    dplyr::collect()
}

adaptar_censo_2010_economica_uf <- function(dados_uf) {
  d <- data.table::as.data.table(dados_uf)
  ausentes <- setdiff(VARIAVEIS_ECONOMICA_CENSO_2010, names(d))
  if (length(ausentes)) {
    stop("Censo 2010 ECO01: variaveis ausentes: ",
         paste(ausentes, collapse = ", "))
  }
  if (nrow(d) == 0L) {
    stop("Censo 2010 ECO01: UF sem registros de pessoas.")
  }

  # Nao imputar renda ausente. Zero declarado e renda valida.
  # A conversao segue a realizada em pobreza_2010.R.
  uf_num   <- suppressWarnings(as.numeric(d[["V0001"]]))
  mun_num  <- suppressWarnings(as.numeric(d[["code_muni"]]))
  peso_num <- suppressWarnings(as.numeric(d[["V0010"]]))
  sexo_num <- suppressWarnings(as.numeric(d[["V0601"]]))
  rdpc_num <- suppressWarnings(as.numeric(d[["V6531"]]))

  # Falhar, em vez de perder silenciosamente observacoes
  # com geografia, peso ou sexo invalido.
  if (anyNA(uf_num) || anyNA(mun_num) ||
      anyNA(peso_num) || any(!is.finite(peso_num) | peso_num <= 0) ||
      anyNA(sexo_num) || any(!sexo_num %in% c(1, 2)) ||
      any(uf_num != floor(uf_num)) ||
      any(mun_num != floor(mun_num))) {
    stop("Censo 2010 ECO01: UF, municipio, peso ou sexo invalidos. ",
         "Revisar os registros antes de prosseguir.")
  }
  if (any(!is.na(rdpc_num) & (!is.finite(rdpc_num) | rdpc_num < 0))) {
    stop("Censo 2010 ECO01: RDPC negativa ou nao finita detectada. ",
         "Nao houve correcao ou exclusao automatica.")
  }

  uf_chr <- sprintf("%02d", as.integer(uf_num))
  mun_chr <- sprintf("%07d", as.integer(mun_num))
  if (any(!grepl("^[0-9]{2}$", uf_chr)) ||
      any(!grepl("^[0-9]{7}$", mun_chr)) ||
      any(substr(mun_chr, 1L, 2L) != uf_chr)) {
    stop("Censo 2010 ECO01: cod_mun nao corresponde a UF ou a 7 digitos.")
  }

  resultado <- data.table::data.table(
    ano = 2010L,
    uf = uf_chr,
    cod_mun = mun_chr,
    peso = peso_num,
    sexo = data.table::fifelse(sexo_num == 1, "Masculino", "Feminino"),
    rdpc = rdpc_num
  )
  resultado[]
}
