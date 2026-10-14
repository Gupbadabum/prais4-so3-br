# ============================================================
# PRAIS4 / SO3.3 / SOC03_EV0
# Preparacao reproduzivel da West estendida (UN DESA 2011/2026)
# e calibracao estadual usando as tabuas oficiais do IBGE.
#
# Usa apenas as referencias XLSX; nao le microdados censitarios.
# Produtos derivados ficam em outputs/intermediario/social/referencias.
# ============================================================

if (!requireNamespace("data.table", quietly = TRUE)) {
  stop("O pacote data.table e necessario.")
}

.dir_referencias_soc03 <- function() {
  file.path(DIR_OUTPUT_INTERMEDIARIO, "social", "referencias")
}

.normalizar_uf_soc03 <- function(uf) {
  mapa <- c(
    RO="11", AC="12", AM="13", RR="14", PA="15", AP="16", TO="17",
    MA="21", PI="22", CE="23", RN="24", PB="25", PE="26", AL="27",
    SE="28", BA="29", MG="31", ES="32", RJ="33", SP="35",
    PR="41", SC="42", RS="43", MS="50", MT="51", GO="52", DF="53"
  )
  u <- toupper(trimws(as.character(uf)))
  u <- ifelse(u %in% names(mapa), unname(mapa[u]), u)
  u[grepl("^[0-9]$", u)] <- paste0("0", u[grepl("^[0-9]$", u)])
  u
}

preparar_west_estendida <- function(
    caminho = ARQ_UNDESA_WEST_COMPLETA,
    dir_saida = .dir_referencias_soc03(),
    forcar = FALSE
) {
  arq_q5 <- file.path(dir_saida, "west_q5_e0.csv")
  arq_lx <- file.path(dir_saida, "west_lx.csv")
  arq_origem <- file.path(dir_saida, "proveniencia_west.csv")

  if (!file.exists(caminho)) {
    stop("Tabua West estendida nao localizada: ", caminho)
  }
  if (!isTRUE(forcar) && all(file.exists(c(arq_q5, arq_lx, arq_origem))) &&
      all(file.info(c(arq_q5, arq_lx, arq_origem))$mtime >=
            file.info(caminho)$mtime)) {
    message("West estendida: derivados existentes e mais recentes que a fonte.")
    return(invisible(list(q5=arq_q5, lx=arq_lx, origem=arq_origem)))
  }
  if (!requireNamespace("readxl", quietly = TRUE)) {
    stop("Instale o pacote readxl para ler a referencia XLSX.")
  }

  # O layout original possui 15 colunas; ler somente as 9 usadas.
  tipos <- c(
    "text", "text", "skip", "text", "numeric", "numeric",
    "skip", "skip", "numeric", "skip", "numeric", "numeric",
    "skip", "numeric", "skip"
  )
  d <- data.table::as.data.table(
    readxl::read_excel(caminho, sheet=1, col_types=tipos,
                       .name_repair="minimal")
  )
  colunas <- c("Type_MLT","Family","Sex","E0","age","lx1","Lx1","Tx1","ex1")
  if (!all(colunas %in% names(d))) {
    stop("Layout UN DESA inesperado. Campos encontrados: ",
         paste(names(d), collapse=", "))
  }
  d <- d[Type_MLT == "CD" & Family == "West"]
  if (!nrow(d)) stop("Familia CD West nao encontrada no XLSX.")
  data.table::setnames(d,
    old=c("Sex","E0","lx1","Lx1","Tx1","ex1"),
    new=c("sex","e0","lx","Lx","Tx","ex"))
  d[, `:=`(e0=as.integer(e0), age=as.integer(age))]
  if (!setequal(unique(d$sex), c("Male", "Female")) ||
      anyNA(d[, .(sex,e0,age,lx,Lx,Tx,ex)]) ||
      anyDuplicated(d[, .(sex,e0,age)]) > 0L ||
      data.table::uniqueN(d[, .(sex,e0)]) != 162L ||
      nrow(d) != 162L * 131L) {
    stop("Cobertura ou unicidade da West estendida invalida.")
  }
  cobertura <- d[, .(
    n_idades=.N,
    idade_min=min(age),
    idade_max=max(age),
    e0_orig=ex[age == 0L][1L],
    e0_tx=Tx[age == 0L][1L] / lx[age == 0L][1L]
  ), by=.(sex,e0)]
  if (any(cobertura$n_idades != 131L |
          cobertura$idade_min != 0L | cobertura$idade_max != 130L) ||
      any(abs(cobertura$e0_orig-cobertura$e0)>1e-4) ||
      any(abs(cobertura$e0_tx-cobertura$e0)>1e-4)) {
    stop("Incoerencia na cobertura etaria ou expectativa de vida da West.")
  }

  a0 <- d[age == 0L, .(sex,e0,l0=lx)]
  a5 <- d[age == 5L, .(sex,e0,l5=lx)]
  grade <- merge(a0,a5,by=c("sex","e0"))
  grade[, q5 := 1 - l5/l0]
  data.table::setorder(grade, sex,e0)
  mono <- grade[, .(
    monotono=all(diff(q5)<0),
    e0_min=min(e0), e0_max=max(e0), n_niveis=.N
  ),by=sex]
  if (any(!mono$monotono | mono$e0_min != 20L |
          mono$e0_max != 100L | mono$n_niveis != 81L) ||
      any(!is.finite(grade$q5) | grade$q5 <= 0 | grade$q5 >= 1)) {
    stop("A curva West nao apresentou dominio e monotonicidade esperados.")
  }

  dir.create(dir_saida, recursive=TRUE, showWarnings=FALSE)
  data.table::fwrite(grade[, .(sex,e0,q5)], arq_q5)
  data.table::setorder(d, sex,e0,age)
  data.table::fwrite(d[, .(sex,e0,age,lx,Lx,Tx,ex)], arq_lx)
  data.table::fwrite(
    data.table::data.table(
      origem=as.character(caminho), md5=unname(tools::md5sum(caminho)),
      familia="CD West", n_tabuas=162L, n_idades=131L,
      derivacao_q5="1-lx(5)/lx(0)"
    ), arq_origem
  )
  message("West preparada: 81 niveis por sexo, idades 0-130.")
  message("q5: ", arq_q5)
  message("lx: ", arq_lx)
  invisible(list(q5=arq_q5, lx=arq_lx, origem=arq_origem))
}

preparar_delta_west_ibge <- function(
    caminho_ibge = ARQ_TABUAS_MORTALIDADE_IBGE,
    dir_saida = .dir_referencias_soc03(),
    forcar = FALSE
) {
  arq_delta <- file.path(dir_saida, "calibracao_delta_ibge.csv")
  arq_west <- file.path(dir_saida, "west_q5_e0.csv")
  if (!file.exists(arq_west)) {
    stop("Prepare primeiro a West: preparar_west_estendida().")
  }
  if (!file.exists(caminho_ibge)) {
    stop("Tabua IBGE nao encontrada: ", caminho_ibge)
  }
  if (!isTRUE(forcar) && file.exists(arq_delta) &&
      file.info(arq_delta)$mtime >= file.info(caminho_ibge)$mtime &&
      file.info(arq_delta)$mtime >= file.info(arq_west)$mtime) {
    message("Calibracao IBGE: derivado existente e atualizado.")
    return(invisible(arq_delta))
  }
  if (!requireNamespace("readxl", quietly = TRUE)) {
    stop("Instale o pacote readxl para ler a referencia IBGE.")
  }

  # A tabela IBGE Revisao 2024 utilizada no projeto tem cabecalho
  # apos cinco linhas iniciais, conforme a rotina de validacao original.
  ib <- data.table::as.data.table(readxl::read_excel(
    caminho_ibge, skip=5, .name_repair="minimal"
  ))
  nomes <- names(ib)
  # Converter para maiusculas ANTES de remover caracteres especiais.
  # Caso contrario, os nomes originais "lx" e "ex" seriam apagados.
  padronizados <- gsub(
    "[^A-Z0-9]", "",
    toupper(iconv(nomes, to = "ASCII//TRANSLIT"))
  )
  requisitados <- c("SIGLA","ANO","SEXO","IDADE","LX","EX")
  if (!all(requisitados %in% padronizados)) {
    stop(
      "Colunas esperadas do IBGE nao encontradas apos skip=5. ",
      "Esperadas: ", paste(requisitados,collapse=", "),
      ". Encontradas: ", paste(nomes,collapse=", "),
      ". Nao foi gerada calibracao."
    )
  }
  data.table::setnames(ib, nomes[match(requisitados,padronizados)],
                       c("uf","ano","sexo","idade","lx","e0_ibge"))
  ib[, `:=`(
    uf=.normalizar_uf_soc03(uf),
    ano=as.integer(ano),
    idade=as.integer(idade),
    sexo=toupper(trimws(as.character(sexo))),
    lx=as.numeric(lx),
    e0_ibge=as.numeric(e0_ibge)
  )]
  ib[, sex := data.table::fcase(
    sexo %in% c("HOMENS","HOMEM","MASCULINO","MALE"), "Male",
    sexo %in% c("MULHERES","MULHER","FEMININO","FEMALE"), "Female",
    default=NA_character_
  )]
  ufs <- c("11","12","13","14","15","16","17","21","22","23",
           "24","25","26","27","28","29","31","32","33","35",
           "41","42","43","50","51","52","53")
  ib <- ib[
    uf %in% ufs & ano %in% c(2000L,2010L,2022L) &
      sex %in% c("Male","Female") & idade %in% c(0L,5L)
  ]
  if (!nrow(ib)) stop("Nenhuma observacao IBGE UF/ano/sexo/idade aproveitavel.")
  if (anyDuplicated(ib[, .(uf,ano,sex,idade)]) > 0L) {
    stop("Duplicidade no IBGE para UF/ano/sexo/idade.")
  }
  nasc <- ib[idade == 0L, .(uf,ano,sex,l0=lx,e0_ibge)]
  cinco <- ib[idade == 5L, .(uf,ano,sex,l5=lx)]
  estados <- merge(nasc,cinco,by=c("uf","ano","sex"))
  estados[,q5_ibge := 1-l5/l0]
  if (data.table::uniqueN(estados[, .(uf,ano,sex)]) != 27L*3L*2L ||
      anyNA(estados[, .(q5_ibge,e0_ibge)]) ||
      any(!is.finite(estados$q5_ibge) | estados$q5_ibge<=0 |
          estados$q5_ibge>=1)) {
    stop("Cobertura 27 UFs x 3 anos x 2 sexos ou q5 IBGE invalido. ",
         "Encontradas ", nrow(estados), " linhas.")
  }

  ref <- data.table::fread(arq_west)
  # A interpolacao abaixo usa o mesmo dominio e escala que o conversor:
  # log q5 (e nao a escala linear de probabilidade).
  interp <- function(q5, sex) {
    tab <- ref[ref$sex == sex & is.finite(ref$q5) & ref$q5>0]
    tab <- tab[order(tab$q5)]
    if (!length(q5)) return(numeric())
    stats::approx(log(tab$q5),tab$e0,xout=log(q5),rule=1)$y
  }
  estados[,e0_west:=NA_real_]
  for (sx in c("Male","Female")) {
    idx <- which(estados$sex == sx)
    estados$e0_west[idx] <- interp(estados$q5_ibge[idx], sx)
  }
  if (anyNA(estados$e0_west)) {
    stop("q5 IBGE fora do dominio West estendida: ",
         sum(is.na(estados$e0_west)), " pares UF/ano/sexo.")
  }
  estados[, delta := e0_ibge - e0_west]
  delta <- data.table::dcast(
    estados[, .(uf,ano,sex,delta)],
    uf+ano ~ sex, value.var="delta"
  )
  data.table::setnames(delta, c("Male","Female"), c("delta_M","delta_F"))
  data.table::setorder(delta, ano,uf)
  dir.create(dir_saida,recursive=TRUE,showWarnings=FALSE)
  data.table::fwrite(delta,arq_delta)
  message("Calibracao estadual preparada: ",nrow(delta),
          " combinacoes UF/ano, sexos Masculino e Feminino.")
  message("Calibracao: ",arq_delta)
  invisible(arq_delta)
}

preparar_referencias_soc03 <- function(forcar=FALSE) {
  west <- preparar_west_estendida(forcar=forcar)
  delta <- preparar_delta_west_ibge(forcar=forcar)
  invisible(list(west=west, delta=delta))
}
