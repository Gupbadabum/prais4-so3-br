# PRAIS4 / SO3.3 / INF02 / ETAPA 02
# Populacao censitaria TOTAL (2000/2010/2022) + base municipal hidrologica 2025.
# Associacao por codigo: resultado INTERMEDIARIO; nao certifica geometria historica.
# Sem atribuicao populacional por sexo; sem calculo per capita definitivo.
# Nao modifica produtos da Etapa 01 nem o main.R.

# Interface de leitura e verificacao da fonte SIDRA.
# Carregada no mesmo ambiente do processador.
source("so3.3/R/01_leitura/ler_populacao_censitaria_inf02.R")

.inf02_e02_salvar_sem_sobrescrever <- function(objeto, arquivo, tipo = "rds") {
  dir.create(dirname(arquivo), recursive = TRUE, showWarnings = FALSE)
  temp <- tempfile(pattern = ".inf02_e02_", tmpdir = dirname(arquivo),
                   fileext = paste0(".", tipo))
  on.exit(if (file.exists(temp)) unlink(temp), add = TRUE)
  if (tipo == "rds") {
    saveRDS(objeto, temp, version = 3L)
    if (file.exists(arquivo)) {
      anterior <- readRDS(arquivo)
      .inf02_e02_exigir(isTRUE(all.equal(anterior, objeto,
                       tolerance = 1e-12, check.attributes = FALSE)),
        paste0("produto RDS existente diverge; nao sobrescrevendo: ", arquivo))
      return(invisible(arquivo))
    }
  } else {
    data.table::fwrite(objeto, temp, sep = ";", dec = ".", na = "")
    if (file.exists(arquivo)) {
      .inf02_e02_exigir(
        identical(unname(tools::md5sum(temp)),
                  unname(tools::md5sum(arquivo))),
        paste0("produto CSV existente diverge; nao sobrescrevendo: ", arquivo))
      return(invisible(arquivo))
    }
  }
  .inf02_e02_exigir(file.rename(temp, arquivo),
                    paste0("nao foi possivel salvar: ", arquivo))
  invisible(arquivo)
}

processar_inf02_etapa02 <- function(
  anos = c(2000L, 2010L, 2022L),
  arquivo_hidrologico = file.path(
    "so3.3", "outputs", "intermediario", "infraestrutural",
    "inf02", "etapa01",
    "INF02_E01_contribuicao_incremental_municipal_IBGE2025.rds"),
  dir_fontes = file.path("so3.3", "inputs", "referencias", "ibge",
                         "populacao_censitaria_inf02"),
  dir_saida = file.path("so3.3", "outputs", "intermediario",
                        "infraestrutural", "inf02", "etapa02")) {

  for (pkg in c("data.table", "jsonlite")) {
    .inf02_e02_exigir(requireNamespace(pkg, quietly = TRUE),
      paste0("pacote obrigatorio indisponivel: ", pkg))
  }
  anos <- sort(unique(as.integer(anos)))
  .inf02_e02_exigir(length(anos) > 0L && !anyNA(anos) &&
    all(anos %in% c(2000L, 2010L, 2022L)),
    "anos devem ser 2000, 2010 e/ou 2022")
  .inf02_e02_exigir(file.exists(arquivo_hidrologico),
    paste0("Etapa 01 nao encontrada: ", arquivo_hidrologico))

  h <- data.table::as.data.table(readRDS(arquivo_hidrologico))
  requeridos <- c("cod_mun", "uf", "nm_mun", "tipo_territorio",
    "q_inc_parcial_estimada_m3s", "situacao_qualidade",
    "cobertura_bho_pct", "cobertura_ana_estimada_pct",
    "n_bho_nao_estimadas", "area_sem_bho_km2")
  .inf02_e02_exigir(all(requeridos %in% names(h)),
                    "campos obrigatorios ausentes na Etapa 01")
  .inf02_e02_exigir(nrow(h) == 5571L && !anyDuplicated(h$cod_mun) &&
    all(grepl("^[0-9]{7}$", h$cod_mun)) &&
    all(h$tipo_territorio == "unidade_municipal"),
    "Etapa 01: cardinalidade ou identificadores inconsistentes")
  hidrologico_md5 <- unname(tools::md5sum(arquivo_hidrologico))
  h <- h[, ..requeridos]
  data.table::setorder(h, cod_mun)

  dir.create(dir_saida, recursive = TRUE, showWarnings = FALSE)

  caminhos <- list()
  for (ano_proc in anos) {
    origem <- ler_populacao_censitaria_inf02(ano_proc, dir_fontes)
    p <- data.table::copy(origem$dados)

    # Comparar as chaves antes da juncao. A comparacao e apenas nominal.
    nao_na_malha <- p[!cod_mun %in% h$cod_mun]
    sem_censo <- h[!cod_mun %in% p$cod_mun,
      .(ano = as.integer(ano_proc), uf, cod_mun, nm_mun)]
    sem_origem <- nao_na_malha[, .(ano, cod_mun, populacao_total_censo)]

    associacao <- merge(
      data.table::copy(h),
      p[, .(cod_mun, populacao_total_censo)],
      by = "cod_mun", all.x = TRUE, sort = FALSE)
    associacao[, ano := as.integer(ano_proc)]
    associacao[, tabela_sidra := as.integer(origem$tabela)]
    associacao[, tipo_desagregacao := "compartilhada"]
    associacao[, status_correspondencia := data.table::fifelse(
      is.na(populacao_total_censo),
      "SEM_POPULACAO_NO_CODIGO_IBGE2025",
      "CODIGO_COINCIDENTE_NAO_HARMONIZADO")]

    # Casos particularmente conhecidos: BEN (2025) desmembrado de
    # Sorriso e Nova Ubirata. A coincidencia dos codigos dos municipios
    # de origem nao comprova que seus territorios sejam os de 2025.
    no_mt <- associacao$uf == "MT"
    nome_ascii <- toupper(iconv(associacao$nm_mun,
                               from = "", to = "ASCII//TRANSLIT"))
    afetados_ben <- no_mt & !is.na(nome_ascii) &
      nome_ascii %in% c("SORRISO", "NOVA UBIRATA")
    associacao[afetados_ben & !is.na(populacao_total_censo),
      status_correspondencia :=
        "CODIGO_COINCIDENTE_DIVISAO_TERRITORIAL_ALTERADA_2025"]

    data.table::setcolorder(associacao, c("ano", "cod_mun", "uf", "nm_mun",
      "populacao_total_censo", "tabela_sidra", "tipo_desagregacao",
      "status_correspondencia", setdiff(names(associacao),
      c("ano", "cod_mun", "uf", "nm_mun", "populacao_total_censo",
        "tabela_sidra", "tipo_desagregacao", "status_correspondencia"))))
    data.table::setorder(associacao, cod_mun)

    .inf02_e02_exigir(nrow(associacao) == 5571L &&
        !anyDuplicated(associacao$cod_mun),
      paste0("associacao incompleta ou duplicada: ", ano_proc))
    .inf02_e02_exigir(sum(!is.na(associacao$populacao_total_censo)) ==
        nrow(p) - nrow(nao_na_malha),
      paste0("nao conservacao dos correspondentes por codigo: ", ano_proc))
    .inf02_e02_exigir(sum(associacao$populacao_total_censo, na.rm = TRUE) +
        sum(nao_na_malha$populacao_total_censo) ==
        origem$populacao_brasil,
      paste0("populacao da fonte nao conservada: ", ano_proc))

    qa <- data.table::data.table(
      ano = as.integer(ano_proc),
      tabela_sidra = as.integer(origem$tabela),
      n_populacao_origem = nrow(p),
      soma_populacao_origem = origem$populacao_brasil,
      n_unidades_ibge2025 = nrow(associacao),
      n_codigos_coincidentes = sum(!is.na(associacao$populacao_total_censo)),
      n_sem_populacao_no_codigo2025 = nrow(sem_censo),
      n_codigos_origem_fora_2025 = nrow(sem_origem),
      n_afetados_boa_esperanca_norte = sum(afetados_ben),
      n_sem_q_estimada = sum(is.na(associacao$q_inc_parcial_estimada_m3s)),
      fonte_md5 = origem$md5,
      hidrologia_e01_md5 = hidrologico_md5,
      status = "ASSOCIACAO_PRELIMINAR_SEM_HARMONIZACAO_TERRITORIAL")

    stem <- file.path(dir_saida, paste0("INF02_E02_", ano_proc))
    arq_assoc <- paste0(stem, "_associacao_preliminar_IBGE2025.rds")
    arq_csv <- sub("[.]rds$", ".csv", arq_assoc)
    arq_qa <- paste0(stem, "_qa.csv")
    arq_sem_censo <- paste0(stem, "_codigos_2025_sem_censo.csv")
    arq_sem_origem <- paste0(stem, "_codigos_censo_fora_2025.csv")

    .inf02_e02_salvar_sem_sobrescrever(as.data.frame(associacao), arq_assoc)
    .inf02_e02_salvar_sem_sobrescrever(associacao, arq_csv, tipo = "csv")
    .inf02_e02_salvar_sem_sobrescrever(qa, arq_qa, tipo = "csv")
    .inf02_e02_salvar_sem_sobrescrever(sem_censo, arq_sem_censo,
                                      tipo = "csv")
    .inf02_e02_salvar_sem_sobrescrever(sem_origem, arq_sem_origem,
                                      tipo = "csv")

    message(sprintf(
      "INF02/E02 | %d: origem=%d | relacionados=%d/5571 | sem codigo=%d",
      ano_proc, nrow(p), qa$n_codigos_coincidentes,
      qa$n_sem_populacao_no_codigo2025))
    caminhos[[as.character(ano_proc)]] <- list(
      associacao = arq_assoc, csv = arq_csv, qa = arq_qa,
      codigos_ausentes = arq_sem_censo, codigos_fora_2025 = arq_sem_origem)
  }
  message("INF02/E02 | Associacao censitaria preliminar concluida; ",
          "nenhum INF02 per capita foi promovido a bruto.")
  invisible(caminhos)
}
