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
