#!/usr/bin/env Rscript

# PRAIS4 / SO3.3 - Bloco F: componentes por media aritmetica simples.
# Entrada: outputs/orientado; saida: outputs/componentes.
# Exige TODOS os indicadores da dimensao; sem imputacao nem media parcial.
# Executar da raiz do repositorio:
# Rscript so3.3/executar_componentes_so33.R

so33_componentes <- function() {

  raiz <- 'so3.3'

  modulo <- file.path(
    raiz,
    'R',
    '03_diagnostico',
    'estatistica_brutos_conjuntos.R'
  )

  if (!file.exists(modulo))
    stop('Execute a partir da raiz do repositorio.')

  source(modulo, local = TRUE)

  catalogo <- estat_so33_catalogo()
  anos <- estat_so33_anos()
  grupos <- estat_so33_grupos()

  entrada <- file.path(raiz, 'outputs', 'orientado')
  destino <- file.path(raiz, 'outputs', 'componentes')
  metadata <- file.path(raiz, 'metadata')

  componentes <- c(
    social = 'SOCIAL',
    economica = 'ECONOMICA',
    infraestrutural = 'INFRAESTRUTURAL'
  )

  obrig <- c(
    'ano', 'uf', 'cod_mun', 'nm_mun',
    'indicador', 'grupo', 'valor'
  )

  chave <- function(x) {
    paste(x$ano, x$cod_mun, x$grupo, sep = '|')
  }

  # Chave territorial soberana:
  # ano + cod_mun (IBGE, 7 digitos) + grupo.
  #
  # UF e nome municipal sao metadados de origem,
  # preservados na saida.
  #
  # Nao precisam ter a mesma representacao textual entre fontes.
  # Nao efetuar harmonizacao ou comparacao de UF entre indicadores.

  ler <- function(dim, id, ano) {

    arq <- file.path(
      entrada,
      dim,
      as.character(ano),
      paste0(id, '_', ano, '.csv')
    )

    if (!file.exists(arq))
      stop('Arquivo orientado ausente: ', arq)

    x <- utils::read.csv(
      arq,
      sep = ';',
      dec = '.',
      quote = '"',
      colClasses = 'character',
      na.strings = c('', 'NA'),
      fileEncoding = 'UTF-8',
      check.names = FALSE,
      stringsAsFactors = FALSE
    )

    if (
      !all(obrig %in% names(x)) ||
      anyDuplicated(names(x)) ||
      anyNA(
        x[c(
          'ano', 'uf', 'cod_mun', 'nm_mun',
          'indicador', 'grupo'
        )]
      ) ||
      any(x$ano != as.character(ano)) ||
      any(x$indicador != id) ||
      !setequal(unique(x$grupo), grupos) ||
      anyDuplicated(chave(x)) ||
      any(!grepl('^[0-9]{7}$', x$cod_mun))
    ) {
      stop('Contrato ou chaves invalidas: ', arq)
    }

    esperado <- if (id == 'INF02_RECURSOS_HIDRICOS_PC') {
      5571L
    } else {
      switch(
        as.character(ano),
        '2000' = 5507L,
        '2010' = 5565L,
        '2022' = 5570L
      )
    }

    if (
      nrow(x) != 3L * esperado ||
      length(unique(x$cod_mun)) != esperado ||
      any(
        as.integer(
          table(factor(x$grupo, levels = grupos))
        ) != esperado
      )
    ) {
      stop('Cardinalidade invalida: ', arq)
    }

    original <- trimws(x$valor)

    original[
      !is.na(original) & original %in% c('', 'NA')
    ] <- NA_character_

    v <- suppressWarnings(as.numeric(original))

    if (
      any(
        !is.na(original) &
          (is.na(v) | !is.finite(v))
      ) ||
      any(
        !is.na(v) &
          (v < -1e-10 | v > 1 + 1e-10)
      )
    ) {
      stop('Valor orientado invalido [0,1]: ', arq)
    }

    if (
      any(
        !is.na(v) &
          (v < 0 | v > 1)
      )
    ) {
      stop('Valor orientado ultrapassou [0,1]: ', arq)
    }

    x$valor <- v

    if (
      catalogo$natureza[
        match(id, catalogo$indicador)
      ] == 'territorial_compartilhado'
    ) {
      estat_so33_series(
        x,
        'territorial_compartilhado'
      )
    }

    list(
      dados = x,
      arquivo = arq,
      md5 = unname(tools::md5sum(arq))
    )
  }

  todos_produtos <- list()
  parametros <- list()
  cobertura <- list()
  faltantes <- list()

  i <- j <- k <- m <- 0L

  for (dim in names(componentes)) {

    ids <- catalogo$indicador[
      catalogo$dimensao == dim
    ]

    n_ind <- length(ids)

    # ---------------------------------------------------------
    # Parametros metodologicos da componente
    # ---------------------------------------------------------

    for (id in ids) {

      j <- j + 1L

      parametros[[j]] <- data.frame(
        dimensao = dim,
        componente = componentes[[dim]],
        indicador = id,
        peso = 1 / n_ind,
        n_indicadores_exigidos = n_ind,
        regra_ausentes = 'TODOS_OBRIGATORIOS',
        metodo = 'MEDIA_ARITMETICA_SIMPLES',
        stringsAsFactors = FALSE
      )
    }

    # ---------------------------------------------------------
    # Processamento por ano censitario
    # ---------------------------------------------------------

    for (ano in anos) {

      fontes <- lapply(
        ids,
        function(id) ler(dim, id, ano)
      )

      names(fontes) <- ids

      # O primeiro indicador da dimensao define
      # a malha territorial de referencia.
      #
      # Para Infraestrutural, INF01 e a ancora.
      #
      # Municipios adicionais presentes no INF02
      # nao sao incorporados artificialmente.

      base <- fontes[[1L]]$dados

      if (anyDuplicated(chave(base))) {
        stop('Chaves repetidas na ancora.')
      }

      chaves <- chave(base)

      valores <- matrix(
        NA_real_,
        nrow = nrow(base),
        ncol = n_ind,
        dimnames = list(NULL, ids)
      )

      # -------------------------------------------------------
      # Associacao territorial dos indicadores
      # -------------------------------------------------------

      for (p in seq_along(ids)) {

        x <- fontes[[p]]$dados

        # Associacao exclusivamente por:
        # ano + cod_mun + grupo

        pos <- match(
          chaves,
          chave(x)
        )

        extras <- sum(
          !(chave(x) %in% chaves)
        )

        faltam_chaves <- sum(
          is.na(pos)
        )

        if (faltam_chaves > 0L) {
          stop(
            'Arquivo ', ids[[p]],
            ' nao cobre a malha de referencia em ',
            ano,
            ' (', faltam_chaves,
            ' chaves ausentes). Revisar territorialidade.'
          )
        }

        # A correspondencia foi validada pela chave municipal.
        #
        # UF e nm_mun sao metadados e nao entram no join.
        #
        # Nao ha imputacao de municipios ou indicadores
        # ausentes.

        valores[, p] <- x$valor[pos]

        m <- m + 1L

        faltantes[[m]] <- data.frame(
          dimensao = dim,
          ano = ano,
          indicador = ids[[p]],
          registros_fora_da_malha_base = extras,
          registros_sem_correspondencia_na_base = faltam_chaves,
          md5_entrada = fontes[[p]]$md5,
          arquivo_entrada = fontes[[p]]$arquivo,
          stringsAsFactors = FALSE
        )
      }

      # -------------------------------------------------------
      # Regra de completude
      #
      # TODOS OS INDICADORES OU NADA FEITO.
      # -------------------------------------------------------

      completos <- rowSums(
        !is.na(valores)
      ) == n_ind

      resultado <- rep(
        NA_real_,
        nrow(base)
      )

      resultado[completos] <- rowMeans(
        valores[completos, , drop = FALSE]
      )

      if (
        any(
          !is.na(resultado) &
            (resultado < 0 | resultado > 1)
        )
      ) {
        stop('Componente fora de [0,1].')
      }

      # -------------------------------------------------------
      # Produto municipal da componente
      # -------------------------------------------------------

      produto <- base[
        ,
        c(
          'ano', 'uf', 'cod_mun',
          'nm_mun', 'grupo'
        ),
        drop = FALSE
      ]

      produto$componente <- componentes[[dim]]
      produto$valor <- resultado

      caminho <- file.path(
        destino,
        dim,
        as.character(ano),
        paste0(
          'COMP_',
          componentes[[dim]],
          '_',
          ano,
          '.csv'
        )
      )

      i <- i + 1L

      todos_produtos[[i]] <- list(
        caminho = caminho,
        dados = produto
      )

      # -------------------------------------------------------
      # Diagnostico de cobertura
      # -------------------------------------------------------

      for (grupo in grupos) {

        sel <- base$grupo == grupo

        completos_grupo <- completos[sel]

        n_ok <- sum(completos_grupo)

        k <- k + 1L

        cobertura[[k]] <- data.frame(
          dimensao = dim,
          componente = componentes[[dim]],
          ano = ano,
          grupo = grupo,
          n_municipios = sum(sel),
          n_completos = n_ok,
          n_incompletos = sum(sel) - n_ok,
          percentual_completos = 100 * n_ok / sum(sel),
          n_ausentes_por_indicador = paste(
            paste(
              ids,
              colSums(
                is.na(
                  valores[sel, , drop = FALSE]
                )
              ),
              sep = ':'
            ),
            collapse = '|'
          ),
          stringsAsFactors = FALSE
        )
      }
    }
  }

  # -----------------------------------------------------------
  # Destinos dos metadados
  # -----------------------------------------------------------

  arq_param <- file.path(
    metadata,
    'componentes_parametros.csv'
  )

  arq_cob <- file.path(
    metadata,
    'componentes_cobertura.csv'
  )

  arq_fontes <- file.path(
    metadata,
    'componentes_fontes.csv'
  )

  destinos <- c(
    vapply(
      todos_produtos,
      `[[`,
      character(1),
      'caminho'
    ),
    arq_param,
    arq_cob,
    arq_fontes
  )

  # Proibir sobrescrita silenciosa.

  ja_existem <- destinos[
    file.exists(destinos)
  ]

  if (length(ja_existem)) {
    stop(
      'Nao sobrescrever resultado existente; ',
      'nenhum arquivo gravado. Ex.: ',
      ja_existem[[1]]
    )
  }

  # -----------------------------------------------------------
  # Escrita dos produtos
  # -----------------------------------------------------------

  gravar <- function(x, arq) {

    dir.create(
      dirname(arq),
      recursive = TRUE,
      showWarnings = FALSE
    )

    utils::write.table(
      x,
      arq,
      sep = ';',
      dec = '.',
      row.names = FALSE,
      col.names = TRUE,
      quote = TRUE,
      na = '',
      fileEncoding = 'UTF-8'
    )
  }

  for (item in todos_produtos) {
    gravar(
      item$dados,
      item$caminho
    )
  }

  gravar(
    do.call(rbind, parametros),
    arq_param
  )

  gravar(
    do.call(rbind, cobertura),
    arq_cob
  )

  gravar(
    do.call(rbind, faltantes),
    arq_fontes
  )

  # -----------------------------------------------------------
  # Resumo da execucao
  # -----------------------------------------------------------

  cat(
    'SO3.3: componentes concluidas. Produtos:',
    length(todos_produtos),
    '| regras:',
    length(parametros),
    '| linhas de cobertura:',
    length(cobertura),
    '\n'
  )

  print(
    do.call(rbind, cobertura)[
      ,
      c(
        'dimensao',
        'ano',
        'grupo',
        'n_completos',
        'n_incompletos'
      )
    ],
    row.names = FALSE
  )

  invisible(
    list(
      produtos = todos_produtos,
      parametros = parametros,
      cobertura = cobertura
    )
  )
}

if (sys.nframe() == 0L) {
  so33_componentes()
}
