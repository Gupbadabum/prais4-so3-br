#!/usr/bin/env Rscript
# PRAIS4 / SO3.3 - Promocao segura dos produtos estatisticos aprovados.
# Executar da raiz: RSCRIPT so3.3/promover_tratados_so33.R
# Pode ser invocado pela futura normalizacao antes de ler outputs/tratado.
# Nao recalcula, nao normaliza, nao altera outputs/intermediario ou bruto.

promover_tratados_so33 <- function() {
  modulo <- 'so3.3/R/03_diagnostico/estatistica_brutos_conjuntos.R'
  if (!file.exists(modulo)) stop('Execute a partir da raiz do repositorio.')
  source(modulo, local = TRUE)
  catalogo <- estat_so33_catalogo()
  anos <- estat_so33_anos()
  campos_chave <- c('ano', 'uf', 'cod_mun', 'nm_mun', 'indicador', 'grupo')
  origem_raiz <- 'so3.3/outputs/intermediario/estatistica/tratamento'
  destino_raiz <- 'so3.3/outputs/tratado'
  manifest <- list()
  planos <- list()
  n_plano <- 0L

  ler <- function(arq) utils::read.csv(
    arq, sep = ';', dec = '.', quote = '"',
    colClasses = 'character', na.strings = c('', 'NA'),
    fileEncoding = 'UTF-8', check.names = FALSE,
    stringsAsFactors = FALSE
  )
  exigir <- function(cond, msg) if (!isTRUE(cond)) stop(msg, call. = FALSE)

  for (i in seq_len(nrow(catalogo))) {
    id <- catalogo$indicador[i]
    dimensao <- catalogo$dimensao[i]
    natureza <- catalogo$natureza[i]
    raiz <- file.path(origem_raiz, dimensao)
    exigir(dir.exists(raiz), paste('Sem execucoes:', raiz))
    execucoes <- list.dirs(raiz, full.names = TRUE, recursive = FALSE)
    execucoes <- sort(execucoes, decreasing = TRUE)
    # Selecionar a execucao mais recente deste indicador.
    candidatos <- execucoes[file.exists(file.path(execucoes, id, '01_decisoes.csv'))]
    exigir(length(candidatos) > 0L, paste('Nenhum relatorio:', id))
    pasta <- file.path(candidatos[1L], id)
    decisao <- ler(file.path(pasta, '01_decisoes.csv'))
    inventario <- ler(file.path(pasta, '02_fontes_md5.csv'))
    exigir(all(c('grupo_referencia', 'decisao_winsor', 'decisao_yj') %in% names(decisao)),
           paste('Relatorio de decisao incompleto:', id))
    grupos <- if (natureza == 'territorial_compartilhado') 'Compartilhado' else estat_so33_grupos()
    exigir(nrow(decisao) == length(grupos) && setequal(decisao$grupo_referencia, grupos),
           paste('Grupos divergentes:', id))
    if (id %in% c('ECO02_PIBPC', 'INF02_RECURSOS_HIDRICOS_PC')) {
      exigir(all(decisao$decisao_yj == 'APLICAR_YJ_DECISAO_DOCUMENTADA') &&
             all(decisao$decisao_winsor == 'NAO_APLICAR_DECISAO_DOCUMENTADA'),
             paste('Tratamento YJ aprovado nao encontrado:', id))
      exigir('lambda_candidato' %in% names(decisao) &&
             all(is.finite(suppressWarnings(as.numeric(decisao$lambda_candidato)))),
             paste('Lambda ausente:', id))
    } else {
      exigir(all(decisao$decisao_yj == 'MANTER_SEM_TRANSFORMACAO') &&
             all(decisao$decisao_winsor == 'SEM_WINSORIZACAO'),
             paste('Intervencao nao aprovada:', id))
    }
    exigir(all(c('ano', 'arquivo', 'md5') %in% names(inventario)) &&
           setequal(inventario$ano, as.character(anos)) && nrow(inventario) == length(anos),
           paste('Inventario incompleto:', id))

    for (ano in anos) {
      arquivo_candidato <- file.path(pasta, paste0(id, '_', ano, '_candidato.csv'))
      exigir(file.exists(arquivo_candidato), paste('Ausente:', arquivo_candidato))
      arquivo_bruto <- file.path('so3.3/outputs/bruto', dimensao, as.character(ano),
                                paste0(id, '_', ano, '.csv'))
      exigir(file.exists(arquivo_bruto), paste('Bruto ausente:', arquivo_bruto))
      inv <- inventario[inventario$ano == as.character(ano), , drop = FALSE]
      exigir(nrow(inv) == 1L && identical(unname(tools::md5sum(arquivo_bruto)), inv$md5[[1L]]),
             paste('Bruto mudou desde a execucao candidata:', id, ano))
      original <- ler(arquivo_bruto)
      tratado <- ler(arquivo_candidato)
      exigir(identical(names(original), names(tratado)) && nrow(original) == nrow(tratado),
             paste('Estrutura alterada:', id, ano))
      exigir(identical(original[campos_chave], tratado[campos_chave]),
             paste('Chaves alteradas:', id, ano))
      exigir(identical(which(is.na(original$valor)), which(is.na(tratado$valor))),
             paste('Posicoes NA alteradas:', id, ano))
      campos_extras <- setdiff(names(original), 'valor')
      exigir(identical(original[campos_extras], tratado[campos_extras]),
             paste('Colunas nao numericas ou metadados alterados:', id, ano))
      if (!(id %in% c('ECO02_PIBPC', 'INF02_RECURSOS_HIDRICOS_PC'))) {
        x0 <- suppressWarnings(as.numeric(original$valor))
        x1 <- suppressWarnings(as.numeric(tratado$valor))
        exigir(identical(which(is.na(x0)), which(is.na(x1))) &&
               all(is.finite(x0[!is.na(x0)])) && all(is.finite(x1[!is.na(x1)])) &&
               isTRUE(all.equal(x0, x1, tolerance = 1e-12, check.attributes = FALSE)),
               paste('Indicador aprovado sem intervencao foi alterado:', id, ano))
      }
      destino <- file.path(destino_raiz, dimensao, as.character(ano), paste0(id, '_', ano, '.csv'))
      if (file.exists(destino)) {
        exigir(identical(unname(tools::md5sum(destino)),
                         unname(tools::md5sum(arquivo_candidato))),
               paste('Conflito: tratado ja existe com conteudo diferente:', destino))
      }
      n_plano <- n_plano + 1L
      planos[[n_plano]] <- list(origem = arquivo_candidato, destino = destino)
      manifest[[n_plano]] <- data.frame(
        indicador = id, dimensao = dimensao, ano = ano,
        arquivo_candidato = arquivo_candidato, arquivo_tratado = destino,
        md5_candidato = unname(tools::md5sum(arquivo_candidato)),
        execucao_origem = basename(candidatos[1L]),
        stringsAsFactors = FALSE
      )
    }
  }

  # Somente agora, apos validar os 27 produtos, efetuar as copias.
  for (p in planos) {
    dir.create(dirname(p$destino), recursive = TRUE, showWarnings = FALSE)
    if (!file.exists(p$destino)) {
      exigir(file.copy(p$origem, p$destino, overwrite = FALSE),
             paste('Falha na copia:', p$destino))
    }
    exigir(identical(unname(tools::md5sum(p$origem)),
                     unname(tools::md5sum(p$destino))),
           paste('Divergencia MD5:', p$destino))
  }
  manifest <- do.call(rbind, manifest)
  message('Promocao validada: ', nrow(manifest), ' arquivos CSV em ', destino_raiz)
  invisible(manifest)
}

if (sys.nframe() == 0L) promover_tratados_so33()
