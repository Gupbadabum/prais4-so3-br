# ============================================================
# PRAIS4 - SO3.3
# EXECUCAO DA DIMENSAO SOCIAL
# ============================================================
#
# Filosofia operacional:
#
#   uma execucao = uma dimensao + um ano
#
# Os microdados censitarios sao processados em blocos e nao
# permanecem simultaneamente em memoria. Produtos municipais
# e intermediarios metodologicos sao gravados em disco assim
# que ficam disponiveis.
#
# Checkpoints existentes sao reutilizados por padrao. O
# recálculo completo ocorre apenas quando forcar_recalculo
# for explicitamente TRUE.
#
# O tratamento estatistico temporal (winsorizacao / Box-Cox)
# NAO ocorre aqui. Ele deve ser executado posteriormente com
# os tres recortes censitarios ja reduzidos a bases municipais.
#
# ============================================================


# ============================================================
# 1. UTILITARIOS DE SAIDA
# ============================================================

diretorios_social_ano <- function(
  ano
) {

  dir_bruto <- file.path(
    DIR_OUTPUT_BRUTO,
    "social",
    as.character(ano)
  )

  dir_intermediario <- file.path(
    DIR_OUTPUT_INTERMEDIARIO,
    "social",
    as.character(ano)
  )

  dir.create(
    dir_bruto,
    recursive = TRUE,
    showWarnings = FALSE
  )

  dir.create(
    dir_intermediario,
    recursive = TRUE,
    showWarnings = FALSE
  )

  list(
    bruto = dir_bruto,
    intermediario = dir_intermediario
  )
}


salvar_rds_social <- function(
  objeto,
  caminho
) {

  dir.create(
    dirname(caminho),
    recursive = TRUE,
    showWarnings = FALSE
  )

  saveRDS(
    objeto,
    caminho
  )

  message(
    "Checkpoint salvo: ",
    caminho
  )

  invisible(
    caminho
  )
}


carregar_rds_social <- function(
  caminho
) {

  objeto <- readRDS(
    caminho
  )

  message(
    "Checkpoint carregado: ",
    caminho
  )

  objeto
}


# ============================================================
# 2. SOC03 - ETAPAS DEMOGRAFICAS
# ============================================================

processar_soc03_intermediarios <- function(
  insumos_ev0,
  ano,
  dir_intermediario,
  executar_eb = TRUE,
  forcar_recalculo = FALSE
) {

  arq_trussell <- file.path(
    dir_intermediario,
    paste0(
      "mortalidade_trussell_",
      ano,
      ".rds"
    )
  )

  arq_insumos_q5 <- file.path(
    dir_intermediario,
    paste0(
      "insumos_q5_",
      ano,
      "_normalizada_amostra.rds"
    )
  )

  arq_q5_eb <- file.path(
    dir_intermediario,
    paste0(
      "q5_eb_",
      ano,
      "_normalizada_amostra.rds"
    )
  )


  # ----------------------------------------------------------
  # Brass-Trussell
  # ----------------------------------------------------------

  if (
    file.exists(arq_trussell) &&
      !isTRUE(forcar_recalculo)
  ) {

    mortalidade_trussell <-
      carregar_rds_social(
        arq_trussell
      )

  } else {

    mortalidade_trussell <-
      estimar_mortalidade_trussell(
        insumos_ev0
      )

    salvar_rds_social(
      mortalidade_trussell,
      arq_trussell
    )
  }


  resultado <- list(
    mortalidade_trussell =
      mortalidade_trussell
  )


  if (!isTRUE(executar_eb)) {
    return(
      resultado
    )
  }


  # ----------------------------------------------------------
  # Funcoes do EB
  #
  # Se os dois checkpoints EB ja existirem, eles podem ser
  # recuperados sem recalculo. As funcoes somente sao
  # obrigatorias quando alguma etapa precisa ser produzida.
  # ----------------------------------------------------------

  checkpoints_eb_completos <-
    file.exists(arq_insumos_q5) &&
    file.exists(arq_q5_eb) &&
    !isTRUE(forcar_recalculo)


  if (checkpoints_eb_completos) {

    resultado$insumos_q5 <-
      carregar_rds_social(
        arq_insumos_q5
      )

    resultado$q5_eb <-
      carregar_rds_social(
        arq_q5_eb
      )

    return(
      resultado
    )
  }


  funcoes_eb <- c(
    "preparar_insumos_q5_eb",
    "estabilizar_q5_eb"
  )

  faltantes_eb <- funcoes_eb[
    !vapply(
      funcoes_eb,
      exists,
      logical(1),
      mode = "function",
      inherits = TRUE
    )
  ]

  if (length(faltantes_eb) > 0L) {

    warning(
      "Etapa EB nao executada. Funcoes ausentes: ",
      paste(
        faltantes_eb,
        collapse = ", "
      )
    )

    return(
      resultado
    )
  }


  # ----------------------------------------------------------
  # Insumos EB
  # ----------------------------------------------------------

  if (
    file.exists(arq_insumos_q5) &&
      !isTRUE(forcar_recalculo)
  ) {

    insumos_q5 <-
      carregar_rds_social(
        arq_insumos_q5
      )

  } else {

    insumos_q5 <-
      preparar_insumos_q5_eb(
        trussell = mortalidade_trussell,
        base_contagem = "normalizada_amostra"
      )

    salvar_rds_social(
      insumos_q5,
      arq_insumos_q5
    )
  }


  # ----------------------------------------------------------
  # q(5) estabilizado por EB
  #
  # Especificacao principal:
  #
  #   - gama-Poisson;
  #   - sem covariaveis;
  #   - hiperparametro nacional por ano x grupo;
  #   - D_UF;
  #   - k_UF e t_UF;
  #   - intervalo posterior aproximado de 90%.
  # ----------------------------------------------------------

  if (
    file.exists(arq_q5_eb) &&
      !isTRUE(forcar_recalculo)
  ) {

    q5_eb <-
      carregar_rds_social(
        arq_q5_eb
      )

  } else {

    q5_eb <-
      estabilizar_q5_eb(
        insumos_q5 = insumos_q5,
        modelo = "gama_poisson",
        covariaveis = NULL,
        estrato = "nacional",
        nivel_ic = 0.90,
        k_modo = "uf"
      )

    salvar_rds_social(
      q5_eb,
      arq_q5_eb
    )
  }


  resultado$insumos_q5 <- insumos_q5
  resultado$q5_eb <- q5_eb

  resultado
}


# ============================================================
# 3. SOCIAL - CENSO 2010
# ============================================================

processar_social_2010 <- function(
  executar_soc03 = TRUE,
  executar_eb = TRUE,
  showProgress = TRUE,
  forcar_recalculo = FALSE
) {

  dirs <- diretorios_social_ano(
    2010L
  )

  arq_social_direto <- file.path(
    dirs$bruto,
    "social_direto_2010.rds"
  )

  arq_insumos_ev0 <- file.path(
    dirs$intermediario,
    "insumos_ev0_2010.rds"
  )


  checkpoints_censo_completos <-
    file.exists(arq_social_direto) &&
    file.exists(arq_insumos_ev0) &&
    !isTRUE(forcar_recalculo)


  if (checkpoints_censo_completos) {

    social_direto <-
      carregar_rds_social(
        arq_social_direto
      )

    insumos_ev0 <-
      carregar_rds_social(
        arq_insumos_ev0
      )

  } else {

    message(
      "Abrindo Censo 2010 como Arrow Dataset..."
    )

    censo_arrow <-
      abrir_censo_2010_social(
        showProgress = showProgress
      )


    ufs <-
      listar_ufs_censo_2010(
        censo_arrow
      )


    resultados_direto <-
      vector(
        "list",
        length(ufs)
      )

    resultados_ev0 <-
      vector(
        "list",
        length(ufs)
      )


    for (i in seq_along(ufs)) {

      uf_atual <- ufs[i]

      message(
        sprintf(
          "[%02d/%02d] Social 2010 - UF %02d",
          i,
          length(ufs),
          uf_atual
        )
      )


      dados_uf <-
        coletar_uf_censo_2010(
          censo_arrow,
          uf_atual
        )


      dados_uf <-
        adaptar_censo_2010_uf(
          dados_uf
        )


      resultados_direto[[i]] <-
        calcular_social_direto(
          dados_uf
        )


      resultados_ev0[[i]] <-
        preparar_insumos_soc03_ev0(
          dados_uf
        )


      rm(
        dados_uf
      )

      invisible(
        gc()
      )
    }


    social_direto <-
      data.table::rbindlist(
        resultados_direto,
        use.names = TRUE,
        fill = TRUE
      )


    insumos_ev0 <-
      data.table::rbindlist(
        resultados_ev0,
        use.names = TRUE,
        fill = TRUE
      )


    data.table::setorder(
      social_direto,
      indicador,
      cod_mun,
      grupo
    )


    data.table::setorder(
      insumos_ev0,
      ano,
      cod_mun,
      grupo,
      idade_mae
    )


    salvar_rds_social(
      social_direto,
      arq_social_direto
    )


    salvar_rds_social(
      insumos_ev0,
      arq_insumos_ev0
    )


    rm(
      resultados_direto,
      resultados_ev0,
      censo_arrow
    )

    invisible(
      gc()
    )
  }


  resultado <- list(
    direto = social_direto,
    ev0 = insumos_ev0
  )


  if (isTRUE(executar_soc03)) {

    soc03 <-
      processar_soc03_intermediarios(
        insumos_ev0 = insumos_ev0,
        ano = 2010L,
        dir_intermediario =
          dirs$intermediario,
        executar_eb =
          executar_eb,
        forcar_recalculo =
          forcar_recalculo
      )

    resultado$soc03 <- soc03
  }


  resultado
}


# ============================================================
# 4. SOCIAL - CENSO 2022
# ============================================================

processar_social_2022 <- function(
  executar_soc03 = TRUE,
  executar_eb = TRUE,
  forcar_recalculo = FALSE
) {

  dirs <- diretorios_social_ano(
    2022L
  )

  arq_social_direto <- file.path(
    dirs$bruto,
    "social_direto_2022.rds"
  )

  arq_insumos_ev0 <- file.path(
    dirs$intermediario,
    "insumos_ev0_2022.rds"
  )


  checkpoints_censo_completos <-
    file.exists(arq_social_direto) &&
    file.exists(arq_insumos_ev0) &&
    !isTRUE(forcar_recalculo)


  if (checkpoints_censo_completos) {

    social_direto <-
      carregar_rds_social(
        arq_social_direto
      )

    insumos_ev0 <-
      carregar_rds_social(
        arq_insumos_ev0
      )

  } else {

    censo_2022 <-
      preparar_censo_2022()


    processamento <-
      processar_social_censo(
        arquivos = censo_2022$arquivos,
        adaptar_fun = adaptar_censo_2022
      )


    social_direto <-
      processamento$direto

    insumos_ev0 <-
      processamento$ev0


    salvar_rds_social(
      social_direto,
      arq_social_direto
    )


    salvar_rds_social(
      insumos_ev0,
      arq_insumos_ev0
    )
  }


  resultado <- list(
    direto = social_direto,
    ev0 = insumos_ev0
  )


  if (isTRUE(executar_soc03)) {

    soc03 <-
      processar_soc03_intermediarios(
        insumos_ev0 = insumos_ev0,
        ano = 2022L,
        dir_intermediario =
          dirs$intermediario,
        executar_eb =
          executar_eb,
        forcar_recalculo =
          forcar_recalculo
      )

    resultado$soc03 <- soc03
  }


  resultado
}


# ============================================================
# 5. DISPATCHER DA DIMENSAO SOCIAL
# ============================================================

processar_dimensao_social <- function(
  ano,
  executar_soc03 = TRUE,
  executar_eb = TRUE,
  forcar_recalculo = FALSE
) {

  ano <- as.integer(
    ano
  )


  if (!ano %in% ANOS_DVI) {
    stop(
      "Ano invalido para o DVI: ",
      ano
    )
  }


  if (ano == 2010L) {

    return(
      processar_social_2010(
        executar_soc03 = executar_soc03,
        executar_eb = executar_eb,
        forcar_recalculo = forcar_recalculo
      )
    )
  }


  if (ano == 2022L) {

    return(
      processar_social_2022(
        executar_soc03 = executar_soc03,
        executar_eb = executar_eb,
        forcar_recalculo = forcar_recalculo
      )
    )
  }


  if (ano == 2000L) {

    stop(
      "O adaptador 2000 ainda nao foi migrado para a nova ",
      "arquitetura de execucao por dimensao + ano. ",
      "A interrupcao e intencional para impedir uma leitura ",
      "censitaria nao controlada."
    )
  }


  stop(
    "Ano nao implementado para a dimensao Social."
  )
}
