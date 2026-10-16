# ============================================================
# PRAIS4 / SO3.3 / ECO01 - ADAPTADOR ECONOMICO CENSO 2022
#
# Microdados controlados: pessoas + domicilios, uma UF por vez.
# Identificacao: P0080 + P0100 <-> D0080 + D0100.
# RDPC: D0360 (ausente nos domicilios coletivos).
# Peso: P0111 (registro de pessoa), sexo: P0160.
#
# Sem imputacao e sem exclusao da populacao institucionalizada.
# Nenhum registro individual e gravado em disco por este modulo.
# ============================================================

if (!requireNamespace("data.table", quietly = TRUE)) {
  stop("ECO01 2022: o pacote data.table e necessario.")
}

VARIAVEIS_ECO01_PESSOAS_2022 <- c(
  "P0080", "P0100", "P0111", "P0160"
)
VARIAVEIS_ECO01_DOMICILIOS_2022 <- c(
  "D0080", "D0100", "D0360"
)

listar_pares_eco01_2022 <- function(dir_censo = DIR_CENSO_2022) {
  if (length(dir_censo) != 1L || is.na(dir_censo) ||
      !dir.exists(dir_censo)) {
    stop("ECO01 2022: diretorio DIR_CENSO_2022 nao encontrado.")
  }

  arqs_p <- sort(list.files(
    dir_censo,
    pattern = "^Pessoas_[0-9]{2}_controlado[.]csv$",
    recursive = TRUE, full.names = TRUE
  ))
  arqs_d <- sort(list.files(
    dir_censo,
    pattern = "^Domicilios_[0-9]{2}_controlado[.]csv$",
    recursive = TRUE, full.names = TRUE
  ))
  ufs_p <- sub("^Pessoas_", "", sub("_controlado[.]csv$", "",
                                   basename(arqs_p)))
  ufs_d <- sub("^Domicilios_", "", sub("_controlado[.]csv$", "",
                                     basename(arqs_d)))
  ufs_esperadas <- sprintf("%02d", c(
    11:17, 21:29, 31:33, 35, 41:43, 50:53
  ))

  if (length(arqs_p) != 27L || length(arqs_d) != 27L ||
      anyDuplicated(ufs_p) || anyDuplicated(ufs_d) ||
      !setequal(ufs_p, ufs_esperadas) ||
      !setequal(ufs_d, ufs_esperadas)) {
    stop("ECO01 2022: esperados 27 pares unicos de Pessoas e ",
         "Domicilios, um par para cada UF.")
  }

  resultado <- data.table::data.table(
    uf = ufs_esperadas,
    arquivo_pessoas = arqs_p[match(ufs_esperadas, ufs_p)],
    arquivo_domicilios = arqs_d[match(ufs_esperadas, ufs_d)]
  )

  if (any(dirname(resultado$arquivo_pessoas) !=
          dirname(resultado$arquivo_domicilios))) {
    stop("ECO01 2022: Pessoas e Domicilios nao estao na mesma ",
         "pasta da respectiva UF.")
  }
  resultado[]
}

validar_cabecalhos_eco01_2022 <- function(arquivo_pessoas,
                                          arquivo_domicilios) {
  cab_p <- names(data.table::fread(
    arquivo_pessoas, sep = ";", nrows = 0L, showProgress = FALSE
  ))
  cab_d <- names(data.table::fread(
    arquivo_domicilios, sep = ";", nrows = 0L, showProgress = FALSE
  ))
  faltam_p <- setdiff(VARIAVEIS_ECO01_PESSOAS_2022, cab_p)
  faltam_d <- setdiff(VARIAVEIS_ECO01_DOMICILIOS_2022, cab_d)
  if (length(faltam_p) || length(faltam_d)) {
    stop(
      "ECO01 2022: colunas ausentes. Pessoas: ",
      paste(faltam_p, collapse = ", "),
      "; Domicilios: ", paste(faltam_d, collapse = ", ")
    )
  }
  invisible(TRUE)
}

adaptar_censo_2022_economica_uf <- function(
  arquivo_pessoas, arquivo_domicilios, uf
) {
  uf_chr <- sprintf("%02d", as.integer(uf))
  if (length(uf_chr) != 1L ||
      !uf_chr %in% sprintf("%02d", c(
        11:17, 21:29, 31:33, 35, 41:43, 50:53
      ))) {
    stop("ECO01 2022: UF invalida.")
  }
  validar_cabecalhos_eco01_2022(
    arquivo_pessoas, arquivo_domicilios
  )

  # Identificadores como texto para evitar perda de zeros e
  # conversoes numericas indevidas na chave de relacionamento.
  p <- data.table::fread(
    arquivo_pessoas, sep = ";",
    select = VARIAVEIS_ECO01_PESSOAS_2022,
    colClasses = list(character = c("P0080", "P0100")),
    na.strings = c("", "NA"), showProgress = FALSE
  )
  d <- data.table::fread(
    arquivo_domicilios, sep = ";",
    select = VARIAVEIS_ECO01_DOMICILIOS_2022,
    colClasses = list(character = c("D0080", "D0100")),
    na.strings = c("", "NA"), showProgress = FALSE
  )

  if (nrow(p) == 0L || nrow(d) == 0L) {
    stop("ECO01 2022: arquivo de Pessoas ou Domicilios vazio.")
  }

  data.table::setnames(
    p, VARIAVEIS_ECO01_PESSOAS_2022,
    c("cod_mun", "controle", "peso", "sexo_original")
  )
  data.table::setnames(
    d, VARIAVEIS_ECO01_DOMICILIOS_2022,
    c("cod_mun", "controle", "rdpc")
  )

  if (anyNA(p[, .(cod_mun, controle)]) ||
      anyNA(d[, .(cod_mun, controle)]) ||
      any(!nzchar(p$controle)) || any(!nzchar(d$controle)) ||
      any(!grepl("^[0-9]{7}$", p$cod_mun)) ||
      any(!grepl("^[0-9]{7}$", d$cod_mun)) ||
      any(substr(p$cod_mun, 1L, 2L) != uf_chr) ||
      any(substr(d$cod_mun, 1L, 2L) != uf_chr)) {
    stop("ECO01 2022: chave de municipio/controle invalida.")
  }

  peso <- suppressWarnings(as.numeric(p$peso))
  sexo <- suppressWarnings(as.numeric(p$sexo_original))
  rdpc_original <- d$rdpc
  rdpc <- suppressWarnings(as.numeric(rdpc_original))

  if (anyNA(peso) || any(!is.finite(peso) | peso <= 0) ||
      anyNA(sexo) || any(!sexo %in% c(1, 2))) {
    stop("ECO01 2022: peso ou sexo invalido no registro de Pessoas.")
  }
  if (any(!is.na(rdpc_original) & is.na(rdpc)) ||
      any(!is.na(rdpc) & (!is.finite(rdpc) | rdpc < 0))) {
    stop("ECO01 2022: RDPC invalida ou nao numerica. ",
         "A renda ausente original deve continuar NA.")
  }

  p[, peso := peso]
  p[, sexo := data.table::fifelse(
    sexo == 1, "Masculino", "Feminino"
  )]
  p[, sexo_original := NULL]
  d[, rdpc := rdpc]

  chaves <- c("cod_mun", "controle")
  duplicados_d <- anyDuplicated(d, by = chaves)
  if (duplicados_d) {
    stop("ECO01 2022: domicilio duplicado na chave ",
         "municipio + controle; join interrompido.")
  }

  sem_domicilio <- p[!d, on = .(cod_mun, controle), .N]
  sem_pessoas <- d[!p, on = .(cod_mun, controle), .N]
  if (sem_domicilio != 0L || sem_pessoas != 0L) {
    stop("ECO01 2022: relacionamento incompleto: ",
         sem_domicilio, " pessoas sem domicilio e ",
         sem_pessoas, " domicilios sem pessoas. Nenhuma exclusao feita.")
  }

  vinculados <- merge(
    p[, .(cod_mun, controle, peso, sexo)],
    d[, .(cod_mun, controle, rdpc)],
    by = chaves, all.x = TRUE, sort = FALSE
  )
  if (nrow(vinculados) != nrow(p)) {
    stop("ECO01 2022: a associacao alterou o numero de pessoas.")
  }

  canonico <- data.table::data.table(
    ano = rep.int(2022L, nrow(vinculados)),
    uf = rep.int(uf_chr, nrow(vinculados)),
    cod_mun = vinculados$cod_mun,
    peso = vinculados$peso,
    sexo = vinculados$sexo,
    rdpc = vinculados$rdpc
  )
  message(sprintf(
    "ECO01 2022 | UF %s | pessoas=%d; domicilios=%d; RDPC ausente=%d",
    uf_chr, nrow(p), nrow(d), sum(is.na(canonico$rdpc))
  ))
  canonico[]
}
