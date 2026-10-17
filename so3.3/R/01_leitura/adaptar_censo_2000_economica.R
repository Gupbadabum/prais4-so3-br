# ============================================================
# PRAIS4 / SO3.3 / ECO01 - ADAPTADOR ECONOMICO CENSO 2000
#
# Microdados censobr: Pessoas e Domicilios, uma UF por vez.
# Chave: V0103 + V0300.
# Geografia de saida: code_muni (harmonizada pelo censobr),
# consistente com o adaptador social de 2000.
#
# RDPC dos domicilios particulares:
#   V7616 / (V7100 - numero de pessoas com V0402 em 9,10,11).
# Domicilios coletivos: RDPC ausente (sem imputacao).
# Renda zero e valida. Os registros individuais dessas tres
# categorias permanecem no universo do indicador.
#
# Nenhum microdado e gravado por este modulo.
# ============================================================

for (pacote in c("data.table", "dplyr", "censobr")) {
  if (!requireNamespace(pacote, quietly = TRUE)) {
    stop("ECO01 2000: pacote necessario nao instalado: ", pacote)
  }
}

VARIAVEIS_ECO01_PESSOAS_2000 <- c(
  "code_muni", "V0102", "V0103", "V0300",
  "P001", "V0401", "V0402"
)

VARIAVEIS_ECO01_DOMICILIOS_2000 <- c(
  "V0102", "V0103", "V0300", "V0201",
  "V7100", "V7616"
)

abrir_censo_2000_economica <- function(showProgress = TRUE) {
  list(
    pessoas = censobr::read_population(
      year = 2000,
      columns = VARIAVEIS_ECO01_PESSOAS_2000,
      as_data_frame = FALSE,
      showProgress = showProgress
    ),
    domicilios = censobr::read_households(
      year = 2000,
      columns = VARIAVEIS_ECO01_DOMICILIOS_2000,
      as_data_frame = FALSE,
      showProgress = showProgress
    )
  )
}

listar_ufs_censo_2000_economica <- function(censo_arrow) {
  ufs_p <- censo_arrow$pessoas |>
    dplyr::distinct(V0102) |>
    dplyr::collect()
  ufs_d <- censo_arrow$domicilios |>
    dplyr::distinct(V0102) |>
    dplyr::collect()

  ufs_p <- sort(as.integer(ufs_p$V0102))
  ufs_d <- sort(as.integer(ufs_d$V0102))
  ufs_esperadas <- sort(as.integer(c(
    11:17, 21:29, 31:33, 35, 41:43, 50:53
  )))

  if (length(ufs_p) != 27L || length(ufs_d) != 27L ||
      anyNA(ufs_p) || anyNA(ufs_d) ||
      anyDuplicated(ufs_p) || anyDuplicated(ufs_d) ||
      !identical(ufs_p, ufs_esperadas) ||
      !identical(ufs_d, ufs_esperadas)) {
    stop("ECO01 2000: esperadas as mesmas 27 UFs nos arquivos ",
         "de Pessoas e Domicilios.")
  }
  ufs_p
}

coletar_uf_censo_2000_economica <- function(censo_arrow, uf) {
  uf <- as.integer(uf)
  list(
    pessoas = censo_arrow$pessoas |>
      dplyr::filter(V0102 == uf) |>
      dplyr::collect(),
    domicilios = censo_arrow$domicilios |>
      dplyr::filter(V0102 == uf) |>
      dplyr::collect()
  )
}

# Conversao rigorosa: valores originais nao ausentes que nao
# sejam interpretaveis como numeros produzem erro.
.numero_eco01_2000 <- function(x, campo) {
  valor <- suppressWarnings(as.numeric(x))
  if (any(!is.na(x) & is.na(valor))) {
    stop("ECO01 2000: conversao numerica invalida em ", campo)
  }
  valor
}

adaptar_censo_2000_economica_uf <- function(dados_uf, uf) {
  if (!is.list(dados_uf) ||
      !all(c("pessoas", "domicilios") %in% names(dados_uf))) {
    stop("ECO01 2000: informe Pessoas e Domicilios da mesma UF.")
  }

  uf <- as.integer(uf)
  uf_esperadas <- c(11:17, 21:29, 31:33, 35, 41:43, 50:53)
  if (length(uf) != 1L || is.na(uf) || !uf %in% uf_esperadas) {
    stop("ECO01 2000: codigo de UF invalido.")
  }
  uf_chr <- sprintf("%02d", uf)

  p <- data.table::as.data.table(dados_uf$pessoas)
  d <- data.table::as.data.table(dados_uf$domicilios)
  faltam_p <- setdiff(VARIAVEIS_ECO01_PESSOAS_2000, names(p))
  faltam_d <- setdiff(VARIAVEIS_ECO01_DOMICILIOS_2000, names(d))
  if (length(faltam_p) || length(faltam_d)) {
    stop("ECO01 2000: colunas ausentes. Pessoas: ",
         paste(faltam_p, collapse = ", "),
         "; Domicilios: ", paste(faltam_d, collapse = ", "))
  }
  if (!nrow(p) || !nrow(d)) {
    stop("ECO01 2000: UF sem registros de Pessoas ou Domicilios.")
  }

  # V0103 e V0300 constituem a chave testada nos microdados.
  # Sao tratados como texto em AMBOS os registros.
  for (campo in c("V0103", "V0300")) {
    p[, (campo) := as.character(get(campo))]
    d[, (campo) := as.character(get(campo))]
  }
  chaves <- c("V0103", "V0300")
  if (anyNA(p[, ..chaves]) || anyNA(d[, ..chaves]) ||
      any(!nzchar(p$V0103) | !nzchar(p$V0300)) ||
      any(!nzchar(d$V0103) | !nzchar(d$V0300))) {
    stop("ECO01 2000: chave domiciliar ausente ou vazia.")
  }

  uf_p <- .numero_eco01_2000(p$V0102, "V0102 Pessoas")
  uf_d <- .numero_eco01_2000(d$V0102, "V0102 Domicilios")
  mun <- .numero_eco01_2000(p$code_muni, "code_muni")
  peso <- .numero_eco01_2000(p$P001, "P001")
  sexo <- .numero_eco01_2000(p$V0401, "V0401")
  relacao <- .numero_eco01_2000(p$V0402, "V0402")
  especie <- .numero_eco01_2000(d$V0201, "V0201")
  moradores <- .numero_eco01_2000(d$V7100, "V7100")
  renda <- .numero_eco01_2000(d$V7616, "V7616")

  if (anyNA(uf_p) || anyNA(uf_d) ||
      any(uf_p != uf) || any(uf_d != uf) ||
      anyNA(mun) || any(!is.finite(mun) | mun != floor(mun)) ||
      anyNA(peso) || any(!is.finite(peso) | peso <= 0) ||
      anyNA(sexo) || any(!sexo %in% c(1, 2)) ||
      anyNA(relacao) || any(!is.finite(relacao)) ||
      anyNA(especie) || any(!especie %in% c(1, 2, 3)) ||
      anyNA(moradores) ||
      any(!is.finite(moradores) | moradores <= 0 |
          moradores != floor(moradores)) ||
      any(!is.na(renda) & (!is.finite(renda) | renda < 0))) {
    stop("ECO01 2000: geografia, peso, sexo, relacao, ",
         "especie, moradores ou rendimento invalidos.")
  }

  p[, cod_mun := sprintf("%07d", as.integer(mun))]
  if (any(!grepl("^[0-9]{7}$", p$cod_mun)) ||
      any(substr(p$cod_mun, 1L, 2L) != uf_chr)) {
    stop("ECO01 2000: municipio harmonizado invalido.")
  }

  p[, peso := peso]
  p[, sexo := data.table::fifelse(
    sexo == 1, "Masculino", "Feminino"
  )]
  p[, excluido_divisor := relacao %in% c(9, 10, 11)]
  d[, especie := especie]
  d[, moradores := moradores]
  d[, renda := renda]

  # Um registro por domicilio. Todos os moradores devem possuir
  # correspondencia e vice-versa; nenhuma exclusao silenciosa.
  if (anyDuplicated(d, by = chaves)) {
    stop("ECO01 2000: duplicidade em V0103 + V0300.")
  }
  sem_domicilio <- p[!d, on = .(V0103, V0300), .N]
  sem_pessoas <- d[!p, on = .(V0103, V0300), .N]
  if (sem_domicilio != 0L || sem_pessoas != 0L) {
    stop("ECO01 2000: relacionamento incompleto: ",
         sem_domicilio, " pessoas sem domicilio; ",
         sem_pessoas, " domicilios sem pessoas.")
  }

  contagem <- p[, .(
    n_pessoas = .N,
    n_excluidos = sum(excluido_divisor)
  ), by = .(V0103, V0300)]
  domicilios <- merge(
    d[, .(V0103, V0300, especie, moradores, renda)],
    contagem, by = chaves, all.x = TRUE, sort = FALSE
  )
  if (nrow(domicilios) != nrow(d) ||
      anyNA(domicilios[, .(n_pessoas, n_excluidos)]) ||
      any(domicilios$moradores != domicilios$n_pessoas)) {
    stop("ECO01 2000: V7100 diverge da contagem de Pessoas ",
         "ou a vinculacao alterou a cardinalidade.")
  }

  # A regra de ajuste vale somente para domicilios particulares.
  # Nos coletivos o rendimento domiciliar e estruturalmente ausente.
  domicilios[, divisor := moradores - n_excluidos]
  if (any(domicilios$especie %in% c(1, 2) &
          domicilios$divisor <= 0)) {
    stop("ECO01 2000: domicilio particular com divisor ",
         "RDPC nulo ou negativo. Revisar antes do calculo.")
  }
  if (any(domicilios$especie == 3 & !is.na(domicilios$renda))) {
    stop("ECO01 2000: domicilio coletivo com renda inesperada. ",
         "Revisar, sem imputacao ou alteracao automatica.")
  }
  domicilios[, rdpc := data.table::fifelse(
    especie %in% c(1, 2) & !is.na(renda),
    renda / divisor,
    NA_real_
  )]
  if (any(!is.na(domicilios$rdpc) &
          (!is.finite(domicilios$rdpc) | domicilios$rdpc < 0))) {
    stop("ECO01 2000: RDPC negativa ou nao finita.")
  }

  # Mapeamento municipal harmonizado do proprio registro de Pessoas.
  municipios <- unique(p[, .(V0103, cod_mun)])
  if (anyDuplicated(municipios, by = "V0103")) {
    stop("ECO01 2000: V0103 aponta para mais de um code_muni.")
  }
  domicilios <- merge(
    domicilios, municipios, by = "V0103",
    all.x = TRUE, sort = FALSE
  )
  if (nrow(domicilios) != nrow(d) || anyNA(domicilios$cod_mun)) {
    stop("ECO01 2000: geografia de domicilio nao harmonizada.")
  }

  # Auditoria de construcao da RDPC: apenas dados MUNICIPAIS agregados.
  # Nao se exportam identificadores individuais nem domiciliares.
  auditoria_construcao <- domicilios[, .(
    n_domicilios = .N,
    n_particulares = sum(especie %in% c(1, 2)),
    n_coletivos = sum(especie == 3),
    n_particulares_ajustados = sum(
      especie %in% c(1, 2) & n_excluidos > 0
    ),
    n_moradores_descontados = sum(
      n_excluidos[especie %in% c(1, 2)]
    ),
    n_renda_ausente_domicilios = sum(is.na(renda)),
    n_renda_zero_domicilios = sum(!is.na(renda) & renda == 0),
    n_pessoas_registradas = sum(n_pessoas)
  ), by = .(cod_mun)]
  auditoria_construcao[, `:=`(ano = 2000L, uf = uf_chr)]
  data.table::setcolorder(
    auditoria_construcao,
    c("ano", "uf", "cod_mun",
      setdiff(names(auditoria_construcao),
              c("ano", "uf", "cod_mun")))
  )
  data.table::setorder(auditoria_construcao, ano, cod_mun)

  vinculados <- merge(
    p[, .(V0103, V0300, cod_mun, peso, sexo)],
    domicilios[, .(V0103, V0300, rdpc)],
    by = chaves, all.x = TRUE, sort = FALSE
  )
  if (nrow(vinculados) != nrow(p) ||
      anyNA(vinculados[, .(cod_mun, peso, sexo)])) {
    stop("ECO01 2000: a atribuicao da RDPC alterou as Pessoas.")
  }

  canonico <- vinculados[, .(
    ano = 2000L,
    uf = uf_chr,
    cod_mun,
    peso,
    sexo,
    rdpc
  )]

  message(sprintf(
    "ECO01 2000 | UF %s | pessoas=%d; domicilios=%d; ",
    uf_chr, nrow(p), nrow(d)
  ), sprintf(
    "domicilios particulares ajustados=%d; RDPC ausente=%d",
    sum(auditoria_construcao$n_particulares_ajustados),
    sum(is.na(canonico$rdpc))
  ))

  list(
    dados = canonico[],
    auditoria_construcao = auditoria_construcao[]
  )
}
