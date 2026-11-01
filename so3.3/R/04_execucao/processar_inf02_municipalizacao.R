# ============================================================================
# PRAIS4 / SO3.3 / INF02
# ETAPA 01 (PRODUCAO) - MUNICIPALIZACAO HIDROLOGICA ANA x BHO 50K / IBGE 2025
#
# Operacao UNICA, independente dos anos censitarios. NAO calcula m3/hab/ano.
# Usa checkpoints hidrologicos e territoriais ja validados; nao os altera.
# Processamento por UF e blocos; checkpoints em disco; retomada sem sobrescrita.
#
# Fonte de vazao: ANA Qmltinc incremental superficial, em m3/s.
# Q municipal = soma[ Q_j * area(BHO_j intersecao municipio)/area(BHO_j) ].
# A area integral de BHO_j (inclusive parcela estrangeira) e denominador.
# Nao usa Q=0 como imputacao para fontes "Internacional nao Estimado".
# ============================================================================

.inf02_e01_versao <- "INF02_E01_1.0.4"
.inf02_e01_crs_area <- 6933L
.inf02_e01_bloco <- 200L

.inf02_e01_assert <- function(condicao, mensagem) {
  if (length(condicao) != 1L || is.na(condicao) || !isTRUE(condicao)) {
    stop("INF02/Etapa01: ", mensagem, call. = FALSE)
  }
}

.inf02_e01_gravar_rds <- function(objeto, arquivo) {
  .inf02_e01_assert(!file.exists(arquivo),
                    paste0("Sobrescrita proibida: ", arquivo))
  dir.create(dirname(arquivo), recursive = TRUE, showWarnings = FALSE)
  temporario <- paste0(arquivo, ".parcial")
  .inf02_e01_assert(!file.exists(temporario),
                    paste0("Checkpoint parcial presente: ", temporario))
  saveRDS(objeto, temporario, compress = "gzip", version = 3L)
  .inf02_e01_assert(file.rename(temporario, arquivo),
                    paste0("Falha ao consolidar: ", arquivo))
  invisible(arquivo)
}

.inf02_e01_gravar_ou_validar <- function(objeto, arquivo, tipo = "rds") {
  if (file.exists(arquivo)) {
    if (tipo == "rds") {
      antigo <- readRDS(arquivo)
    } else {
      # Preservar identificadores e demais campos textuais na releitura.
      # fread() sem colClasses pode converter cod_mun para inteiro,
      # provocando um falso erro no all.equal() de um CSV correto.
      colunas_texto <- names(objeto)[
        vapply(objeto, is.character, logical(1))
      ]
      tipos <- if (length(colunas_texto)) {
        list(character = colunas_texto)
      } else {
        NULL
      }
      antigo <- data.table::fread(
        arquivo, sep = ";", dec = ".", colClasses = tipos,
        showProgress = FALSE
      )
    }

    diferencas <- all.equal(
      as.data.frame(antigo), as.data.frame(objeto),
      tolerance = 1e-9, check.attributes = FALSE
    )
    .inf02_e01_assert(
      isTRUE(diferencas),
      paste0(
        "Produto existente diferente do recalculado: ", arquivo,
        " | detalhe: ",
        if (isTRUE(diferencas)) "nenhum" else
          paste(utils::head(as.character(diferencas), 3L), collapse = "; ")
      )
    )
    message("INF02/E01 | Produto existente validado: ", arquivo)
    return(invisible(arquivo))
  }
  if (tipo == "rds") return(.inf02_e01_gravar_rds(objeto, arquivo))
  dir.create(dirname(arquivo), recursive = TRUE, showWarnings = FALSE)
  temporario <- paste0(arquivo, ".parcial")
  .inf02_e01_assert(!file.exists(temporario),
                    paste0("Checkpoint parcial presente: ", temporario))
  data.table::fwrite(objeto, temporario, sep = ";", dec = ".", na = "")
  .inf02_e01_assert(file.rename(temporario, arquivo),
                    paste0("Falha ao consolidar: ", arquivo))
  invisible(arquivo)
}

.inf02_e01_identidade <- function(arquivos, modulo) {
  arquivos <- normalizePath(arquivos, winslash = "/", mustWork = TRUE)
  atributos <- file.info(arquivos)
  .inf02_e01_assert(all(is.finite(atributos$size)),
                    "Tamanho de algum insumo indisponivel")
  list(
    versao = .inf02_e01_versao,
    modulo_md5 = unname(tools::md5sum(modulo)),
    arquivos = arquivos,
    tamanho = as.numeric(atributos$size),
    modificacao = as.numeric(atributos$mtime)
  )
}

# Compatibilidade controlada de checkpoints v1.0.0 ate v1.0.3.
# V1.0.4 corrige somente a releitura e comparacao dos arquivos CSV.
# Intersecao, reparticao e dependencias de entrada permanecem inalteradas.
# Sao aceitas somente assinaturas exatas das versoes publicadas.
.inf02_e01_identidade_compativel <- function(anterior, atual) {
  if (identical(anterior, atual)) return(TRUE)
  if (!is.list(anterior) || !is.list(atual)) return(FALSE)
  campos_insumos <- c("arquivos", "tamanho", "modificacao")
  if (!all(vapply(campos_insumos, function(campo) {
      identical(anterior[[campo]], atual[[campo]])
    }, logical(1)))) return(FALSE)
  assinaturas <- c(
    "INF02_E01_1.0.0" = "3123f937c7d07c03c0614e797ad0de48",
    "INF02_E01_1.0.1" = "aeef97f8273049d785855800eb4972ef",
    "INF02_E01_1.0.2" = "393022efa41959a131fb0accac13b5d4",
    "INF02_E01_1.0.3" = "df2719defba20e02abc1f817f7e77cfb"
  )
  versao_ant <- anterior$versao
  if (!is.character(versao_ant) || length(versao_ant) != 1L ||
      !versao_ant %in% names(assinaturas)) return(FALSE)
  isTRUE(identical(anterior$modulo_md5, unname(assinaturas[[versao_ant]])) &&
         identical(atual$versao, "INF02_E01_1.0.4"))
}

.inf02_e01_ufs_ibge <- c(
  "11" = "RO", "12" = "AC", "13" = "AM", "14" = "RR",
  "15" = "PA", "16" = "AP", "17" = "TO", "21" = "MA",
  "22" = "PI", "23" = "CE", "24" = "RN", "25" = "PB",
  "26" = "PE", "27" = "AL", "28" = "SE", "29" = "BA",
  "31" = "MG", "32" = "ES", "33" = "RJ", "35" = "SP",
  "41" = "PR", "42" = "SC", "43" = "RS", "50" = "MS",
  "51" = "MT", "52" = "GO", "53" = "DF"
)

#' Etapa 01: municipalizar Qmltinc superficial incremental da ANA.
#'
#' @param dir_insumos Pasta INFO2 que contem intermediate/, spatial/, diagnostics/.
#' @param arquivo_municipios Shapefile BR_Municipios_2025.shp (IBGE).
#' @param dir_saida Diretoro de checkpoint/produto sob outputs/intermediario/.
#' @param modo 'uf' (processa uma UF e persiste), ou 'completo' (as 27 UFs).
#' @param uf_alvo Sigla da UF quando modo='uf', padrao DF.
#' @param tamanho_bloco N. de geometrias BHO carregadas por leitura.
#' @return Invisivelmente: resumo da UF ou caminhos das tabelas nacionais.
processar_inf02_municipalizacao <- function(
    dir_insumos,
    arquivo_municipios,
    dir_saida = file.path("so3.3", "outputs", "intermediario",
                          "infraestrutural", "inf02", "etapa01"),
    modo = "uf",
    uf_alvo = "DF",
    tamanho_bloco = .inf02_e01_bloco) {

  for (pacote in c("sf", "data.table", "DBI", "RSQLite")) {
    .inf02_e01_assert(requireNamespace(pacote, quietly = TRUE),
                      paste0("Instale o pacote R: ", pacote))
  }
  .inf02_e01_assert(modo %in% c("uf", "completo"),
                    "modo deve ser 'uf' ou 'completo'")
  .inf02_e01_assert(tamanho_bloco >= 1L && tamanho_bloco <= 500L,
                    "tamanho_bloco deve estar entre 1 e 500")
  tamanho_bloco <- as.integer(tamanho_bloco)
  uf_alvo <- toupper(uf_alvo)
  if (modo == "uf") {
    .inf02_e01_assert(uf_alvo %in% unname(.inf02_e01_ufs_ibge),
                      paste0("UF desconhecida: ", uf_alvo))
  }
  dir_insumos <- normalizePath(dir_insumos, winslash = "/", mustWork = TRUE)
  arquivo_municipios <- normalizePath(arquivo_municipios,
                                     winslash = "/", mustWork = TRUE)

  gpkg <- file.path(dir_insumos, "spatial", "inf02_bho50k_integrada_v01.gpkg")
  area_rds <- file.path(dir_insumos, "intermediate",
                        "inf02_bho50k_area_brasil_2025_v01.rds")
  hidro_rds <- file.path(dir_insumos, "intermediate",
                         "inf02_hidrologia_50k_v02.rds")
  mapa_csv <- file.path(dir_insumos, "diagnostics",
                         "inf02_teste18a_mapa_fid.csv")
  balan_uf_csv <- file.path(dir_insumos, "diagnostics",
                            "inf02_teste19b_cobertura_por_uf_2025.csv")
  balan_br_csv <- file.path(dir_insumos, "diagnostics",
                            "inf02_teste19a_resumo_cobertura_2025.csv")

  insumos <- c(gpkg, area_rds, hidro_rds, mapa_csv, balan_uf_csv,
               balan_br_csv, arquivo_municipios,
               sub("[.]shp$", ".dbf", arquivo_municipios),
               sub("[.]shp$", ".shx", arquivo_municipios))
  .inf02_e01_assert(all(file.exists(insumos)),
    paste0("Insumos ausentes: ", paste(insumos[!file.exists(insumos)],
                                      collapse = "; ")))

  modulo <- file.path("so3.3", "R", "04_execucao",
                       "processar_inf02_municipalizacao.R")
  .inf02_e01_assert(file.exists(modulo),
                    paste0("Execute a partir da raiz do repositorio: ", modulo))
  identidade <- .inf02_e01_identidade(insumos, modulo)

  dir.create(dir_saida, recursive = TRUE, showWarnings = FALSE)
  dir_check <- file.path(dir_saida, "ufs")
  dir.create(dir_check, recursive = TRUE, showWarnings = FALSE)

  sf::sf_use_s2(FALSE)
  DT <- data.table::as.data.table
  area <- DT(readRDS(area_rds))
  hidro <- DT(readRDS(hidro_rds))
  mapa <- data.table::fread(mapa_csv, showProgress = FALSE)
  qa_uf_ref <- data.table::fread(balan_uf_csv, showProgress = FALSE)
  qa_br_ref <- data.table::fread(balan_br_csv, showProgress = FALSE)

  .inf02_e01_assert(nrow(area) == 115107L &&
                      data.table::uniqueN(area$cotrecho) == 115107L,
                    "Area 19A: quantidade/unicidade inesperada")
  .inf02_e01_assert(nrow(hidro) == 113923L &&
                      data.table::uniqueN(hidro$cotrecho_50k) == 113923L,
                    "Hidrologia: quantidade/unicidade inesperada")
  .inf02_e01_assert(nrow(mapa) == 88859L &&
                      data.table::uniqueN(mapa$fid) == 88859L &&
                      data.table::uniqueN(mapa$cotrecho) == 88859L,
                    "Mapa FID 18A: quantidade/unicidade inesperada")
  .inf02_e01_assert(nrow(qa_uf_ref) == 27L && nrow(qa_br_ref) == 1L,
                    "Balancos 19A/19B: formato inesperado")
  .inf02_e01_assert(all(c("cotrecho", "classe_hidro", "area_brasil_km2",
                             "area_geometrica_km2") %in% names(area)),
                    "Area 19A: campos obrigatorios ausentes")
  .inf02_e01_assert(all(c("cotrecho_50k", "Qmltinc_soma",
      "Qmltinc_soma_sem_lacuna", "n_nao_estimados") %in% names(hidro)),
                    "Hidrologia: campos obrigatorios ausentes")
  .inf02_e01_assert(all(c("uf", "soma_area_bho_uf_km2") %in%
                         names(qa_uf_ref)), "Balanco 19B: colunas ausentes")
  .inf02_e01_assert(
    !anyNA(qa_uf_ref$uf) &&
      data.table::uniqueN(qa_uf_ref$uf) == 27L &&
      setequal(as.character(qa_uf_ref$uf),
               unname(.inf02_e01_ufs_ibge)),
    "Balanco 19B: UF ausente, duplicada ou nao reconhecida"
  )

  meta <- area[match(mapa$cotrecho, area$cotrecho)]
  .inf02_e01_assert(identical(as.integer(meta$cotrecho),
                               as.integer(mapa$cotrecho)) &&
                     all(is.finite(meta$area_geometrica_km2)) &&
                     all(meta$area_geometrica_km2 > 0) &&
                     all(meta$area_brasil_km2 > 0),
                    "Mapa 18A e areas 19A nao coincidem")
  meta[, fid := as.integer(mapa$fid)]
  idxh <- match(meta$cotrecho, hidro$cotrecho_50k)
  eh_ana <- meta$classe_hidro == "com_contribuicao_agregada"
  .inf02_e01_assert(sum(eh_ana) == 87678L && sum(!eh_ana) == 1181L &&
                      all(!is.na(idxh[eh_ana])) &&
                      all(is.na(idxh[!eh_ana])),
                    "Incompatibilidade de classes e chaves ANA-BHO")
  meta[, n_nao_estimados := hidro$n_nao_estimados[idxh]]
  meta[, Qmltinc_soma_sem_lacuna := hidro$Qmltinc_soma_sem_lacuna[idxh]]
  meta[, Qmltinc_soma_bruta := hidro$Qmltinc_soma[idxh]]
  meta[, situacao_fonte := data.table::fifelse(
    classe_hidro != "com_contribuicao_agregada", "extra_sem_ana",
    data.table::fifelse(n_nao_estimados > 0L, "ana_nao_estimada", "ana_estimada")
  )]
  .inf02_e01_assert(
    all(is.finite(meta$Qmltinc_soma_sem_lacuna[
      meta$situacao_fonte == "ana_estimada"])) &&
    all(is.na(meta$Qmltinc_soma_sem_lacuna[
      meta$situacao_fonte != "ana_estimada"])) &&
    all(meta$n_nao_estimados[meta$situacao_fonte == "ana_estimada"] == 0L),
    "Tratamento de fontes nao estimadas inconsistente")
  data.table::setkey(meta, cotrecho)
  data.table::setkey(mapa, fid)

  # A chave geocodigo CD_MUN e tratada como texto (7 digitos).
  municipios <- sf::st_read(arquivo_municipios, quiet = TRUE)
  .inf02_e01_assert(nrow(municipios) == 5573L &&
                      all(c("CD_MUN", "NM_MUN") %in% names(municipios)) &&
                      !is.na(sf::st_crs(municipios)),
                    "Malha municipal 2025: quantidade/campos/CRS inesperados")
  municipios$cod_mun <- as.character(municipios$CD_MUN)
  municipios$nm_mun <- as.character(municipios$NM_MUN)
  .inf02_e01_assert(all(grepl("^[0-9]{7}$", municipios$cod_mun)) &&
                      !anyDuplicated(municipios$cod_mun) &&
                      all(nzchar(municipios$nm_mun)),
                    "Malha municipal 2025: cod_mun ou nomes invalidos")
  municipios$uf <- unname(.inf02_e01_ufs_ibge[
    substr(municipios$cod_mun, 1L, 2L)])
  .inf02_e01_assert(!anyNA(municipios$uf) &&
                      data.table::uniqueN(municipios$uf) == 27L,
                    "Codigos IBGE dos municipios nao correspondem a 27 UFs")
  if ("SIGLA_UF" %in% names(municipios)) {
    .inf02_e01_assert(all(as.character(municipios$SIGLA_UF) == municipios$uf),
                      "SIGLA_UF diverge do prefixo do codigo municipal")
  }
  # Malha 2025, conforme IBGE: 5569 municipios + DF + Fernando de
  # Noronha + 2 areas estaduais operacionais (Lagoa dos Patos/Mirim).
  # As duas areas do RS nao sao municipios; permanecem num livro-razão
  # territorial separado para conservar superficies e eventuais vazoes.
  nomes_norm <- toupper(iconv(municipios$nm_mun, to = "ASCII//TRANSLIT"))
  .inf02_e01_assert(!anyNA(nomes_norm),
                    "Nao foi possivel normalizar NM_MUN da malha 2025")
  operacional <- municipios$uf == "RS" & (
    grepl("LAGOA DOS PATOS", nomes_norm, fixed = TRUE) |
    grepl("LAGOA MIRIM", nomes_norm, fixed = TRUE)
  )
  esperado_operacional <- 2L
  .inf02_e01_assert(sum(operacional) == esperado_operacional,
    paste0("Malha IBGE 2025: esperadas ", esperado_operacional,
      " areas operacionais no RS, encontradas ", sum(operacional),
      ". Inspecione NM_MUN das feicoes excepcionais."))
  municipios$tipo_territorio <- ifelse(
    operacional, "area_operacional", "unidade_municipal"
  )
  .inf02_e01_assert(sum(municipios$tipo_territorio == "unidade_municipal") == 5571L,
                    "Malha 2025 nao possui 5571 unidades municipais/equivalentes")
  message("INF02/E01 | Malha IBGE 2025: ", nrow(municipios),
          " geocodigos; 5571 unidades municipais; ",
          sum(operacional), " areas operacionais do RS.")
  validade <- sf::st_is_valid(municipios)
  .inf02_e01_assert(!anyNA(validade) && all(validade) &&
                      !any(sf::st_is_empty(municipios)),
                    paste0("Malha municipal possui geometria invalida/vazia. Exemplos: ",
                      paste(head(municipios$cod_mun[is.na(validade) | !validade |
                        sf::st_is_empty(municipios)], 12L), collapse = ", ")))
  municipios <- municipios[, c("cod_mun", "nm_mun", "uf", "tipo_territorio")]
  municipios_eq <- sf::st_transform(municipios, .inf02_e01_crs_area)
  municipios_eq$area_municipal_km2 <-
    as.numeric(sf::st_area(municipios_eq)) / 1e6
  .inf02_e01_assert(all(is.finite(municipios_eq$area_municipal_km2)) &&
                      all(municipios_eq$area_municipal_km2 > 0),
                    "Area municipal geometricamente invalida")

  # Consultar uma feicao: CRS original da BHO, sem carregamento nacional.
  amostra <- sf::st_read(gpkg, query = paste0(
    'SELECT "cotrecho", "geom" FROM "inf02_bho50k" LIMIT 1'), quiet = TRUE)
  crs_bho <- sf::st_crs(amostra)
  .inf02_e01_assert(nrow(amostra) == 1L && !is.na(crs_bho),
                    "CRS BHO nao identificado")
  rm(amostra)

  con <- DBI::dbConnect(RSQLite::SQLite(), gpkg,
                       flags = RSQLite::SQLITE_RO,
                       default.extensions = FALSE)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  nrt <- DBI::dbGetQuery(con,
    'SELECT COUNT(*) AS n FROM "rtree_inf02_bho50k_geom"')$n[[1L]]
  .inf02_e01_assert(nrt == 115107L, "Indice R-tree BHO ausente/incompleto")

  consulta_rtree <- paste0(
    'SELECT id AS fid FROM "rtree_inf02_bho50k_geom" ',
    'WHERE minx <= ? AND maxx >= ? AND miny <= ? AND maxy >= ? ORDER BY id')

  vazio <- function() data.table::data.table(
    uf = character(), cod_mun = character(),
    cotrecho = integer(), fid = integer(),
    classe_hidro = character(), situacao_fonte = character(),
    area_intersecao_km2 = numeric(), fracao_bho_integral = numeric(),
    q_inc_parcela_estimada_m3s = numeric()
  )

  # Um bloco = um conjunto disjunto de FIDs de uma mesma UF.
  calcular_bloco <- function(fids, uf, municipios_uf) {
    if (!length(fids)) return(vazio())
    fids <- sort(as.integer(fids))
    dados_mapa <- mapa[match(fids, mapa$fid)]
    .inf02_e01_assert(!anyNA(dados_mapa$fid),
                      "FIDs do R-tree ausentes no mapa 18A")
    sql <- sprintf(
      'SELECT "cotrecho", "geom" FROM "inf02_bho50k" WHERE "fid" IN (%s)',
      paste(fids, collapse = ","))
    geo <- sf::st_read(gpkg, query = sql, quiet = TRUE)
    .inf02_e01_assert(nrow(geo) == length(fids) &&
                      "cotrecho" %in% names(geo) &&
                      !anyDuplicated(geo$cotrecho) &&
                      setequal(as.integer(geo$cotrecho),
                               as.integer(dados_mapa$cotrecho)) &&
                      !any(sf::st_is_empty(geo)),
                      paste0("Geometrias BHO nao correspondem aos FIDs da UF ", uf))
    valido <- sf::st_is_valid(geo)
    .inf02_e01_assert(!anyNA(valido) && all(valido),
                      paste0("Geometria BHO invalida em UF ", uf))
    ge <- sf::st_transform(geo["cotrecho"], .inf02_e01_crs_area)
    inter <- suppressWarnings(sf::st_intersection(
      ge, municipios_uf["cod_mun"]))
    if (!nrow(inter)) return(vazio())
    areas <- as.numeric(sf::st_area(inter)) / 1e6
    .inf02_e01_assert(all(is.finite(areas)) && all(areas >= 0),
                      "Area de intersecao invalida")
    pedacos <- data.table::data.table(
      cod_mun = as.character(inter$cod_mun),
      cotrecho = as.integer(inter$cotrecho),
      area_intersecao_km2 = areas)
    # Ignorar residuos GEOS inferiores a 0,0001 m2 (nao areas hidrologicas).
    pedacos <- pedacos[area_intersecao_km2 > 1e-10,
      .(area_intersecao_km2 = sum(area_intersecao_km2)),
      by = .(cod_mun, cotrecho)]
    if (!nrow(pedacos)) return(vazio())
    idx <- match(pedacos$cotrecho, meta$cotrecho)
    .inf02_e01_assert(!anyNA(idx), "Intersecoes com cotrecho fora dos metadados")
    area_fonte <- meta$area_geometrica_km2[idx]
    fracao <- pedacos$area_intersecao_km2 / area_fonte
    .inf02_e01_assert(all(is.finite(fracao)) &&
                        all(fracao >= 0) && all(fracao <= 1 + 1e-6),
                      "Fracao de ottobacia maior do que 1 ou invalida")
    tipo <- meta$situacao_fonte[idx]
    q <- meta$Qmltinc_soma_sem_lacuna[idx] * fracao
    q[tipo != "ana_estimada"] <- NA_real_
    saida <- data.table::data.table(
      uf = rep(uf, nrow(pedacos)),
      cod_mun = pedacos$cod_mun,
      cotrecho = pedacos$cotrecho,
      fid = meta$fid[idx],
      classe_hidro = meta$classe_hidro[idx],
      situacao_fonte = tipo,
      area_intersecao_km2 = pedacos$area_intersecao_km2,
      fracao_bho_integral = fracao,
      q_inc_parcela_estimada_m3s = q
    )
    data.table::setorder(saida, cod_mun, cotrecho)
    saida[]
  }

  # Agregador de pares: tambem preserva area sem atribuicao ANA.
  consolidar_municipios <- function(uf, municipios_uf, pares, dir_uf) {
    b <- data.table::data.table(
      uf = as.character(municipios_uf$uf),
      cod_mun = as.character(municipios_uf$cod_mun),
      nm_mun = as.character(municipios_uf$nm_mun),
      tipo_territorio = as.character(municipios_uf$tipo_territorio),
      area_municipal_km2 = as.numeric(municipios_uf$area_municipal_km2))

    if (nrow(pares)) {
      p <- pares[, .(
        area_bho_com_ana_estimada_km2 = sum(area_intersecao_km2[
          situacao_fonte == "ana_estimada"]),
        area_bho_ana_nao_estimada_km2 = sum(area_intersecao_km2[
          situacao_fonte == "ana_nao_estimada"]),
        area_bho_extra_sem_ana_km2 = sum(area_intersecao_km2[
          situacao_fonte == "extra_sem_ana"]),
        n_bho_com_estimativa = sum(situacao_fonte == "ana_estimada"),
        n_bho_nao_estimadas = sum(situacao_fonte == "ana_nao_estimada"),
        n_bho_extra = sum(situacao_fonte == "extra_sem_ana"),
        q_inc_parcial_estimada_m3s = sum(q_inc_parcela_estimada_m3s,
                                        na.rm = TRUE)
      ), by = cod_mun]
      b <- merge(b, p, by = "cod_mun", all.x = TRUE, sort = FALSE)
    }
    campos_zeros <- c(
      "area_bho_com_ana_estimada_km2", "area_bho_ana_nao_estimada_km2",
      "area_bho_extra_sem_ana_km2", "n_bho_com_estimativa",
      "n_bho_nao_estimadas", "n_bho_extra", "q_inc_parcial_estimada_m3s")
    for (col in campos_zeros) {
      if (!col %in% names(b)) b[, (col) := 0]
      valor_zero <- if (is.integer(b[[col]])) 0L else 0
      data.table::set(b, which(is.na(b[[col]])), col, valor_zero)
    }
    b[, area_bho_somada_km2 := area_bho_com_ana_estimada_km2 +
        area_bho_ana_nao_estimada_km2 + area_bho_extra_sem_ana_km2]
    b[, area_sem_bho_km2 := pmax(0, area_municipal_km2 - area_bho_somada_km2)]
    b[, cobertura_bho_pct := 100 * pmin(1, area_bho_somada_km2 / area_municipal_km2)]
    b[, cobertura_ana_estimada_pct := 100 * pmin(1,
      area_bho_com_ana_estimada_km2 / area_municipal_km2)]
    b[, q_inc_parcial_estimada_m3s := data.table::fifelse(
      n_bho_com_estimativa > 0L, q_inc_parcial_estimada_m3s, NA_real_)]
    b[, situacao_qualidade := data.table::fifelse(
      n_bho_com_estimativa == 0L, "sem_contribuicao_estimada",
      data.table::fifelse(n_bho_nao_estimadas > 0L,
        "estimativa_com_fonte_nao_estimada",
        data.table::fifelse(
          area_bho_extra_sem_ana_km2 > 1e-6 | area_sem_bho_km2 > 1e-6,
          "estimativa_com_cobertura_incompleta", "estimativa_sem_ressalva_espacial")))]
    # Controle integrado: tolerancia espacial documentada, sem alterar
    # as areas ou as vazoes calculadas. Limite: piso 1000m2,
    # 1 ppm da area municipal e teto absoluto de 5000m2.
    n_duplicados <- anyDuplicated(b$cod_mun)
    n_esperado <- nrow(municipios_uf)
    falha_area_ibge <- !is.finite(b$area_municipal_km2) |
      b$area_municipal_km2 <= 0
    falha_area_bho <- !is.finite(b$area_bho_somada_km2) |
      b$area_bho_somada_km2 < 0
    excesso_km2 <- b$area_bho_somada_km2 - b$area_municipal_km2
    limite_excesso_km2 <- pmax(
      0.001, pmin(0.005, 1e-6 * b$area_municipal_km2)
    )
    falha_excesso <- is.finite(excesso_km2) &
      excesso_km2 > limite_excesso_km2

    # Acima do limite absoluto anterior (1000 m2), mas dentro do
    # limite relativo/cap. Preservar diagnostico para auditoria.
    residuo_tolerado <- is.finite(excesso_km2) &
      excesso_km2 > 0.001 & !falha_excesso
    if (any(residuo_tolerado)) {
      registro <- data.table::copy(b[residuo_tolerado, .(
        uf, cod_mun, nm_mun,
        area_municipal_km2, area_bho_somada_km2
      )])
      registro[, excesso_area_m2 :=
        (area_bho_somada_km2 - area_municipal_km2) * 1e6]
      registro[, limite_tolerado_m2 :=
        limite_excesso_km2[residuo_tolerado] * 1e6]
      arq_residuos <- file.path(dir_uf,
        paste0("INF02_E01_", uf,
               "_residuos_area_tolerados_v103.csv"))
      .inf02_e01_gravar_ou_validar(registro, arq_residuos, "csv")
      message("INF02/E01 | UF=", uf, " | residuos espaciais aceitos=",
              nrow(registro), " | maximo=",
              sprintf("%.3f m2", max(registro$excesso_area_m2)),
              " | sem alterar area ou vazao")
    }

    falhou <- n_duplicados != 0L || nrow(b) != n_esperado ||
      any(falha_area_ibge) || any(falha_area_bho) || any(falha_excesso)

    if (falhou) {
      diagnostico <- data.table::copy(b)[, .(
        uf, cod_mun, nm_mun, tipo_territorio,
        area_municipal_km2, area_bho_somada_km2,
        area_bho_com_ana_estimada_km2,
        area_bho_ana_nao_estimada_km2,
        area_bho_extra_sem_ana_km2,
        n_bho_com_estimativa, n_bho_nao_estimadas, n_bho_extra,
        q_inc_parcial_estimada_m3s
      )]
      diagnostico[, excesso_area_km2 := area_bho_somada_km2 - area_municipal_km2]
      diagnostico[, excesso_area_m2 := excesso_area_km2 * 1e6]
      diagnostico[, falha_area_ibge :=
        !is.finite(area_municipal_km2) | area_municipal_km2 <= 0]
      diagnostico[, falha_area_bho :=
        !is.finite(area_bho_somada_km2) | area_bho_somada_km2 < 0]
      diagnostico[, limite_excesso_m2 :=
        pmax(0.001, pmin(0.005, 1e-6 * area_municipal_km2)) * 1e6]
      diagnostico[, falha_excesso_limite :=
        is.finite(excesso_area_km2) &
        excesso_area_m2 > limite_excesso_m2]
      data.table::setorder(diagnostico, -excesso_area_km2)
      arquivo_diag <- file.path(dir_uf,
        paste0("INF02_E01_", uf, "_diagnostico_agregacao_v103.csv"))
      if (file.exists(arquivo_diag)) {
        anterior_diag <- data.table::fread(arquivo_diag, sep = ";",
          colClasses = list(character = c("uf", "cod_mun", "nm_mun")),
          showProgress = FALSE)
        .inf02_e01_assert(isTRUE(all.equal(
          as.data.frame(anterior_diag), as.data.frame(diagnostico),
          tolerance = 1e-9, check.attributes = FALSE)),
          paste0("Diagnostico existente diverge; nao sobrescrevendo: ",
                 arquivo_diag))
      } else {
        .inf02_e01_gravar_ou_validar(diagnostico, arquivo_diag, "csv")
      }
      message("INF02/E01 | UF=", uf,
        " | municipios calculados=", nrow(b),
        " | esperados=", n_esperado,
        " | primeiro duplicado=", n_duplicados,
        " | areas IBGE invalidas=", sum(falha_area_ibge),
        " | areas BHO invalidas=", sum(falha_area_bho),
        " | municipios com excesso acima do limite=", sum(falha_excesso))
      message("INF02/E01 | Maiores excessos (m2), incluindo resultados validos:")
      print(head(diagnostico[, .(
        cod_mun, nm_mun, area_municipal_km2,
        area_bho_somada_km2, excesso_area_m2,
        limite_excesso_m2, falha_excesso_limite)], 12L), digits = 12)
      .inf02_e01_assert(FALSE,
        paste0("Agregacao municipal inconsistente em UF ", uf,
          ". Diagnostico persistido: ", arquivo_diag))
    }
    data.table::setorder(b, cod_mun)
    b[]
  }

  processar_uf <- function(uf) {
    m <- municipios_eq[municipios_eq$uf == uf, ]
    .inf02_e01_assert(nrow(m) > 0L &&
                        data.table::uniqueN(m$cod_mun) == nrow(m),
                      paste0("Municipios da UF indisponiveis: ", uf))
    dir_uf <- file.path(dir_check, paste0("UF_", uf))
    dir.create(dir_uf, recursive = TRUE, showWarnings = FALSE)
    # Envelope em CRS da BHO: densificar antes da transformacao.
    envelope <- sf::st_as_sfc(sf::st_bbox(m))
    envelope <- sf::st_segmentize(envelope, dfMaxLength = 5000)
    envelope <- sf::st_transform(envelope, crs_bho)
    bb <- sf::st_bbox(envelope)
    ids <- DBI::dbGetQuery(con, consulta_rtree, params = list(
      as.numeric(bb[["xmax"]]) + 1e-4,
      as.numeric(bb[["xmin"]]) - 1e-4,
      as.numeric(bb[["ymax"]]) + 1e-4,
      as.numeric(bb[["ymin"]]) - 1e-4))$fid
    ids <- sort(unique(as.integer(ids[ids %in% mapa$fid])))
    inicios <- if (length(ids)) seq.int(1L, length(ids), by = tamanho_bloco)
               else integer()
    arquivos <- file.path(dir_uf, sprintf("bloco_%04d.rds",
                                             seq_along(inicios)))
    message(sprintf("INF02/E01 | UF=%s | municipios=%d | bbox=%d | blocos=%d",
                    uf, nrow(m), length(ids), length(inicios)))
    for (k in seq_along(inicios)) {
      lo <- inicios[[k]]
      hi <- min(length(ids), lo + tamanho_bloco - 1L)
      fids <- ids[lo:hi]
      arq <- arquivos[[k]]
      if (file.exists(arq)) {
        ck <- readRDS(arq)
        .inf02_e01_assert(is.list(ck) &&
                            all(c("identidade", "uf", "bloco", "fids", "pares") %in%
                                names(ck)) &&
                            .inf02_e01_identidade_compativel(ck$identidade, identidade) &&
                            identical(ck$uf, uf) &&
                            identical(ck$bloco, as.integer(k)) &&
                            identical(as.integer(ck$fids), as.integer(fids)) &&
                            identical(names(ck$pares), names(vazio())) &&
                            !anyDuplicated(ck$pares, by = c("cod_mun", "cotrecho")) &&
                            all(ck$pares$uf == uf) &&
                            all(ck$pares$cod_mun %in% m$cod_mun) &&
                            all(ck$pares$fid %in% fids) &&
                            all(ck$pares$cotrecho %in%
                                  mapa$cotrecho[match(fids, mapa$fid)]) &&
                            all(is.finite(ck$pares$area_intersecao_km2)) &&
                            all(ck$pares$area_intersecao_km2 > 0) &&
                            all(is.finite(ck$pares$fracao_bho_integral)),
                          paste0("Checkpoint divergente: ", arq))
      } else {
        pares <- calcular_bloco(fids, uf, m)
        ck <- list(identidade = identidade, uf = uf,
                   bloco = as.integer(k), fids = fids, pares = pares)
        .inf02_e01_gravar_rds(ck, arq)
        rm(pares, ck)
      }
      if (k == 1L || k %% 15L == 0L || k == length(inicios)) {
        message(sprintf("INF02/E01 | UF=%s | blocos %d/%d", uf, k,
                        length(inicios)))
      }
      if (k %% 15L == 0L) invisible(gc(verbose = FALSE))
    }
    pares <- if (length(arquivos)) {
      data.table::rbindlist(lapply(arquivos, function(x) readRDS(x)$pares),
                            use.names = TRUE)
    } else vazio()
    .inf02_e01_assert(!anyDuplicated(pares, by = c("cod_mun", "cotrecho")) &&
                        all(pares$uf == uf) &&
                        all(pares$cod_mun %in% m$cod_mun),
                      paste0("Pares repetidos/incorretos na UF ", uf))
    todas_unidades <- consolidar_municipios(uf, m, pares, dir_uf)
    qmunicipios <- todas_unidades[tipo_territorio == "unidade_municipal"]
    qoperacionais <- todas_unidades[tipo_territorio == "area_operacional"]
    area_bho <- sum(pares$area_intersecao_km2)
    # data.table prioriza nomes de coluna dentro de i: nunca comparar
    # qa_uf_ref$uf == uf, pois 'uf' seria a propria coluna da tabela.
    uf_consulta <- as.character(uf)
    ref_uf <- qa_uf_ref[uf == uf_consulta]
    .inf02_e01_assert(nrow(ref_uf) == 1L,
                      paste0("Referencial 19B: esperada uma linha para ",
                             uf_consulta, "; encontradas ", nrow(ref_uf)))
    delta_area <- area_bho - ref_uf$soma_area_bho_uf_km2[[1L]]
    q_pares <- sum(pares$q_inc_parcela_estimada_m3s, na.rm = TRUE)
    q_unidades <- sum(todas_unidades$q_inc_parcial_estimada_m3s, na.rm = TRUE)
    q_municipios <- sum(qmunicipios$q_inc_parcial_estimada_m3s, na.rm = TRUE)
    q_operacionais <- sum(qoperacionais$q_inc_parcial_estimada_m3s, na.rm = TRUE)
    .inf02_e01_assert(abs(q_pares - q_unidades) < 1e-7 &&
                        abs(q_pares - q_municipios - q_operacionais) < 1e-7,
                      paste0("Nao conservacao de vazao agregada em UF ", uf))
    # Diagnostico: diferencas maiores que 0.01km2 em relacao ao balanço 19B
    # ficam explicitadas; nao se substitui a area das geometrias.
    qa <- data.table::data.table(
      uf = uf,
      n_municipios = nrow(qmunicipios),
      n_areas_operacionais = nrow(qoperacionais),
      n_pares_unidade_ibge_bho = nrow(pares),
      area_municipios_ibge_km2 = sum(qmunicipios$area_municipal_km2),
      area_operacional_ibge_km2 = sum(qoperacionais$area_municipal_km2),
      area_bho_nas_unidades_ibge_km2 = area_bho,
      area_bho_referencia_19b_km2 = ref_uf$soma_area_bho_uf_km2[[1L]],
      delta_area_uf_vs_19b_km2 = delta_area,
      conciliacao_area_ate_0_01km2 = abs(delta_area) <= 0.01,
      q_inc_pares_estimada_m3s = q_pares,
      q_inc_municipios_estimada_m3s = q_municipios,
      q_inc_operacionais_estimada_m3s = q_operacionais,
      n_municipios_com_fonte_nao_estimada =
        sum(qmunicipios$n_bho_nao_estimadas > 0L),
      n_municipios_com_area_extra_sem_ana =
        sum(qmunicipios$area_bho_extra_sem_ana_km2 > 1e-6),
      n_municipios_sem_contribuicao_estimada =
        sum(is.na(qmunicipios$q_inc_parcial_estimada_m3s)))
    res <- list(identidade = identidade, uf = uf,
                pares = pares, municipios = qmunicipios,
                areas_operacionais = qoperacionais, qa = qa)
    arq_uf <- file.path(dir_uf, paste0("INF02_E01_", uf, ".rds"))
    if (file.exists(arq_uf)) {
      anterior <- readRDS(arq_uf)
      .inf02_e01_assert(.inf02_e01_identidade_compativel(anterior$identidade, identidade) &&
                        isTRUE(all.equal(anterior$pares, pares,
                          tolerance = 1e-9, check.attributes = FALSE)) &&
                        isTRUE(all.equal(anterior$municipios, qmunicipios,
                          tolerance = 1e-9, check.attributes = FALSE)) &&
                        isTRUE(all.equal(anterior$areas_operacionais, qoperacionais,
                          tolerance = 1e-9, check.attributes = FALSE)),
                        paste0("Consolidacao UF existente divergente: ", arq_uf))
    } else {
      .inf02_e01_gravar_rds(res, arq_uf)
    }
    message(sprintf(
      "INF02/E01 | UF=%s | pares=%d | Q estimada=%.5f m3/s | delta area 19B=%.6f km2",
      uf, nrow(pares), q_pares, delta_area))
    invisible(qa)
  }

  if (modo == "uf") return(invisible(processar_uf(uf_alvo)))

  for (uf in unname(.inf02_e01_ufs_ibge)) {
    processar_uf(uf)
    invisible(gc(verbose = FALSE))
  }

  saidas_uf <- file.path(dir_check, paste0("UF_",
                   unname(.inf02_e01_ufs_ibge)),
                   paste0("INF02_E01_", unname(.inf02_e01_ufs_ibge), ".rds"))
  .inf02_e01_assert(all(file.exists(saidas_uf)),
                    "Consolidacao nacional incompleta: falta UF")
  nacional <- lapply(saidas_uf, readRDS)
  .inf02_e01_assert(all(vapply(nacional, function(x)
    .inf02_e01_identidade_compativel(x$identidade, identidade), logical(1))),
    "Assinatura dos checkpoints de UF divergente")
  municipal <- data.table::rbindlist(lapply(nacional, `[[`, "municipios"),
                                     use.names = TRUE)
  areas_operacionais <- data.table::rbindlist(
    lapply(nacional, `[[`, "areas_operacionais"), use.names = TRUE)
  pares <- data.table::rbindlist(lapply(nacional, `[[`, "pares"),
                                 use.names = TRUE)
  pares_municipais <- pares[cod_mun %in% municipal$cod_mun]
  pares_operacionais <- pares[cod_mun %in% areas_operacionais$cod_mun]
  qa_uf <- data.table::rbindlist(lapply(nacional, `[[`, "qa"),
                                 use.names = TRUE)
  data.table::setorder(municipal, cod_mun)
  data.table::setorder(areas_operacionais, cod_mun)
  data.table::setorder(pares, cod_mun, cotrecho)
  data.table::setorder(pares_municipais, cod_mun, cotrecho)
  data.table::setorder(pares_operacionais, cod_mun, cotrecho)
  data.table::setorder(qa_uf, uf)
  .inf02_e01_assert(nrow(municipal) == 5571L &&
                      data.table::uniqueN(municipal$cod_mun) == 5571L &&
                      nrow(areas_operacionais) == esperado_operacional &&
                      !anyDuplicated(pares, by = c("cod_mun", "cotrecho")) &&
                      nrow(pares_municipais) + nrow(pares_operacionais) == nrow(pares) &&
                      nrow(qa_uf) == 27L,
                    "Consolidacao nacional: cardinalidade inesperada")
  q_reconst_pares <- sum(pares$q_inc_parcela_estimada_m3s, na.rm = TRUE)
  q_municip <- sum(municipal$q_inc_parcial_estimada_m3s, na.rm = TRUE)
  q_operacionais <- sum(areas_operacionais$q_inc_parcial_estimada_m3s,
                         na.rm = TRUE)
  .inf02_e01_assert(abs(q_municip + q_operacionais - q_reconst_pares) < 1e-6,
                    "Nao conservacao de Q entre pares, municipios e areas operacionais")

  idx <- match(pares$cotrecho, meta$cotrecho)
  reparticao <- pares[, .(area_municipalizada_km2 =
                          sum(area_intersecao_km2)), by = cotrecho]
  idxr <- match(reparticao$cotrecho, meta$cotrecho)
  .inf02_e01_assert(!anyNA(idx) && !anyNA(idxr), "Cotrecho nao encontrado")
  q_ref_territorial <- sum(
    meta$Qmltinc_soma_sem_lacuna[
      meta$situacao_fonte == "ana_estimada"] *
    meta$area_brasil_km2[meta$situacao_fonte == "ana_estimada"] /
    meta$area_geometrica_km2[meta$situacao_fonte == "ana_estimada"])
  delta_q_territorial <- q_municip + q_operacionais - q_ref_territorial
  area_bho_reconst <- sum(pares$area_intersecao_km2)
  area_bho_ref <- qa_br_ref$soma_areas_bho_dentro_brasil_km2[[1L]]
  delta_area <- area_bho_reconst - area_bho_ref
  qa_nac <- data.table::data.table(
    n_municipios = nrow(municipal),
    n_areas_operacionais = nrow(areas_operacionais),
    n_ufs = nrow(qa_uf),
    n_pares = nrow(pares),
    area_municipios_ibge_km2 = sum(municipal$area_municipal_km2),
    area_operacionais_ibge_km2 =
      sum(areas_operacionais$area_municipal_km2),
    area_brasil_referencia_19a_km2 =
      qa_br_ref$area_brasil_IBGE_2025_km2[[1L]],
    delta_area_unidades_ibge_menos_brasil_km2 =
      sum(municipal$area_municipal_km2) +
      sum(areas_operacionais$area_municipal_km2) -
      qa_br_ref$area_brasil_IBGE_2025_km2[[1L]],
    q_inc_estimada_municipal_m3s = q_municip,
    q_inc_estimada_area_operacional_m3s = q_operacionais,
    q_inc_estimada_repartida_m3s = q_municip + q_operacionais,
    q_inc_referencia_area_brasil_m3s = q_ref_territorial,
    delta_q_repartida_menos_referencia_m3s = delta_q_territorial,
    q_pares_menos_q_unidades_m3s = q_reconst_pares - q_municip - q_operacionais,
    area_bho_nas_unidades_ibge_km2 = area_bho_reconst,
    area_bho_nos_municipios_km2 =
      sum(pares_municipais$area_intersecao_km2),
    area_bho_nas_operacionais_km2 =
      sum(pares_operacionais$area_intersecao_km2),
    area_bho_referencia_19a_km2 = area_bho_ref,
    delta_area_municipalizada_menos_19a_km2 = delta_area,
    municipios_com_q_na = sum(is.na(municipal$q_inc_parcial_estimada_m3s)),
    municipios_com_fonte_nao_estimada =
      sum(municipal$n_bho_nao_estimadas > 0),
    municipios_com_area_extra_sem_ana =
      sum(municipal$area_bho_extra_sem_ana_km2 > 1e-6),
    pct_area_coberta_por_bho = 100 *
      area_bho_reconst / (sum(municipal$area_municipal_km2) +
                            sum(areas_operacionais$area_municipal_km2)),
    qa_conciliacao_area_ate_0_01km2 = abs(delta_area) <= 0.01,
    qa_conciliacao_unidades_ibge_brasil_ate_0_01km2 =
      abs(sum(municipal$area_municipal_km2) +
          sum(areas_operacionais$area_municipal_km2) -
          qa_br_ref$area_brasil_IBGE_2025_km2[[1L]]) <= 0.01,
    qa_conciliacao_q_ate_0_01m3s = abs(delta_q_territorial) <= 0.01
  )

  # Divergencias materiais de area/vazao invalidam a conclusao nacional.
  # Os checkpoints de UF continuam preservados para diagnostico dirigido.
  .inf02_e01_assert(
    isTRUE(qa_nac$qa_conciliacao_area_ate_0_01km2) &&
      isTRUE(qa_nac$qa_conciliacao_unidades_ibge_brasil_ate_0_01km2) &&
      isTRUE(qa_nac$qa_conciliacao_q_ate_0_01m3s),
    paste0("Conciliacao nacional acima da tolerancia: delta A=",
      format(delta_area, digits = 10), " km2; delta Q=",
      format(delta_q_territorial, digits = 10),
      " m3/s. Checkpoints preservados; investigar sem reprocessar todas as UFs."))

  # Produtos municipais e registro separado das areas nao municipais.
  # Nenhuma etapa demografica e executada.
  arquivo_mun_rds <- file.path(dir_saida,
    "INF02_E01_contribuicao_incremental_municipal_IBGE2025.rds")
  arquivo_mun_csv <- sub("[.]rds$", ".csv", arquivo_mun_rds)
  arquivo_pares <- file.path(dir_saida,
    "INF02_E01_correspondencia_municipio_BHO50K_IBGE2025.rds")
  arquivo_operacionais <- file.path(dir_saida,
    "INF02_E01_areas_operacionais_RS_IBGE2025.rds")
  arquivo_pares_operacionais <- file.path(dir_saida,
    "INF02_E01_correspondencia_areas_operacionais_RS_BHO50K.rds")
  arquivo_qa_uf <- file.path(dir_saida, "INF02_E01_qa_ufs.csv")
  arquivo_qa_br <- file.path(dir_saida, "INF02_E01_qa_nacional.csv")
  .inf02_e01_gravar_ou_validar(as.data.frame(municipal), arquivo_mun_rds, "rds")
  # CSV so de atributos, separador ; igual ao padrao INF01 do repositorio.
  if (file.exists(arquivo_mun_csv)) {
    existente <- data.table::fread(arquivo_mun_csv, sep = ";",
      colClasses = list(character = c("uf", "cod_mun", "nm_mun")),
      showProgress = FALSE)
    alvo <- data.table::copy(municipal)
    .inf02_e01_assert(identical(names(existente), names(alvo)) &&
       identical(existente$cod_mun, alvo$cod_mun) &&
       identical(existente$situacao_qualidade, alvo$situacao_qualidade) &&
       isTRUE(all.equal(as.data.frame(existente), as.data.frame(alvo),
                        tolerance = 1e-9, check.attributes = FALSE)),
       "CSV municipal ja existente diverge")
  } else {
    temporario <- paste0(arquivo_mun_csv, ".parcial")
    .inf02_e01_assert(!file.exists(temporario), "CSV parcial existente")
    data.table::fwrite(municipal, temporario, sep = ";", dec = ".", na = "")
    .inf02_e01_assert(file.rename(temporario, arquivo_mun_csv),
                      "Falha de gravacao do CSV municipal")
  }
  .inf02_e01_gravar_ou_validar(as.data.frame(pares_municipais),
                               arquivo_pares, "rds")
  .inf02_e01_gravar_ou_validar(as.data.frame(areas_operacionais),
                               arquivo_operacionais, "rds")
  .inf02_e01_gravar_ou_validar(as.data.frame(pares_operacionais),
                               arquivo_pares_operacionais, "rds")
  # Relatorios CSV usam o separador ; e contem exclusivamente numeros/UF.
  .inf02_e01_gravar_ou_validar(qa_uf, arquivo_qa_uf, "csv")
  .inf02_e01_gravar_ou_validar(qa_nac, arquivo_qa_br, "csv")

  message(sprintf(paste0("INF02/E01 | CONCLUIDA | %d unidades municipais, ",
                          "%d operacionais | Q municipal estimada=%.6f m3/s"),
                  nrow(municipal), nrow(areas_operacionais), q_municip))
  invisible(list(municipal_csv = arquivo_mun_csv,
                 municipal_rds = arquivo_mun_rds,
                 correspondencia_rds = arquivo_pares,
                 areas_operacionais_rds = arquivo_operacionais,
                 correspondencia_operacional_rds = arquivo_pares_operacionais,
                 qa_ufs_csv = arquivo_qa_uf,
                 qa_nacional_csv = arquivo_qa_br))
}
