#!/usr/bin/env Rscript
# PRAIS4 / SO3.3 - Bloco B/C: winsorizacao automatica conservadora e Yeo-Johnson.
# Instalar este arquivo em: so3.3/executar_tratamento_estatistico.R
# Executar da raiz: RSCRIPT so3.3/executar_tratamento_estatistico.R social SOC01_ALF15
# R base; reutiliza catalogo, leitura, validacao e momentos do Bloco A.
# A politica de selecao automatica abaixo e PROPOSTA OPERACIONAL PRAIS-BRASIL,
# NAO um requisito expresso do manual da UNCCD ou funcao COINr.

so33_tratamento <- function(args = commandArgs(trailingOnly = TRUE)) {
  modulo <- 'so3.3/R/03_diagnostico/estatistica_brutos_conjuntos.R'
  if (!file.exists(modulo)) stop('Execute da raiz do repositorio: modulo do Bloco A ausente.')
  source(modulo, local = TRUE)
  if (length(args) != 2L) stop('Uso: RSCRIPT so3.3/executar_tratamento_estatistico.R DIMENSAO INDICADOR|todos')
  dimensao <- tolower(args[[1L]]); escolha <- args[[2L]]
  catalogo <- estat_so33_catalogo()
  ids <- catalogo$indicador[catalogo$dimensao == dimensao]
  if (!length(ids)) stop('Dimensao invalida: ', dimensao)
  if (tolower(escolha) == 'todos') selecionados <- ids else {
    if (!(escolha %in% ids)) stop('Indicador desconhecido nesta dimensao: ', escolha)
    selecionados <- escolha
  }
  # Parametros configuraveis, predefinidos de forma conservadora.
  cfg <- list(
    max_winsor = 0.05, passos_winsor = c(0.005, 0.01, 0.02, 0.05),
    melhora_minima = 0.20, deterioracao_maxima = 0.10,
    iqr_rel_max = 0.20, delta_med_max = 0.05, delta_p95_max = 0.15,
    delta_temporal_rel_max = 0.20, delta_temporal_abs_max = 0.02,
    diferenca_temporal_pequena = 0.02,
    lambda_intervalo = c(-3, 3)
  )
  timestamp <- format(Sys.time(), '%Y%m%dT%H%M%S')
  destino_raiz <- file.path('so3.3','outputs','intermediario','estatistica',
                             'tratamento', dimensao, timestamp)
  if (dir.exists(destino_raiz)) stop('Diretorio ja existe; sem sobrescrita: ', destino_raiz)
  dir.create(destino_raiz, recursive = TRUE, showWarnings = FALSE)
  gravar <- function(x, p) utils::write.table(x, p, sep=';', dec='.', row.names=FALSE,
                                               col.names=TRUE, quote=TRUE, na='', fileEncoding='UTF-8')
  resumo <- list(); i_res <- 0L
  momentos <- function(x) estat_so33_momentos_coinr(x)
  metrica <- function(m) {
    if (is.na(m$assimetria) || is.na(m$curtose_excesso)) return(Inf)
    max(abs(m$assimetria) / 2, 0) + max(m$curtose_excesso / 3.5, 0)
  }
  # Aplicacao de caps por contagem. Todos os empates no limiar recebem
  # o mesmo tratamento; pode alterar MENOS observacoes do que o teto.
  caps <- function(v, qinf, qsup) {
    z <- v; ok <- which(!is.na(v)); a <- sort(v[ok]); n <- length(a)
    if (!n || (qinf == 0L && qsup == 0L)) return(z)
    if (qinf > 0L && qinf < n) {
      lim <- a[qinf + 1L]
      z[ok[v[ok] < lim]] <- lim
    }
    if (qsup > 0L && qsup < n) {
      lim <- a[n - qsup]
      z[ok[v[ok] > lim]] <- lim
    }
    z
  }
  # Compara a winsorizacao ANTES de autorizar sua aplicacao. A avaliacao
  # territorial/temporal e obrigatoria para cada candidato que passa COINr.
  # Nenhum candidato reprovado substitui os valores originais.
  escolher_winsor <- function(x, m0, anos) {
    n <- sum(!is.na(x))
    vazio <- list(x=x, regime='nenhum', frac=0,
                  n_alterados=0L, status='SEM_WINSORIZACAO',
                  comparacao=list(ok=NA, iqr_rel=NA_real_,
                                  med_delta=NA_real_, p95_delta=NA_real_,
                                  temporal_ok=NA, motivo='NAO_APLICAVEL'),
                  candidato_rejeitado=NULL)
    if (!identical(m0$status, 'INVESTIGAR')) return(vazio)
    validos <- list(); k <- 0L
    for (p in cfg$passos_winsor) {
      nmax <- floor(n * min(p, cfg$max_winsor))
      metade <- floor(n * min(p, cfg$max_winsor)/2)
      planos <- list(bilateral=c(metade, metade),
                     inferior=c(nmax, 0), superior=c(0, nmax))
      for (modo in names(planos)) {
        pp <- planos[[modo]]; y <- caps(x, pp[[1L]], pp[[2L]])
        alterados <- sum(!is.na(x) & x != y)
        if (alterados > floor(n * cfg$max_winsor))
          stop('Violacao do teto de winsorizacao')
        if (alterados == 0L || !identical(momentos(y)$status,'PASSA')) next
        k <- k + 1L
        validos[[k]] <- list(x=y, regime=modo, frac=p,
                              n_alterados=alterados, status='CANDIDATO',
                              comparacao=comparar(x, y, anos))
      }
    }
    if (!length(validos)) {
      vazio$status <- 'REVISAR_WINSOR_SEM_CANDIDATO_COINR'
      return(vazio)
    }
    # Criterio primario: menor numero de modificacoes. Se o candidato
    # menos interventivo reprovar preservacao, procurar o seguinte.
    ord <- order(vapply(validos, `[[`, numeric(1), 'n_alterados'),
                 vapply(validos, function(z) metrica(momentos(z$x)), numeric(1)))
    validos <- validos[ord]
    aprovados <- Filter(function(z) isTRUE(z$comparacao$ok), validos)
    if (length(aprovados)) {
      melhor <- aprovados[[1L]]
      melhor$status <- 'APLICAR_WINSOR'
      return(melhor)
    }
    vazio$status <- 'REVISAR_WINSOR_PRESERVACAO'
    vazio$candidato_rejeitado <- validos[[1L]]
    vazio
  }
  yeojohnson <- function(x, lambda) {
    z <- x; pos <- !is.na(x) & x >= 0; neg <- !is.na(x) & x < 0
    if (any(pos)) z[pos] <- if (abs(lambda) < 1e-8) log1p(x[pos]) else
      expm1(lambda * log1p(x[pos]))/lambda
    if (any(neg)) z[neg] <- if (abs(lambda-2) < 1e-8) -log1p(-x[neg]) else
      -expm1((2-lambda)*log1p(-x[neg]))/(2-lambda)
    z
  }
  estimar_lambda <- function(x) {
    a <- x[!is.na(x)]; if (length(a) < 4L || stats::sd(a) == 0) return(NA_real_)
    objetivo <- function(lambda) {
      z <- yeojohnson(a, lambda)
      if (!all(is.finite(z))) return(Inf)
      variancia <- mean((z-mean(z))^2)
      if (!is.finite(variancia) || variancia <= 0) return(Inf)
      -(-length(a)/2 * log(variancia) +
          (lambda-1)*sum(sign(a)*log1p(abs(a))))
    }
    stats::optimize(objetivo, cfg$lambda_intervalo, tol=1e-5)$minimum
  }
  normalizar <- function(x) {
    ok <- x[!is.na(x)]; if (!length(ok) || max(ok) == min(ok)) return(rep(NA_real_,length(x)))
    (x-min(ok))/(max(ok)-min(ok))
  }
  comparar <- function(x, y, anos) {
    a <- normalizar(x); b <- normalizar(y)
    if (all(is.na(a)) || all(is.na(b))) return(list(ok=FALSE, iqr_rel=NA_real_,
        med_delta=NA_real_, p95_delta=NA_real_, temporal_ok=FALSE, motivo='SEM_VARIACAO'))
    q <- function(z) unname(stats::IQR(z, na.rm=TRUE))
    ia <- q(a); ib <- q(b)
    iqr_rel <- if (ia <= 1e-12) if (ib <= 1e-12) 0 else Inf else abs(ib/ia-1)
    delta <- abs(a-b); med <- stats::median(delta, na.rm=TRUE)
    p95 <- unname(stats::quantile(delta, .95, na.rm=TRUE))
    ma <- vapply(c(2000L,2010L,2022L), function(t) stats::median(a[anos==t],na.rm=TRUE),numeric(1))
    mb <- vapply(c(2000L,2010L,2022L), function(t) stats::median(b[anos==t],na.rm=TRUE),numeric(1))
    temporal_ok <- TRUE
    if (any(!is.finite(c(ma,mb)))) temporal_ok <- FALSE else {
      da <- diff(ma); db <- diff(mb)
      for (j in seq_along(da)) {
        if (abs(da[j]) < cfg$diferenca_temporal_pequena) {
          if (abs(db[j]-da[j]) > cfg$delta_temporal_abs_max) temporal_ok <- FALSE
        } else {
          if (sign(da[j]) != sign(db[j]) ||
              abs(db[j]/da[j]-1) > cfg$delta_temporal_rel_max) temporal_ok <- FALSE
        }
      }
    }
    list(ok=is.finite(iqr_rel) && iqr_rel <= cfg$iqr_rel_max &&
           med <= cfg$delta_med_max && p95 <= cfg$delta_p95_max && temporal_ok,
         iqr_rel=iqr_rel, med_delta=med, p95_delta=p95,
         temporal_ok=temporal_ok, motivo=if(temporal_ok) 'OK' else 'MUDANCA_TEMPORAL')
  }
  eficacia <- function(a,b) {
    sk0 <- abs(a$assimetria); sk1 <- abs(b$assimetria)
    ku0 <- max(0,a$curtose_excesso); ku1 <- max(0,b$curtose_excesso)
    reduzir_sk <- if (sk0 > 1e-10) (sk0-sk1)/sk0 else 0
    reduzir_ku <- if (ku0 > 1e-10) (ku0-ku1)/ku0 else 0
    piora_sk <- if (sk0 > 1e-10) (sk1-sk0)/sk0 else if(sk1 <= 1e-10) 0 else Inf
    piora_ku <- if (ku0 > 1e-10) (ku1-ku0)/ku0 else if(ku1 <= 1e-10) 0 else Inf
    (reduzir_sk >= cfg$melhora_minima || reduzir_ku >= cfg$melhora_minima) &&
      piora_sk <= cfg$deterioracao_maxima && piora_ku <= cfg$deterioracao_maxima
  }
  # Parametro INF02 congelado no diagnostico especifico aprovado.
  # Fonte exata: nao substituir por numero arredondado do terminal.
  parametros_aprovados <- function(id) {
    if (identical(id, 'ECO02_PIBPC')) {
      return(list(lambda = -0.239620859028258, fonte = 'PARAMETRO_DOCUMENTADO_ECO02'))
    }
    if (identical(id, 'INF02_RECURSOS_HIDRICOS_PC')) {
      fonte <- file.path(
        'so3.3', 'outputs', 'intermediario', 'estatistica',
        'avaliacao_yj', 'INF02_RECURSOS_HIDRICOS_PC',
        '20261101T172859', '01_resumo_yj.csv'
      )
      if (!file.exists(fonte)) {
        stop('INF02: falta relatorio aprovado com lambda integral: ', fonte,
             '\nRepor a saida da avaliacao de 20261101T172859 antes de executar.')
      }
      tab <- utils::read.csv(fonte, sep = ';', dec = '.',
                             stringsAsFactors = FALSE, check.names = FALSE)
      campos <- c('indicador', 'grupo', 'n_validos', 'lambda',
                  'triagem_original', 'triagem_yj',
                  'monotonicidade_preservada', 'ausencias_preservadas')
      if (!all(campos %in% names(tab)) || nrow(tab) != 1L ||
          !identical(tab$indicador[[1L]], id) ||
          !identical(tab$grupo[[1L]], 'Compartilhado') ||
          !identical(as.integer(tab$n_validos[[1L]]), 16600L) ||
          !identical(tab$triagem_original[[1L]], 'INVESTIGAR') ||
          !identical(tab$triagem_yj[[1L]], 'PASSA') ||
          !isTRUE(tab$monotonicidade_preservada[[1L]]) ||
          !isTRUE(tab$ausencias_preservadas[[1L]]) ||
          !is.finite(tab$lambda[[1L]]) ||
          abs(tab$lambda[[1L]] - 0.0177523) > 1e-4) {
        stop('INF02: contrato/parametro do resumo YJ inconsistente: ', fonte)
      }
      return(list(lambda = tab$lambda[[1L]], fonte = fonte,
                  md5_fonte = unname(tools::md5sum(fonte))))
    }
    NULL
  }
  for (id in selecionados) {
    meta <- catalogo[catalogo$indicador==id,,drop=FALSE]
    entradas <- lapply(estat_so33_anos(), function(ano) estat_so33_ler_bruto(id,ano))
    base <- do.call(rbind,lapply(entradas, `[[`, 'dados'))
    series <- estat_so33_series(base,meta$natureza)
    trilha <- list(); k <- 0L; saida <- base
    parametro_aprovado <- parametros_aprovados(id)
    for (g in names(series)) {
      d <- series[[g]]; x <- d$valor; m0 <- momentos(x)
      tratamento_documentado <- !is.null(parametro_aprovado)
      if (tratamento_documentado) {
        w <- list(x=x, regime='nenhum', frac=0, n_alterados=0L,
          status='NAO_APLICAR_DECISAO_DOCUMENTADA',
          comparacao=list(ok=NA, iqr_rel=NA_real_, med_delta=NA_real_,
            p95_delta=NA_real_, temporal_ok=NA, motivo=paste0(id, '_DECISAO_DOCUMENTADA')),
          candidato_rejeitado=NULL)
      } else w <- escolher_winsor(x,m0,d$ano)
      xw <- w$x; mw <- momentos(xw)
      lambda <- NA_real_; my <- mw; comp <- list(ok=NA, iqr_rel=NA_real_,
                           med_delta=NA_real_,p95_delta=NA_real_,temporal_ok=NA)
      decisao_yj <- 'MANTER_SEM_TRANSFORMACAO'; xf <- xw
      if (tratamento_documentado) {
        lambda <- parametro_aprovado$lambda
        candidato <- yeojohnson(x, lambda)
        validos <- which(!is.na(x))
        ux <- sort(unique(x[validos]))
        if (!identical(which(is.na(x)), which(is.na(candidato))) ||
            any(!is.finite(candidato[validos])) ||
            (length(ux)>1L && !all(diff(yeojohnson(ux,lambda))>0))) {
          stop(id, ': falha de integridade ou monotonicidade')
        }
        my <- momentos(candidato)
        comp <- comparar(x,candidato,d$ano)
        if (!identical(my$status,'PASSA')) stop(id, ': YJ nao passou na triagem')
        decisao_yj <- 'APLICAR_YJ_DECISAO_DOCUMENTADA'
        xf <- candidato
      } else if (identical(mw$status,'INVESTIGAR')) {
        lambda <- estimar_lambda(xw)
        if (!is.finite(lambda)) {
          decisao_yj <- 'REVISAR_YJ_PARAMETRO_INVALIDO'
        } else {
          candidato <- yeojohnson(xw,lambda)
          my <- momentos(candidato); comp <- comparar(xw,candidato,d$ano)
          if (eficacia(mw,my) && isTRUE(comp$ok)) {
            decisao_yj <- 'APLICAR_YJ'; xf <- candidato
          } else decisao_yj <- 'REVISAR_YJ_CRITERIOS'
        }
      } else if (mw$status != 'PASSA') decisao_yj <- 'REVISAR_YJ_TRIAGEM_INDETERMINADA'
      if (meta$natureza == 'territorial_compartilhado') {
        for (grupo in estat_so33_grupos()) {
          idx <- saida$grupo==grupo
          chave <- paste(saida$ano[idx],saida$cod_mun[idx])
          orig_chave <- paste(d$ano,d$cod_mun)
          pos <- match(chave,orig_chave)
          if (anyNA(pos)) stop('Chaves territoriais incompatíveis.')
          saida$valor[idx] <- xf[pos]
        }
      } else {
        idx <- saida$grupo==g; pos <- match(paste(saida$ano[idx],saida$cod_mun[idx]),
                                            paste(d$ano,d$cod_mun))
        if(anyNA(pos)) stop('Chaves populacionais incompatíveis.')
        saida$valor[idx] <- xf[pos]
      }
      # Mesmo quando o candidato e rejeitado, registrar o diagnostico
      # do candidato menos interventivo sem aplicar seus valores.
      wc <- if (is.null(w$candidato_rejeitado)) w else w$candidato_rejeitado
      cw <- wc$comparacao
      k<-k+1L
      trilha[[k]] <- data.frame(indicador=id, grupo_referencia=g,
        n_validos=sum(!is.na(x)), politica=if (tratamento_documentado) paste0(id, '_YJ_APROVADA') else 'REGRA_GERAL', triagem_original=m0$status,
        assimetria_original=m0$assimetria, curtose_original=m0$curtose_excesso,
        regime_winsor=w$regime, fracao_teto_testada=w$frac,
        n_modificados_winsor=w$n_alterados, decisao_winsor=w$status,
        regime_winsor_candidato=wc$regime,
        fracao_winsor_candidata=wc$frac,
        n_modificados_winsor_candidato=wc$n_alterados,
        winsor_preservacao_ok=cw$ok,
        winsor_delta_iqr_rel=cw$iqr_rel,
        winsor_med_delta_normalizado=cw$med_delta,
        winsor_p95_delta_normalizado=cw$p95_delta,
        winsor_temporal_ok=cw$temporal_ok,
        winsor_motivo_preservacao=cw$motivo,
        triagem_pos_winsor=mw$status,
        assimetria_pos_winsor=mw$assimetria, curtose_pos_winsor=mw$curtose_excesso,
        lambda_candidato=lambda, decisao_yj=decisao_yj,
        fonte_lambda=if (tratamento_documentado) parametro_aprovado$fonte else NA_character_,
        md5_fonte_lambda=if (tratamento_documentado && !is.null(parametro_aprovado$md5_fonte)) parametro_aprovado$md5_fonte else NA_character_,
        assimetria_yj_candidata=my$assimetria,
        curtose_yj_candidata=my$curtose_excesso,
        delta_iqr_rel=comp$iqr_rel, med_delta_normalizado=comp$med_delta,
        p95_delta_normalizado=comp$p95_delta,
        temporal_ok=comp$temporal_ok, stringsAsFactors=FALSE)
    }
    if (identical(id, 'INF02_RECURSOS_HIDRICOS_PC')) {
      campos_status <- c('status_calculo', 'situacao_qualidade',
                         'compatibilidade_territorial')
      if (!all(campos_status %in% names(base)) ||
          !identical(base[campos_status], saida[campos_status]) ||
          !identical(which(is.na(base$valor)), which(is.na(saida$valor))) ||
          !identical(base[c('ano','uf','cod_mun','nm_mun','indicador','grupo')],
                     saida[c('ano','uf','cod_mun','nm_mun','indicador','grupo')])) {
        stop('INF02: metadados, chaves ou posicoes NA alteradas')
      }
      # O mesmo valor territorial deve ser replicado em todos os grupos.
      estat_so33_series(saida, meta$natureza)
    }
    pasta <- file.path(destino_raiz,id); dir.create(pasta,recursive=TRUE)
    rel <- do.call(rbind,trilha); gravar(rel,file.path(pasta,'01_decisoes.csv'))
    inventario <- do.call(rbind,lapply(entradas, `[[`, 'inventario'))
    gravar(inventario,file.path(pasta,'02_fontes_md5.csv'))
    for (ano in estat_so33_anos()) {
      # Saida de trabalho, nao substitui nem sobrescreve bruto ou tratado oficial.
      gravar(saida[saida$ano==ano,,drop=FALSE], file.path(pasta,paste0(id,'_',ano,'_candidato.csv')))
    }
    resumo[[id]] <- rel
    message('SO3.3 | ',id,' | ',pasta)
    print(rel[,c('grupo_referencia','triagem_original','decisao_winsor',
                 'n_modificados_winsor','winsor_preservacao_ok','decisao_yj','lambda_candidato')], row.names=FALSE)
  }
  writeLines(c('PRAIS4 SO3.3 - avaliacao automatica candidata B/C.',
    'NAO sao produtos finais normalizados nem aprovacao cientifica de cada serie.',
    'Brutos imutaveis. Resultados candidatos gravados apenas em outputs/intermediario.',
    'Triagem COINr ja validada no Bloco A; momentos recalculados so apos alteracoes.',
    'Winsorizacao somente aplicada quando passa COINr E preservacao territorial/temporal.',
    'Candidatos reprovados: diagnostico registrado; valores originais mantidos.',
    'ECO02 e INF02: YJ aprovada sem winsorizacao; diagnosticos de distancia informativos.',
    'INF02: lambda integral e MD5 vinculados ao 01_resumo_yj.csv da avaliacao aprovada.',
    'Politica automatica e limiares de eficacia/preservacao sao escolhas operacionais PRAIS-BRASIL.',
    paste('Data UTC:',format(Sys.time(),tz='UTC',usetz=TRUE)),
    paste('R:',R.version.string)),file.path(destino_raiz,'LEIA_ME.txt'))
  writeLines(capture.output(utils::sessionInfo()),file.path(destino_raiz,'sessao_R.txt'))
  message('Concluido. Saidas: ',normalizePath(destino_raiz))
  invisible(resumo)
}
if (sys.nframe() == 0L) so33_tratamento()
