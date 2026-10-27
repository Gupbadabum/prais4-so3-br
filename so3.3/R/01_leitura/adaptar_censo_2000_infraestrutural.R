# ============================================================================
# PRAIS4 / SO3.3 / INF01 - Adaptador domiciliar do Censo 2000
# ============================================================================
# Entrada: censobr::read_households(year = 2000), apenas uma UF em memoria.
# Saida: DPP no formato canonico do INF01, SOMENTE em memoria.
# Nenhum microdado ou identificador de domicilio e gravado em disco.
# ============================================================================

VARIAVEIS_INF01_DOMICILIOS_2000 <- c(
  "V0102", "V0103", "code_muni", "V0201", "V0207", "V0208",
  "V0110", "V0111", "V7100", "P001"
)

.infra_inf01_ufs <- c(11:17, 21:29, 31:33, 35, 41:43, 50:53)

.infra_numero_estrito <- function(x, campo) {
  original <- trimws(as.character(x))
  original[is.na(original) | original == ""] <- NA_character_
  valor <- suppressWarnings(as.numeric(original))
  if (any(!is.na(original) & (is.na(valor) | !is.finite(valor)))) {
    stop("INF01/2000: conversao numerica invalida em ", campo, ".")
  }
  valor
}

abrir_censo_2000_infraestrutural <- function(showProgress = TRUE) {
  for (p in c("censobr", "dplyr", "data.table")) {
    if (!requireNamespace(p, quietly = TRUE)) {
      stop("INF01/2000: pacote requerido ausente: ", p)
    }
  }
  base <- censobr::read_households(
    year = 2000L,
    columns = NULL,
    as_data_frame = FALSE,
    showProgress = showProgress
  )
  if (is.null(base)) stop("INF01/2000: censobr retornou NULL.")
  faltantes <- setdiff(VARIAVEIS_INF01_DOMICILIOS_2000, names(base))
  if (length(faltantes)) {
    stop("INF01/2000: campos domiciliares ausentes: ",
         paste(faltantes, collapse = ", "))
  }
  base
}

coletar_censo_2000_infraestrutural_uf <- function(base_arrow, uf) {
  uf <- as.integer(uf)
  if (length(uf) != 1L || is.na(uf) || !uf %in% .infra_inf01_ufs) {
    stop("INF01/2000: UF invalida.")
  }
  base_arrow |>
    dplyr::select(dplyr::all_of(VARIAVEIS_INF01_DOMICILIOS_2000)) |>
    dplyr::filter(V0102 == uf) |>
    dplyr::collect()
}

adaptar_censo_2000_infraestrutural_uf <- function(dados_uf, uf) {
  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("INF01/2000: pacote data.table requerido.")
  }
  uf <- as.integer(uf)
  if (length(uf) != 1L || is.na(uf) || !uf %in% .infra_inf01_ufs) {
    stop("INF01/2000: UF invalida no adaptador.")
  }
  uf_chr <- sprintf("%02d", uf)
  d <- data.table::as.data.table(dados_uf)
  faltantes <- setdiff(VARIAVEIS_INF01_DOMICILIOS_2000, names(d))
  if (length(faltantes)) {
    stop("INF01/2000: registros sem campos: ", paste(faltantes, collapse = ", "))
  }
  if (!nrow(d)) stop("INF01/2000: UF sem registros domiciliares.")

  # V0103 permanece texto: e o codigo municipal original de sete digitos.
  d[, uf_num := .infra_numero_estrito(V0102, "V0102")]
  d[, especie := .infra_numero_estrito(V0201, "V0201")]
  if (anyNA(d$uf_num) || any(d$uf_num != uf) ||
      anyNA(d$especie) || any(!d$especie %in% c(1, 2, 3))) {
    stop("INF01/2000: UF ou especie do domicilio invalida.")
  }

  dpp <- d[especie == 1]
  if (!nrow(dpp)) stop("INF01/2000: nenhum DPP na UF.")
  dpp[, cod_original := trimws(as.character(V0103))]
  if (anyNA(dpp$cod_original) ||
      any(!grepl("^[0-9]{7}$", dpp$cod_original)) ||
      any(substr(dpp$cod_original, 1L, 2L) != uf_chr)) {
    stop("INF01/2000: codigo municipal original invalido.")
  }
  code_muni_n <- .infra_numero_estrito(dpp$code_muni, "code_muni")
  if (anyNA(code_muni_n) || any(code_muni_n != floor(code_muni_n))) {
    stop("INF01/2000: code_muni nao inteiro ou ausente.")
  }
  dpp[, cod_mun := sprintf("%07d", as.integer(code_muni_n))]
  if (any(!grepl("^[0-9]{7}$", dpp$cod_mun)) ||
      any(substr(dpp$cod_mun, 1L, 2L) != uf_chr)) {
    stop("INF01/2000: geografia harmonizada invalida.")
  }
  # Como no Teste 03: V0103 pode diferir do identificador harmonizado,
  # mas um codigo original nao pode apontar para multiplos destinos.
  mapa_mun <- unique(dpp[, .(cod_original, cod_mun)])
  if (any(mapa_mun[, .(n_destinos = data.table::uniqueN(cod_mun)),
                   by = cod_original]$n_destinos > 1L)) {
    stop("INF01/2000: geografia original com mapeamento ambiguo.")
  }

  for (campo in c("V0207", "V0208", "V0110", "V0111", "V7100", "P001")) {
    data.table::set(dpp, j = paste0(campo, "_n"),
                    value = .infra_numero_estrito(dpp[[campo]], campo))
  }
  if (anyNA(dpp[, .(V0207_n, V0208_n)]) ||
      any(!dpp$V0207_n %in% 1:3) ||
      any(!dpp$V0208_n %in% 1:3)) {
    stop("INF01/2000: origem/canalizacao ausente ou fora do dominio nos DPP.")
  }
  ns <- as.matrix(dpp[, .(V7100_n, V0110_n, V0111_n)])
  if (anyNA(ns) || any(!is.finite(ns)) || any(ns < 0) ||
      any(ns != floor(ns)) || any(dpp$V7100_n <= 0) ||
      any(dpp$V7100_n != dpp$V0110_n + dpp$V0111_n)) {
    stop("INF01/2000: contagens de moradores invalidas ou divergentes.")
  }
  if (anyNA(dpp$P001_n) ||
      any(!is.finite(dpp$P001_n) | dpp$P001_n <= 0)) {
    stop("INF01/2000: peso domiciliar invalido.")
  }

  # Canonico domiciliar: somente memoria, com nomes independentes do censo.
  dpp[, .(
    ano = 2000L,
    uf = uf_chr,
    cod_mun,
    peso = P001_n,
    moradores_total = V7100_n,
    moradores_masculino = V0110_n,
    moradores_feminino = V0111_n,
    rede_geral = V0207_n == 1,
    atendimento = V0207_n == 1 & V0208_n == 1
  )]
}
