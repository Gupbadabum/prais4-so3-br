# =============================================================================
# PRAIS4 / SO3.3 / INF01 2022 - Processador modular de producao
# Origem: produtos agregados nacionais aprovados no Teste 18.
# Nao reprocessa microdados e nao modifica 2000, 2010 ou main.R.
# Nao sobrescreve checkpoint nem produtos divergentes.
# =============================================================================

.infra_2022_modulos <- file.path("so3.3", "R", c(
  "03_diagnostico/validar_inf01_2022.R",
  "05_exportacao/exportar_resultados_csv.R",
  "05_exportacao/exportar_inf01_2022_bruto_csv.R"
))
if (!all(file.exists(.infra_2022_modulos))) {
  stop("INF01/2022: modulos ausentes: ",
       paste(.infra_2022_modulos[!file.exists(.infra_2022_modulos)],
             collapse = ", "))
}
for (.infra_2022_arquivo in .infra_2022_modulos) {
  source(.infra_2022_arquivo, local = TRUE)
}
rm(.infra_2022_arquivo)

.infra_2022_conferir_tabelas <- function(anterior, novo, rotulo) {
  if (!is.data.frame(anterior) || !is.data.frame(novo) ||
      !identical(names(anterior), names(novo)) ||
      nrow(anterior) != nrow(novo)) {
    stop("INF01/2022: estrutura divergente: ", rotulo)
  }
  for (nm in names(novo)) {
    x <- anterior[[nm]]
    y <- novo[[nm]]
    if (is.numeric(x) && is.numeric(y)) {
      if (!identical(is.na(x), is.na(y)) ||
          !.infra_2022_aprox(x[!is.na(x)], y[!is.na(y)])) {
        stop("INF01/2022: divergencia em ", rotulo, "/", nm)
      }
    } else if (!identical(as.character(x), as.character(y))) {
      stop("INF01/2022: identificador divergente em ", rotulo, "/", nm)
    }
  }
  invisible(TRUE)
}

.infra_2022_verificar_csv <- function(arquivo, original) {
  lido <- data.table::fread(
    arquivo, sep = ";", na.strings = "NA",
    colClasses = list(character = c("uf", "cod_mun")),
    encoding = "UTF-8", showProgress = FALSE
  )
  .infra_2022_conferir_tabelas(lido, original, "CSV bruto")
  invisible(TRUE)
}

.infra_2022_salvar_checkpoint <- function(obj, arquivo) {
  if (file.exists(arquivo)) {
    stop("INF01/2022: checkpoint existente nao pode ser sobrescrito: ",
         arquivo)
  }
  dir.create(dirname(arquivo), recursive = TRUE, showWarnings = FALSE)
  temporario <- tempfile(".inf01_2022_", tmpdir = dirname(arquivo),
                        fileext = ".rds")
  on.exit(if (file.exists(temporario)) unlink(temporario), add = TRUE)
  saveRDS(obj, temporario, version = 3L)
  if (!file.rename(temporario, arquivo)) {
    stop("INF01/2022: falha ao criar checkpoint: ", arquivo)
  }
  invisible(arquivo)
}

.infra_2022_promover <- function(resultados, dir_bruto) {
  publicado <- preparar_inf01_2022_bruto_csv(resultados)
  pasta <- file.path(dir_bruto, "infraestrutural", "2022")
  arq_rds <- file.path(pasta, "INF01_REDE_CANALIZADA_2022.rds")
  arq_csv <- file.path(pasta, "INF01_REDE_CANALIZADA_2022.csv")
  if (xor(file.exists(arq_rds), file.exists(arq_csv))) {
    stop("INF01/2022: RDS/CSV bruto parcial; nenhum arquivo alterado.")
  }
  if (file.exists(arq_rds)) {
    .infra_2022_conferir_tabelas(readRDS(arq_rds), resultados, "RDS bruto")
    .infra_2022_verificar_csv(arq_csv, publicado)
    return(list(status = "bruto_reutilizado_validado",
                rds = arq_rds, csv = arq_csv))
  }
  dir.create(pasta, recursive = TRUE, showWarnings = FALSE)
  tmp_rds <- tempfile(".inf01_2022_", tmpdir = pasta, fileext = ".rds")
  tmp_csv <- tempfile(".inf01_2022_", tmpdir = pasta, fileext = ".csv")
  on.exit({
    if (file.exists(tmp_rds)) unlink(tmp_rds)
    if (file.exists(tmp_csv)) unlink(tmp_csv)
  }, add = TRUE)
  saveRDS(resultados, tmp_rds, version = 3L)
  data.table::fwrite(publicado, tmp_csv, sep = ";", dec = ".",
                     na = "", quote = "auto", bom = FALSE)
  .infra_2022_conferir_tabelas(readRDS(tmp_rds), resultados,
                                "RDS temporario")
  .infra_2022_verificar_csv(tmp_csv, publicado)
  if (!file.rename(tmp_rds, arq_rds)) {
    stop("INF01/2022: impossivel criar RDS bruto.")
  }
  if (!file.rename(tmp_csv, arq_csv)) {
    unlink(arq_rds)  # Desfaz apenas o RDS criado nesta chamada.
    stop("INF01/2022: falha no CSV; RDS desta chamada revertido.")
  }
  list(status = "bruto_gravado_validado", rds = arq_rds, csv = arq_csv)
}

processar_inf01_2022 <- function(promover = FALSE,
                                forcar_recalculo = FALSE,
                                origem = "teste18") {
  if (!identical(promover, TRUE) && !identical(promover, FALSE)) {
    stop("INF01/2022: promover deve ser TRUE ou FALSE.")
  }
  if (!identical(forcar_recalculo, FALSE)) {
    stop("INF01/2022: reprocessamento/sobrescrita destrutiva desabilitados.")
  }
  if (!identical(origem, "teste18")) {
    stop("INF01/2022: nesta versao, origem deve ser 'teste18'.")
  }
  if (!exists("DIR_OUTPUT_BRUTO", inherits = TRUE) ||
      !exists("DIR_OUTPUT_INTERMEDIARIO", inherits = TRUE)) {
    stop("INF01/2022: carregue so3.3/config/config.R antes de executar.")
  }
  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("INF01/2022: pacote data.table necessario.")
  }
  message("INF01/2022 | Recuperando Teste 18 nacional aprovado...")
  ref <- .infra_2022_referencias()
  # Resultados municipais T18 sao a fonte autorizada; nao recalcular
  # percentuais apos reserializar componentes em CSV.
  r <- data.table::copy(ref$municipal)
  a <- .infra_2022_montar_auditoria(ref)
  qa <- validar_inf01_2022_nacional(r, a, ref)

  pasta <- file.path(DIR_OUTPUT_INTERMEDIARIO,
                     "infraestrutural", "2022", "inf01")
  checkpoint <- file.path(pasta,
                           "INF01_REDE_CANALIZADA_2022_validado.rds")
  nacional <- list(
    resultados = r,
    auditoria = a,
    qa = qa,
    referencia_teste18_md5 = ref$md5,
    fonte = paste(
      "IBGE Censo 2022 - amostra de acesso controlado;",
      "Pessoas e Domicilios; DPP. Validacao externa pendente."
    )
  )
  if (file.exists(checkpoint)) {
    anterior <- readRDS(checkpoint)
    requeridos <- c("resultados", "auditoria", "qa", "referencia_teste18_md5")
    if (!is.list(anterior) || !all(requeridos %in% names(anterior)) ||
        !identical(anterior$referencia_teste18_md5, ref$md5)) {
      stop("INF01/2022: checkpoint nacional desatualizado ou parcial; ",
           "nenhuma sobrescrita realizada.")
    }
    .infra_2022_conferir_tabelas(anterior$resultados, r,
                                 "checkpoint resultados")
    .infra_2022_conferir_tabelas(anterior$auditoria, a,
                                 "checkpoint auditoria")
    .infra_2022_conferir_tabelas(anterior$qa, qa, "checkpoint QA")
  } else {
    .infra_2022_salvar_checkpoint(nacional, checkpoint)
  }
  status <- "intermediario_validado_sem_promocao"
  rds <- NA_character_
  csv <- NA_character_
  if (promover) {
    produto <- .infra_2022_promover(r, DIR_OUTPUT_BRUTO)
    status <- produto$status
    rds <- produto$rds
    csv <- produto$csv
  }
  message("INF01/2022 | ", status, " | ", qa$n_municipios,
          " municipios | ", qa$n_grupos, " grupos | INF01 Brasil=",
          sprintf("%.5f%%", qa$inf01_brasil))
  invisible(list(
    indicador = "INF01_REDE_CANALIZADA", ano = 2022L,
    status = status, integral = TRUE, qa = qa,
    origem = origem, checkpoint = checkpoint,
    arquivo_bruto_rds = rds, arquivo_bruto_csv = csv
  ))
}
