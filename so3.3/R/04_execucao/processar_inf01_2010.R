# =============================================================================
# PRAIS4 / SO3.3 / INF01 2010 - Processador modular de producao
# =============================================================================
# Origem padrao: produtos municipais do Teste 12 NACIONAL aprovado.
# Origem opcional: microdados censobr, uma UF por vez, para reproducao.
# Ambos os modos exigem equivalencia integral com os agregados do Teste 12.
# Promocao controla integridade, conserva checkpoints e nao sobrescreve.
# Nao altera o main.R nem qualquer resultado do INF01/2000.
# =============================================================================

# Carregar os modulos no MESMO ambiente lexical deste processador.
# Assim, as funcoes auxiliares de reproducao, QA e publicacao enxergam
# as dependencias compartilhadas mesmo quando chamado por processar_inf01().
.infra_2010_modulos <- file.path("so3.3", "R", c(
  "02_indicadores/inf01_agua_rede_canalizada.R",
  "03_diagnostico/validar_inf01.R",
  "03_diagnostico/validar_inf01_2010.R",
  "05_exportacao/exportar_resultados_csv.R",
  "05_exportacao/exportar_inf01_2010_bruto_csv.R",
  "01_leitura/adaptar_censo_2010_infraestrutural.R",
  "02_indicadores/inf01_2010_pessoas.R"
))
if (!all(file.exists(.infra_2010_modulos))) {
  stop("INF01/2010: modulos ausentes: ",
       paste(.infra_2010_modulos[!file.exists(.infra_2010_modulos)],
             collapse = ", "))
}
for (.infra_2010_arquivo in .infra_2010_modulos) {
  source(.infra_2010_arquivo, local = TRUE)
}
rm(.infra_2010_arquivo)

.infra_2010_gravar_rds_novo <- function(obj, arquivo) {
  if (file.exists(arquivo)) {
    stop("INF01/2010: sobrescrita de checkpoint proibida: ", arquivo)
  }
  dir.create(dirname(arquivo), recursive = TRUE, showWarnings = FALSE)
  tmp <- tempfile(".inf01_2010_", tmpdir = dirname(arquivo),
                  fileext = ".rds")
  on.exit(if (file.exists(tmp)) unlink(tmp), add = TRUE)
  saveRDS(obj, tmp, version = 3L)
  if (!file.rename(tmp, arquivo)) {
    stop("INF01/2010: falha ao criar checkpoint: ", arquivo)
  }
  invisible(arquivo)
}

.infra_2010_conferir_objeto <- function(anterior, atual, rotulo) {
  if (!is.data.frame(anterior) || !is.data.frame(atual) ||
      !identical(names(anterior), names(atual)) ||
      nrow(anterior) != nrow(atual)) {
    stop("INF01/2010: estrutura divergente no produto existente: ", rotulo)
  }
  for (nm in names(atual)) {
    x <- anterior[[nm]]
    y <- atual[[nm]]
    if (is.numeric(x) && is.numeric(y)) {
      if (!identical(is.na(x), is.na(y)) ||
          !.infra_2010_aprox(x[!is.na(x)], y[!is.na(y)], tol = 1e-9)) {
        stop("INF01/2010: componente divergente em ", rotulo, "/", nm)
      }
    } else if (!identical(as.character(x), as.character(y))) {
      stop("INF01/2010: identificador divergente em ", rotulo, "/", nm)
    }
  }
  invisible(TRUE)
}

.infra_2010_montar_auditoria_t12 <- function(referencias) {
  x <- data.table::copy(referencias$componentes)
  seis <- c("denominador_total", "numerador_total",
            "denominador_masculino", "numerador_masculino",
            "denominador_feminino", "numerador_feminino")
  outras <- c("ano", "uf", "cod_mun", "n_dpp_amostra",
    "n_rede_geral_amostra", "n_rede_canalizada_amostra",
    "n_pessoas_dpp_amostra", "n_pessoas_rede_canalizada_amostra")
  if (any(!c(outras, paste0(seis, "_pessoas")) %in% names(x))) {
    stop("INF01/2010: componentes do Teste 12 incompletos.")
  }
  a <- x[, ..outras]
  for (nm in seis) {
    a[, (nm) := as.numeric(x[[paste0(nm, "_pessoas")]])]
  }
  data.table::setorder(a, cod_mun)
  if (anyNA(a[, ..outras]) || any(a$ano != 2010L)) {
    stop("INF01/2010: auditoria derivada do Teste 12 invalida.")
  }
  a[]
}

.infra_2010_recalcular_microdados <- function(showProgress) {
  message("INF01/2010 | Reproducao integral via censobr; uma UF por vez...")
  censo <- abrir_censo_2010_infraestrutural(showProgress = showProgress)
  saidas <- vector("list", length(.infra_inf01_2010_ufs))
  for (i in seq_along(.infra_inf01_2010_ufs)) {
    uf <- .infra_inf01_2010_ufs[[i]]
    message("INF01/2010 | Calculando UF ", sprintf("%02d", uf), "...")
    bruto <- coletar_censo_2010_infraestrutural_uf(censo, uf)
    canonico <- adaptar_censo_2010_infraestrutural_uf(bruto, uf)
    calculado <- calcular_inf01_2010_pessoas(canonico)
    validar_inf01_uf(calculado$resultados, calculado$auditoria, 2010L, uf)
    saidas[[i]] <- list(resultados = calculado$resultados,
                        auditoria = calculado$auditoria)
    rm(bruto, canonico, calculado)
    invisible(gc(verbose = FALSE))
  }
  rm(censo)
  r <- data.table::rbindlist(lapply(saidas, `[[`, "resultados"),
                             use.names = TRUE)
  a <- data.table::rbindlist(lapply(saidas, `[[`, "auditoria"),
                             use.names = TRUE)
  r[, ordem_grupo := match(grupo, c("Total", "Masculino", "Feminino"))]
  data.table::setorder(r, cod_mun, ordem_grupo)
  r[, ordem_grupo := NULL]
  data.table::setorder(a, cod_mun)
  list(resultados = r[], auditoria = a[])
}

.infra_2010_validar_csv_releitura <- function(arquivo, original) {
  lido <- data.table::fread(arquivo, sep = ";", na.strings = "NA",
    colClasses = list(character = c("uf", "cod_mun")),
    encoding = "UTF-8", showProgress = FALSE)
  .infra_2010_conferir_objeto(lido, original, "CSV de publicacao")
  invisible(TRUE)
}

.infra_2010_promover <- function(r, dir_bruto) {
  publicado <- preparar_inf01_2010_bruto_csv(r)
  pasta <- file.path(dir_bruto, "infraestrutural", "2010")
  arq_rds <- file.path(pasta, "INF01_REDE_CANALIZADA_2010.rds")
  arq_csv <- file.path(pasta, "INF01_REDE_CANALIZADA_2010.csv")
  if (xor(file.exists(arq_rds), file.exists(arq_csv))) {
    stop("INF01/2010: produto bruto parcial RDS/CSV. ",
         "Revise antes de prosseguir; nenhum arquivo sera alterado.")
  }
  if (file.exists(arq_rds)) {
    .infra_2010_conferir_objeto(readRDS(arq_rds), r, "RDS bruto")
    .infra_2010_validar_csv_releitura(arq_csv, publicado)
    return(list(status = "bruto_reutilizado_validado", rds = arq_rds,
                csv = arq_csv))
  }
  dir.create(pasta, recursive = TRUE, showWarnings = FALSE)
  tmp_rds <- tempfile(".inf01_2010_", tmpdir = pasta, fileext = ".rds")
  tmp_csv <- tempfile(".inf01_2010_", tmpdir = pasta, fileext = ".csv")
  on.exit({
    if (file.exists(tmp_rds)) unlink(tmp_rds)
    if (file.exists(tmp_csv)) unlink(tmp_csv)
  }, add = TRUE)
  saveRDS(r, tmp_rds, version = 3L)
  data.table::fwrite(publicado, tmp_csv, sep = ";", dec = ".",
                     na = "", quote = "auto", bom = FALSE)
  .infra_2010_conferir_objeto(readRDS(tmp_rds), r, "RDS temporario")
  .infra_2010_validar_csv_releitura(tmp_csv, publicado)
  if (!file.rename(tmp_rds, arq_rds)) {
    stop("INF01/2010: impossivel publicar RDS bruto.")
  }
  if (!file.rename(tmp_csv, arq_csv)) {
    unlink(arq_rds) # Remove somente o RDS criado nesta chamada.
    stop("INF01/2010: falha no CSV; RDS desta chamada revertido.")
  }
  list(status = "bruto_gravado_validado", rds = arq_rds, csv = arq_csv)
}

processar_inf01_2010 <- function(promover = FALSE,
                                 forcar_recalculo = FALSE,
                                 showProgress = TRUE,
                                 origem = c("teste12", "microdados")) {
  origem <- match.arg(origem)
  if (!identical(promover, TRUE) && !identical(promover, FALSE)) {
    stop("INF01/2010: promover deve ser TRUE ou FALSE.")
  }
  if (!identical(forcar_recalculo, FALSE)) {
    stop("INF01/2010: recálculo destrutivo proibido. Use origem='microdados' ",
         "para reproducao sem sobrescrever arquivos existentes.")
  }
  if (!exists("DIR_OUTPUT_BRUTO", inherits = TRUE) ||
      !exists("DIR_OUTPUT_INTERMEDIARIO", inherits = TRUE)) {
    stop("INF01/2010: carregue so3.3/config/config.R.")
  }
  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("INF01/2010: pacote data.table necessario.")
  }
  referencias <- .infra_2010_referencias()
  if (origem == "teste12") {
    message("INF01/2010 | Reaproveitando Teste 12 nacional aprovado...")
    # O Teste 12 ja consolidou e validou os tres grupos a partir de
    # Pessoas. Na promocao, NAO recalcular valor = 100 * num / den a
    # partir de outro CSV: a reserializacao dos componentes pode gerar
    # diferencas residuais de ponto flutuante (inclusive junto a 100%).
    # As linhas municipais aprovadas sao a fonte autoritativa; a auditoria
    # segue montada dos seis componentes e e reconciliada logo abaixo
    # por validar_inf01_2010_nacional(), inclusive municipio a municipio.
    a <- .infra_2010_montar_auditoria_t12(referencias)
    r <- data.table::copy(referencias$municipal)
  } else {
    recalculado <- .infra_2010_recalcular_microdados(showProgress)
    a <- recalculado$auditoria
    r <- recalculado$resultados
    rm(recalculado)
  }
  qa <- validar_inf01_2010_nacional(r, a, referencias)
  pasta <- file.path(DIR_OUTPUT_INTERMEDIARIO, "infraestrutural", "2010",
                     "inf01")
  checkpoint <- file.path(pasta, "INF01_REDE_CANALIZADA_2010_validado.rds")
  nacional <- list(resultados = r, auditoria = a, qa = qa,
    referencia_teste12_md5 = referencias$md5,
    fonte = "IBGE Censo 2010 amostra / Pessoas e Domicilios / DPP")
  if (file.exists(checkpoint)) {
    anterior <- readRDS(checkpoint)
    if (!is.list(anterior) ||
        !all(c("resultados", "auditoria", "qa", "referencia_teste12_md5") %in%
             names(anterior)) ||
        !identical(anterior$referencia_teste12_md5, referencias$md5)) {
      stop("INF01/2010: checkpoint nacional desatualizado/incompleto. ",
           "Nenhuma sobrescrita realizada.")
    }
    .infra_2010_conferir_objeto(anterior$resultados, r, "checkpoint resultados")
    .infra_2010_conferir_objeto(anterior$auditoria, a, "checkpoint auditoria")
    .infra_2010_conferir_objeto(anterior$qa, qa, "checkpoint QA")
  } else {
    .infra_2010_gravar_rds_novo(nacional, checkpoint)
  }
  status <- "intermediario_validado_sem_promocao"
  bruto_rds <- NA_character_
  bruto_csv <- NA_character_
  if (promover) {
    pub <- .infra_2010_promover(r, DIR_OUTPUT_BRUTO)
    status <- pub$status
    bruto_rds <- pub$rds
    bruto_csv <- pub$csv
  }
  message("INF01/2010 | ", status, " | ", qa$n_municipios,
          " municipios | ", qa$n_grupos, " grupos | INF01 Brasil=",
          sprintf("%.5f%%", qa$inf01_brasil))
  invisible(list(indicador = "INF01_REDE_CANALIZADA",
    ano = 2010L, status = status, integral = TRUE, qa = qa,
    origem = origem, checkpoint = checkpoint,
    arquivo_bruto_rds = bruto_rds, arquivo_bruto_csv = bruto_csv))
}
