# ============================================================
# PRAIS4 / SO3.3 / SOC03_EV0
# Conversao do q5 municipal EB em e0 por sexo e Total.
#
# Base conceitual: proposta tecnica converter_q5_para_e0.R
# (avaliada e adaptada; extrapolacao fora do dominio e proibida).
# Nao altera Brass-Trussell, EB nem outros indicadores.
# ============================================================

if (!requireNamespace("data.table", quietly=TRUE)) {
  stop("Pacote data.table necessario.")
}

interpolar_west_soc03 <- function(q, sexo, grade) {
  tab <- grade[sex == sexo & is.finite(q5) & q5>0]
  data.table::setorder(tab, q5)
  valido <- is.finite(q) & q>0
  saida <- rep(NA_real_,length(q))
  dentro <- valido & q>=min(tab$q5) & q<=max(tab$q5)
  if (any(dentro)) {
    saida[dentro] <- stats::approx(
      x=log(tab$q5),y=tab$e0,xout=log(q[dentro]),rule=1
    )$y
  }
  flag <- rep("q5_ausente_ou_invalido",length(q))
  flag[valido & q<min(tab$q5)] <- "abaixo_do_dominio"
  flag[valido & q>max(tab$q5)] <- "acima_do_dominio"
  flag[dentro] <- "ok"
  list(e0=saida,flag=flag)
}

converter_soc03_ev0 <- function(
    q5_eb,
    dir_referencias=file.path(DIR_OUTPUT_INTERMEDIARIO,"social","referencias"),
    usar_calibracao=TRUE,
    p_M=105/205
) {
  obrigatorias <- c("ano","uf","cod_mun","grupo",
                    "q5_estabilizado","q5_ic_inf","q5_ic_sup",
                    "q5_uf_trussell","ano_referencia_q5")
  faltam <- setdiff(obrigatorias,names(q5_eb))
  if(length(faltam)) stop("Colunas ausentes no EB: ",paste(faltam,collapse=", "))
  d <- data.table::as.data.table(data.table::copy(q5_eb))
  if(anyDuplicated(d[, .(ano,cod_mun,grupo)]) > 0L ||
     !setequal(unique(d$grupo),c("Total","Masculino","Feminino"))) {
    stop("EB com chaves repetidas ou grupos inesperados.")
  }
  d[, uf := .normalizar_uf_soc03(uf)]
  d[, cod_mun := sprintf("%07d",as.integer(cod_mun))]

  w <- data.table::fread(file.path(dir_referencias,"west_q5_e0.csv"))
  if(!all(c("sex","e0","q5") %in% names(w))) stop("West sem colunas requeridas.")
  for(sx in c("Male","Female")) {
    t <- w[sex==sx][order(e0)]
    if(nrow(t)!=81L || !identical(as.integer(t$e0),20:100) ||
       any(!is.finite(t$q5) | t$q5<=0) ||
       !all(diff(t$q5)<0)) {
      stop("West invalida para ",sx)
    }
  }
  total <- d[grupo=="Total", .(ano,uf,cod_mun,
        q5_T=q5_estabilizado,q5_T_l=q5_ic_inf,
        q5_T_u=q5_ic_sup,ano_ref_T=ano_referencia_q5,
        q5_T_uf=q5_uf_trussell)]
  m <- d[grupo=="Masculino",.(ano,cod_mun,q5_M_uf=q5_uf_trussell)]
  f <- d[grupo=="Feminino",.(ano,cod_mun,q5_F_uf=q5_uf_trussell)]
  x <- merge(total,m,by=c("ano","cod_mun"),all.x=TRUE,sort=FALSE)
  x <- merge(x,f,by=c("ano","cod_mun"),all.x=TRUE,sort=FALSE)
  if(nrow(x)!=nrow(total) ||
     anyNA(x[, .(q5_T_uf,q5_M_uf,q5_F_uf)])) {
    stop("Decomposicao M/F: cobertura municipal ou ancoras ausentes.")
  }

  rho_M <- x$q5_M_uf/x$q5_T_uf
  rho_F <- x$q5_F_uf/x$q5_T_uf
  den <- p_M*rho_M + (1-p_M)*rho_F
  if(any(!is.finite(den) | den<=0)) {
    stop("Diferenciais estaduais invalidos na decomposicao.")
  }
  x[, `:=`(rho_M=rho_M,rho_F=rho_F)]
  coef_M <- rho_M/den
  coef_F <- rho_F/den
  for(suf in c("","_l","_u")) {
    x[[paste0("q5_M",suf)]] <- x[[paste0("q5_T",suf)]]*coef_M
    x[[paste0("q5_F",suf)]] <- x[[paste0("q5_T",suf)]]*coef_F
  }
  erro <- abs(p_M*x$q5_M+(1-p_M)*x$q5_F-x$q5_T)
  if(any(is.finite(erro) & erro>1e-12)) {
    stop("Coerencia q5 Total/M/F nao satisfeita.")
  }
  for(sx in c("M","F")) {
    sexo_west <- if(sx=="M") "Male" else "Female"
    base <- interpolar_west_soc03(x[[paste0("q5_",sx)]],sexo_west,w)
    # Como e0 diminui quando q5 aumenta, inverter os ICs.
    inf <- interpolar_west_soc03(x[[paste0("q5_",sx,"_u")]],sexo_west,w)
    sup <- interpolar_west_soc03(x[[paste0("q5_",sx,"_l")]],sexo_west,w)
    x[[paste0("e0_west_",sx)]] <- base$e0
    x[[paste0("flag_dominio_",sx)]] <- base$flag
    x[[paste0("e0_west_",sx,"_l")]] <- inf$e0
    x[[paste0("e0_west_",sx,"_u")]] <- sup$e0
  }

  x[, `:=`(delta_M=0.0,delta_F=0.0,
             flag_calibracao_nacional_M=FALSE,
             flag_calibracao_nacional_F=FALSE)]
  if(isTRUE(usar_calibracao)) {
    delta <- data.table::fread(
      file.path(dir_referencias,"calibracao_delta_ibge.csv"),
      colClasses=list(character="uf")
    )
    if(!all(c("uf","ano","delta_M","delta_F") %in% names(delta))) {
      stop("Calibracao IBGE sem estrutura requerida.")
    }
    delta[,uf:=.normalizar_uf_soc03(uf)]
    if(anyDuplicated(delta[, .(uf,ano)])>0L) stop("Calibracao duplicada.")
    idx <- match(paste(x$uf,x$ano,sep=":"),
                 paste(delta$uf,delta$ano,sep=":"))
    if(anyNA(idx)) {
      stop("Calibracao estadual ausente para ",sum(is.na(idx)),
           " municipios. Revise chaves UF/ano; fallback nao automatico.")
    }
    if(anyNA(delta[idx, .(delta_M,delta_F)])) {
      stop("Calibracao incompleta em UF/ano.")
    }
    x[, `:=`(delta_M=delta$delta_M[idx],delta_F=delta$delta_F[idx])]
  }
  for(sx in c("M","F")) {
    for(suf in c("","_l","_u")) {
      x[[paste0("e0_",sx,suf)]] <-
        x[[paste0("e0_west_",sx,suf)]]+x[[paste0("delta_",sx)]]
    }
  }
  for(suf in c("","_l","_u")) {
    x[[paste0("e0_T",suf)]] <-
      p_M*x[[paste0("e0_M",suf)]]+(1-p_M)*x[[paste0("e0_F",suf)]]
  }
  x[, `:=`(ic90_amplitude_T=e0_T_u-e0_T_l,
             p_M_usado=p_M,calibracao_aplicada=isTRUE(usar_calibracao))]
  controle <- x[
    is.finite(e0_T_l) & is.finite(e0_T_u) & is.finite(e0_T),
    .(ruim=any(e0_T_l>e0_T+1e-10 |
                e0_T>e0_T_u+1e-10 |
                ic90_amplitude_T < -1e-10))
  ]
  if(nrow(controle) && controle$ruim) {
    stop("Intervalos de e0 fora da ordem esperada.")
  }
  x[]
}

produzir_soc03_ev0 <- function(
    ano,
    dir_intermediario=DIR_OUTPUT_INTERMEDIARIO,
    dir_bruto=DIR_OUTPUT_BRUTO,
    forcar=FALSE
) {
  stopifnot(length(ano)==1L, ano %in% c(2000L,2010L,2022L))
  dir_i <- file.path(dir_intermediario,"social",as.character(ano))
  dir_b <- file.path(dir_bruto,"social",as.character(ano))
  entrada <- file.path(dir_i,paste0("q5_eb_",ano,"_normalizada_amostra.rds"))
  intermediario <- file.path(dir_i,paste0("soc03_ev0_auditoria_",ano,".rds"))
  saida <- file.path(dir_b,paste0("SOC03_EV0_",ano,".rds"))

  if(!file.exists(entrada)) {
    stop("Checkpoint EB nao encontrado: ", entrada,
         "\nExecute apenas etapas Brass-Trussell/EB usando os insumos_ev0 existentes.")
  }
  if(file.exists(saida) && !isTRUE(forcar)) {
    message("Produto SOC03 existente; nao sobrescrevendo: ",saida)
    return(invisible(readRDS(saida)))
  }
  q5 <- readRDS(entrada)
  dados <- converter_soc03_ev0(q5)
  resultado <- data.table::rbindlist(lapply(
    c("Total","Masculino","Feminino"),
    function(g) {
      s <- switch(g,Total="T",Masculino="M",Feminino="F")
      data.table::data.table(
        ano=dados$ano,uf=dados$uf,cod_mun=dados$cod_mun,
        dimensao="Social",indicador="SOC03_EV0",grupo=g,
        valor=dados[[paste0("e0_",s)]],
        e0_ic_inf=dados[[paste0("e0_",s,"_l")]],
        e0_ic_sup=dados[[paste0("e0_",s,"_u")]],
        ano_referencia_q5=dados$ano_ref_T,
        flag_dominio=if(s=="T") {
          ifelse(dados$flag_dominio_M=="ok" &
                 dados$flag_dominio_F=="ok","ok","sexo_fora_dominio")
        } else dados[[paste0("flag_dominio_",s)]]
      )
    }
  ),use.names=TRUE)
  data.table::setorder(resultado,indicador,cod_mun,grupo)
  dir.create(dir_i,recursive=TRUE,showWarnings=FALSE)
  dir.create(dir_b,recursive=TRUE,showWarnings=FALSE)
  saveRDS(dados,intermediario)
  saveRDS(resultado,saida)
  message("SOC03 produzido: ",saida)
  message("Auditoria: ",intermediario)
  message("Ausencias e0: ",sum(is.na(resultado$valor)),
          "; municipios: ",data.table::uniqueN(resultado$cod_mun))
  invisible(resultado)
}
