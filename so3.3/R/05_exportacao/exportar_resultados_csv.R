# ============================================================
# PRAIS4 / SO3.3
# EXPORTACAO DOS INDICADORES MUNICIPAIS EM CSV
#
# Etapa publica de distribuicao: somente resultados municipais.
# Nao altera os RDS, nao recalcula indicadores e nao acessa
# microdados ou checkpoints metodologicos.
#
# Referencia de nomes: malha municipal IBGE 2025. A associacao
# usa cod_mun, apenas como rotulo; nao muda o recorte territorial
# de 2000, 2010 ou 2022.
#
# Execucao a partir da raiz do repositorio:
# source("so3.3/R/05_exportacao/exportar_resultados_csv.R")
# exportar_social_bruto_csv(2000L, somente_validar = TRUE)
# exportar_social_bruto_csv(2000L)
# ============================================================

.ler_municipios_ibge_2025 <- function(arquivo) {
  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("O pacote data.table e necessario.")
  }
  if (!file.exists(arquivo)) {
    stop("Referencia municipal ausente: ", arquivo)
  }

  ref <- data.table::fread(
    arquivo,
    sep = ";",
    encoding = "UTF-8",
    colClasses = list(character = "CD_MUN"),
    showProgress = FALSE
  )
  if (!setequal(names(ref), c("CD_MUN", "NM_MUN"))) {
    stop("Referencia IBGE 2025: esperadas as colunas CD_MUN e NM_MUN.")
  }
  ref[, CD_MUN := trimws(as.character(CD_MUN))]
  ref[, NM_MUN := trimws(as.character(NM_MUN))]

  if (nrow(ref) != 5573L ||
      anyNA(ref[, .(CD_MUN, NM_MUN)]) ||
      any(!grepl("^[0-9]{7}$", ref$CD_MUN)) ||
      any(!nzchar(ref$NM_MUN)) ||
      anyDuplicated(ref$CD_MUN) > 0L) {
    stop("Referencia municipal IBGE 2025 incompleta, duplicada ou invalida.")
  }

  # Duas unidades operacionais da malha nao sao municipios.
  areas_operacionais <- c("4300001", "4300002")
  if (!all(areas_operacionais %in% ref$CD_MUN)) {
    stop("Referencia IBGE 2025 sem as duas areas operacionais esperadas.")
  }
  ref <- ref[!CD_MUN %in% areas_operacionais, .(CD_MUN, NM_MUN)]
  if (nrow(ref) != 5571L) {
    stop("Referencia municipal inesperada apos excluir areas operacionais.")
  }
  ref
}

.preparar_indicador_social_csv <- function(
  caminho_rds, ano, indicador, ref, municipios_esperados
) {
  if (!file.exists(caminho_rds)) {
    stop("Produto bruto ausente: ", caminho_rds)
  }
  d <- data.table::as.data.table(readRDS(caminho_rds))
  colunas <- c("ano", "uf", "cod_mun", "dimensao",
               "indicador", "grupo", "valor")
  faltantes <- setdiff(colunas, names(d))
  if (length(faltantes)) {
    stop("Colunas ausentes em ", caminho_rds, ": ",
         paste(faltantes, collapse = ", "))
  }

  grupos <- c("Total", "Masculino", "Feminino")
  codigos <- trimws(as.character(d$cod_mun))
  ufs <- trimws(as.character(d$uf))
  grupos_dados <- as.character(d$grupo)

  if (!nrow(d) || anyNA(d[, ..colunas]) ||
      any(as.integer(d$ano) != ano) ||
      any(as.character(d$dimensao) != "Social") ||
      any(as.character(d$indicador) != indicador) ||
      any(!grupos_dados %in% grupos) ||
      !setequal(unique(grupos_dados), grupos)) {
    stop("Identificadores ou grupos invalidos em ", caminho_rds)
  }

  if (any(!grepl("^[0-9]{7}$", codigos)) ||
      any(!grepl("^[0-9]{2}$", ufs)) ||
      any(ufs != substr(codigos, 1L, 2L))) {
    stop("Geocodigo municipal ou UF inconsistente em ", caminho_rds)
  }

  if (!is.numeric(d$valor) ||
      any(!is.finite(d$valor)) ||
      any(d$valor < 0) ||
      (indicador != "SOC03_EV0" && any(d$valor > 100))) {
    stop("Valores municipais ausentes ou fora de faixa em ", caminho_rds)
  }

  n_municipios <- data.table::uniqueN(codigos)
  if (!is.null(municipios_esperados) &&
      n_municipios != municipios_esperados) {
    stop("Cobertura municipal inesperada em ", caminho_rds,
         ": obtidos ", n_municipios,
         ", esperados ", municipios_esperados)
  }
  if (anyDuplicated(data.frame(cod_mun = codigos, grupo = grupos_dados)) ||
      nrow(d) != 3L * n_municipios) {
    stop("Duplicidades ou grupos municipais incompletos em ", caminho_rds)
  }

  idx <- match(codigos, ref$CD_MUN)
  if (anyNA(idx)) {
    sem_nome <- unique(codigos[is.na(idx)])
    stop(
      "Municipios sem nome na referencia IBGE 2025 para ",
      indicador, "/", ano, ": ",
      paste(head(sem_nome, 12L), collapse = ", "),
      ". Nenhum valor sera descartado."
    )
  }

  resultado <- data.table::data.table(
    ano = as.integer(d$ano),
    uf = ufs,
    cod_mun = codigos,
    nm_mun = ref$NM_MUN[idx],
    indicador = as.character(d$indicador),
    grupo = grupos_dados,
    valor = as.numeric(d$valor)
  )

  resultado[, ordem_grupo := match(grupo, grupos)]
  data.table::setorder(resultado, cod_mun, ordem_grupo)
  resultado[, ordem_grupo := NULL]
  resultado
}

# Exportador v1: somente SOC01, SOC02, SOC03 e SOC04 brutos.
# As outras categorias (tratado, normalizado, componentes e dvi)
# serao incorporadas quando seus respectivos RDS forem produzidos.
exportar_social_bruto_csv <- function(
  ano,
  arquivo_municipios = file.path(
    "so3.3", "inputs", "referencias", "ibge", "municipios_ibge_2025.csv"
  ),
  dir_bruto = file.path("so3.3", "outputs", "bruto"),
  somente_validar = FALSE,
  sobrescrever = FALSE,
  conferir_leitura = TRUE
) {
  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("O pacote data.table e necessario.")
  }
  if (length(ano) != 1L || is.na(ano) ||
      !is.numeric(ano) || !ano %in% c(2000L, 2010L, 2022L)) {
    stop("Ano invalido. Use 2000, 2010 ou 2022.")
  }
  ano <- as.integer(ano)
  ids <- c("SOC01_ALF15", "SOC02_RURAL",
           "SOC03_EV0", "SOC04_POP1564")
  n_esperado <- c("2000" = 5507L, "2010" = 5565L, "2022" = 5570L)
  dir_ano <- file.path(dir_bruto, "social", as.character(ano))
  arquivos_rds <- file.path(dir_ano, paste0(ids, "_", ano, ".rds"))
  arquivos_csv <- file.path(dir_ano, paste0(ids, "_", ano, ".csv"))

  if (!all(file.exists(arquivos_rds))) {
    stop("Produtos RDS ausentes: ",
         paste(arquivos_rds[!file.exists(arquivos_rds)], collapse = ", "))
  }
  if (!isTRUE(somente_validar) &&
      !isTRUE(sobrescrever) &&
      any(file.exists(arquivos_csv))) {
    stop("CSV ja existente; nao sobrescrevendo: ",
         paste(arquivos_csv[file.exists(arquivos_csv)], collapse = ", "),
         ". Use sobrescrever=TRUE somente apos revisar.")
  }

  ref <- .ler_municipios_ibge_2025(arquivo_municipios)
  preparados <- lapply(seq_along(ids), function(i) {
    .preparar_indicador_social_csv(
      caminho_rds = arquivos_rds[i],
      ano = ano,
      indicador = ids[i],
      ref = ref,
      municipios_esperados = unname(n_esperado[as.character(ano)])
    )
  })
  names(preparados) <- ids

  manifesto <- data.table::data.table(
    ano = ano,
    indicador = ids,
    municipios = vapply(preparados, function(x) {
      data.table::uniqueN(x$cod_mun)
    }, integer(1)),
    registros = vapply(preparados, nrow, integer(1)),
    arquivo_csv = arquivos_csv,
    gravado = FALSE
  )

  # Prepara e valida os quatro indicadores antes de gravar qualquer CSV.
  if (isTRUE(somente_validar)) {
    message("Validacao concluida: nenhum CSV foi escrito.")
    return(manifesto[])
  }

  dir.create(dir_ano, recursive = TRUE, showWarnings = FALSE)
  for (i in seq_along(ids)) {
    data.table::fwrite(
      preparados[[i]],
      file = arquivos_csv[i],
      sep = ";",
      quote = "auto",
      dec = ".",
      bom = FALSE,
      na = ""
    )

    if (isTRUE(conferir_leitura)) {
      lido <- data.table::fread(
        arquivos_csv[i],
        sep = ";",
        colClasses = list(character = c("uf", "cod_mun")),
        encoding = "UTF-8",
        showProgress = FALSE
      )
      original <- preparados[[i]]
      if (nrow(lido) != nrow(original) ||
          !identical(names(lido), names(original)) ||
          !identical(lido$cod_mun, original$cod_mun) ||
          !identical(lido$nm_mun, original$nm_mun) ||
          !identical(lido$grupo, original$grupo) ||
          anyNA(lido$valor) ||
          !isTRUE(all.equal(lido$valor, original$valor,
                            tolerance = 1e-12))) {
        stop("Falha na leitura de verificacao do CSV: ", arquivos_csv[i])
      }
    }
    manifesto[i, gravado := TRUE]
    message("CSV validado: ", arquivos_csv[i])
  }
  manifesto[]
}


# ============================================================
# ECO01 - EXPORTACAO ECONOMICA BRUTA E VALIDACAO CONJUNTA
#
# Os processadores 2000, 2010 e 2022 produzem RDS nacionais
# e auditorias. Este bloco exporta apenas os valores municipais.
# Mantem o mesmo esquema publico da dimensao Social:
#   ano;uf;cod_mun;nm_mun;indicador;grupo;valor
#
# Regras:
# - validar RDS e auditoria antes de exportar;
# - verificar a releitura integral do CSV;
# - reutilizar CSV existente somente se coincidir com o RDS;
# - nunca sobrescrever CSV divergente automaticamente;
# - preservar RDS, checkpoints e demais produtos existentes.
# ============================================================

.caminhos_eco01_csv <- function(
  ano, dir_bruto, dir_intermediario
) {
  ano <- as.integer(ano)
  nome <- paste0("ECO01_POV3_PPC21_", ano)
  list(
    rds = file.path(
      dir_bruto, "economica", as.character(ano), paste0(nome, ".rds")
    ),
    auditoria = file.path(
      dir_intermediario, "economica", as.character(ano),
      paste0("auditoria_eco01_", ano, ".rds")
    ),
    csv = file.path(
      dir_bruto, "economica", as.character(ano), paste0(nome, ".csv")
    )
  )
}

.preparar_eco01_csv <- function(
  ano, ref, dir_bruto, dir_intermediario
) {
  if (!exists("validar_resultados_eco01", mode = "function",
              inherits = TRUE)) {
    stop("ECO01 CSV: carregue o modulo eco01_pobreza.R.")
  }
  if (length(ano) != 1L || is.na(ano) ||
      !is.numeric(ano) || !ano %in% c(2000L, 2010L, 2022L)) {
    stop("ECO01 CSV: ano invalido.")
  }
  ano <- as.integer(ano)
  n_esperados <- c("2000" = 5507L, "2010" = 5565L, "2022" = 5570L)
  n_mun <- unname(n_esperados[as.character(ano)])
  caminhos <- .caminhos_eco01_csv(ano, dir_bruto, dir_intermediario)

  if (!file.exists(caminhos$rds) || !file.exists(caminhos$auditoria)) {
    stop("ECO01 CSV: RDS ou auditoria nacional ausente para ", ano,
         ". Nenhum CSV sera gerado.")
  }
  bruto <- data.table::as.data.table(readRDS(caminhos$rds))
  auditoria <- data.table::as.data.table(readRDS(caminhos$auditoria))
  validar_resultados_eco01(
    bruto, auditoria, ano = ano, municipios_esperados = n_mun
  )

  # A validacao compartilhada verifica as taxas e a aditividade
  # de numeradores/denominadores. Conferir adicionalmente as
  # chaves publicas, a referencia municipal e a cobertura RDPC.
  ids <- c("ano", "uf", "cod_mun", "grupo", "indicador", "valor")
  codigos <- as.character(bruto$cod_mun)
  ufs <- as.character(bruto$uf)
  if (anyNA(bruto[, ..ids]) ||
      any(!grepl("^[0-9]{7}$", codigos)) ||
      any(!grepl("^[0-9]{2}$", ufs)) ||
      any(ufs != substr(codigos, 1L, 2L))) {
    stop("ECO01 CSV: identificadores municipais invalidos em ", ano)
  }
  tolerancia_numerica <- 1e-8

  if (!"cobertura_rdpc" %in% names(auditoria) ||
      anyNA(auditoria$cobertura_rdpc) ||
      any(!is.finite(auditoria$cobertura_rdpc) |
          auditoria$cobertura_rdpc < -tolerancia_numerica |
          auditoria$cobertura_rdpc > 100 + tolerancia_numerica)) {
    stop("ECO01 CSV: cobertura da RDPC invalida em ", ano)
  }

  md5 <- unique(as.character(auditoria$md5_fonte_ipca))
  if (length(md5) != 1L || is.na(md5) || !nzchar(md5)) {
    stop("ECO01 CSV: fonte monetaria inconsistente em ", ano)
  }

  pos <- match(codigos, ref$CD_MUN)
  if (anyNA(pos)) {
    stop(
      "ECO01 CSV: municipios sem correspondente na referencia ",
      "IBGE 2025 em ", ano, ": ",
      paste(head(unique(codigos[is.na(pos)]), 12L), collapse = ", "),
      ". Nenhum municipio sera descartado."
    )
  }

  tabela <- data.table::data.table(
    ano = as.integer(bruto$ano),
    uf = ufs,
    cod_mun = codigos,
    nm_mun = ref$NM_MUN[pos],
    indicador = as.character(bruto$indicador),
    grupo = as.character(bruto$grupo),
    valor = as.numeric(bruto$valor)
  )
  tabela[, ordem_grupo := match(
    grupo, c("Total", "Masculino", "Feminino")
  )]
  data.table::setorder(tabela, cod_mun, ordem_grupo)
  tabela[, ordem_grupo := NULL]

  list(
    tabela = tabela[],
    auditoria = auditoria,
    md5_ipca = md5,
    caminhos = caminhos
  )
}

.conferir_eco01_csv <- function(arquivo_csv, esperado) {
  if (!file.exists(arquivo_csv)) {
    stop("ECO01 CSV: arquivo para conferencia ausente: ", arquivo_csv)
  }
  lido <- data.table::fread(
    arquivo_csv,
    sep = ";",
    dec = ".",
    colClasses = list(character = c("uf", "cod_mun")),
    encoding = "UTF-8",
    showProgress = FALSE
  )
  chaves <- c(
    "ano", "uf", "cod_mun", "nm_mun", "indicador", "grupo"
  )

  if (!identical(names(lido), names(esperado)) ||
      nrow(lido) != nrow(esperado) ||
      !all(vapply(chaves, function(x) {
        identical(lido[[x]], esperado[[x]])
      }, logical(1L))) ||
      !is.numeric(lido$valor) ||
      anyNA(lido$valor) ||
      !isTRUE(all.equal(
        lido$valor, esperado$valor,
        tolerance = 1e-12, check.attributes = FALSE
      ))) {
    stop(
      "ECO01 CSV: divergencia entre CSV e RDS: ", arquivo_csv,
      ". O arquivo existente nao foi modificado."
    )
  }
  invisible(TRUE)
}

exportar_eco01_bruto_csv <- function(
  ano,
  arquivo_municipios = file.path(
    "so3.3", "inputs", "referencias", "ibge",
    "municipios_ibge_2025.csv"
  ),
  dir_bruto = file.path("so3.3", "outputs", "bruto"),
  dir_intermediario = file.path("so3.3", "outputs", "intermediario"),
  somente_validar = FALSE
) {
  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("ECO01 CSV: pacote data.table necessario.")
  }
  ref <- .ler_municipios_ibge_2025(arquivo_municipios)
  preparado <- .preparar_eco01_csv(
    ano, ref, dir_bruto, dir_intermediario
  )
  csv <- preparado$caminhos$csv

  if (file.exists(csv)) {
    .conferir_eco01_csv(csv, preparado$tabela)
    status <- "reutilizado_validado"
  } else if (isTRUE(somente_validar)) {
    status <- "validado_sem_gravacao"
  } else {
    # A escrita temporaria permite conferir o arquivo antes de
    # disponibiliza-lo no destino final.
    dir.create(dirname(csv), recursive = TRUE, showWarnings = FALSE)
    temporario <- tempfile(
      pattern = ".eco01_csv_",
      tmpdir = dirname(csv),
      fileext = ".csv"
    )
    on.exit(
      if (file.exists(temporario)) unlink(temporario),
      add = TRUE
    )
    data.table::fwrite(
      preparado$tabela,
      file = temporario,
      sep = ";",
      quote = "auto",
      dec = ".",
      bom = FALSE,
      na = ""
    )
    .conferir_eco01_csv(temporario, preparado$tabela)
    if (file.exists(csv)) {
      stop("ECO01 CSV: o destino apareceu durante a exportacao: ", csv)
    }
    if (!file.rename(temporario, csv)) {
      stop("ECO01 CSV: nao foi possivel finalizar a escrita: ", csv)
    }
    status <- "gravado_validado"
  }

  message("ECO01 CSV | ", ano, " | ", status, " | ", csv)
  data.table::data.table(
    ano = as.integer(ano),
    indicador = "ECO01_POV3_PPC21",
    municipios = data.table::uniqueN(preparado$tabela$cod_mun),
    registros = nrow(preparado$tabela),
    arquivo_csv = csv,
    status = status
  )
}

# Confronta TODOS os CSVs nacionais com seus RDS e auditorias.
# A funcao nao altera arquivos; apenas le e valida produtos.
validar_eco01_tres_recortes_csv <- function(
  arquivo_municipios = file.path(
    "so3.3", "inputs", "referencias", "ibge",
    "municipios_ibge_2025.csv"
  ),
  dir_bruto = file.path("so3.3", "outputs", "bruto"),
  dir_intermediario = file.path("so3.3", "outputs", "intermediario")
) {
  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("ECO01: pacote data.table necessario.")
  }
  anos <- c(2000L, 2010L, 2022L)
  ref <- .ler_municipios_ibge_2025(arquivo_municipios)

  preparados <- lapply(anos, function(ano) {
    produto <- .preparar_eco01_csv(
      ano, ref, dir_bruto, dir_intermediario
    )
    .conferir_eco01_csv(produto$caminhos$csv, produto$tabela)
    produto
  })

  fontes <- vapply(
    preparados, function(x) x$md5_ipca, character(1L)
  )
  if (length(unique(fontes)) != 1L) {
    stop("ECO01: os tres censos nao usam a mesma fonte IPCA.")
  }

  conjunto <- data.table::rbindlist(
    lapply(preparados, function(x) x$tabela),
    use.names = TRUE
  )
  if (nrow(conjunto) != 49926L ||
      anyDuplicated(conjunto, by = c("ano", "cod_mun", "grupo")) ||
      !identical(sort(unique(conjunto$ano)), anos) ||
      anyNA(conjunto$valor) ||
      any(!is.finite(conjunto$valor) |
          conjunto$valor < 0 | conjunto$valor > 100)) {
    stop("ECO01: integracao 2000/2010/2022 inconsistente.")
  }

  resumo <- conjunto[, .(
    municipios = data.table::uniqueN(cod_mun),
    registros = .N,
    minimo = min(valor),
    maximo = max(valor)
  ), by = .(ano, grupo)]
  data.table::setorder(resumo, ano, grupo)

  cobertura <- data.table::rbindlist(lapply(preparados, function(x) {
    x$auditoria[, .(
      cobertura_min = min(cobertura_rdpc),
      cobertura_p05 = as.numeric(
        stats::quantile(cobertura_rdpc, probs = 0.05)
      ),
      cobertura_mediana = stats::median(cobertura_rdpc),
      municipios_abaixo_95 = sum(cobertura_rdpc < 95)
    ), by = .(ano, grupo)]
  }), use.names = TRUE)
  data.table::setorder(cobertura, ano, grupo)

  message(
    "ECO01 | Tres CSVs conferidos com RDS e auditorias. ",
    "Total: ", nrow(conjunto), " registros municipais."
  )
  list(
    resumo = resumo[],
    cobertura = cobertura[],
    registros = nrow(conjunto),
    md5_fonte_ipca = fontes[[1L]]
  )
}


# ============================================================
# ECO03_AGROPIB - EXPORTACAO BRUTA E CONFERENCIA DOS 3 RECORTES
#
# Uma linha publica por municipio, ano PRAIS e grupo T/M/F.
# O valor de cada grupo e identico (escopo comum_municipal).
# O ano-fonte (2002/2010/2021) fica no RDS/auditoria.
# CSV publico: ano;uf;cod_mun;nm_mun;indicador;grupo;valor
#
# As fontes, os RDS e o codigo ECO03 sao verificados ANTES de
# gravar. CSV existente divergente jamais e sobrescrito.
# ============================================================

.caminhos_eco03_csv <- function(ano, dir_bruto, dir_intermediario) {
  ano <- .validar_ano_eco03(ano)
  nome <- paste0("ECO03_AGROPIB_", ano)
  list(
    rds = file.path(
      dir_bruto, "economica", as.character(ano), paste0(nome, ".rds")
    ),
    auditoria = file.path(
      dir_intermediario, "economica", as.character(ano),
      paste0("auditoria_eco03_", ano, ".rds")
    ),
    csv = file.path(
      dir_bruto, "economica", as.character(ano), paste0(nome, ".csv")
    )
  )
}

.preparar_eco03_csv <- function(
  ano, ref, dir_bruto, dir_intermediario, dir_sidra
) {
  dependencias <- c(
    ".validar_ano_eco03", "validar_resultados_eco03",
    ".ler_municipios_prais_sidra", ".assinatura_codigo_eco03"
  )
  faltantes <- dependencias[!vapply(
    dependencias, exists, logical(1L),
    mode = "function", inherits = TRUE
  )]
  if (length(faltantes)) {
    stop("ECO03 CSV: carregue antes os modulos de leitura, ",
         "diagnostico, calculo e processamento do ECO03: ",
         paste(faltantes, collapse = ", "))
  }
  ano <- .validar_ano_eco03(ano)
  caminhos <- .caminhos_eco03_csv(ano, dir_bruto, dir_intermediario)
  if (!all(file.exists(c(caminhos$rds, caminhos$auditoria)))) {
    stop("ECO03 CSV: RDS ou auditoria ausente para ", ano,
         ". Nenhum CSV sera gerado.")
  }
  bruto <- data.table::as.data.table(readRDS(caminhos$rds))
  auditoria_rds <- readRDS(caminhos$auditoria)
  assinatura_salva <- attr(
    auditoria_rds, "assinatura_codigo_eco03", exact = TRUE
  )
  auditoria <- data.table::as.data.table(auditoria_rds)
  codigos_prais <- .ler_municipios_prais_sidra(ano, dir_bruto)
  validar_resultados_eco03(bruto, auditoria, ano, codigos_prais)

  assinatura_atual <- .assinatura_codigo_eco03()
  if (is.null(assinatura_salva) ||
      !identical(assinatura_salva, assinatura_atual)) {
    stop("ECO03 CSV: assinatura do codigo difere da auditoria RDS em ",
         ano, ". Nenhum produto sera sobrescrito.")
  }

  # MD5 de ambos os arquivos 5938: precisam coincidir com
  # aqueles registrados na auditoria municipal.
  fontes <- file.path(
    dir_sidra, c("tabela5938.csv", "tabela5938_vab.csv")
  )
  if (!all(file.exists(fontes))) {
    stop("ECO03 CSV: fonte SIDRA ausente: ",
         paste(fontes[!file.exists(fontes)], collapse = ", "))
  }
  md5_atual <- unname(as.character(tools::md5sum(fontes)))
  md5_auditoria <- c(
    unique(as.character(auditoria$md5_tabela5938)),
    unique(as.character(auditoria$md5_tabela5938_vab))
  )
  if (length(md5_auditoria) != 2L ||
      anyNA(md5_auditoria) ||
      !identical(md5_atual, unname(md5_auditoria))) {
    stop("ECO03 CSV: assinaturas das fontes SIDRA divergentes em ", ano,
         ". Nenhum CSV sera gravado.")
  }

  codigos <- as.character(bruto$cod_mun)
  ufs <- as.character(bruto$uf)
  pos <- match(codigos, ref$CD_MUN)
  if (anyNA(pos)) {
    stop(
      "ECO03 CSV: municipios sem nome IBGE 2025 em ", ano, ": ",
      paste(head(unique(codigos[is.na(pos)]), 12L), collapse = ", "),
      ". Nenhum registro foi descartado."
    )
  }
  if (any(!grepl("^[0-9]{2}$", ufs)) ||
      any(ufs != substr(codigos, 1L, 2L))) {
    stop("ECO03 CSV: geocodigos municipais inconsistentes em ", ano)
  }

  tabela <- data.table::data.table(
    ano = as.integer(bruto$ano),
    uf = ufs,
    cod_mun = codigos,
    nm_mun = ref$NM_MUN[pos],
    indicador = as.character(bruto$indicador),
    grupo = as.character(bruto$grupo),
    valor = as.numeric(bruto$valor)
  )
  tabela[, ordem_grupo := match(
    grupo, c("Total", "Masculino", "Feminino")
  )]
  if (anyNA(tabela$ordem_grupo)) {
    stop("ECO03 CSV: grupo desconhecido em ", ano)
  }
  data.table::setorder(tabela, cod_mun, ordem_grupo)
  tabela[, ordem_grupo := NULL]

  list(
    tabela = tabela[],
    auditoria = auditoria,
    md5_fontes = md5_atual,
    caminhos = caminhos
  )
}

.conferir_eco03_csv <- function(arquivo_csv, esperado) {
  if (!file.exists(arquivo_csv)) {
    stop("ECO03 CSV: arquivo ausente: ", arquivo_csv)
  }
  lido <- data.table::fread(
    arquivo_csv, sep = ";", dec = ".",
    colClasses = list(character = c("uf", "cod_mun")),
    encoding = "UTF-8", showProgress = FALSE
  )
  identificadores <- c(
    "ano", "uf", "cod_mun", "nm_mun", "indicador", "grupo"
  )
  if (!identical(names(lido), names(esperado)) ||
      nrow(lido) != nrow(esperado) ||
      !all(vapply(identificadores, function(campo) {
        identical(lido[[campo]], esperado[[campo]])
      }, logical(1L))) ||
      !is.numeric(lido$valor) ||
      anyNA(lido$valor) ||
      !isTRUE(all.equal(
        lido$valor, esperado$valor, tolerance = 1e-12,
        check.attributes = FALSE
      ))) {
    stop("ECO03 CSV: divergencia entre CSV e RDS: ", arquivo_csv,
         ". Arquivo existente nao foi modificado.")
  }
  invisible(TRUE)
}

exportar_eco03_bruto_csv <- function(
  ano,
  arquivo_municipios = file.path(
    "so3.3", "inputs", "referencias", "ibge",
    "municipios_ibge_2025.csv"
  ),
  dir_sidra = file.path(
    "so3.3", "inputs", "referencias", "sidra"
  ),
  dir_bruto = file.path("so3.3", "outputs", "bruto"),
  dir_intermediario = file.path("so3.3", "outputs", "intermediario"),
  somente_validar = FALSE
) {
  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("ECO03 CSV: pacote data.table necessario.")
  }
  if (length(somente_validar) != 1L ||
      !is.logical(somente_validar) || is.na(somente_validar)) {
    stop("ECO03 CSV: somente_validar deve ser TRUE ou FALSE.")
  }
  ref <- .ler_municipios_ibge_2025(arquivo_municipios)
  preparado <- .preparar_eco03_csv(
    ano, ref, dir_bruto, dir_intermediario, dir_sidra
  )
  csv <- preparado$caminhos$csv
  if (file.exists(csv)) {
    .conferir_eco03_csv(csv, preparado$tabela)
    status <- "reutilizado_validado"
  } else if (isTRUE(somente_validar)) {
    status <- "validado_sem_gravacao"
  } else {
    dir.create(dirname(csv), recursive = TRUE, showWarnings = FALSE)
    temporario <- tempfile(
      pattern = ".eco03_csv_",
      tmpdir = dirname(csv),
      fileext = ".csv"
    )
    on.exit(
      if (file.exists(temporario)) unlink(temporario),
      add = TRUE
    )
    data.table::fwrite(
      preparado$tabela, temporario,
      sep = ";", quote = "auto",
      dec = ".", bom = FALSE, na = ""
    )
    .conferir_eco03_csv(temporario, preparado$tabela)
    if (file.exists(csv)) {
      stop("ECO03 CSV: destino apareceu durante a exportacao: ", csv)
    }
    if (!file.rename(temporario, csv)) {
      stop("ECO03 CSV: nao foi possivel finalizar o arquivo: ", csv)
    }
    status <- "gravado_validado"
  }
  message("ECO03 CSV | ", ano, " | ", status, " | ", csv)
  data.table::data.table(
    ano = as.integer(ano),
    indicador = "ECO03_AGROPIB",
    municipios = data.table::uniqueN(preparado$tabela$cod_mun),
    registros = nrow(preparado$tabela),
    arquivo_csv = csv,
    status = status
  )[]
}

validar_eco03_tres_recortes_csv <- function(
  arquivo_municipios = file.path(
    "so3.3", "inputs", "referencias", "ibge",
    "municipios_ibge_2025.csv"
  ),
  dir_sidra = file.path(
    "so3.3", "inputs", "referencias", "sidra"
  ),
  dir_bruto = file.path("so3.3", "outputs", "bruto"),
  dir_intermediario = file.path("so3.3", "outputs", "intermediario")
) {
  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("ECO03 CSV: pacote data.table necessario.")
  }
  anos <- c(2000L, 2010L, 2022L)
  ref <- .ler_municipios_ibge_2025(arquivo_municipios)
  preparados <- lapply(anos, function(ano) {
    p <- .preparar_eco03_csv(
      ano, ref, dir_bruto, dir_intermediario, dir_sidra
    )
    .conferir_eco03_csv(p$caminhos$csv, p$tabela)
    p
  })
  assinaturas <- vapply(
    preparados, function(x) paste(x$md5_fontes, collapse = ":"),
    character(1L)
  )
  if (length(unique(assinaturas)) != 1L) {
    stop("ECO03 CSV: fontes distintas entre os tres recortes.")
  }

  conjunto <- data.table::rbindlist(
    lapply(preparados, function(x) x$tabela), use.names = TRUE
  )
  esperado <- sum(c(5507L, 5565L, 5570L)) * 3L
  if (nrow(conjunto) != esperado ||
      anyNA(conjunto$valor) ||
      any(!is.finite(conjunto$valor) | conjunto$valor < 0) ||
      anyDuplicated(conjunto, by = c("ano", "cod_mun", "grupo")) ||
      !identical(sort(unique(conjunto$ano)), anos) ||
      any(conjunto$indicador != "ECO03_AGROPIB")) {
    stop("ECO03 CSV: integracao municipal dos tres recortes inconsistente.")
  }
  resumo <- conjunto[, .(
    municipios = data.table::uniqueN(cod_mun),
    registros = .N,
    minimo_pct = min(valor),
    maximo_pct = max(valor)
  ), by = .(ano, grupo)]
  data.table::setorder(resumo, ano, grupo)
  auditoria <- data.table::rbindlist(
    lapply(preparados, function(x) x$auditoria), use.names = TRUE
  )
  auditoria_resumo <- auditoria[, .(
    municipios = .N,
    ano_fonte = unique(ano_fonte),
    vab_zero = sum(vab_zero),
    participacoes_acima_100 = sum(vab_acima_100)
  ), by = ano]
  data.table::setorder(auditoria_resumo, ano)

  message(
    "ECO03 | Tres CSVs conferidos com os RDS, as auditorias ",
    "e as fontes SIDRA. Total: ", nrow(conjunto), " registros."
  )
  list(
    resumo = resumo[],
    auditoria = auditoria_resumo[],
    registros = nrow(conjunto),
    md5_fontes = preparados[[1L]]$md5_fontes
  )
}
