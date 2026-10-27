# ============================================================================
# PRAIS4 / SO3.3 - Processador independente do INF01
# ============================================================================
# V1: apenas 2000, ja validado nos Testes 01-07.
# Modo padrao: validar e salvar checkpoints agregados, SEM promover a bruto.
# Uma UF por vez em RAM; checkpoints RDS sem microdados individuais.
# 2010 e 2022 exigirao adaptadores proprios antes de serem habilitados.
# Este arquivo NAO altera o dispatcher main.R.
# ============================================================================

.infra_inf01_salvar_novo_rds <- function(objeto, arquivo) {
  if (file.exists(arquivo)) {
    stop("INF01: sobrescrita proibida: ", arquivo)
  }
  dir.create(dirname(arquivo), recursive = TRUE, showWarnings = FALSE)
  tmp <- tempfile(pattern = ".inf01_", tmpdir = dirname(arquivo),
                  fileext = ".rds")
  on.exit(if (file.exists(tmp)) unlink(tmp), add = TRUE)
  saveRDS(objeto, file = tmp, version = 3L)
  if (!file.rename(tmp, arquivo)) {
    stop("INF01: falha ao salvar atomicamente: ", arquivo)
  }
  invisible(arquivo)
}

.infra_inf01_conferir_existente <- function(existente, atual, rotulo) {
  if (!isTRUE(all.equal(existente, atual, tolerance = 1e-12,
                        check.attributes = FALSE))) {
    stop("INF01: produto existente diverge do calculo validado: ", rotulo,
         ". Nenhuma sobrescrita foi realizada.")
  }
  invisible(TRUE)
}

processar_inf01 <- function(ano, promover = FALSE,
                           forcar_recalculo = FALSE,
                           showProgress = TRUE) {
  if (length(ano) != 1L || !is.numeric(ano) || is.na(ano) ||
      !is.finite(ano) || ano != floor(ano) ||
      !ano %in% c(2000L, 2010L, 2022L)) {
    stop("INF01: use ano 2000, 2010 ou 2022.")
  }
  ano <- as.integer(ano)
  if (ano != 2000L) {
    stop("INF01/", ano, ": adaptador ainda nao validado. ",
         "A execucao desta versao esta restrita a 2000.")
  }
  if (!identical(promover, TRUE) && !identical(promover, FALSE)) {
    stop("INF01: promover deve ser TRUE ou FALSE.")
  }
  if (!identical(forcar_recalculo, FALSE)) {
    stop("INF01: reprocessamento destrutivo proibido neste processador. ",
         "Arquive explicitamente checkpoints antigos apos auditoria.")
  }
  if (!exists("DIR_OUTPUT_BRUTO", inherits = TRUE) ||
      !exists("DIR_OUTPUT_INTERMEDIARIO", inherits = TRUE)) {
    stop("INF01: execute source('so3.3/config/config.R') antes.")
  }
  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("INF01: pacote data.table requerido.")
  }

  modulos <- file.path("so3.3", "R", c(
    "01_leitura/adaptar_censo_2000_infraestrutural.R",
    "02_indicadores/inf01_agua_rede_canalizada.R",
    "03_diagnostico/validar_inf01.R",
    "05_exportacao/exportar_inf01_bruto_csv.R"
  ))
  if (!all(file.exists(modulos))) {
    stop("INF01: modulos ausentes: ",
         paste(modulos[!file.exists(modulos)], collapse = ", "))
  }
  # Apenas leitura, calculo e QA afetam checkpoints do indicador.
  # Mudancas futuras no formato de exportacao nao os invalidam.
  assinatura <- tools::md5sum(modulos[1:3])
  for (arq in modulos) source(arq, local = TRUE)

  base <- file.path(DIR_OUTPUT_INTERMEDIARIO, "infraestrutural",
                    "2000", "inf01")
  dir_uf <- file.path(base, "ufs")
  dir.create(dir_uf, recursive = TRUE, showWarnings = FALSE)
  ufs <- .infra_inf01_ufs
  saidas <- vector("list", length(ufs))
  base_arrow <- NULL

  for (i in seq_along(ufs)) {
    uf <- ufs[[i]]
    uf_chr <- sprintf("%02d", uf)
    arq <- file.path(dir_uf, paste0("uf", uf_chr, ".rds"))
    if (file.exists(arq)) {
      ck <- readRDS(arq)
      if (!is.list(ck) ||
          !all(c("resultados", "auditoria", "assinatura") %in% names(ck)) ||
          !identical(ck$assinatura, assinatura)) {
        stop("INF01/2000: checkpoint da UF ", uf_chr,
             " tem estrutura ou assinatura de codigo diferente. ",
             "Revisar antes de reutilizar; nao foi sobrescrito.")
      }
      origem <- "reutilizado_validado"
    } else {
      if (is.null(base_arrow)) {
        message("INF01/2000 | Abrindo censobr (Domicilios, Arrow)...")
        base_arrow <- abrir_censo_2000_infraestrutural(showProgress)
      }
      message("INF01/2000 | Calculando UF ", uf_chr, "...")
      dados <- coletar_censo_2000_infraestrutural_uf(base_arrow, uf)
      canonico <- adaptar_censo_2000_infraestrutural_uf(dados, uf)
      calculado <- calcular_inf01_domicilios(canonico)
      validar_inf01_uf(calculado$resultados, calculado$auditoria,
                       ano = 2000L, uf = uf)
      ck <- list(resultados = calculado$resultados,
                 auditoria = calculado$auditoria,
                 assinatura = assinatura,
                 ano = 2000L, uf = uf_chr)
      .infra_inf01_salvar_novo_rds(ck, arq)
      rm(dados, canonico, calculado)
      invisible(gc(verbose = FALSE))
      origem <- "processado_validado"
    }
    validar_inf01_uf(ck$resultados, ck$auditoria, 2000L, uf)
    saidas[[i]] <- ck
    message("INF01/2000 | UF ", uf_chr, ": ",
            data.table::uniqueN(ck$auditoria$cod_mun),
            " municipios; ", origem)
    rm(ck)
  }
  if (!is.null(base_arrow)) rm(base_arrow)
  invisible(gc(verbose = FALSE))

  r <- data.table::rbindlist(lapply(saidas, `[[`, "resultados"),
                             use.names = TRUE)
  a <- data.table::rbindlist(lapply(saidas, `[[`, "auditoria"),
                             use.names = TRUE)
  r[, ord_grupo := match(grupo, c("Total", "Masculino", "Feminino"))]
  data.table::setorder(r, cod_mun, ord_grupo)
  r[, ord_grupo := NULL]
  data.table::setorder(a, cod_mun)
  rm(saidas)
  invisible(gc(verbose = FALSE))

  message("INF01/2000 | Validando contra Testes 05, 06, 07 e SIDRA...")
  qa <- validar_inf01_2000_nacional(r, a)
  arq_validado <- file.path(base, "INF01_REDE_CANALIZADA_2000_validado.rds")
  validado <- list(resultados = r, auditoria = a, qa = qa,
                  assinatura = assinatura,
                  fonte = "censobr 2000 / amostra domiciliar / DPP")
  if (file.exists(arq_validado)) {
    anterior <- readRDS(arq_validado)
    .infra_inf01_conferir_existente(anterior, validado,
                                  "checkpoint nacional")
  } else {
    .infra_inf01_salvar_novo_rds(validado, arq_validado)
  }

  status <- "intermediario_validado_sem_promocao"
  arq_rds <- file.path(DIR_OUTPUT_BRUTO, "infraestrutural", "2000",
                       "INF01_REDE_CANALIZADA_2000.rds")
  arq_csv <- sub("[.]rds$", ".csv", arq_rds)
  if (promover) {
    publicado <- preparar_inf01_bruto_csv(r)
    if (xor(file.exists(arq_rds), file.exists(arq_csv))) {
      stop("INF01: produto bruto parcial (RDS sem CSV, ou vice-versa). ",
           "Nao reescrever sem auditoria.")
    }
    if (file.exists(arq_rds)) {
      .infra_inf01_conferir_existente(readRDS(arq_rds), r, "RDS bruto")
      relido <- data.table::fread(arq_csv, sep = ";",
        colClasses = list(character = c("uf", "cod_mun")),
        encoding = "UTF-8", showProgress = FALSE)
      if (!identical(names(relido), names(publicado)) ||
          !identical(relido$cod_mun, publicado$cod_mun) ||
          !identical(relido$grupo, publicado$grupo) ||
          !identical(relido$nm_mun, publicado$nm_mun) ||
          !.infra_inf01_aprox(relido$valor, publicado$valor, 1e-10)) {
        stop("INF01: CSV bruto existente diverge; nao sobrescrevendo.")
      }
      status <- "bruto_reutilizado_validado"
    } else {
      dir.create(dirname(arq_rds), recursive = TRUE, showWarnings = FALSE)
      tmp_rds <- tempfile(pattern = ".inf01_", tmpdir = dirname(arq_rds),
                          fileext = ".rds")
      tmp_csv <- tempfile(pattern = ".inf01_", tmpdir = dirname(arq_csv),
                          fileext = ".csv")
      on.exit({
        if (file.exists(tmp_rds)) unlink(tmp_rds)
        if (file.exists(tmp_csv)) unlink(tmp_csv)
      }, add = TRUE)
      saveRDS(r, tmp_rds, version = 3L)
      data.table::fwrite(publicado, file = tmp_csv, sep = ";", dec = ".",
                         bom = FALSE, quote = "auto", na = "")
      lido <- data.table::fread(tmp_csv, sep = ";",
        colClasses = list(character = c("uf", "cod_mun")),
        encoding = "UTF-8", showProgress = FALSE)
      if (!identical(names(lido), names(publicado)) ||
          !identical(lido$cod_mun, publicado$cod_mun) ||
          !identical(lido$grupo, publicado$grupo) ||
          !identical(lido$nm_mun, publicado$nm_mun) ||
          !.infra_inf01_aprox(lido$valor, publicado$valor, 1e-10)) {
        stop("INF01: CSV temporario nao passou na releitura.")
      }
      if (!file.rename(tmp_rds, arq_rds)) {
        stop("INF01: nao foi possivel criar RDS bruto.")
      }
      if (!file.rename(tmp_csv, arq_csv)) {
        # Reverte SOMENTE o RDS criado nesta chamada, sem tocar outros dados.
        unlink(arq_rds)
        stop("INF01: nao foi possivel criar CSV bruto; escrita revertida.")
      }
      status <- "bruto_gravado_validado"
    }
  }

  message("INF01/2000 | ", status, " | 5507 municipios | 3 grupos | ",
          sprintf("%.5f%%", qa$inf01_brasil))
  invisible(list(
    indicador = "INF01_REDE_CANALIZADA",
    ano = 2000L,
    status = status,
    integral = TRUE,
    qa = qa,
    checkpoint = arq_validado,
    arquivo_bruto_rds = if (promover) arq_rds else NA_character_,
    arquivo_bruto_csv = if (promover) arq_csv else NA_character_
  ))
}
