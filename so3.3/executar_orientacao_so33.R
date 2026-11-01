#!/usr/bin/env Rscript
# PRAIS4 SO3.3 - Bloco E: orientacao da vulnerabilidade apos normalizacao.
# Executar da raiz: Rscript so3.3/executar_orientacao_so33.R
# Nao estima minimos/maximos; nao recalcula normalizacao nem tratamento.

so33_orientar <- function() {
  base_dir <- file.path('so3.3', 'outputs')
  entrada <- file.path(base_dir, 'normalizado')
  destino <- file.path(base_dir, 'orientado')
  meta_dir <- file.path('so3.3', 'metadata')
  regras_path <- file.path(meta_dir, 'orientacao_regras.csv')
  parametros_path <- file.path(meta_dir, 'normalizacao_parametros.csv')
  catalog_path <- file.path('so3.3','R','03_diagnostico','estatistica_brutos_conjuntos.R')
  if (!file.exists(catalog_path)) stop('Execute na raiz do repositorio.')
  source(catalog_path, local = TRUE)
  if (!file.exists(regras_path)) stop('Ausente: ', regras_path)
  if (!file.exists(parametros_path)) stop('Ausente: ', parametros_path)
  regras <- utils::read.csv(regras_path, sep=';', dec='.', stringsAsFactors=FALSE,
                            check.names=FALSE, fileEncoding='UTF-8')
  req <- c('dimensao','indicador','sentido','justificativa')
  if (!all(req %in% names(regras)) || anyDuplicated(regras$indicador) || anyNA(regras[req]))
    stop('Regras ausentes, duplicadas ou incompletas.')
  catalogo <- estat_so33_catalogo()
  if (!setequal(regras$indicador, catalogo$indicador) || nrow(regras)!=nrow(catalogo) ||
      any(!regras$sentido %in% c('direto','inverso')) ||
      any(regras$dimensao != catalogo$dimensao[match(regras$indicador,catalogo$indicador)]))
    stop('Regras de orientacao inconsistentes com o catalogo.')
  if (file.info(parametros_path)$size <= 0) stop('Metadados de normalizacao vazios.')
  # A leitura a seguir confirma a existencia dos parametros; nao os recalcula.
  parametros <- utils::read.csv(parametros_path, sep=';', dec='.', stringsAsFactors=FALSE,
                                check.names=FALSE, fileEncoding='UTF-8')
  if (!('indicador' %in% names(parametros)) ||
      !setequal(unique(parametros$indicador),catalogo$indicador))
    stop('Tabela de parametros nao cobre os nove indicadores.')
  anos <- estat_so33_anos(); grupos <- estat_so33_grupos()
  arquivos <- list(); trilha <- list(); i <- 0L
  for (k in seq_len(nrow(catalogo))) {
    id <- catalogo$indicador[k]; dim <- catalogo$dimensao[k]
    natureza <- catalogo$natureza[k]
    sentido <- regras$sentido[match(id,regras$indicador)]
    for (ano in anos) {
      src <- file.path(entrada,dim,as.character(ano),paste0(id,'_',ano,'.csv'))
      dst <- file.path(destino,dim,as.character(ano),paste0(id,'_',ano,'.csv'))
      if (!file.exists(src)) stop('Entrada normalizada ausente: ',src)
      # O contrato original e estritamente preservado, salvo coluna valor.
      x <- utils::read.csv(src, sep=';', dec='.', quote='"',
                           colClasses='character', na.strings=c('','NA'),
                           fileEncoding='UTF-8', check.names=FALSE,
                           stringsAsFactors=FALSE)
      obrig <- c('ano','uf','cod_mun','nm_mun','indicador','grupo','valor')
      if (!all(obrig %in% names(x)) || anyDuplicated(names(x)) ||
          anyNA(x[c('ano','uf','cod_mun','nm_mun','indicador','grupo')]) ||
          any(x$ano != as.character(ano)) || any(x$indicador != id) ||
          !setequal(unique(x$grupo),grupos) ||
          anyDuplicated(paste(x$cod_mun,x$grupo,sep='|'))) stop('Chaves/contrato invalido: ',src)
      esperado <- if (id=='INF02_RECURSOS_HIDRICOS_PC') 5571L else
        switch(as.character(ano),'2000'=5507L,'2010'=5565L,'2022'=5570L)
      if (nrow(x) != esperado*3L || length(unique(x$cod_mun)) != esperado ||
          any(as.integer(table(factor(x$grupo,levels=grupos))) != esperado))
        stop('Cardinalidade inesperada: ',src)
      txt <- trimws(x$valor); txt[!is.na(txt) & txt %in% c('','NA')] <- NA_character_
      v <- suppressWarnings(as.numeric(txt))
      if (any(!is.na(txt) & (!is.finite(v) | is.na(v)))) stop('Valor invalido: ',src)
      if (any(!is.na(v) & (v < -1e-10 | v > 1+1e-10))) stop('Fora de [0,1]: ',src)
      # Apenas residuos numericos minimos de arredondamento sao corrigidos.
      v[!is.na(v) & v < 0] <- 0
      v[!is.na(v) & v > 1] <- 1
      z <- if (sentido=='inverso') 1-v else v
      if (!identical(which(is.na(v)),which(is.na(z)))) stop('Ausencias alteradas: ',src)
      if (natureza=='territorial_compartilhado') {
        spl <- split(seq_len(nrow(x)),x$grupo)
        ref <- x[spl[['Total']],c('cod_mun','valor'),drop=FALSE]
        for (g in grupos[-1]) {
          y <- x[spl[[g]],c('cod_mun','valor'),drop=FALSE]
          p <- match(ref$cod_mun,y$cod_mun)
          if (anyNA(p) || !identical(ref$valor,y$valor[p]))
            stop('Indicador territorial nao compartilhado: ',src)
        }
      }
      x$valor <- z
      i <- i+1L
      arquivos[[i]] <- list(x=x,src=src,dst=dst)
      trilha[[i]] <- data.frame(dimensao=dim,indicador=id,ano=ano,
                               natureza=natureza,sentido=sentido,
                               registros=nrow(x),n_validos=sum(!is.na(v)),
                               n_ausentes=sum(is.na(v)),
                               md5_normalizado=unname(tools::md5sum(src)),
                               stringsAsFactors=FALSE)
    }
  }
  # Nunca sobrescrever arquivos anteriores; reprova antes da primeira escrita.
  destinos <- vapply(arquivos, `[[`, character(1), 'dst')
  existentes <- destinos[file.exists(destinos)]
  if (length(existentes)) stop('Saida orientada ja existe. Nenhuma gravacao realizada. Ex.: ',existentes[1])
  trilha_path <- file.path(meta_dir,'orientacao_execucao.csv')
  if (file.exists(trilha_path)) stop('Metadados de orientacao ja existem. Nenhuma gravacao realizada: ',trilha_path)
  for (item in arquivos) {
    dir.create(dirname(item$dst),recursive=TRUE,showWarnings=FALSE)
    utils::write.table(item$x,item$dst,sep=';',dec='.',row.names=FALSE,
                       col.names=TRUE,quote=TRUE,na='',fileEncoding='UTF-8')
  }
  audit <- do.call(rbind,trilha)
  audit$md5_orientado <- vapply(arquivos,function(a)unname(tools::md5sum(a$dst)),character(1))
  audit$md5_regras <- unname(tools::md5sum(regras_path))
  audit$md5_parametros_normalizacao <- unname(tools::md5sum(parametros_path))
  utils::write.table(audit,trilha_path,sep=';',dec='.',row.names=FALSE,
                     col.names=TRUE,quote=TRUE,na='',fileEncoding='UTF-8')
  message('SO3.3 Bloco E concluido: ',length(arquivos),' arquivos orientados; ',
          nrow(audit),' registros de auditoria. Sem recalcular normalizacao.')
  invisible(audit)
}
if (sys.nframe()==0L) so33_orientar()
