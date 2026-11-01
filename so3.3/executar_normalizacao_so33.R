#!/usr/bin/env Rscript
# SO3.3 - Normalizacao min-max [0,1], sem orientacao.
# Execute da raiz do repositorio: Rscript so3.3/executar_normalizacao_so33.R
# Entradas obrigatorias: 27 CSVs promovidos em outputs/tratado/.
# Saidas: 27 CSVs em outputs/normalizado/ e parametros em metadata/.

so33_normalizar <- function() {
  modulo <- 'so3.3/R/03_diagnostico/estatistica_brutos_conjuntos.R'
  if (!file.exists(modulo)) stop('Execute da raiz do repositorio.')
  source(modulo, local = TRUE)
  catalogo <- estat_so33_catalogo()
  anos <- estat_so33_anos()
  grupos <- estat_so33_grupos()
  dir_tratado <- 'so3.3/outputs/tratado'
  dir_normalizado <- 'so3.3/outputs/normalizado'
  arquivo_meta <- 'so3.3/metadata/normalizacao_parametros.csv'
  stopifnot(nrow(catalogo) == 9L)

  # O processamento nao altera resultados anteriores e nao sobrescreve versoes.
  if (file.exists(arquivo_meta)) stop('Metadados ja existem: ', arquivo_meta,
                                     '. Arquive/versione a versao antes de recalcular.')
  # Todos os dados sao lidos e validados antes de criar saidas.
  resultados <- list(); parametros <- list(); indice <- 0L
  destinos <- character()
  for (j in seq_len(nrow(catalogo))) {
    id <- catalogo$indicador[[j]]
    dim <- catalogo$dimensao[[j]]
    natureza <- catalogo$natureza[[j]]
    entradas <- lapply(anos, function(ano) {
      arquivo <- file.path(dir_tratado, dim, as.character(ano),
                           paste0(id, '_', ano, '.csv'))
      if (!file.exists(arquivo)) stop('Ausente: ', arquivo)
      d <- utils::read.csv(arquivo, sep = ';', dec = '.', quote = '"',
                           colClasses = 'character', na.strings = c('', 'NA'),
                           check.names = FALSE, stringsAsFactors = FALSE,
                           fileEncoding = 'UTF-8')
      campos <- c('ano','uf','cod_mun','nm_mun','indicador','grupo','valor')
      if (!all(campos %in% names(d)) || anyDuplicated(names(d)))
        stop('Contrato invalido: ', arquivo)
      if (anyNA(d[c('ano','uf','cod_mun','nm_mun','indicador','grupo')]) ||
          any(d$ano != as.character(ano)) || any(d$indicador != id) ||
          !setequal(unique(d$grupo), grupos) ||
          anyDuplicated(paste(d$cod_mun, d$grupo)))
        stop('Chaves invalidas: ', arquivo)
      esperado <- if (id == 'INF02_RECURSOS_HIDRICOS_PC') 5571L else
        switch(as.character(ano), '2000' = 5507L, '2010' = 5565L, '2022' = 5570L)
      if (nrow(d) != 3L * esperado || length(unique(d$cod_mun)) != esperado ||
          any(as.integer(table(factor(d$grupo, levels = grupos))) != esperado) ||
          any(as.integer(table(d$cod_mun)) != 3L))
        stop('Cardinalidade invalida: ', arquivo)
      txt <- trimws(d$valor)
      txt[!is.na(txt) & txt %in% c('', 'NA')] <- NA_character_
      valor <- suppressWarnings(as.numeric(txt))
      if (any(!is.na(txt) & (!is.finite(valor) | is.na(valor))))
        stop('Valor nao numerico/nao finito: ', arquivo)
      d$valor <- valor
      d$ano <- as.integer(d$ano)
      list(dados = d, caminho = arquivo,
           md5 = unname(tools::md5sum(arquivo)))
    })
    base <- do.call(rbind, lapply(entradas, `[[`, 'dados'))
    rownames(base) <- NULL
    series <- estat_so33_series(base, natureza)
    normal <- base
    for (grupo in names(series)) {
      s <- series[[grupo]]
      v <- s$valor
      ok <- v[!is.na(v)]
      if (!length(ok) || !all(is.finite(ok))) stop('Serie sem valores finitos: ',id,'/',grupo)
      minimo <- min(ok); maximo <- max(ok)
      if (!(maximo > minimo)) stop('Serie constante: ',id,'/',grupo)
      nv <- (v - minimo) / (maximo - minimo)
      if (!identical(which(is.na(v)), which(is.na(nv))) ||
          any(!is.finite(nv[!is.na(nv)])) ||
          any(nv[!is.na(nv)] < -1e-12 | nv[!is.na(nv)] > 1 + 1e-12))
        stop('Falha de normalizacao: ',id,'/',grupo)
      nv <- pmin(1, pmax(0, nv)) # Apenas tolerancia numerica.
      for (gp in if (natureza == 'territorial_compartilhado') grupos else grupo) {
        idx <- which(normal$grupo == gp)
        pos <- match(paste(normal$ano[idx], normal$cod_mun[idx]),
                     paste(s$ano,s$cod_mun))
        if (anyNA(pos)) stop('Chaves nao correspondentes: ',id,'/',gp)
        normal$valor[idx] <- nv[pos]
      }
      indice <- indice + 1L
      parametros[[indice]] <- data.frame(
        dimensao = dim, indicador = id, natureza = natureza,
        grupo_referencia = grupo,
        anos_referencia = '2000|2010|2022',
        n_validos = length(ok), n_ausentes = sum(is.na(v)),
        minimo = minimo, maximo = maximo,
        metodo = 'min_max_conjunto', orientacao_aplicada = FALSE,
        md5_tratado_2000 = entradas[[1]]$md5,
        md5_tratado_2010 = entradas[[2]]$md5,
        md5_tratado_2022 = entradas[[3]]$md5,
        stringsAsFactors = FALSE)
    }
    if (!identical(which(is.na(normal$valor)), which(is.na(base$valor))))
      stop('NAs foram alterados: ',id)
    if (natureza == 'territorial_compartilhado')
      estat_so33_series(normal, natureza)
    for (ano in anos) {
      destino <- file.path(dir_normalizado,dim,as.character(ano),
                           paste0(id,'_',ano,'.csv'))
      if (file.exists(destino)) stop('Saida ja existente: ',destino)
      destinos <- c(destinos,destino)
      resultados[[length(resultados)+1L]] <- list(
        destino = destino, dados = normal[normal$ano == ano,,drop=FALSE])
    }
  }
  if (length(resultados) != 27L || length(parametros) != 21L)
    stop('Quantidade inesperada de produtos/series.')
  if (anyDuplicated(destinos) || any(file.exists(destinos))) stop('Colisao de destinos.')
  if (!dir.exists(dirname(arquivo_meta))) stop('Diretorio metadata inexistente.')
  # Preparar arquivos em area temporaria. Nenhuma saida e publicada antes da validacao.
  area <- tempfile('so33_norm_')
  dir.create(area)
  on.exit(unlink(area,recursive=TRUE,force=TRUE),add=TRUE)
  op <- options(digits=17)
  on.exit(options(op),add=TRUE)
  gravar <- function(obj,p) utils::write.table(obj, p, sep=';',dec='.',
        row.names=FALSE,col.names=TRUE,quote=TRUE,na='',fileEncoding='UTF-8')
  preparados <- character()
  for (i in seq_along(resultados)) {
    p <- file.path(area,paste0('dados_',i,'.csv'))
    gravar(resultados[[i]]$dados,p)
    preparados <- c(preparados,p)
  }
  arquivo_temp_meta <- file.path(area,'normalizacao_parametros.csv')
  gravar(do.call(rbind,parametros),arquivo_temp_meta)
  # Promocao de cada CSV, sem sobrescrita. Em falha de copia, reverte os publicados.
  publicados <- character()
  tryCatch({
    for (i in seq_along(resultados)) {
      dest <- resultados[[i]]$destino
      dir.create(dirname(dest),recursive=TRUE,showWarnings=FALSE)
      if (file.exists(dest) || !file.copy(preparados[[i]],dest,overwrite=FALSE))
        stop('Falha ao promover: ',dest)
      publicados <- c(publicados,dest)
    }
    if (file.exists(arquivo_meta) ||
        !file.copy(arquivo_temp_meta,arquivo_meta,overwrite=FALSE))
      stop('Falha ao publicar parametros.')
  },error=function(e){
    unlink(publicados)
    stop(conditionMessage(e),call.=FALSE)
  })
  message('SO3.3 | Normalizacao concluida: 27 CSVs, 21 series de referencia.')
  message('Parametros: ',arquivo_meta)
  invisible(TRUE)
}
if (sys.nframe() == 0L) so33_normalizar()
