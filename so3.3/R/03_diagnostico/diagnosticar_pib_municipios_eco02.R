# ============================================================
# PRAIS4 / SO3.3 / ECO02 - AUDITORIA DO PIB PER CAPITA IBGE
#
# Compara o PIB municipal historico (R$ 1.000) com a Tabela
# SIDRA 5938: tolera somente arredondamento de ate 0,5 mil R$.
# Confere a cobertura dos municipios PRAIS a partir do SOC01
# consolidado de cada recorte (5507 / 5565 / 5570).
#
# Nao calcula PIBpc deflacionado, nao define ano-base monetario,
# nao salva dados e nao modifica outputs ou o GitHub.
#
# A partir da raiz do repositorio:
# source("so3.3/R/01_leitura/ler_pib_municipios_eco02.R")
# source("so3.3/R/01_leitura/ler_sidra_economica.R")
# source("so3.3/R/03_diagnostico/diagnosticar_sidra_economica.R")
# source("so3.3/R/03_diagnostico/diagnosticar_pib_municipios_eco02.R")
# insumos_pib <- ler_pib_municipios_eco02()
# diagnostico_pib <- diagnosticar_pib_municipios_eco02(insumos_pib)
# ============================================================

if (!requireNamespace("data.table", quietly = TRUE)) {
  stop("ECO02 diagnostico: pacote data.table necessario.")
}

.verificar_fontes_eco02 <- function(fontes) {
  f <- data.table::as.data.table(fontes)
  obrigatorias <- c("periodo", "arquivo", "md5")
  if (length(setdiff(obrigatorias, names(f))) ||
      nrow(f) != 2L ||
      !setequal(as.character(f$periodo), c("2002_2009", "2010_2023")) ||
      anyDuplicated(f$periodo) ||
      anyNA(f[, ..obrigatorias]) ||
      any(!file.exists(f$arquivo)) ||
      any(!grepl("^[0-9a-f]{32}$", f$md5))) {
    stop("ECO02 diagnostico: manifesto das duas planilhas incompleto.")
  }
  md5_atual <- unname(as.character(tools::md5sum(f$arquivo)))
  if (!identical(md5_atual, as.character(f$md5))) {
    stop("ECO02 diagnostico: um XLSX mudou depois da leitura.")
  }
  data.table::copy(f)
}

diagnosticar_pib_municipios_eco02 <- function(
  insumos_pib = ler_pib_municipios_eco02(),
  insumos_sidra = ler_sidra_economica(),
  dir_bruto = file.path("so3.3", "outputs", "bruto"),
  tolerancia_pib_mil_reais = 0.500001
) {
  dependencias <- c(
    "ler_pib_municipios_eco02", "ler_sidra_economica",
    ".ler_municipios_prais_sidra"
  )
  ausentes <- dependencias[!vapply(
    dependencias, exists, logical(1L),
    mode = "function", inherits = TRUE
  )]
  if (length(ausentes)) {
    stop("ECO02 diagnostico: carregue os modulos antes de executar: ",
         paste(ausentes, collapse = ", "))
  }
  if (length(tolerancia_pib_mil_reais) != 1L ||
      !is.numeric(tolerancia_pib_mil_reais) ||
      is.na(tolerancia_pib_mil_reais) ||
      !is.finite(tolerancia_pib_mil_reais) ||
      tolerancia_pib_mil_reais < 0 ||
      tolerancia_pib_mil_reais > 0.500001) {
    stop("ECO02 diagnostico: tolerancia nao pode exceder ",
         "0,500001 mil reais (arredondamento do SIDRA).")
  }
  if (!is.list(insumos_pib) ||
      !all(c("dados", "fontes") %in% names(insumos_pib))) {
    stop("ECO02 diagnostico: estrutura dos insumos XLSX incompleta.")
  }
  fontes <- .verificar_fontes_eco02(insumos_pib$fontes)
  d <- data.table::copy(data.table::as.data.table(insumos_pib$dados))
  obrigatorias <- c(
    "ano_prais", "ano_fonte", "uf", "cod_mun", "nome_mun_ibge",
    "pib_mil_reais", "pib_pc_reais", "referencia_populacional",
    "revisao_pendente", "periodo_arquivo"
  )
  if (length(setdiff(obrigatorias, names(d))) ||
      nrow(d) != 16695L ||
      anyNA(d[, ..obrigatorias]) ||
      anyDuplicated(d, by = c("ano_fonte", "cod_mun")) ||
      !identical(sort(unique(d$ano_prais)), c(2000L, 2010L, 2022L)) ||
      !identical(sort(unique(d$ano_fonte)), c(2002L, 2010L, 2022L)) ||
      any(d$uf != substr(d$cod_mun, 1L, 2L)) ||
      any(!grepl("^[0-9]{7}$", d$cod_mun)) ||
      any(!is.finite(d$pib_mil_reais) | d$pib_mil_reais <= 0) ||
      any(!is.finite(d$pib_pc_reais) | d$pib_pc_reais <= 0)) {
    stop("ECO02 diagnostico: municipios ou valores XLSX inconsistentes.")
  }
  relacao_temporal <- c("2000" = 2002L, "2010" = 2010L, "2022" = 2022L)
  if (any(d$ano_fonte != unname(relacao_temporal[
        as.character(d$ano_prais)
      ])) ||
      any(d$referencia_populacional != data.table::fifelse(
        d$ano_fonte == 2022L, "primeira_apuracao_censo2022",
        "estimativa_populacional_1_julho_TCU"
      )) ||
      any(d$revisao_pendente != (d$ano_fonte == 2022L))) {
    stop("ECO02 diagnostico: anos ou metadados populacionais alterados.")
  }

  if (!is.list(insumos_sidra) ||
      !all(c("dados_municipais", "fontes") %in% names(insumos_sidra))) {
    stop("ECO02 diagnostico: insumos SIDRA incompletos.")
  }
  f_sidra <- data.table::as.data.table(insumos_sidra$fontes)
  if (!all(c("arquivo", "md5", "tabela") %in% names(f_sidra)) ||
      anyNA(f_sidra[, .(arquivo, md5, tabela)]) ||
      any(!file.exists(f_sidra$arquivo)) ||
      !identical(
        unname(as.character(tools::md5sum(f_sidra$arquivo))),
        as.character(f_sidra$md5)
      )) {
    stop("ECO02 diagnostico: fontes SIDRA mudaram depois da leitura.")
  }
  sidra <- data.table::copy(
    data.table::as.data.table(insumos_sidra$dados_municipais)
  )
  campos_sidra <- c("ano_fonte", "cod_mun", "pib_mil_reais")
  if (length(setdiff(campos_sidra, names(sidra))) ||
      nrow(sidra) != 4L * 5570L ||
      anyDuplicated(sidra, by = c("ano_fonte", "cod_mun"))) {
    stop("ECO02 diagnostico: base SIDRA 5938 incompleta.")
  }
  pib_sidra <- sidra[
    ano_fonte %in% c(2002L, 2010L, 2022L),
    .(
      ano_fonte, cod_mun,
      pib_mil_reais_sidra = pib_mil_reais
    )
  ]
  if (nrow(pib_sidra) != 3L * 5570L) {
    stop("ECO02 diagnostico: anos-fonte SIDRA inesperados.")
  }

  confronto <- merge(
    d, pib_sidra, by = c("ano_fonte", "cod_mun"),
    all.x = TRUE, sort = FALSE
  )
  if (nrow(confronto) != 16695L ||
      anyNA(confronto$pib_mil_reais_sidra) ||
      any(!is.finite(confronto$pib_mil_reais_sidra) |
          confronto$pib_mil_reais_sidra <= 0)) {
    stop("ECO02 diagnostico: PIB historico sem correspondencia SIDRA.")
  }
  confronto[, diferenca_pib_mil_reais :=
              pib_mil_reais - pib_mil_reais_sidra]
  divergentes <- confronto[
    abs(diferenca_pib_mil_reais) > tolerancia_pib_mil_reais,
    .(
      ano_prais, ano_fonte, uf, cod_mun, nome_mun_ibge,
      pib_mil_reais, pib_mil_reais_sidra, diferenca_pib_mil_reais
    )
  ]
  if (nrow(divergentes)) {
    stop("ECO02 diagnostico: ", nrow(divergentes),
         " municipio(s) com divergencia PIB maior que ",
         tolerancia_pib_mil_reais, " mil reais. Primeiro: ",
         divergentes$cod_mun[[1L]], " em ",
         divergentes$ano_fonte[[1L]], ".")
  }

  comparacao_sidra <- confronto[, .(
    municipios_conferidos = .N,
    divergencias_acima_tolerancia = sum(
      abs(diferenca_pib_mil_reais) > tolerancia_pib_mil_reais
    ),
    max_diferenca_abs_mil_reais = max(
      abs(diferenca_pib_mil_reais)
    )
  ), by = .(ano_prais, ano_fonte)]
  data.table::setorder(comparacao_sidra, ano_prais)

  anos <- c(2000L, 2010L, 2022L)
  coberturas <- vector("list", length(anos))
  diferencas_territoriais <- vector("list", length(anos))
  resumo_fontes <- vector("list", length(anos))
  for (i in seq_along(anos)) {
    ano <- anos[[i]]
    base <- d[ano_prais == ano]
    codigos_prais <- .ler_municipios_prais_sidra(ano, dir_bruto)
    nao_presentes <- setdiff(codigos_prais, base$cod_mun)
    adicionais <- setdiff(base$cod_mun, codigos_prais)
    ano_fonte <- unique(base$ano_fonte)

    resumo_fontes[[i]] <- data.table::data.table(
      ano_prais = ano,
      ano_fonte = ano_fonte,
      municipios_fonte = nrow(base),
      pib_validos = sum(is.finite(base$pib_mil_reais) &
                         base$pib_mil_reais > 0),
      pib_pc_validos = sum(is.finite(base$pib_pc_reais) &
                            base$pib_pc_reais > 0),
      minimo_pib_pc_reais = min(base$pib_pc_reais),
      maximo_pib_pc_reais = max(base$pib_pc_reais)
    )
    coberturas[[i]] <- data.table::data.table(
      ano_prais = ano,
      ano_fonte = ano_fonte,
      municipios_prais = length(codigos_prais),
      municipios_fonte = nrow(base),
      municipios_correspondentes = sum(codigos_prais %in% base$cod_mun),
      municipios_sem_correspondencia = length(nao_presentes),
      municipios_adicionais_na_fonte = length(adicionais)
    )
    diferencas_territoriais[[i]] <- data.table::rbindlist(list(
      data.table::data.table(
        ano_prais = ano,
        cod_mun = nao_presentes,
        situacao = "sem_correspondencia"
      ),
      data.table::data.table(
        ano_prais = ano,
        cod_mun = adicionais,
        situacao = "adicional_na_fonte"
      )
    ), use.names = TRUE)
  }
  cobertura <- data.table::rbindlist(coberturas, use.names = TRUE)
  resumo <- data.table::rbindlist(resumo_fontes, use.names = TRUE)
  divergencias <- data.table::rbindlist(
    diferencas_territoriais, use.names = TRUE
  )
  if (any(cobertura$municipios_sem_correspondencia != 0L) ||
      !identical(
        cobertura$municipios_correspondentes,
        c(5507L, 5565L, 5570L)
      ) ||
      !identical(
        cobertura$municipios_adicionais_na_fonte,
        c(53L, 0L, 0L)
      )) {
    stop("ECO02 diagnostico: correspondencia territorial ",
         "diferente da verificada nas fontes. Nenhum dado foi eliminado.")
  }
  data.table::setorder(divergencias, ano_prais, situacao, cod_mun)
  message(
    "ECO02 diagnostico | 2002/2010/2022: 16695 registros ",
    "conferidos com SIDRA 5938; diferenca maxima: ",
    format(max(comparacao_sidra$max_diferenca_abs_mil_reais),
           digits = 7), " mil reais."
  )
  message(
    "ECO02 diagnostico | cobertura PRAIS 2000/2010/2022: ",
    "5507/5565/5570; sem lacunas territoriais."
  )
  list(
    resumo_fontes = resumo[],
    cobertura_territorial = cobertura[],
    comparacao_sidra = comparacao_sidra[],
    divergencias_territoriais = divergencias[],
    fontes_ibge = fontes[],
    fontes_sidra = data.table::copy(f_sidra)
  )
}
