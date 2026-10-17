# ============================================================
# PRAIS4 / SO3.3 - DIAGNOSTICO DOS INSUMOS ECONOMICOS SIDRA
# Auditoria independente das Tabelas 5938 e 6784.
# Referencia territorial: cod_mun dos CSVs SOC01 municipais.
# Apenas diagnostico: nao grava arquivos nem calcula ECO02/03.
#
# Uso, a partir da raiz do repositorio:
#   source("so3.3/R/01_leitura/ler_sidra_economica.R")
#   source("so3.3/R/03_diagnostico/diagnosticar_sidra_economica.R")
#   auditoria <- diagnosticar_sidra_economica()
#   auditoria$resumo_fontes
#   auditoria$cobertura_territorial
#   auditoria$casos_vab_acima_pib
# ============================================================

if (!requireNamespace("data.table", quietly = TRUE)) {
  stop("Diagnostico SIDRA economica: pacote data.table necessario.")
}

.ler_municipios_prais_sidra <- function(ano, dir_bruto) {
  arquivo <- file.path(dir_bruto, "social", as.character(ano),
                       paste0("SOC01_ALF15_", ano, ".csv"))
  if (!file.exists(arquivo)) {
    stop("Diagnostico SIDRA: referencia territorial ausente: ", arquivo)
  }
  dt <- data.table::fread(
    arquivo, sep = ";", select = c("ano", "cod_mun", "grupo"),
    colClasses = list(character = "cod_mun"),
    encoding = "UTF-8", showProgress = FALSE
  )
  grupos <- c("Total", "Masculino", "Feminino")
  esperados <- c("2000" = 5507L, "2010" = 5565L, "2022" = 5570L)
  codigos <- unique(as.character(dt$cod_mun))
  if (nrow(dt) != 3L * unname(esperados[as.character(ano)]) ||
      length(codigos) != unname(esperados[as.character(ano)]) ||
      anyNA(dt[, .(ano, cod_mun, grupo)]) ||
      any(dt$ano != ano) ||
      !setequal(unique(dt$grupo), grupos) ||
      anyDuplicated(dt, by = c("cod_mun", "grupo")) ||
      any(!grepl("^[0-9]{7}$", codigos))) {
    stop("Diagnostico SIDRA: SOC01/", ano,
         " nao oferece referencia territorial completa.")
  }
  sort(codigos)
}

diagnosticar_sidra_economica <- function(
  insumos = ler_sidra_economica(),
  dir_bruto = file.path("so3.3", "outputs", "bruto")
) {
  if (!exists("selecionar_recortes_sidra_economica", mode = "function",
              inherits = TRUE)) {
    stop("Diagnostico SIDRA: carregue antes ler_sidra_economica.R.")
  }
  if (!is.list(insumos) ||
      !all(c("dados_municipais", "deflator_anual", "fontes") %in%
           names(insumos))) {
    stop("Diagnostico SIDRA: objeto de leitura incompleto.")
  }
  m <- data.table::as.data.table(insumos$dados_municipais)
  deflator <- data.table::as.data.table(insumos$deflator_anual)
  if (nrow(m) != 4L * 5570L ||
      !identical(sort(unique(m$ano_fonte)),
                 c(2002L, 2010L, 2021L, 2022L)) ||
      anyDuplicated(m, by = c("ano_fonte", "cod_mun")) ||
      anyNA(m[, .(ano_fonte, uf, cod_mun, nome_mun_sidra,
                  status_pib, status_vab_agro)]) ||
      any(!grepl("^[0-9]{7}$", m$cod_mun)) ||
      any(m$uf != substr(m$cod_mun, 1L, 2L)) ||
      any(!is.na(m$pib_mil_reais) &
          (!is.finite(m$pib_mil_reais) | m$pib_mil_reais <= 0)) ||
      any(!is.na(m$vab_agro_mil_reais) &
          (!is.finite(m$vab_agro_mil_reais) | m$vab_agro_mil_reais < 0))) {
    stop("Diagnostico SIDRA: base municipal inconsistente.")
  }
  if (any(m[, .N, by = ano_fonte]$N != 5570L)) {
    stop("Diagnostico SIDRA: municipios faltantes em algum ano-fonte.")
  }
  serie_necessaria <- deflator[ano_fonte %in% 2002:2022]
  if (nrow(serie_necessaria) != 21L ||
      anyDuplicated(deflator, by = "ano_fonte") ||
      !setequal(serie_necessaria$ano_fonte, 2002:2022) ||
      anyNA(serie_necessaria$variacao_deflator_pct) ||
      any(!is.finite(serie_necessaria$variacao_deflator_pct))) {
    stop("Diagnostico SIDRA: deflator incompleto para 2002-2022.")
  }

  resumo_fontes <- m[, .(
    municipios = data.table::uniqueN(cod_mun),
    pib_validos = sum(!is.na(pib_mil_reais)),
    pib_ausentes = sum(is.na(pib_mil_reais)),
    vab_validos = sum(!is.na(vab_agro_mil_reais)),
    vab_ausentes = sum(is.na(vab_agro_mil_reais)),
    vab_zero = sum(vab_agro_mil_reais == 0, na.rm = TRUE)
  ), by = ano_fonte][order(ano_fonte)]

  anos <- c(2000L, 2010L, 2022L)
  referencia <- setNames(lapply(anos, .ler_municipios_prais_sidra,
                                dir_bruto = dir_bruto), as.character(anos))
  resumos <- list()
  divergencias <- list()
  anomalias <- list()
  n <- 0L
  for (indicador in c("ECO02", "ECO03")) {
    base <- selecionar_recortes_sidra_economica(m, indicador)
    for (ano in anos) {
      n <- n + 1L
      d <- base[ano_prais == ano]
      codigos_ref <- referencia[[as.character(ano)]]
      validos <- !is.na(d$pib_mil_reais)
      if (indicador == "ECO03") {
        validos <- validos & !is.na(d$vab_agro_mil_reais)
      }
      codigos_validos <- as.character(d$cod_mun[validos])
      ausentes <- setdiff(codigos_ref, codigos_validos)
      extras <- setdiff(codigos_validos, codigos_ref)

      resumos[[n]] <- data.table::data.table(
        indicador = indicador,
        ano_prais = as.integer(ano),
        ano_fonte = unique(d$ano_fonte),
        municipios_prais = length(codigos_ref),
        municipios_validos_fonte = length(codigos_validos),
        municipios_correspondentes = sum(codigos_ref %in% codigos_validos),
        municipios_sem_correspondencia = length(ausentes),
        municipios_adicionais_na_fonte = length(extras)
      )
      divergencias[[n]] <- data.table::rbindlist(list(
        data.table::data.table(
          indicador = indicador, ano_prais = ano, cod_mun = ausentes,
          situacao = "sem_valor_na_fonte"
        ),
        data.table::data.table(
          indicador = indicador, ano_prais = ano, cod_mun = extras,
          situacao = "adicional_na_fonte"
        )
      ), use.names = TRUE)

      if (indicador == "ECO03") {
        # Apenas identifica casos de participacao > 100%.
        # Nao corrige nem limita valores oficiais.
        caso <- d[
          validos & vab_agro_mil_reais > pib_mil_reais,
          .(ano_prais, ano_fonte, uf, cod_mun,
            nome_mun_sidra, pib_mil_reais, vab_agro_mil_reais,
            participacao_preliminar_pct =
              100 * vab_agro_mil_reais / pib_mil_reais)
        ]
        if (nrow(caso)) anomalias[[length(anomalias) + 1L]] <- caso
      }
    }
  }
  cobertura <- data.table::rbindlist(resumos, use.names = TRUE)
  divergencias <- data.table::rbindlist(divergencias, use.names = TRUE)
  casos <- if (length(anomalias)) {
    data.table::rbindlist(anomalias, use.names = TRUE)
  } else {
    data.table::data.table(
      ano_prais = integer(), ano_fonte = integer(), uf = character(),
      cod_mun = character(), nome_mun_sidra = character(),
      pib_mil_reais = numeric(), vab_agro_mil_reais = numeric(),
      participacao_preliminar_pct = numeric()
    )
  }
  data.table::setorder(cobertura, indicador, ano_prais)
  data.table::setorder(divergencias, indicador, ano_prais, situacao, cod_mun)
  data.table::setorder(casos, ano_prais, cod_mun)

  message("SIDRA economica | Insumos verificados; cobertura territorial pronta.")
  message("SIDRA economica | Municipios do PRAIS sem fonte valida: ",
          sum(cobertura$municipios_sem_correspondencia),
          " (somados os seis recortes indicador/ano).")
  message("SIDRA economica | Participacoes VAB/PIB acima de 100%: ",
          nrow(casos), " (registradas, sem correcao).")

  list(
    resumo_fontes = resumo_fontes[],
    cobertura_territorial = cobertura[],
    divergencias_territoriais = divergencias[],
    casos_vab_acima_pib = casos[],
    deflator_anual = data.table::copy(deflator),
    fontes = data.table::copy(insumos$fontes)
  )
}
