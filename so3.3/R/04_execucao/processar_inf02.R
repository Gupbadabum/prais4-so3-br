# ============================================================================
# PRAIS4 / SO3.3 / INF02 - Integracao dos produtos brutos aprovados da E03
# ============================================================================
#
# Este modulo NAO recalcula Qmlt, correspondencia territorial ou populacao.
# Os produtos E03 devem ser promovidos antes da execucao pelo main.R:
#
#   Rscript so3.3/executar_inf02_etapa03.R completo promover
#
# A validacao abaixo verifica integridade dos arquivos promovidos, nao
# representa harmonizacao territorial nem validacao hidrologica externa.
# Nenhum arquivo e escrito ou sobrescrito.
# ============================================================================

.infra_inf02_conferir_tabela <- function(dados, ano, origem) {
  campos <- c(
    "ano", "uf", "cod_mun", "nm_mun", "indicador", "grupo", "valor",
    "unidade", "tipo_desagregacao", "status_calculo",
    "situacao_qualidade", "compatibilidade_territorial"
  )
  if (!is.data.frame(dados)) {
    stop("INF02/", ano, ": ", origem, " nao contem tabela municipal longa.")
  }
  x <- data.table::as.data.table(data.table::copy(dados))
  faltantes <- setdiff(campos, names(x))
  if (length(faltantes)) {
    stop("INF02/", ano, ": campos ausentes em ", origem, ": ",
         paste(faltantes, collapse = ", "))
  }

  x[, cod_mun := as.character(cod_mun)]
  x[, uf := as.character(uf)]
  x[, grupo := as.character(grupo)]
  x[, status_calculo := as.character(status_calculo)]

  anos <- suppressWarnings(as.integer(x$ano))
  if (nrow(x) != 16713L ||
      data.table::uniqueN(x$cod_mun) != 5571L ||
      anyNA(anos) || any(anos != ano) ||
      anyNA(x$cod_mun) || any(!nzchar(x$cod_mun)) ||
      anyNA(x$uf) || any(!nzchar(x$uf)) ||
      anyNA(x$grupo) ||
      !setequal(unique(x$grupo), c("Total", "Masculino", "Feminino")) ||
      anyNA(x$indicador) ||
      any(x$indicador != "INF02_RECURSOS_HIDRICOS_PC") ||
      !is.numeric(x$valor) ||
      any(is.infinite(x$valor)) ||
      any(x$valor < 0, na.rm = TRUE) ||
      anyNA(x$status_calculo) ||
      any(!nzchar(x$status_calculo)) ||
      anyDuplicated(x, by = c("cod_mun", "grupo"))) {
    stop("INF02/", ano, ": estrutura, chaves ou valores invalidos em ", origem,
         ". Nenhum produto foi alterado.")
  }

  # INF02 e um atributo territorial. As tres linhas de um municipio
  # devem compartilhar valor (inclusive NA) e metadados da E03.
  grupos_por_municipio <- x[, .(
    n = .N,
    n_uf = data.table::uniqueN(uf, na.rm = FALSE),
    n_nome = data.table::uniqueN(nm_mun, na.rm = FALSE),
    n_indicador = data.table::uniqueN(indicador, na.rm = FALSE),
    n_valor = data.table::uniqueN(valor, na.rm = FALSE),
    n_status = data.table::uniqueN(status_calculo, na.rm = FALSE),
    n_unidade = data.table::uniqueN(unidade, na.rm = FALSE),
    n_tipo = data.table::uniqueN(tipo_desagregacao, na.rm = FALSE),
    n_qualidade = data.table::uniqueN(situacao_qualidade, na.rm = FALSE),
    n_territorio = data.table::uniqueN(compatibilidade_territorial,
                                      na.rm = FALSE)
  ), by = cod_mun]
  if (any(grupos_por_municipio$n != 3L) ||
      any(grupos_por_municipio$n_uf != 1L) ||
      any(grupos_por_municipio$n_nome != 1L) ||
      any(grupos_por_municipio$n_indicador != 1L) ||
      any(grupos_por_municipio$n_valor != 1L) ||
      any(grupos_por_municipio$n_status != 1L) ||
      any(grupos_por_municipio$n_unidade != 1L) ||
      any(grupos_por_municipio$n_tipo != 1L) ||
      any(grupos_por_municipio$n_qualidade != 1L) ||
      any(grupos_por_municipio$n_territorio != 1L)) {
    stop("INF02/", ano, ": divergencia entre grupos territoriais em ", origem)
  }

  # Contrato efetivamente publicado pela E03. Valores NA representam
  # situacoes documentadas, nunca falhas a serem imputadas automaticamente.
  n_disponiveis <- c("2000" = 5493L, "2010" = 5551L, "2022" = 5556L)
  status_calculado <- "CALCULADO_SEM_HARMONIZACAO_TERRITORIAL"
  status_na <- c(
    "DIVISAO_TERRITORIAL_ALTERADA_2025",
    "Q_NEGATIVA_NAO_INTERPRETAVEL",
    "SEM_CONTRIBUICAO_ESTIMADA",
    "SEM_POPULACAO_CENSITARIA"
  )
  total <- x[grupo == "Total"]
  estados <- unique(total$status_calculo)
  if (!setequal(estados, c(status_calculado, status_na))) {
    stop("INF02/", ano, ": conjunto de status da E03 diverge em ", origem,
         ": ", paste(sort(estados), collapse = ", "))
  }
  if (sum(!is.na(total$valor)) != n_disponiveis[[as.character(ano)]]) {
    stop("INF02/", ano, ": quantidade de valores disponiveis diverge da E03.")
  }
  if (any(!is.na(total$valor) & total$status_calculo != status_calculado) ||
      any(is.na(total$valor) & !total$status_calculo %in% status_na)) {
    stop("INF02/", ano,
         ": inconsistencia entre status_calculo e presenca de valor em ",
         origem, ".")
  }

  data.table::setorderv(x, c("cod_mun", "grupo"))
  x[]
}

.infra_inf02_conferir_par <- function(rds, csv, ano) {
  # As colunas do contrato E03 devem permanecer equivalentes no par.
  campos <- c(
    "ano", "uf", "cod_mun", "nm_mun", "indicador", "grupo", "valor",
    "unidade", "tipo_desagregacao", "status_calculo",
    "situacao_qualidade", "compatibilidade_territorial"
  )
  if (nrow(rds) != nrow(csv)) {
    stop("INF02/", ano, ": tamanhos diferentes entre RDS e CSV.")
  }
  for (nm in campos) {
    a <- rds[[nm]]
    b <- csv[[nm]]
    if (nm == "valor") {
      if (!identical(is.na(a), is.na(b)) ||
          !isTRUE(all.equal(a[!is.na(a)], b[!is.na(b)],
                            tolerance = 1e-12, check.attributes = FALSE))) {
        stop("INF02/", ano, ": campo valor difere entre RDS e CSV.")
      }
    } else if (!identical(as.character(a), as.character(b))) {
      stop("INF02/", ano, ": campo ", nm, " difere entre RDS e CSV.")
    }
  }
  invisible(TRUE)
}

processar_inf02 <- function(ano, dir_bruto = DIR_OUTPUT_BRUTO) {
  if (length(ano) != 1L || is.na(ano) ||
      !ano %in% c(2000L, 2010L, 2022L)) {
    stop("INF02: ano deve ser 2000, 2010 ou 2022.")
  }
  ano <- as.integer(ano)
  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("INF02: pacote data.table necessario.")
  }

  base <- file.path(dir_bruto, "infraestrutural", as.character(ano))
  prefixo <- paste0("INF02_RECURSOS_HIDRICOS_PC_", ano)
  arq_rds <- file.path(base, paste0(prefixo, ".rds"))
  arq_csv <- file.path(base, paste0(prefixo, ".csv"))
  if (!file.exists(arq_rds) || !file.exists(arq_csv)) {
    stop(
      "INF02/", ano, ": par bruto RDS/CSV nao encontrado ou incompleto em ",
      base, ". Promova antes a E03 com: ",
      "Rscript so3.3/executar_inf02_etapa03.R completo promover. ",
      "O main.R nao promove nem recalcula a E03."
    )
  }

  rds <- .infra_inf02_conferir_tabela(readRDS(arq_rds), ano, "RDS")
  csv <- .infra_inf02_conferir_tabela(
    data.table::fread(
      arq_csv,
      colClasses = list(character = c("uf", "cod_mun")),
      na.strings = c("", "NA"),
      encoding = "UTF-8",
      showProgress = FALSE
    ),
    ano, "CSV"
  )
  .infra_inf02_conferir_par(rds, csv, ano)

  total <- rds[grupo == "Total"]
  qa <- list(
    ano = ano,
    n_unidades = data.table::uniqueN(total$cod_mun),
    n_registros_grupo = nrow(rds),
    n_disponiveis = sum(!is.na(total$valor)),
    n_ausentes = sum(is.na(total$valor)),
    registros_por_status = as.list(table(total$status_calculo)),
    status_valores_calculados = "CALCULADO_SEM_HARMONIZACAO_TERRITORIAL",
    sem_harmonizacao_territorial = TRUE,
    verificacao = "Integridade e consistencia CSV/RDS da E03; nao e validacao hidrologica",
    md5 = as.list(tools::md5sum(c(arq_rds, arq_csv)))
  )

  message("INF02/", ano, " | bruto_reutilizado_validado_com_ressalva | ",
          qa$n_disponiveis, " valores, ", qa$n_ausentes,
          " NA | territorio nao harmonizado.")
  invisible(list(
    indicador = "INF02_RECURSOS_HIDRICOS_PC",
    ano = ano,
    status = "bruto_reutilizado_validado_com_ressalva",
    integral = TRUE,
    qa = qa,
    arquivo_bruto_rds = arq_rds,
    arquivo_bruto_csv = arq_csv
  ))
}
