# ============================================================
# PRAIS4 / SO3.3 / INF02 - ETAPA 03
# CALCULO E CONSOLIDACAO DO INDICADOR PER CAPITA
# ============================================================
#
# Entradas:
#   E01 - Contribuicao hidrologica municipalizada
#   E02 - Populacao total censitaria
#
# Saidas:
#   Valores municipais em m3/habitante/ano
#   Valores compartilhados para os tres grupos do DVI
#   Relatorios de qualidade
#
# Restricoes:
#   Nao reprocessa E01/E02
#   Nao realiza harmonizacao territorial
#   Nao imputa populacao ou vazao
#   Nao sobrescreve produtos divergentes
# ============================================================


.inf02_e03_exigir <- function(condicao, mensagem) {

  if (!isTRUE(condicao)) {
    stop(
      "INF02/E03: ",
      mensagem,
      call. = FALSE
    )
  }
}


# ============================================================
# 1. PERSISTENCIA SEGURA
# ============================================================

.inf02_e03_gravar <- function(
    objeto,
    destino,
    tipo = "rds"
) {

  dir.create(
    dirname(destino),
    recursive = TRUE,
    showWarnings = FALSE
  )

  temporario <- tempfile(
    ".inf02_e03_",
    tmpdir = dirname(destino),
    fileext = paste0(".", tipo)
  )

  on.exit(
    if (file.exists(temporario)) {
      unlink(temporario)
    },
    add = TRUE
  )

  if (tipo == "rds") {

    saveRDS(
      as.data.frame(objeto),
      temporario,
      version = 3L
    )

    if (file.exists(destino)) {

      anterior <- readRDS(destino)

      .inf02_e03_exigir(
        identical(names(anterior), names(objeto)) &&
          isTRUE(
            all.equal(
              as.data.frame(anterior),
              as.data.frame(objeto),
              tolerance = 1e-12,
              check.attributes = FALSE
            )
          ),
        paste0(
          "RDS existente diverge; preservado: ",
          destino
        )
      )

      return(invisible(destino))
    }

  } else if (tipo == "csv") {

    data.table::fwrite(
      objeto,
      temporario,
      sep = ";",
      dec = ".",
      na = "",
      quote = "auto",
      bom = FALSE
    )

    if (file.exists(destino)) {

      .inf02_e03_exigir(
        identical(
          unname(tools::md5sum(temporario)),
          unname(tools::md5sum(destino))
        ),
        paste0(
          "CSV existente diverge; preservado: ",
          destino
        )
      )

      return(invisible(destino))
    }

  } else {

    stop(
      "INF02/E03: tipo de arquivo desconhecido.",
      call. = FALSE
    )
  }

  .inf02_e03_exigir(
    file.rename(temporario, destino),
    paste0(
      "nao foi possivel gravar: ",
      destino
    )
  )

  invisible(destino)
}


# ============================================================
# 2. PROCESSADOR PRINCIPAL
# ============================================================

processar_inf02_etapa03 <- function(

    anos = c(2000L, 2010L, 2022L),

    promover = FALSE,

    dir_intermediario = DIR_OUTPUT_INTERMEDIARIO,

    dir_bruto = DIR_OUTPUT_BRUTO

) {

  .inf02_e03_exigir(
    requireNamespace("data.table", quietly = TRUE),
    "pacote data.table ausente"
  )

  .inf02_e03_exigir(
    identical(promover, TRUE) ||
      identical(promover, FALSE),
    "promover precisa ser TRUE ou FALSE"
  )

  anos <- sort(unique(as.integer(anos)))

  .inf02_e03_exigir(
    length(anos) > 0L &&
      !anyNA(anos) &&
      all(anos %in% c(2000L, 2010L, 2022L)),
    "anos permitidos: 2000, 2010 e 2022"
  )


  # ----------------------------------------------------------
  # 2.1. Localizacao dos produtos anteriores
  # ----------------------------------------------------------

  pasta_inf02 <- file.path(
    dir_intermediario,
    "infraestrutural",
    "inf02"
  )

  arq_h <- file.path(
    pasta_inf02,
    "etapa01",
    "INF02_E01_contribuicao_incremental_municipal_IBGE2025.rds"
  )

  arq_qa_h <- file.path(
    pasta_inf02,
    "etapa01",
    "INF02_E01_qa_nacional.csv"
  )

  .inf02_e03_exigir(
    file.exists(arq_h) &&
      file.exists(arq_qa_h),
    "produtos nacionais aprovados da Etapa 01 ausentes"
  )


  # ----------------------------------------------------------
  # 2.2. Recuperar e validar a referencia hidrologica
  # ----------------------------------------------------------

  h <- data.table::as.data.table(
    readRDS(arq_h)
  )

  qa_h <- data.table::fread(
    arq_qa_h,
    sep = ";",
    showProgress = FALSE
  )

  campos_h <- c(
    "cod_mun",
    "tipo_territorio",
    "q_inc_parcial_estimada_m3s"
  )

  .inf02_e03_exigir(
    all(campos_h %in% names(h)) &&
      nrow(h) == 5571L &&
      !anyDuplicated(h$cod_mun) &&
      all(
        h$tipo_territorio == "unidade_municipal"
      ),
    "base hidrologica E01 com estrutura inesperada"
  )

  .inf02_e03_exigir(

    nrow(qa_h) == 1L &&

      isTRUE(
        qa_h$qa_conciliacao_area_ate_0_01km2[[1L]]
      ) &&

      isTRUE(
        qa_h$qa_conciliacao_q_ate_0_01m3s[[1L]]
      ) &&

      isTRUE(
        qa_h$qa_conciliacao_unidades_ibge_brasil_ate_0_01km2[[1L]]
      ) &&

      abs(
        sum(
          h$q_inc_parcial_estimada_m3s,
          na.rm = TRUE
        ) -
          qa_h$q_inc_estimada_municipal_m3s[[1L]]
      ) < 0.01,

    "conciliacao nacional hidrologica E01 nao confirmada"
  )

  md5_h <- unname(
    tools::md5sum(arq_h)
  )


  # ----------------------------------------------------------
  # 2.3. Parametros do indicador
  # ----------------------------------------------------------

  segundos_ano <- 31536000

  grupos <- c(
    "Total",
    "Masculino",
    "Feminino"
  )

  referencias <- data.table::data.table(

    ano = c(
      2000L,
      2010L,
      2022L
    ),

    n_pop = c(
      5507L,
      5565L,
      5570L
    ),

    pop_total = c(
      169799170,
      190755799,
      203080756
    ),

    tabela = c(
      202L,
      202L,
      4709L
    )
  )

  pasta_saida <- file.path(
    pasta_inf02,
    "etapa03"
  )

  resumo <- vector(
    "list",
    length(anos)
  )


  # ==========================================================
  # 3. PROCESSAMENTO DOS RECORTES
  # ==========================================================

  for (i in seq_along(anos)) {

    ano <- anos[[i]]

    ano_selecionado <- ano

    referencia <- referencias[
      referencias$ano == ano_selecionado
    ]


    # --------------------------------------------------------
    # 3.1. Ler associacao populacional
    # --------------------------------------------------------

    arq_e02 <- file.path(
      pasta_inf02,
      "etapa02",
      sprintf(
        "INF02_E02_%d_associacao_preliminar_IBGE2025.rds",
        ano
      )
    )

    arq_qa_e02 <- file.path(
      pasta_inf02,
      "etapa02",
      sprintf(
        "INF02_E02_%d_qa.csv",
        ano
      )
    )

    .inf02_e03_exigir(
      file.exists(arq_e02) &&
        file.exists(arq_qa_e02),
      paste0(
        "produtos E02 ausentes para ",
        ano
      )
    )

    x <- data.table::as.data.table(
      readRDS(arq_e02)
    )

    qa2 <- data.table::fread(
      arq_qa_e02,
      sep = ";",
      showProgress = FALSE
    )


    # --------------------------------------------------------
    # 3.2. Validar estrutura
    # --------------------------------------------------------

    campos <- c(
      "ano",
      "uf",
      "cod_mun",
      "nm_mun",
      "tipo_territorio",
      "populacao_total_censo",
      "q_inc_parcial_estimada_m3s",
      "situacao_qualidade",
      "cobertura_bho_pct",
      "cobertura_ana_estimada_pct",
      "n_bho_nao_estimadas",
      "area_sem_bho_km2",
      "tipo_desagregacao",
      "status_correspondencia",
      "tabela_sidra"
    )

    .inf02_e03_exigir(
      all(campos %in% names(x)),
      paste0(
        "colunas obrigatorias E02 ausentes em ",
        ano
      )
    )

    .inf02_e03_exigir(

      nrow(x) == 5571L &&

        !anyDuplicated(x$cod_mun) &&

        all(
          grepl("^[0-9]{7}$", x$cod_mun)
        ) &&

        all(x$ano == ano) &&

        all(
          x$tipo_desagregacao == "compartilhada"
        ) &&

        all(
          x$tipo_territorio == "unidade_municipal"
        ) &&

        all(
          x$tabela_sidra == referencia$tabela
        ),

      paste0(
        "estrutura/ano incorretos no arquivo E02/",
        ano
      )
    )


    # --------------------------------------------------------
    # 3.3. Conciliacao com o QA da Etapa 02
    # --------------------------------------------------------

    .inf02_e03_exigir(

      nrow(qa2) == 1L &&

        qa2$ano[[1L]] == ano &&

        identical(
          as.character(
            qa2$hidrologia_e01_md5[[1L]]
          ),
          md5_h
        ) &&

        qa2$n_codigos_origem_fora_2025[[1L]] == 0L &&

        qa2$n_populacao_origem[[1L]] ==
          referencia$n_pop &&

        qa2$n_codigos_coincidentes[[1L]] ==
          referencia$n_pop &&

        qa2$n_sem_populacao_no_codigo2025[[1L]] ==
          5571L - referencia$n_pop &&

        qa2$n_sem_q_estimada[[1L]] ==
          sum(
            is.na(x$q_inc_parcial_estimada_m3s)
          ) &&

        qa2$soma_populacao_origem[[1L]] ==
          referencia$pop_total,

      paste0(
        "auditoria E02 nao conciliada para ",
        ano
      )
    )

    .inf02_e03_exigir(

      sum(
        !is.na(x$populacao_total_censo)
      ) == referencia$n_pop &&

        sum(
          x$populacao_total_censo,
          na.rm = TRUE
        ) == referencia$pop_total &&

        all(
          is.na(x$populacao_total_censo) |
            (
              is.finite(x$populacao_total_censo) &
                x$populacao_total_censo > 0
            )
        ),

      paste0(
        "populacao censitaria inconsistente em ",
        ano
      )
    )


    # --------------------------------------------------------
    # 3.4. Confirmar identidade das contribuicoes
    # --------------------------------------------------------

    pos <- match(
      x$cod_mun,
      h$cod_mun
    )

    .inf02_e03_exigir(

      !anyNA(pos) &&

        isTRUE(
          all.equal(
            x$q_inc_parcial_estimada_m3s,
            h$q_inc_parcial_estimada_m3s[pos],
            tolerance = 1e-12,
            check.attributes = FALSE
          )
        ),

      paste0(
        "vazoes E02 divergem da E01 em ",
        ano
      )
    )

    .inf02_e03_exigir(
      all(
        is.na(x$q_inc_parcial_estimada_m3s) |
          is.finite(x$q_inc_parcial_estimada_m3s)
      ),
      paste0(
        "Q nao finita em ",
        ano
      )
    )


    # ========================================================
    # 4. COMPATIBILIDADE TERRITORIAL
    # ========================================================

    # Municipios de origem de Boa Esperanca do Norte.
    # Identificacao por codigo, sem depender de nomes.

    x[, alteracao_territorial_conhecida :=
        cod_mun %in% c(
          "5106240",
          "5107925"
        )
    ]

    x[
      alteracao_territorial_conhecida &
        !is.na(populacao_total_censo),

      status_correspondencia :=
        "CODIGO_COINCIDENTE_DIVISAO_TERRITORIAL_ALTERADA_2025"
    ]

    x[, compatibilidade_territorial :=
        "CODIGOS_COINCIDENTES_SEM_HARMONIZACAO_GEOGRAFICA"
    ]

    x[
      alteracao_territorial_conhecida == TRUE,
      compatibilidade_territorial :=
        "ALTERACAO_TERRITORIAL_CONHECIDA"
    ]

    x[
      is.na(populacao_total_censo),
      compatibilidade_territorial :=
        "SEM_POPULACAO_NO_RECORTE"
    ]


    # ========================================================
    # 5. CALCULO PER CAPITA
    # ========================================================

    p <- x$populacao_total_censo

    q <- x$q_inc_parcial_estimada_m3s

    populacao_ok <-
      !is.na(p) &
      is.finite(p) &
      p > 0

    q_ok <-
      !is.na(q) &
      is.finite(q) &
      q >= 0

    pode_calcular <-
      populacao_ok & q_ok


    # --------------------------------------------------------
    # 5.1. Valor calculado sem harmonizacao territorial
    # --------------------------------------------------------

    x[, valor_calculado_nao_harmonizado := NA_real_]

    x$valor_calculado_nao_harmonizado[pode_calcular] <-
      q[pode_calcular] *
      segundos_ano /
      p[pode_calcular]


    # --------------------------------------------------------
    # 5.2. Valor disponibilizado para utilizacao
    # --------------------------------------------------------

    x[, valor := valor_calculado_nao_harmonizado]

    # Nao utilizar os valores calculados para municipios
    # com incompatibilidade territorial conhecida.

    x[
      alteracao_territorial_conhecida == TRUE,
      valor := NA_real_
    ]


    # --------------------------------------------------------
    # 5.3. Situacao do calculo
    # --------------------------------------------------------

    x[, status_calculo :=
        "CALCULADO_SEM_HARMONIZACAO_TERRITORIAL"
    ]

    x[
      alteracao_territorial_conhecida &
        pode_calcular,
      status_calculo :=
        "DIVISAO_TERRITORIAL_ALTERADA_2025"
    ]

    # Contribuicoes negativas nao sao convertidas em zero.
    # Sao preservadas no campo Q, mas nao produzem INF02.

    x[
      !is.na(q) &
        q < 0 &
        populacao_ok,
      status_calculo :=
        "Q_NEGATIVA_NAO_INTERPRETAVEL"
    ]

    x[
      is.na(q) &
        populacao_ok,
      status_calculo :=
        "SEM_CONTRIBUICAO_ESTIMADA"
    ]

    x[
      !populacao_ok,
      status_calculo :=
        "SEM_POPULACAO_CENSITARIA"
    ]


    # --------------------------------------------------------
    # 5.4. Identificacao do indicador
    # --------------------------------------------------------

    x[, indicador :=
        "INF02_RECURSOS_HIDRICOS_PC"
    ]

    x[, unidade :=
        "m3/habitante/ano"
    ]

    x[, referencia_hidrologica :=
        "ANA_BHO50K_QMLTINC_FIXA"
    ]

    x[, referencia_territorial :=
        "IBGE_2025"
    ]


    # --------------------------------------------------------
    # 5.5. Organizar colunas
    # --------------------------------------------------------

    colunas_inicio <- c(
      "ano",
      "uf",
      "cod_mun",
      "nm_mun",
      "indicador",
      "valor",
      "valor_calculado_nao_harmonizado",
      "unidade",
      "populacao_total_censo",
      "q_inc_parcial_estimada_m3s",
      "status_calculo",
      "situacao_qualidade",
      "status_correspondencia",
      "compatibilidade_territorial",
      "alteracao_territorial_conhecida",
      "tipo_desagregacao"
    )

    data.table::setcolorder(
      x,
      c(
        colunas_inicio,
        setdiff(
          names(x),
          colunas_inicio
        )
      )
    )

    data.table::setorder(
      x,
      cod_mun
    )


    # ========================================================
    # 6. VALIDACAO MUNICIPAL
    # ========================================================

    .inf02_e03_exigir(

      nrow(x) == 5571L &&

        all(
          is.na(x$valor) |
            (
              is.finite(x$valor) &
                x$valor >= 0
            )
        ) &&

        sum(
          x$alteracao_territorial_conhecida
        ) == 2L &&

        all(
          is.na(
            x$valor[
              x$alteracao_territorial_conhecida
            ]
          )
        ) &&

        all(
          is.na(x$valor) ==
            (
              x$status_calculo !=
                "CALCULADO_SEM_HARMONIZACAO_TERRITORIAL"
            )
        ),

      paste0(
        "calculo/status inconsistente em ",
        ano
      )
    )


    # ========================================================
    # 7. COMPARTILHAMENTO ENTRE GRUPOS
    # ========================================================

    # O mesmo valor municipal e reproduzido para os tres
    # grupos. Nao se utiliza populacao masculina ou feminina.

    longo <- data.table::rbindlist(
      lapply(
        grupos,
        function(g) {

          x[, .(
            ano,
            uf,
            cod_mun,
            nm_mun,
            indicador,
            grupo = g,
            valor,
            unidade,
            tipo_desagregacao,
            status_calculo,
            situacao_qualidade,
            compatibilidade_territorial
          )]
        }
      ),
      use.names = TRUE
    )

    longo[, ordem_grupo :=
        match(grupo, grupos)
    ]

    data.table::setorder(
      longo,
      cod_mun,
      ordem_grupo
    )

    longo[, ordem_grupo := NULL]


    # --------------------------------------------------------
    # 7.1. Conferir igualdade entre grupos
    # --------------------------------------------------------

    .inf02_e03_exigir(

      nrow(longo) == 5571L * 3L &&

        !anyDuplicated(
          longo,
          by = c(
            "ano",
            "cod_mun",
            "grupo"
          )
        ) &&

        all(
          vapply(
            grupos,
            function(g) {
              identical(
                longo[grupo == g]$valor,
                x$valor
              )
            },
            logical(1)
          )
        ),

      paste0(
        "valor nao compartilhado de forma identica em ",
        ano
      )
    )


    # ========================================================
    # 8. RELATORIO DE QUALIDADE
    # ========================================================

    qa <- data.table::data.table(

      ano = ano,

      n_unidades_municipais = nrow(x),

      n_populacao_disponivel =
        sum(populacao_ok),

      soma_populacao_total =
        sum(p, na.rm = TRUE),

      n_sem_populacao =
        sum(!populacao_ok),

      n_sem_q_estimada =
        sum(is.na(q)),

      n_q_negativa =
        sum(!is.na(q) & q < 0),

      n_alteracao_territorial_conhecida =
        sum(x$alteracao_territorial_conhecida),

      n_valor_calculado =
        sum(
          !is.na(
            x$valor_calculado_nao_harmonizado
          )
        ),

      n_valor_uso_com_ressalva =
        sum(!is.na(x$valor)),

      n_valor_na =
        sum(is.na(x$valor)),

      n_calculados_cobertura_incompleta =
        sum(
          !is.na(x$valor) &
            x$situacao_qualidade !=
              "estimativa_sem_ressalva_espacial"
        ),

      n_linhas_grupos =
        nrow(longo),

      md5_etapa01 =
        md5_h,

      md5_associacao_etapa02 =
        unname(
          tools::md5sum(arq_e02)
        ),

      status =
        "CALCULADO_COM_RESSALVA_NAO_HARMONIZADO"
    )


    # ========================================================
    # 9. PERSISTENCIA DOS PRODUTOS
    # ========================================================

    prefixo <- file.path(
      pasta_saida,
      sprintf(
        "INF02_E03_%d",
        ano
      )
    )

    .inf02_e03_gravar(
      x,
      paste0(prefixo, "_municipal.rds")
    )

    .inf02_e03_gravar(
      x,
      paste0(prefixo, "_municipal.csv"),
      "csv"
    )

    .inf02_e03_gravar(
      longo,
      paste0(prefixo, "_grupos.rds")
    )

    .inf02_e03_gravar(
      longo,
      paste0(prefixo, "_grupos.csv"),
      "csv"
    )

    .inf02_e03_gravar(
      qa,
      paste0(prefixo, "_qa.csv"),
      "csv"
    )


    # ========================================================
    # 10. PROMOCAO OPCIONAL AO DIRETORIO BRUTO
    # ========================================================

    if (promover) {

      bruto <- file.path(
        dir_bruto,
        "infraestrutural",
        as.character(ano)
      )

      arq_base <- file.path(
        bruto,
        sprintf(
          "INF02_RECURSOS_HIDRICOS_PC_%d",
          ano
        )
      )

      .inf02_e03_gravar(
        longo,
        paste0(arq_base, ".rds")
      )

      .inf02_e03_gravar(
        longo,
        paste0(arq_base, ".csv"),
        "csv"
      )
    }


    # --------------------------------------------------------
    # 11. Resumo da execucao
    # --------------------------------------------------------

    resumo[[i]] <- qa

    message(
      "INF02/E03 | ",
      ano,
      " | municipios=5571",
      " | valor disponivel=",
      qa$n_valor_uso_com_ressalva,
      " | sem valor=",
      qa$n_valor_na,
      " | grupos=",
      qa$n_linhas_grupos,
      " | promocao=",
      promover
    )
  }


  # ==========================================================
  # 12. CONSOLIDACAO DO QA
  # ==========================================================

  final <- data.table::rbindlist(
    resumo,
    use.names = TRUE
  )

  data.table::setorder(
    final,
    ano
  )

  nome_resumo <- if (length(anos) == 3L) {
    "completo"
  } else {
    paste(anos, collapse = "_")
  }

  .inf02_e03_gravar(
    final,
    file.path(
      pasta_saida,
      sprintf(
        "INF02_E03_qa_resumo_%s.csv",
        nome_resumo
      )
    ),
    "csv"
  )

  message(
    "INF02/E03 | FIM | ",
    "valores nao harmonizados, ",
    "metadados preservados."
  )

  invisible(final)
}
