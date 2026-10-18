# ============================================================
# PRAIS4 / SO3.3 - PROCESSADOR INTEGRADO DA DIMENSAO ECONOMICA
#
# Uma execucao = uma dimensao (Economica) + um ano PRAIS.
# Coordena ECO01, ECO02 e ECO03 sem modificar suas formulas.
# Reutiliza RDS/CSV completos e validos, processa apenas o
# indicador ausente e interrompe em produtos divergentes.
#
# A validacao final confronta os tres indicadores no MESMO ano.
# Nao executa outros anos nem os tratamentos estatisticos.
#
# Requer config/config.R previamente carregado pelo main.R.
# Recalculo destrutivo nao e permitido neste orquestrador.
# ============================================================

if (!requireNamespace("data.table", quietly = TRUE)) {
  stop("Economica: pacote data.table necessario.")
}

.econ_ano_valido <- function(ano) {
  if (length(ano) != 1L || !is.numeric(ano) || is.na(ano) ||
      !is.finite(ano) || ano != floor(ano) ||
      !ano %in% c(2000L, 2010L, 2022L)) {
    stop("Economica: use exclusivamente ANO_ATIVO = 2000, 2010 ou 2022.")
  }
  as.integer(ano)
}

.econ_caminhos_ano <- function(ano, dir_bruto, dir_intermediario) {
  nomes <- c(
    "ECO01_POV3_PPC21", "ECO02_PIBPC", "ECO03_AGROPIB"
  )
  ids <- c("ECO01", "ECO02", "ECO03")
  data.table::data.table(
    id = ids,
    indicador = nomes,
    rds = file.path(
      dir_bruto, "economica", as.character(ano),
      paste0(nomes, "_", ano, ".rds")
    ),
    auditoria = file.path(
      dir_intermediario, "economica", as.character(ano),
      paste0("auditoria_", tolower(ids), "_", ano, ".rds")
    ),
    csv = file.path(
      dir_bruto, "economica", as.character(ano),
      paste0(nomes, "_", ano, ".csv")
    )
  )
}

.econ_conferir_estado_arquivos <- function(caminhos) {
  for (i in seq_len(nrow(caminhos))) {
    existe_rds <- file.exists(caminhos$rds[[i]])
    existe_auditoria <- file.exists(caminhos$auditoria[[i]])
    existe_csv <- file.exists(caminhos$csv[[i]])
    if (xor(existe_rds, existe_auditoria)) {
      stop(
        "Economica ", caminhos$id[[i]], ": RDS bruto/auditoria ",
        "incompletos; nenhum produto existente sera sobrescrito."
      )
    }
    if (existe_csv && !existe_rds) {
      stop(
        "Economica ", caminhos$id[[i]], ": CSV existe, mas ",
        "RDS/auditoria nao estao disponiveis para validacao."
      )
    }
  }
  invisible(TRUE)
}

.econ_carregar_modulos <- function() {
  # Mantem o padrao de source() do main.R para que as funcoes
  # compartilhadas estejam disponiveis aos processadores
  # e exportadores existentes.
  modulos <- file.path("so3.3", "R", c(
    "02_indicadores/preparar_referencias_eco01.R",
    "02_indicadores/eco01_pobreza.R",
    "01_leitura/ler_sidra_economica.R",
    "01_leitura/ler_pib_municipios_eco02.R",
    "03_diagnostico/diagnosticar_sidra_economica.R",
    "03_diagnostico/diagnosticar_pib_municipios_eco02.R",
    "02_indicadores/eco02_pibpc.R",
    "04_execucao/processar_eco02.R",
    "02_indicadores/eco03_agropib.R",
    "04_execucao/processar_eco03.R",
    "05_exportacao/exportar_resultados_csv.R"
  ))
  if (!all(file.exists(modulos))) {
    stop(
      "Economica: modulos ausentes: ",
      paste(modulos[!file.exists(modulos)], collapse = ", ")
    )
  }
  for (arquivo in modulos) {
    source(arquivo, local = FALSE)
  }
  invisible(TRUE)
}

.econ_validar_eco01_rds <- function(
  ano, dir_bruto, dir_intermediario, ref_municipios
) {
  # A rotina ja aprovada confere cobertura, grupos, valores,
  # auditoria e identificacao territorial, sem gravar arquivos.
  preparado <- .preparar_eco01_csv(
    ano = ano,
    ref = ref_municipios,
    dir_bruto = dir_bruto,
    dir_intermediario = dir_intermediario
  )
  a <- preparado$auditoria

  # O exportador original valida a PRESENCA do MD5 do IPCA.
  # Aqui tambem exigimos correspondencia com o arquivo ATUAL
  # e com a linha PPC calculada sem escrita em disco.
  referencias <- preparar_referencias_eco01(salvar = FALSE)
  referencia <- referencias[ano_censo == ano]
  if (nrow(referencia) != 1L) {
    stop("Economica ECO01: limiar PPC nao encontrado para ", ano)
  }
  md5_atuais <- unique(as.character(a$md5_fonte_ipca))
  limiares_rds <- unique(as.numeric(a$linha_pobreza_mes))
  if (length(md5_atuais) != 1L ||
      length(limiares_rds) != 1L ||
      is.na(md5_atuais) || is.na(limiares_rds) ||
      !identical(
        md5_atuais, as.character(referencia$md5_fonte[[1L]])
      ) ||
      !isTRUE(all.equal(
        limiares_rds,
        as.numeric(referencia$linha_reais_mes_censo[[1L]]),
        tolerance = 1e-12, check.attributes = FALSE
      ))) {
    stop(
      "Economica ECO01: o RDS nao corresponde ao IPCA/limiar ",
      "PPC atual para ", ano, ". Nenhum RDS sera regravado."
    )
  }
  invisible(TRUE)
}

.econ_processar_eco01_ausente <- function(ano) {
  # Somente usado quando os DOIS RDS nacionais estao ausentes.
  # Os processadores estaduais historicos permanecem intactos.
  if (ano == 2000L) {
    source("so3.3/R/01_leitura/adaptar_censo_2000_economica.R",
           local = FALSE)
    source("so3.3/R/04_execucao/processar_eco01_2000.R",
           local = FALSE)
    resultado <- processar_eco01_2000(forcar_recalculo = FALSE)
  } else if (ano == 2010L) {
    source("so3.3/R/01_leitura/adaptar_censo_2010_economica.R",
           local = FALSE)
    source("so3.3/R/04_execucao/processar_eco01_2010.R",
           local = FALSE)
    resultado <- processar_eco01_2010(forcar_recalculo = FALSE)
  } else {
    source("so3.3/R/01_leitura/adaptar_censo_2022_economica.R",
           local = FALSE)
    source("so3.3/R/04_execucao/processar_eco01_2022.R",
           local = FALSE)
    resultado <- processar_eco01_2022(forcar_recalculo = FALSE)
  }
  if (!isTRUE(resultado$integral)) {
    stop("Economica ECO01: processamento nacional incompleto em ", ano)
  }
  invisible(TRUE)
}

.econ_conferir_dimensao_ano <- function(
  ano, caminhos, dir_bruto
) {
  # Os exportadores ja confrontaram cada CSV com seu RDS,
  # auditoria, e as fontes correspondentes. Nesta etapa
  # verificamos que os TRES usam precisamente as mesmas
  # chaves municipais e grupos no ano PRAIS solicitado.
  codigos_prais <- .ler_municipios_prais_sidra(ano, dir_bruto)
  n_mun <- length(codigos_prais)
  esperado <- c("2000" = 5507L, "2010" = 5565L, "2022" = 5570L)
  if (n_mun != unname(esperado[[as.character(ano)]])) {
    stop("Economica: cobertura PRAIS inesperada em ", ano)
  }
  grupos <- c("Total", "Masculino", "Feminino")
  chaves_esperadas <- sort(paste(
    rep(codigos_prais, each = length(grupos)),
    rep(grupos, times = n_mun), sep = "|"
  ))

  resumos <- lapply(seq_len(nrow(caminhos)), function(i) {
    arquivo <- caminhos$csv[[i]]
    if (!file.exists(arquivo)) {
      stop("Economica: CSV ausente durante conferencia: ", arquivo)
    }
    d <- data.table::fread(
      arquivo, sep = ";", dec = ".", encoding = "UTF-8",
      colClasses = list(character = c("uf", "cod_mun")),
      showProgress = FALSE
    )
    colunas <- c(
      "ano", "uf", "cod_mun", "nm_mun",
      "indicador", "grupo", "valor"
    )
    if (!identical(names(d), colunas) ||
        nrow(d) != 3L * n_mun ||
        anyNA(d[, ..colunas]) ||
        any(d$ano != ano) ||
        any(as.character(d$indicador) != caminhos$indicador[[i]]) ||
        any(!d$grupo %in% grupos) ||
        any(!grepl("^[0-9]{7}$", d$cod_mun)) ||
        any(d$uf != substr(d$cod_mun, 1L, 2L)) ||
        anyDuplicated(d, by = c("cod_mun", "grupo")) ||
        !is.numeric(d$valor) ||
        any(!is.finite(d$valor)) ||
        !identical(
          sort(paste(d$cod_mun, d$grupo, sep = "|")),
          chaves_esperadas
        )) {
      stop(
        "Economica: chaves, valores ou grupos divergentes em ",
        caminhos$indicador[[i]], " / ", ano
      )
    }
    if ((caminhos$id[[i]] == "ECO01" &&
         any(d$valor < 0 | d$valor > 100)) ||
        (caminhos$id[[i]] != "ECO01" &&
         any(d$valor <= 0))) {
      stop(
        "Economica: faixa de valores inesperada em ",
        caminhos$indicador[[i]], " / ", ano
      )
    }
    data.table::data.table(
      ano = ano,
      indicador = caminhos$indicador[[i]],
      municipios = data.table::uniqueN(d$cod_mun),
      registros = nrow(d),
      minimo = min(d$valor),
      maximo = max(d$valor),
      unidade = switch(
        caminhos$id[[i]],
        ECO01 = "Percentual da populacao",
        ECO02 = "R$ de 2010 por habitante",
        ECO03 = "Percentual do PIB"
      )
    )
  })
  resumo <- data.table::rbindlist(resumos, use.names = TRUE)
  if (nrow(resumo) != 3L ||
      sum(resumo$registros) != 9L * n_mun) {
    stop("Economica: dimensao incompleta em ", ano)
  }
  data.table::setorder(resumo, indicador)
  resumo[]
}

processar_dimensao_economica <- function(
  ano,
  forcar_recalculo = FALSE
) {
  ano <- .econ_ano_valido(ano)
  if (length(forcar_recalculo) != 1L ||
      !is.logical(forcar_recalculo) ||
      is.na(forcar_recalculo)) {
    stop("Economica: forcar_recalculo deve ser TRUE ou FALSE.")
  }
  if (isTRUE(forcar_recalculo)) {
    stop(
      "Economica: FORCAR_RECALCULO = TRUE nao e permitido na ",
      "execucao integrada. Execute um indicador isoladamente ",
      "para reprocessamento intencional."
    )
  }
  if (!exists("DIR_OUTPUT_BRUTO", inherits = TRUE) ||
      !exists("DIR_OUTPUT_INTERMEDIARIO", inherits = TRUE) ||
      !exists("ARQ_IPCA_1737", inherits = TRUE)) {
    stop("Economica: carregue config/config.R antes do processador.")
  }
  dir_bruto <- DIR_OUTPUT_BRUTO
  dir_intermediario <- DIR_OUTPUT_INTERMEDIARIO

  caminhos <- .econ_caminhos_ano(
    ano, dir_bruto, dir_intermediario
  )
  # Nao permite pares parciais, nem CSV orfao; valida os tres
  # estados ANTES de executar qualquer processador.
  .econ_conferir_estado_arquivos(caminhos)
  .econ_carregar_modulos()

  ref_municipios <- .ler_municipios_ibge_2025(file.path(
    "so3.3", "inputs", "referencias", "ibge",
    "municipios_ibge_2025.csv"
  ))

  message(
    "Economica ", ano, " | iniciando ECO01, ECO02 e ECO03 ",
    "(sem recalculo destrutivo)."
  )

  # ----------------------------------------------------------
  # ECO01: RDS preexistentes nao acionam o processador
  # censitario, que historicamente regrava RDS nacionais.
  # ----------------------------------------------------------
  i_eco01 <- match("ECO01", caminhos$id)
  rds_eco01_existente <- file.exists(caminhos$rds[[i_eco01]])
  if (rds_eco01_existente) {
    .econ_validar_eco01_rds(
      ano, dir_bruto, dir_intermediario, ref_municipios
    )
    status_eco01 <- "reutilizado_validado"
  } else {
    .econ_processar_eco01_ausente(ano)
    .econ_validar_eco01_rds(
      ano, dir_bruto, dir_intermediario, ref_municipios
    )
    status_eco01 <- "processado_validado"
  }
  exportacao_eco01 <- exportar_eco01_bruto_csv(
    ano = ano,
    dir_bruto = dir_bruto,
    dir_intermediario = dir_intermediario
  )

  # ----------------------------------------------------------
  # Insumos comuns do ECO02 e ECO03: somente uma leitura SIDRA.
  # Cada processador verifica suas fontes, assinaturas de
  # codigo, recortes e consistencia dos RDS originais.
  # ----------------------------------------------------------
  insumos_sidra <- ler_sidra_economica()
  insumos_pib <- ler_pib_municipios_eco02()
  diagnostico_sidra <- diagnosticar_sidra_economica(
    insumos = insumos_sidra, dir_bruto = dir_bruto
  )
  diagnostico_pib <- diagnosticar_pib_municipios_eco02(
    insumos_pib = insumos_pib,
    insumos_sidra = insumos_sidra,
    dir_bruto = dir_bruto
  )

  # ----------------------------------------------------------
  # ECO02: permite gravar somente se os dois RDS nao existirem;
  # resultados presentes so sao reutilizados se identicos.
  # ----------------------------------------------------------
  eco02 <- processar_eco02(
    ano = ano,
    insumos_pib = insumos_pib,
    insumos_sidra = insumos_sidra,
    diagnostico = diagnostico_pib,
    dir_bruto = dir_bruto,
    dir_intermediario = dir_intermediario,
    salvar = TRUE
  )
  if (!eco02$status %in% c(
    "gravado_validado", "reutilizado_validado"
  )) {
    stop("Economica ECO02: persistencia nao validada em ", ano)
  }
  exportacao_eco02 <- exportar_eco02_bruto_csv(
    ano = ano,
    insumos_pib = insumos_pib,
    insumos_sidra = insumos_sidra,
    dir_bruto = dir_bruto,
    dir_intermediario = dir_intermediario
  )

  # ----------------------------------------------------------
  # ECO03: mesmo contrato de persistencia conservadora.
  # ----------------------------------------------------------
  eco03 <- processar_eco03(
    ano = ano,
    insumos = insumos_sidra,
    diagnostico = diagnostico_sidra,
    dir_bruto = dir_bruto,
    dir_intermediario = dir_intermediario,
    salvar = TRUE
  )
  if (!eco03$status %in% c(
    "gravado_validado", "reutilizado_validado"
  )) {
    stop("Economica ECO03: persistencia nao validada em ", ano)
  }
  exportacao_eco03 <- exportar_eco03_bruto_csv(
    ano = ano,
    dir_bruto = dir_bruto,
    dir_intermediario = dir_intermediario
  )

  # ----------------------------------------------------------
  # Conferencia final: apenas os tres indicadores do ano
  # escolhido, todos com o mesmo universo territorial T/M/F.
  # ----------------------------------------------------------
  resumo <- .econ_conferir_dimensao_ano(
    ano, caminhos, dir_bruto
  )
  exportacao <- data.table::rbindlist(
    list(exportacao_eco01, exportacao_eco02, exportacao_eco03),
    use.names = TRUE
  )
  status_rds <- c(
    ECO01 = status_eco01,
    ECO02 = eco02$status,
    ECO03 = eco03$status
  )
  if (nrow(exportacao) != 3L ||
      anyNA(exportacao[, .(
        indicador, municipios, registros, arquivo_csv, status
      )]) ||
      !setequal(exportacao$indicador, caminhos$indicador) ||
      any(!exportacao$status %in% c(
        "gravado_validado", "reutilizado_validado"
      )) ||
      any(exportacao$municipios != unname(c(
        "2000" = 5507L, "2010" = 5565L, "2022" = 5570L
      )[as.character(ano)])) ||
      any(exportacao$registros != 3L * exportacao$municipios)) {
    stop("Economica: produtos CSV incompletos em ", ano)
  }
  data.table::setorder(exportacao, indicador)
  resumo[, status_rds := unname(status_rds[
    sub("_.*$", "", indicador)
  ])]
  if (anyNA(resumo$status_rds)) {
    stop("Economica: estado de persistencia incompleto.")
  }

  message(
    "Economica ", ano, " | integral concluida: 3 indicadores; ",
    sum(resumo$registros), " registros municipais (T/M/F)."
  )
  invisible(list(
    dimensao = "economica",
    ano = ano,
    integral = TRUE,
    resumo = resumo[],
    exportacao = exportacao[],
    caminhos = data.table::copy(caminhos)
  ))
}
