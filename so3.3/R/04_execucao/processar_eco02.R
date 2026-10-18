# ============================================================
# PRAIS4 / SO3.3 / ECO02_PIBPC - PROCESSAMENTO ISOLADO
#
# Executar a partir da raiz do repositorio, apos carregar:
# source("so3.3/R/01_leitura/ler_pib_municipios_eco02.R")
# source("so3.3/R/01_leitura/ler_sidra_economica.R")
# source("so3.3/R/03_diagnostico/diagnosticar_sidra_economica.R")
# source("so3.3/R/03_diagnostico/diagnosticar_pib_municipios_eco02.R")
# source("so3.3/R/02_indicadores/eco02_pibpc.R")
# source("so3.3/R/04_execucao/processar_eco02.R")
#
# Sem gravacao: processar_eco02(2000L)
# Opt-in RDS:  processar_eco02(2000L, salvar = TRUE)
#
# Nem main.R nem exportador CSV sao chamados.
# Arquivos existentes NAO sao sobrescritos automaticamente.
# ============================================================

if (!requireNamespace("data.table", quietly = TRUE)) {
  stop("ECO02 processamento: pacote data.table necessario.")
}

.fontes_md5_eco02 <- function(insumos_pib, insumos_sidra) {
  # Valida os XLSX originais contra seus manifestos de leitura.
  f_ibge <- .verificar_fontes_eco02(insumos_pib$fontes)
  periodo <- c("2002_2009", "2010_2023")
  hashes_ibge <- as.character(
    f_ibge$md5[match(periodo, f_ibge$periodo)]
  )

  f_sidra <- data.table::as.data.table(insumos_sidra$fontes)
  obrigatorias <- c("tabela", "arquivo", "md5")
  if (length(setdiff(obrigatorias, names(f_sidra))) ||
      anyNA(f_sidra[, ..obrigatorias]) ||
      anyDuplicated(f_sidra$tabela) ||
      !all(c("5938", "5938_VAB", "6784") %in% f_sidra$tabela) ||
      any(!file.exists(f_sidra$arquivo)) ||
      !identical(
        unname(as.character(tools::md5sum(f_sidra$arquivo))),
        as.character(f_sidra$md5)
      )) {
    stop("ECO02: manifesto SIDRA inconsistente ou arquivos alterados.")
  }
  hash_deflator <- as.character(
    f_sidra$md5[match("6784", f_sidra$tabela)]
  )
  hashes <- c(hashes_ibge, hash_deflator)
  names(hashes) <- c(periodo, "6784")
  if (anyNA(hashes) ||
      any(!grepl("^[0-9a-f]{32}$", hashes))) {
    stop("ECO02: MD5 dos XLSX ou deflator SIDRA ausente.")
  }
  hashes
}

.assinatura_codigo_eco02 <- function() {
  arquivos <- file.path("so3.3", "R", c(
    "01_leitura/ler_pib_municipios_eco02.R",
    "01_leitura/ler_sidra_economica.R",
    "02_indicadores/eco02_pibpc.R",
    "03_diagnostico/diagnosticar_pib_municipios_eco02.R",
    "03_diagnostico/diagnosticar_sidra_economica.R",
    "04_execucao/processar_eco02.R"
  ))
  if (!all(file.exists(arquivos))) {
    stop("ECO02: codigo-fonte nao localizado na raiz do repositorio.")
  }
  stats::setNames(
    unname(as.character(tools::md5sum(arquivos))), arquivos
  )
}

.tabelas_identicas_eco02 <- function(x, y) {
  if (!is.data.frame(x) || !is.data.frame(y) ||
      nrow(x) != nrow(y) ||
      !identical(names(x), names(y))) {
    return(FALSE)
  }
  all(vapply(names(x), function(campo) {
    identical(x[[campo]], y[[campo]])
  }, logical(1L)))
}

.persistir_eco02 <- function(
  bruto, auditoria, ano, codigos_prais, fatores,
  assinatura, dir_bruto, dir_intermediario
) {
  caminho_bruto <- file.path(
    dir_bruto, "economica", as.character(ano),
    paste0(ECO02_ID, "_", ano, ".rds")
  )
  caminho_auditoria <- file.path(
    dir_intermediario, "economica", as.character(ano),
    paste0("auditoria_eco02_", ano, ".rds")
  )
  caminhos <- c(bruto = caminho_bruto, auditoria = caminho_auditoria)
  existe <- file.exists(caminhos)
  if (any(existe) && !all(existe)) {
    stop("ECO02: so um RDS ja existe; nada sera sobrescrito: ",
         paste(caminhos[existe], collapse = ", "))
  }
  if (all(existe)) {
    bruto_anterior <- readRDS(caminho_bruto)
    auditoria_anterior <- readRDS(caminho_auditoria)
    validar_resultados_eco02(
      bruto_anterior, auditoria_anterior, ano,
      codigos_prais, fatores
    )
    if (!identical(
          attr(auditoria_anterior, "assinatura_codigo_eco02", exact = TRUE),
          assinatura
        ) ||
        !.tabelas_identicas_eco02(bruto_anterior, bruto) ||
        !.tabelas_identicas_eco02(auditoria_anterior, auditoria)) {
      stop("ECO02: RDS existentes divergem dos insumos/codigo atuais. ",
           "Nenhum arquivo sera substituido.")
    }
    return(list(status = "reutilizado_validado", arquivos = caminhos))
  }

  dir.create(dirname(caminho_bruto), recursive = TRUE,
             showWarnings = FALSE)
  dir.create(dirname(caminho_auditoria), recursive = TRUE,
             showWarnings = FALSE)
  temp_bruto <- tempfile(
    ".eco02_bruto_", tmpdir = dirname(caminho_bruto), fileext = ".rds"
  )
  temp_auditoria <- tempfile(
    ".eco02_auditoria_", tmpdir = dirname(caminho_auditoria),
    fileext = ".rds"
  )
  on.exit(
    unlink(c(temp_bruto, temp_auditoria)),
    add = TRUE
  )
  saveRDS(bruto, temp_bruto)
  saveRDS(auditoria, temp_auditoria)
  bruto_teste <- readRDS(temp_bruto)
  auditoria_teste <- readRDS(temp_auditoria)
  validar_resultados_eco02(
    bruto_teste, auditoria_teste, ano, codigos_prais, fatores
  )
  if (!identical(
        attr(auditoria_teste, "assinatura_codigo_eco02", exact = TRUE),
        assinatura
      ) ||
      !.tabelas_identicas_eco02(bruto_teste, bruto) ||
      !.tabelas_identicas_eco02(auditoria_teste, auditoria)) {
    stop("ECO02: releitura dos RDS temporarios divergente.")
  }
  if (any(file.exists(caminhos))) {
    stop("ECO02: destino surgiu durante a escrita. ",
         "Nenhum RDS existente sera sobrescrito.")
  }
  if (!file.rename(temp_bruto, caminho_bruto)) {
    stop("ECO02: falha ao concluir RDS bruto.")
  }
  if (!file.rename(temp_auditoria, caminho_auditoria)) {
    unlink(caminho_bruto)
    stop("ECO02: falha ao concluir auditoria; novo RDS bruto removido.")
  }
  list(status = "gravado_validado", arquivos = caminhos)
}

processar_eco02 <- function(
  ano,
  insumos_pib = NULL,
  insumos_sidra = NULL,
  diagnostico = NULL,
  dir_bruto = file.path("so3.3", "outputs", "bruto"),
  dir_intermediario = file.path("so3.3", "outputs", "intermediario"),
  salvar = FALSE
) {
  ano <- .validar_ano_eco02(ano)
  if (length(salvar) != 1L || !is.logical(salvar) || is.na(salvar)) {
    stop("ECO02: salvar deve ser TRUE ou FALSE.")
  }
  dependencias <- c(
    "ler_pib_municipios_eco02", "ler_sidra_economica",
    ".verificar_fontes_eco02",
    ".ler_municipios_prais_sidra",
    "diagnosticar_pib_municipios_eco02",
    "calcular_fatores_deflator_eco02", "calcular_eco02_pibpc",
    "validar_resultados_eco02"
  )
  faltam <- dependencias[!vapply(
    dependencias, exists, logical(1L),
    mode = "function", inherits = TRUE
  )]
  if (length(faltam)) {
    stop("ECO02: carregue os modulos exigidos: ",
         paste(faltam, collapse = ", "))
  }
  if (is.null(insumos_pib)) {
    insumos_pib <- ler_pib_municipios_eco02()
  }
  if (is.null(insumos_sidra)) {
    insumos_sidra <- ler_sidra_economica()
  }
  if (!is.list(insumos_pib) ||
      !all(c("dados", "fontes") %in% names(insumos_pib)) ||
      !is.list(insumos_sidra) ||
      !all(c("deflator_anual", "fontes", "dados_municipais") %in%
           names(insumos_sidra))) {
    stop("ECO02: objeto de leitura IBGE ou SIDRA incompleto.")
  }
  hashes <- .fontes_md5_eco02(insumos_pib, insumos_sidra)

  if (is.null(diagnostico)) {
    diagnostico <- diagnosticar_pib_municipios_eco02(
      insumos_pib = insumos_pib,
      insumos_sidra = insumos_sidra,
      dir_bruto = dir_bruto
    )
  }
  obrigatorios <- c(
    "cobertura_territorial", "comparacao_sidra",
    "fontes_ibge", "fontes_sidra"
  )
  if (!is.list(diagnostico) ||
      !all(obrigatorios %in% names(diagnostico))) {
    stop("ECO02: diagnostico de origem/cobertura ausente.")
  }
  ibge_diag <- data.table::as.data.table(diagnostico$fontes_ibge)
  sidra_diag <- data.table::as.data.table(diagnostico$fontes_sidra)
  if (length(setdiff(c("periodo", "md5"), names(ibge_diag))) ||
      length(setdiff(c("tabela", "md5"), names(sidra_diag))) ||
      anyDuplicated(ibge_diag$periodo) ||
      anyDuplicated(sidra_diag$tabela)) {
    stop("ECO02: manifestos do diagnostico incompletos.")
  }
  ibge_md5_diag <- as.character(ibge_diag$md5[
    match(c("2002_2009", "2010_2023"), ibge_diag$periodo)
  ])
  deflator_md5_diag <- as.character(sidra_diag$md5[
    match("6784", sidra_diag$tabela)
  ])
  if (anyNA(c(ibge_md5_diag, deflator_md5_diag)) ||
      !identical(
        unname(c(ibge_md5_diag, deflator_md5_diag)),
        unname(hashes)
      )) {
    stop("ECO02: diagnostico e fontes atuais possuem MD5 diferentes.")
  }

  n_prais <- unname(ECO02_MUNICIPIOS_PRAIS[as.character(ano)])
  n_fonte <- unname(ECO02_MUNICIPIOS_FONTE[as.character(ano)])
  ano_fonte <- unname(ECO02_FONTE_POR_PRAIS[as.character(ano)])
  cobertura <- data.table::as.data.table(
    diagnostico$cobertura_territorial
  )
  comparacao <- data.table::as.data.table(
    diagnostico$comparacao_sidra
  )
  campos_cob <- c(
    "ano_prais", "ano_fonte", "municipios_prais",
    "municipios_fonte", "municipios_correspondentes",
    "municipios_sem_correspondencia", "municipios_adicionais_na_fonte"
  )
  campos_cmp <- c(
    "ano_prais", "ano_fonte", "municipios_conferidos",
    "divergencias_acima_tolerancia", "max_diferenca_abs_mil_reais"
  )
  if (length(setdiff(campos_cob, names(cobertura))) ||
      length(setdiff(campos_cmp, names(comparacao)))) {
    stop("ECO02: tabelas de diagnostico incompletas.")
  }
  c <- cobertura[ano_prais == ano]
  v <- comparacao[ano_prais == ano]
  if (nrow(c) != 1L || nrow(v) != 1L ||
      anyNA(c[, ..campos_cob]) ||
      anyNA(v[, ..campos_cmp]) ||
      c$ano_fonte[[1L]] != ano_fonte ||
      v$ano_fonte[[1L]] != ano_fonte ||
      c$municipios_prais[[1L]] != n_prais ||
      c$municipios_fonte[[1L]] != n_fonte ||
      c$municipios_correspondentes[[1L]] != n_prais ||
      c$municipios_sem_correspondencia[[1L]] != 0L ||
      c$municipios_adicionais_na_fonte[[1L]] != (n_fonte - n_prais) ||
      v$municipios_conferidos[[1L]] != n_fonte ||
      v$divergencias_acima_tolerancia[[1L]] != 0L ||
      !is.finite(v$max_diferenca_abs_mil_reais[[1L]]) ||
      v$max_diferenca_abs_mil_reais[[1L]] > 0.500001) {
    stop("ECO02: diagnostico municipal/SIDRA nao aprovado para ", ano)
  }

  codigos_prais <- .ler_municipios_prais_sidra(ano, dir_bruto)
  fatores <- calcular_fatores_deflator_eco02(
    insumos_sidra$deflator_anual
  )
  dados_recorte <- data.table::as.data.table(insumos_pib$dados)[
    ano_prais == ano
  ]
  resultado <- calcular_eco02_pibpc(
    dados_recorte = dados_recorte,
    ano = ano,
    codigos_prais = codigos_prais,
    fatores = fatores$fatores,
    fontes_md5 = hashes
  )
  bruto <- resultado$bruto
  auditoria <- resultado$auditoria
  assinatura <- .assinatura_codigo_eco02()
  attr(auditoria, "assinatura_codigo_eco02") <- assinatura
  validar_resultados_eco02(
    bruto, auditoria, ano, codigos_prais, fatores$fatores
  )

  resumo <- auditoria[, .(
    municipios = .N,
    minimo_corrente_reais = min(pib_pc_corrente_reais),
    maximo_corrente_reais = max(pib_pc_corrente_reais),
    minimo_reais_2010 = min(pib_pc_reais_2010),
    maximo_reais_2010 = max(pib_pc_reais_2010),
    fator_deflator_2010 = unique(fator_deflator_2010)
  ), by = .(ano, ano_fonte, ano_base_monetaria, indicador)]
  data.table::setorder(resumo, ano)

  gravacao <- list(status = "validado_sem_gravacao", arquivos = NULL)
  if (isTRUE(salvar)) {
    gravacao <- .persistir_eco02(
      bruto, auditoria, ano, codigos_prais, fatores$fatores,
      assinatura, dir_bruto, dir_intermediario
    )
  }
  message(
    "ECO02 ", ano,
    " | fonte ", ano_fonte,
    " | base monetaria 2010",
    " | municipios ", nrow(auditoria),
    " | T/M/F ", nrow(bruto),
    " | fator ", format(
      unique(auditoria$fator_deflator_2010), digits = 12
    ),
    " | ", gravacao$status
  )
  invisible(list(
    ano = ano,
    ano_fonte = ano_fonte,
    ano_base_monetaria = 2010L,
    indicador = ECO02_ID,
    bruto = bruto,
    auditoria = auditoria,
    resumo = resumo[],
    fatores_deflator = fatores$fatores,
    serie_deflator = fatores$serie_anual,
    fontes_md5 = hashes,
    status = gravacao$status,
    arquivos = gravacao$arquivos
  ))
}
