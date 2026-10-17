# ============================================================
# PRAIS4 / SO3.3 / ECO03_AGROPIB - PROCESSAMENTO ISOLADO
#
# A partir da raiz do repositorio:
#   source("so3.3/R/01_leitura/ler_sidra_economica.R")
#   source("so3.3/R/03_diagnostico/diagnosticar_sidra_economica.R")
#   source("so3.3/R/02_indicadores/eco03_agropib.R")
#   source("so3.3/R/04_execucao/processar_eco03.R")
#
# Teste sem escrita: processar_eco03(2000L)
# Gravacao opcional: processar_eco03(2000L, salvar = TRUE)
# Uma execucao = um recorte PRAIS. Nao altera o main.R e nao
# exporta CSV. Recusa sobrescrever produtos divergentes.
# ============================================================

if (!requireNamespace("data.table", quietly = TRUE)) {
  stop("ECO03: o pacote data.table e necessario.")
}

.fontes_md5_eco03 <- function(insumos) {
  f <- data.table::as.data.table(insumos$fontes)
  if (!all(c("tabela", "arquivo", "md5") %in% names(f)) ||
      anyNA(f[, .(tabela, arquivo, md5)]) ||
      anyDuplicated(f$tabela)) {
    stop("ECO03: manifesto de fontes SIDRA ausente ou incompleto.")
  }
  esperadas <- c("5938", "5938_VAB")
  pos <- match(esperadas, as.character(f$tabela))
  if (anyNA(pos)) {
    stop("ECO03: hashes da Tabela 5938 e da conferencia VAB ausentes.")
  }
  arqs <- as.character(f$arquivo[pos])
  md5 <- as.character(f$md5[pos])
  if (any(!file.exists(arqs)) ||
      any(!grepl("^[0-9a-f]{32}$", md5)) ||
      !identical(unname(as.character(tools::md5sum(arqs))), md5)) {
    stop("ECO03: arquivos SIDRA mudaram desde a leitura; ",
         "reimporte e revalide os insumos.")
  }
  stats::setNames(md5, esperadas)
}

.assinatura_codigo_eco03 <- function() {
  arquivos <- file.path(
    "so3.3", "R", c(
      "01_leitura/ler_sidra_economica.R",
      "02_indicadores/eco03_agropib.R",
      "03_diagnostico/diagnosticar_sidra_economica.R",
      "04_execucao/processar_eco03.R"
    )
  )
  if (!all(file.exists(arquivos))) {
    stop("ECO03: modulos de codigo ausentes na raiz do repositorio.")
  }
  md5 <- unname(as.character(tools::md5sum(arquivos)))
  stats::setNames(md5, arquivos)
}

.tabelas_identicas_eco03 <- function(x, y) {
  if (!is.data.frame(x) || !is.data.frame(y) ||
      !identical(names(x), names(y)) || nrow(x) != nrow(y)) {
    return(FALSE)
  }
  all(vapply(names(x), function(campo) {
    identical(x[[campo]], y[[campo]])
  }, logical(1L)))
}

# Salvamento conservador. Nenhum arquivo existente e alterado;
# se os dois RDS ja existem, devem reproduzir exatamente a
# mesma auditoria, resultado e assinatura de codigo.
.persistir_eco03 <- function(bruto, auditoria, ano, codigos_prais,
                             assinatura, dir_bruto, dir_intermediario) {
  saida_bruto <- file.path(
    dir_bruto, "economica", as.character(ano),
    paste0(ECO03_ID, "_", ano, ".rds")
  )
  saida_auditoria <- file.path(
    dir_intermediario, "economica", as.character(ano),
    paste0("auditoria_eco03_", ano, ".rds")
  )
  arquivos <- c(bruto = saida_bruto, auditoria = saida_auditoria)
  presentes <- file.exists(arquivos)
  if (any(presentes) && !all(presentes)) {
    stop("ECO03: apenas um dos dois RDS ja existe. ",
         "Nenhum resultado sera sobrescrito: ",
         paste(arquivos[presentes], collapse = ", "))
  }
  if (all(presentes)) {
    bruto_existente <- readRDS(saida_bruto)
    auditoria_existente <- readRDS(saida_auditoria)
    validar_resultados_eco03(
      bruto_existente, auditoria_existente, ano, codigos_prais
    )
    if (!identical(
          attr(auditoria_existente, "assinatura_codigo_eco03"),
          assinatura
        ) ||
        !.tabelas_identicas_eco03(bruto_existente, bruto) ||
        !.tabelas_identicas_eco03(auditoria_existente, auditoria)) {
      stop("ECO03: RDS existente difere dos insumos/codigo atuais. ",
           "Nada foi sobrescrito.")
    }
    return(list(status = "reutilizado_validado", caminhos = arquivos))
  }

  dir.create(dirname(saida_bruto), recursive = TRUE,
             showWarnings = FALSE)
  dir.create(dirname(saida_auditoria), recursive = TRUE,
             showWarnings = FALSE)
  temp_bruto <- tempfile(".eco03_bruto_", tmpdir = dirname(saida_bruto),
                         fileext = ".rds")
  temp_audit <- tempfile(".eco03_auditoria_",
                         tmpdir = dirname(saida_auditoria),
                         fileext = ".rds")
  on.exit(unlink(c(temp_bruto, temp_audit)), add = TRUE)
  saveRDS(bruto, temp_bruto)
  saveRDS(auditoria, temp_audit)
  auditoria_teste <- readRDS(temp_audit)
  bruto_teste <- readRDS(temp_bruto)
  validar_resultados_eco03(bruto_teste, auditoria_teste,
                            ano, codigos_prais)
  if (!identical(
        attr(auditoria_teste, "assinatura_codigo_eco03"), assinatura
      ) ||
      !.tabelas_identicas_eco03(bruto_teste, bruto) ||
      !.tabelas_identicas_eco03(auditoria_teste, auditoria)) {
    stop("ECO03: falha ao reler os RDS temporarios.")
  }
  if (any(file.exists(arquivos))) {
    stop("ECO03: um destino surgiu durante a gravacao. ",
         "Nenhum arquivo existente sera sobrescrito.")
  }
  if (!file.rename(temp_bruto, saida_bruto)) {
    stop("ECO03: falha ao finalizar o RDS bruto.")
  }
  if (!file.rename(temp_audit, saida_auditoria)) {
    unlink(saida_bruto)
    stop("ECO03: falha ao finalizar auditoria; ",
         "novo RDS bruto removido para evitar resultado parcial.")
  }
  list(status = "gravado_validado", caminhos = arquivos)
}

processar_eco03 <- function(
  ano,
  insumos = NULL,
  diagnostico = NULL,
  dir_bruto = file.path("so3.3", "outputs", "bruto"),
  dir_intermediario = file.path("so3.3", "outputs", "intermediario"),
  salvar = FALSE
) {
  ano <- .validar_ano_eco03(ano)
  if (length(salvar) != 1L || !is.logical(salvar) || is.na(salvar)) {
    stop("ECO03: salvar deve ser TRUE ou FALSE.")
  }
  dependencias <- c(
    "ler_sidra_economica", "selecionar_recortes_sidra_economica",
    "diagnosticar_sidra_economica", ".ler_municipios_prais_sidra",
    "calcular_eco03_agropib", "validar_resultados_eco03"
  )
  faltam <- dependencias[!vapply(
    dependencias, exists, logical(1L),
    mode = "function", inherits = TRUE
  )]
  if (length(faltam)) {
    stop("ECO03: carregue primeiro os modulos necessarios: ",
         paste(faltam, collapse = ", "))
  }
  if (is.null(insumos)) {
    insumos <- ler_sidra_economica()
  }
  if (!is.list(insumos) ||
      !all(c("dados_municipais", "fontes", "deflator_anual") %in%
           names(insumos))) {
    stop("ECO03: objeto de insumos SIDRA incompleto.")
  }
  md5 <- .fontes_md5_eco03(insumos)
  if (is.null(diagnostico)) {
    diagnostico <- diagnosticar_sidra_economica(
      insumos = insumos, dir_bruto = dir_bruto
    )
  }
  if (!is.list(diagnostico) ||
      !all(c("cobertura_territorial", "fontes") %in%
           names(diagnostico))) {
    stop("ECO03: diagnostico SIDRA incompleto.")
  }
  fonte_diag <- data.table::as.data.table(diagnostico$fontes)
  ids <- match(names(md5), fonte_diag$tabela)
  if (anyNA(ids) ||
      !identical(as.character(fonte_diag$md5[ids]), unname(md5))) {
    stop("ECO03: diagnostico e insumos SIDRA usam arquivos diferentes.")
  }
  n_esperado <- unname(ECO03_MUNICIPIOS[as.character(ano)])
  recorte <- data.table::as.data.table(diagnostico$cobertura_territorial)[
    indicador == "ECO03" & ano_prais == ano
  ]
  ano_fonte <- unname(ECO03_ANO_FONTE[as.character(ano)])
  if (nrow(recorte) != 1L ||
      anyNA(recorte[, .(ano_fonte, municipios_prais,
                        municipios_correspondentes,
                        municipios_sem_correspondencia)]) ||
      recorte$ano_fonte[[1L]] != ano_fonte ||
      recorte$municipios_prais[[1L]] != n_esperado ||
      recorte$municipios_correspondentes[[1L]] != n_esperado ||
      recorte$municipios_sem_correspondencia[[1L]] != 0L) {
    stop("ECO03: auditoria territorial incompleta no recorte ", ano)
  }

  codigos_prais <- .ler_municipios_prais_sidra(ano, dir_bruto)
  selecionados <- selecionar_recortes_sidra_economica(
    insumos$dados_municipais, "ECO03"
  )
  selecionados <- selecionados[ano_prais == ano]
  resultado <- calcular_eco03_agropib(
    dados_recorte = selecionados,
    ano = ano,
    codigos_prais = codigos_prais,
    fontes_md5 = md5
  )
  bruto <- resultado$bruto
  auditoria <- resultado$auditoria
  assinatura <- .assinatura_codigo_eco03()
  attr(auditoria, "assinatura_codigo_eco03") <- assinatura
  validar_resultados_eco03(bruto, auditoria, ano, codigos_prais)

  resumo <- auditoria[, .(
    municipios = .N,
    minimo_pct = min(participacao_pct),
    maximo_pct = max(participacao_pct),
    vab_zero = sum(vab_zero),
    participacoes_acima_100 = sum(vab_acima_100)
  ), by = .(ano, ano_fonte, indicador)]
  data.table::setorder(resumo, ano)
  gravacao <- list(status = "validado_sem_gravacao", caminhos = NULL)
  if (isTRUE(salvar)) {
    gravacao <- .persistir_eco03(
      bruto, auditoria, ano, codigos_prais, assinatura,
      dir_bruto, dir_intermediario
    )
  }
  message("ECO03 ", ano, " | fonte ", ano_fonte,
          " | municipios ", nrow(auditoria),
          " | linhas T/M/F ", nrow(bruto),
          " | VAB zero ", sum(auditoria$vab_zero),
          " | >100% ", sum(auditoria$vab_acima_100),
          " | ", gravacao$status)
  invisible(list(
    ano = ano,
    ano_fonte = ano_fonte,
    indicador = ECO03_ID,
    bruto = bruto,
    auditoria = auditoria,
    resumo = resumo[],
    fontes_md5 = md5,
    status = gravacao$status,
    arquivos = gravacao$caminhos
  ))
}
