#!/usr/bin/env Rscript
# PRAIS4 / SO3.3 - Bloco G: composicao final do DVI-Brasil.
# Entrada exclusiva: tres componentes municipais ja calculadas e orientadas.
# Metodo: media aritmetica simples, 1/3 por componente.
# Regra: TODAS as tres componentes obrigatorias; sem media parcial.
# Sem nova normalizacao, reescalonamento, orientacao ou classificacao.
# Associacao: ano + cod_mun (IBGE, sete digitos) + grupo.
# UF e nome sao metadados preservados da componente Social, nao chaves.
# Uso, a partir da raiz do repositorio:
#   Rscript so3.3/executar_dvi_so33.R

so33_executar_dvi <- function() {
  raiz <- 'so3.3'
  arq_modulo <- file.path(raiz, 'R', '03_diagnostico',
                           'estatistica_brutos_conjuntos.R')
  if (!file.exists(arq_modulo)) {
    stop('Execute a partir da raiz do repositorio: ', arq_modulo)
  }
  source(arq_modulo, local = TRUE)

  anos <- estat_so33_anos()
  grupos <- estat_so33_grupos()
  ids <- c('SOCIAL', 'ECONOMICA', 'INFRAESTRUTURAL')
  dimensoes <- c('social', 'economica', 'infraestrutural')
  dir_componentes <- file.path(raiz, 'outputs', 'componentes')
  dir_dvi <- file.path(raiz, 'outputs', 'dvi')
  dir_meta <- file.path(raiz, 'metadata')
  chave <- function(x) paste(x$ano, x$cod_mun, x$grupo, sep = '|')

  ler_componente <- function(ano, dim, id) {
    arq <- file.path(dir_componentes, dim, as.character(ano),
                     paste0('COMP_', id, '_', ano, '.csv'))
    if (!file.exists(arq)) stop('Componente ausente: ', arq)
    x <- utils::read.csv(
      arq, sep = ';', dec = '.', quote = '"',
      colClasses = 'character', na.strings = c('', 'NA'),
      fileEncoding = 'UTF-8', check.names = FALSE,
      stringsAsFactors = FALSE
    )
    campos <- c('ano', 'uf', 'cod_mun', 'nm_mun',
                'grupo', 'componente', 'valor')
    if (!all(campos %in% names(x)) || anyDuplicated(names(x))) {
      stop('Contrato de colunas invalido: ', arq)
    }
    campos_chave <- c('ano', 'uf', 'cod_mun', 'nm_mun',
                      'grupo', 'componente')
    if (anyNA(x[campos_chave]) ||
        any(!nzchar(trimws(as.matrix(x[campos_chave])))) ||
        any(x$ano != as.character(ano)) ||
        any(x$componente != id) ||
        any(!grepl('^[0-9]{7}$', x$cod_mun)) ||
        !setequal(unique(x$grupo), grupos) ||
        anyDuplicated(chave(x))) {
      stop('Chaves municipais ou identificacao invalidas: ', arq)
    }

    n_mun <- switch(as.character(ano),
                    '2000' = 5507L, '2010' = 5565L, '2022' = 5570L)
    if (is.null(n_mun) || nrow(x) != 3L * n_mun ||
        length(unique(x$cod_mun)) != n_mun ||
        any(as.integer(table(factor(x$grupo, levels = grupos))) != n_mun) ||
        any(as.integer(table(x$cod_mun)) != 3L)) {
      stop('Cardinalidade municipal invalida: ', arq)
    }

    original <- trimws(x$valor)
    original[!is.na(original) & original %in% c('', 'NA')] <- NA_character_
    v <- suppressWarnings(as.numeric(original))
    if (any(!is.na(original) & (is.na(v) | !is.finite(v))) ||
        any(!is.na(v) & (v < 0 | v > 1))) {
      stop('Valores da componente invalidos ou fora de [0,1]: ', arq)
    }
    x$valor <- v
    list(dados = x, arquivo = arq,
         md5 = unname(tools::md5sum(arq)))
  }

  produtos <- list()
  coberturas <- list()
  fontes <- list()
  ausencias <- list()
  ip <- 0L; ic <- 0L; ifo <- 0L; ia <- 0L

  # Toda a leitura, calculo e validacao ocorrem antes de qualquer escrita.
  for (ano in anos) {
    entradas <- lapply(seq_along(ids), function(j) {
      ler_componente(ano, dimensoes[[j]], ids[[j]])
    })
    names(entradas) <- ids
    base <- entradas[['SOCIAL']]$dados
    chaves <- chave(base)
    valores <- matrix(NA_real_, nrow = nrow(base), ncol = length(ids),
                      dimnames = list(NULL, ids))

    for (j in seq_along(ids)) {
      x <- entradas[[j]]$dados
      chaves_x <- chave(x)
      pos <- match(chaves, chaves_x)
      n_faltantes <- sum(is.na(pos))
      n_extras <- sum(!(chaves_x %in% chaves))
      if (n_faltantes != 0L || n_extras != 0L) {
        stop('Malhas distintas: ', ids[[j]], '/', ano,
             ' | sem correspondencia=', n_faltantes,
             ' | fora da base=', n_extras)
      }
      # Nao comparar UF textual: pode estar em sigla ou codigo IBGE.
      valores[, j] <- x$valor[pos]
      ifo <- ifo + 1L
      fontes[[ifo]] <- data.frame(
        indice = 'DVI_BRASIL', ano = ano, componente = ids[[j]],
        arquivo_entrada = entradas[[j]]$arquivo,
        md5_entrada = as.character(entradas[[j]]$md5),
        n_registros = nrow(x), n_municipios = length(unique(x$cod_mun)),
        n_sem_correspondencia = n_faltantes,
        n_fora_da_malha_base = n_extras,
        stringsAsFactors = FALSE
      )
    }

    # Politica DA FIRMA: as tres componentes precisam estar presentes.
    completos <- rowSums(!is.na(valores)) == 3L
    resultado <- rep(NA_real_, nrow(base))
    resultado[completos] <- rowMeans(valores[completos, , drop = FALSE])
    if (!identical(which(is.na(resultado)), which(!completos)) ||
        any(!is.na(resultado) & !is.finite(resultado)) ||
        any(!is.na(resultado) & (resultado < 0 | resultado > 1))) {
      stop('Integridade do DVI invalida no ano ', ano)
    }

    saida <- base[, c('ano', 'uf', 'cod_mun', 'nm_mun', 'grupo'),
                  drop = FALSE]
    saida$indice <- 'DVI_BRASIL'
    saida$valor <- resultado
    arq_saida <- file.path(dir_dvi, as.character(ano),
                           paste0('DVI_BRASIL_', ano, '.csv'))
    ip <- ip + 1L
    produtos[[ip]] <- list(arquivo = arq_saida, dados = saida)

    if (any(!completos)) {
      incompletos <- base[!completos,
                          c('ano', 'uf', 'cod_mun', 'nm_mun', 'grupo'),
                          drop = FALSE]
      faltantes <- is.na(valores[!completos, , drop = FALSE])
      incompletos$componentes_ausentes <- apply(
        faltantes, 1L, function(z) paste(ids[z], collapse = '|')
      )
      incompletos$n_componentes_validas <- rowSums(!faltantes)
      ia <- ia + 1L
      ausencias[[ia]] <- incompletos
    }

    for (grupo in grupos) {
      sel <- base$grupo == grupo
      validos <- resultado[sel]
      x <- validos[!is.na(validos)]
      ic <- ic + 1L
      coberturas[[ic]] <- data.frame(
        indice = 'DVI_BRASIL', ano = ano, grupo = grupo,
        n_municipios = sum(sel),
        n_validos = length(x),
        n_ausentes = sum(is.na(validos)),
        percentual_validos = 100 * length(x) / sum(sel),
        n_ausentes_social = sum(is.na(valores[sel, 'SOCIAL'])),
        n_ausentes_economica = sum(is.na(valores[sel, 'ECONOMICA'])),
        n_ausentes_infraestrutural = sum(is.na(valores[sel, 'INFRAESTRUTURAL'])),
        minimo_observado = if (length(x)) min(x) else NA_real_,
        maximo_observado = if (length(x)) max(x) else NA_real_,
        media_observada = if (length(x)) mean(x) else NA_real_,
        stringsAsFactors = FALSE
      )
    }
  }

  parametros <- data.frame(
    indice = rep('DVI_BRASIL', 3L),
    componente = ids,
    peso = rep(1 / 3, 3L),
    metodo = rep('MEDIA_ARITMETICA_SIMPLES', 3L),
    regra_ausentes = rep('TODAS_COMPONENTES_OBRIGATORIAS', 3L),
    chave_associacao = rep('ano|cod_mun|grupo', 3L),
    reescalonamento = rep('NAO', 3L),
    orientacao_adicional = rep('NAO', 3L),
    stringsAsFactors = FALSE
  )
  tabela_cobertura <- do.call(rbind, coberturas)
  tabela_fontes <- do.call(rbind, fontes)
  tabela_ausencias <- if (length(ausencias)) {
    do.call(rbind, ausencias)
  } else {
    data.frame(ano = character(), uf = character(), cod_mun = character(),
               nm_mun = character(), grupo = character(),
               componentes_ausentes = character(),
               n_componentes_validas = integer(),
               stringsAsFactors = FALSE)
  }

  metas <- list(
    list(arquivo = file.path(dir_meta, 'dvi_parametros.csv'), dados = parametros),
    list(arquivo = file.path(dir_meta, 'dvi_cobertura.csv'), dados = tabela_cobertura),
    list(arquivo = file.path(dir_meta, 'dvi_fontes.csv'), dados = tabela_fontes),
    list(arquivo = file.path(dir_meta, 'dvi_ausencias.csv'), dados = tabela_ausencias)
  )
  itens <- c(produtos, metas)
  destinos <- vapply(itens, `[[`, character(1), 'arquivo')
  existentes <- destinos[file.exists(destinos)]
  if (length(existentes)) {
    stop('Sobrescrita proibida; produtos existentes. Exemplo: ', existentes[[1L]])
  }

  gravados <- character()
  sucesso <- FALSE
  on.exit({
    if (!sucesso && length(gravados)) unlink(gravados)
  }, add = TRUE)
  for (item in itens) {
    arq <- item$arquivo
    dir.create(dirname(arq), recursive = TRUE, showWarnings = FALSE)
    tmp <- tempfile(pattern = '.dvi_so33_', tmpdir = dirname(arq),
                    fileext = '.csv')
    tryCatch({
      utils::write.table(item$dados, file = tmp, sep = ';', dec = '.',
                         row.names = FALSE, col.names = TRUE, quote = TRUE,
                         na = '', fileEncoding = 'UTF-8')
      if (file.exists(arq) || !file.rename(tmp, arq)) {
        stop('Falha ao publicar sem sobrescrever: ', arq)
      }
      gravados <- c(gravados, arq)
    }, finally = {
      if (file.exists(tmp)) unlink(tmp)
    })
  }
  sucesso <- TRUE

  cat('SO3.3 | DVI-Brasil concluido | arquivos DVI:', length(produtos),
      '| metadados:', length(metas), '\n')
  print(tabela_cobertura[, c('ano', 'grupo', 'n_municipios',
                            'n_validos', 'n_ausentes',
                            'minimo_observado', 'maximo_observado')],
        row.names = FALSE)
  invisible(list(produtos = destinos, cobertura = tabela_cobertura,
                 parametros = parametros, fontes = tabela_fontes,
                 ausencias = tabela_ausencias))
}

if (sys.nframe() == 0L) {
  so33_executar_dvi()
}
