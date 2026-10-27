# =============================================================================
# PRAIS4 / SO3.3 / INF01 - Adaptador censitario 2010
# =============================================================================
# Microdados censobr 2010: Pessoas e Domicilios, uma UF por vez.
# Universo: V4001 == 1 (domicilio particular permanente entrevistado).
# Condicao: V0208 == 1 E V0209 == 1.
# Chave: code_muni + V0300; forma original preferida, sem exclusoes.
# Nenhum microdado nem identificador domiciliar e escrito em disco.
# =============================================================================

.infra_inf01_2010_ufs <- c(11:17, 21:29, 31:33, 35, 41:43, 50:53)
.infra_inf01_2010_campos_d <- c(
  "V0001", "V0002", "code_state", "code_muni", "V0300",
  "V0010", "V4001", "V0401", "V0208", "V0209"
)
.infra_inf01_2010_campos_p <- c(
  "V0001", "V0002", "code_state", "code_muni", "V0300",
  "V0010", "V0601"
)

abrir_censo_2010_infraestrutural <- function(showProgress = TRUE) {
  for (pkg in c("censobr", "dplyr", "data.table")) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      stop("INF01/2010: pacote requerido: ", pkg)
    }
  }
  list(
    domicilios = censobr::read_households(
      year = 2010L, columns = .infra_inf01_2010_campos_d,
      as_data_frame = FALSE, showProgress = showProgress
    ),
    pessoas = censobr::read_population(
      year = 2010L, columns = .infra_inf01_2010_campos_p,
      as_data_frame = FALSE, showProgress = showProgress
    )
  )
}

coletar_censo_2010_infraestrutural_uf <- function(censo, uf) {
  uf <- as.integer(uf)
  if (length(uf) != 1L || is.na(uf) ||
      !uf %in% .infra_inf01_2010_ufs ||
      !is.list(censo) ||
      !all(c("pessoas", "domicilios") %in% names(censo))) {
    stop("INF01/2010: argumento censo ou UF invalido.")
  }
  list(
    domicilios = data.table::as.data.table(
      dplyr::collect(dplyr::filter(censo$domicilios, V0001 == uf))
    ),
    pessoas = data.table::as.data.table(
      dplyr::collect(dplyr::filter(censo$pessoas, V0001 == uf))
    )
  )
}

.infra_inf01_2010_num <- function(x, campo, permitir_na = FALSE) {
  z <- trimws(as.character(x))
  z[is.na(z) | z == ""] <- NA_character_
  y <- suppressWarnings(as.numeric(z))
  if (any(!is.na(z) & is.na(y)) ||
      (!permitir_na && anyNA(y)) ||
      any(!is.na(y) & !is.finite(y))) {
    stop("INF01/2010: valor numerico invalido em ", campo)
  }
  y
}

.infra_inf01_2010_geo <- function(tab, uf, origem) {
  u <- .infra_inf01_2010_num(tab$V0001, paste0(origem, "/V0001"))
  estado <- .infra_inf01_2010_num(tab$code_state,
                                   paste0(origem, "/code_state"))
  mun <- .infra_inf01_2010_num(tab$code_muni,
                                paste0(origem, "/code_muni"))
  original <- .infra_inf01_2010_num(tab$V0002,
                                     paste0(origem, "/V0002"))
  if (any(u != uf | estado != uf) ||
      any(mun != floor(mun) | mun < 1000000 | mun > 9999999) ||
      any(original != floor(original) | original < 0 | original > 99999)) {
    stop("INF01/2010: geografia inconsistente em ", origem)
  }
  cm <- sprintf("%07d", as.integer(mun))
  if (any(substr(cm, 1L, 2L) != sprintf("%02d", uf)) ||
      any(substr(cm, 3L, 7L) != sprintf("%05d", as.integer(original)))) {
    stop("INF01/2010: geocodigo diverge de V0001/V0002 em ", origem)
  }
  cm
}

adaptar_censo_2010_infraestrutural_uf <- function(dados_uf, uf) {
  uf <- as.integer(uf)
  if (length(uf) != 1L || is.na(uf) ||
      !uf %in% .infra_inf01_2010_ufs ||
      !is.list(dados_uf) ||
      !all(c("domicilios", "pessoas") %in% names(dados_uf))) {
    stop("INF01/2010: UF ou arquivos invalidos.")
  }
  d <- data.table::as.data.table(data.table::copy(dados_uf$domicilios))
  p <- data.table::as.data.table(data.table::copy(dados_uf$pessoas))
  if (!nrow(d) || !nrow(p) ||
      length(setdiff(.infra_inf01_2010_campos_d, names(d))) ||
      length(setdiff(.infra_inf01_2010_campos_p, names(p)))) {
    stop("INF01/2010: UF vazia ou campos censitarios ausentes.")
  }
  d[, cod_mun := .infra_inf01_2010_geo(d, uf, "Domicilios")]
  p[, cod_mun := .infra_inf01_2010_geo(p, uf, "Pessoas")]
  for (tab in list(d, p)) {
    v <- trimws(as.character(tab$V0300))
    if (anyNA(v) || any(!grepl("^[0-9]+$", v))) {
      stop("INF01/2010: V0300 ausente ou nao numerico.")
    }
    tab[, chave_original := paste(cod_mun, v, sep = "|")]
    normal <- sub("^0+", "", v)
    normal[normal == ""] <- "0"
    tab[, chave_normalizada := paste(cod_mun, normal, sep = "|")]
  }
  chaves_ok <- function(nome) {
    !anyDuplicated(d[[nome]]) &&
      all(p[[nome]] %in% d[[nome]]) &&
      all(d[[nome]] %in% p[[nome]])
  }
  chave <- if (chaves_ok("chave_original")) {
    "chave_original"
  } else if (chaves_ok("chave_normalizada")) {
    "chave_normalizada"
  } else {
    stop("INF01/2010: vinculo Pessoas/Domicilios incompleto ou duplicado.")
  }
  d[, `:=`(
    especie = .infra_inf01_2010_num(V4001, "V4001"),
    peso = .infra_inf01_2010_num(V0010, "Domicilios/V0010"),
    moradores = .infra_inf01_2010_num(V0401, "V0401", TRUE),
    agua = .infra_inf01_2010_num(V0208, "V0208", TRUE),
    canalizacao = .infra_inf01_2010_num(V0209, "V0209", TRUE)
  )]
  p[, `:=`(
    peso = .infra_inf01_2010_num(V0010, "Pessoas/V0010"),
    sexo = .infra_inf01_2010_num(V0601, "V0601")
  )]
  if (any(!d$especie %in% c(1, 2, 5, 6)) ||
      any(!is.finite(d$peso) | d$peso <= 0) ||
      any(!is.finite(p$peso) | p$peso <= 0) ||
      any(!p$sexo %in% c(1, 2))) {
    stop("INF01/2010: especie, peso ou sexo invalido.")
  }
  dpp <- d[especie == 1]
  if (!nrow(dpp) ||
      anyNA(dpp[, .(moradores, agua, canalizacao)]) ||
      any(dpp$moradores <= 0 | dpp$moradores != floor(dpp$moradores)) ||
      any(!dpp$agua %in% 1:10) ||
      any(!dpp$canalizacao %in% 1:3)) {
    stop("INF01/2010: DPP com moradores/abastecimento invalidos.")
  }
  idx <- match(p[[chave]], d[[chave]])
  if (anyNA(idx)) stop("INF01/2010: Pessoa sem Domicilio.")
  if (any(abs(p$peso - d$peso[idx]) >
          1e-10 * pmax(1, abs(p$peso), abs(d$peso[idx])))) {
    stop("INF01/2010: pesos de Pessoas e Domicilios divergentes.")
  }
  p[, indice_domicilio := idx]
  p[, especie_domicilio := d$especie[idx]]
  pessoas_dpp <- p[especie_domicilio == 1]
  cont <- pessoas_dpp[, .(
    n_pessoas = .N,
    n_homens = sum(sexo == 1),
    n_mulheres = sum(sexo == 2)
  ), by = chave]
  # 'by' aceita nome de coluna armazenado em uma variavel.
  idx_cont <- match(dpp[[chave]], cont[[chave]])
  if (anyNA(idx_cont) ||
      any(dpp$moradores != cont$n_pessoas[idx_cont])) {
    stop("INF01/2010: V0401 diverge da contagem de Pessoas em DPP.")
  }
  dpp[, `:=`(
    homens = cont$n_homens[idx_cont],
    mulheres = cont$n_mulheres[idx_cont],
    rede_geral = agua == 1,
    atendimento = agua == 1 & canalizacao == 1
  )]
  pessoas_dpp[, `:=`(
    rede_geral = d$agua[indice_domicilio] == 1,
    atendimento = d$agua[indice_domicilio] == 1 &
                  d$canalizacao[indice_domicilio] == 1
  )]
  if (anyNA(pessoas_dpp[, .(rede_geral, atendimento)]) ||
      any(pessoas_dpp$cod_mun != d$cod_mun[pessoas_dpp$indice_domicilio]) ||
      any(pessoas_dpp$atendimento & !pessoas_dpp$rede_geral) ||
      any(dpp$moradores != dpp$homens + dpp$mulheres)) {
    stop("INF01/2010: inconsistencia na atribuicao da agua.")
  }
  # IDs individuais permanecem apenas em memoria. Nenhuma funcao salva-os.
  list(
    pessoas = pessoas_dpp[, .(uf = sprintf("%02d", uf), cod_mun,
                              peso, sexo, rede_geral, atendimento)],
    domicilios = dpp[, .(uf = sprintf("%02d", uf), cod_mun,
                             peso, moradores, homens, mulheres,
                             rede_geral, atendimento)],
    chave_utilizada = if (chave == "chave_original") "original" else "normalizada"
  )
}
