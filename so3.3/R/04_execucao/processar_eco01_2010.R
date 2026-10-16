# ============================================================
# PRAIS4 / SO3.3 / ECO01 - EXECUCAO ISOLADA DO CENSO 2010
#
# Requer config.R e tres arquivos:
#   R/02_indicadores/preparar_referencias_eco01.R (ja existente)
#   R/01_leitura/adaptar_censo_2010_economica.R
#   R/02_indicadores/eco01_pobreza.R
#
# Exemplo de teste de uma UF, a partir da raiz do repositorio:
#   source("so3.3/config/config.R")
#   source("so3.3/R/02_indicadores/preparar_referencias_eco01.R")
#   source("so3.3/R/01_leitura/adaptar_censo_2010_economica.R")
#   source("so3.3/R/02_indicadores/eco01_pobreza.R")
#   source("so3.3/R/04_execucao/processar_eco01_2010.R")
#   resultado_teste <- processar_eco01_2010(ufs = 11L)
#
# ufs=NULL: processa as 27 UFs e salva os RDS nacionais.
# ufs=11L: teste de RO; salva apenas checkpoints da UF.
# Nenhuma execucao altera main.R ou produtos da Social.
# ============================================================

if (!requireNamespace("data.table", quietly = TRUE)) {
  stop("O pacote data.table e necessario.")
}

.diretorios_eco01_2010 <- function() {
  dir_bruto <- file.path(DIR_OUTPUT_BRUTO, "economica", "2010")
  dir_inter <- file.path(DIR_OUTPUT_INTERMEDIARIO, "economica", "2010")
  dir_partes <- file.path(dir_inter, "partes_censo_2010")
  for (dir in c(dir_bruto, dir_inter, dir_partes)) {
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  }
  list(bruto = dir_bruto, intermediario = dir_inter, partes = dir_partes)
}

.verificar_checkpoint_eco01 <- function(bruto, auditoria, limiar, md5, uf) {
  validar_resultados_eco01(bruto, auditoria, ano = 2010L)
  if (length(unique(auditoria$uf)) != 1L ||
      unique(auditoria$uf) != sprintf("%02d", uf) ||
      any(abs(auditoria$linha_pobreza_mes - limiar) > 1e-8) ||
      any(auditoria$md5_fonte_ipca != md5)) {
    stop("ECO01: checkpoint da UF ", sprintf("%02d", uf),
         " difere da fonte ou do limiar atual. ",
         "Recalcule essa UF explicitamente.")
  }
  invisible(TRUE)
}

processar_eco01_2010 <- function(ufs = NULL,
                                 showProgress = TRUE,
                                 forcar_recalculo = FALSE) {
  dependencias <- c("preparar_referencias_eco01",
                   "abrir_censo_2010_economica",
                   "listar_ufs_censo_2010_economica",
                   "coletar_uf_censo_2010_economica",
                   "adaptar_censo_2010_economica_uf",
                   "calcular_eco01_pobreza",
                   "validar_resultados_eco01")
  faltantes <- dependencias[!vapply(
    dependencias, exists, logical(1L), mode = "function", inherits = TRUE
  )]
  if (length(faltantes)) {
    stop("ECO01: carregue antes os modulos necessarios: ",
         paste(faltantes, collapse = ", "))
  }

  parametros <- preparar_referencias_eco01(salvar = TRUE)
  ref <- parametros[ano_censo == 2010L]
  if (nrow(ref) != 1L) stop("ECO01: referencia monetaria 2010 ausente.")
  limiar <- ref$linha_reais_mes_censo[[1L]]
  md5 <- ref$md5_fonte[[1L]]
  message(sprintf("ECO01 2010 | Limiar em julho/2010: R$ %.6f", limiar))

  dirs <- .diretorios_eco01_2010()
  message("ECO01 2010 | Abrindo censobr como Arrow Dataset...")
  censo_arrow <- abrir_censo_2010_economica(showProgress = showProgress)
  ufs_disponiveis <- listar_ufs_censo_2010_economica(censo_arrow)

  if (is.null(ufs)) {
    ufs_execucao <- ufs_disponiveis
  } else {
    if (!is.numeric(ufs) || !length(ufs) || anyNA(ufs) ||
        any(ufs != floor(ufs)) || anyDuplicated(ufs) ||
        !all(ufs %in% ufs_disponiveis)) {
      stop("ECO01: vetor ufs invalido ou com UFs nao disponiveis.")
    }
    ufs_execucao <- sort(as.integer(ufs))
  }
  integral <- setequal(ufs_execucao, ufs_disponiveis)

  brutos <- vector("list", length(ufs_execucao))
  auditorias <- vector("list", length(ufs_execucao))
  for (i in seq_along(ufs_execucao)) {
    uf <- ufs_execucao[[i]]
    uf_chr <- sprintf("%02d", uf)
    arq_bruto <- file.path(
      dirs$partes, paste0("ECO01_POV3_PPC21_2010_UF", uf_chr, ".rds")
    )
    arq_audit <- file.path(
      dirs$partes, paste0("auditoria_eco01_2010_UF", uf_chr, ".rds")
    )
    pronto <- !isTRUE(forcar_recalculo) &&
      file.exists(arq_bruto) && file.exists(arq_audit)

    if (pronto) {
      message(sprintf("[%02d/%02d] ECO01 2010 | UF %s: checkpoint",
                      i, length(ufs_execucao), uf_chr))
      resultado <- list(
        bruto = readRDS(arq_bruto),
        auditoria = readRDS(arq_audit)
      )
      .verificar_checkpoint_eco01(
        resultado$bruto, resultado$auditoria, limiar, md5, uf
      )
    } else {
      message(sprintf("[%02d/%02d] ECO01 2010 | UF %s: processamento",
                      i, length(ufs_execucao), uf_chr))
      d <- coletar_uf_censo_2010_economica(censo_arrow, uf)
      d <- adaptar_censo_2010_economica_uf(d)
      resultado <- calcular_eco01_pobreza(d, limiar, md5)
      .verificar_checkpoint_eco01(
        resultado$bruto, resultado$auditoria, limiar, md5, uf
      )
      saveRDS(resultado$bruto, arq_bruto)
      saveRDS(resultado$auditoria, arq_audit)
      rm(d)
      invisible(gc())
    }
    brutos[[i]] <- resultado$bruto
    auditorias[[i]] <- resultado$auditoria
    rm(resultado)
  }

  bruto <- data.table::rbindlist(brutos, use.names = TRUE)
  auditoria <- data.table::rbindlist(auditorias, use.names = TRUE)
  data.table::setorder(bruto, ano, cod_mun, grupo)
  data.table::setorder(auditoria, ano, cod_mun, grupo)
  validar_resultados_eco01(
    bruto, auditoria,
    ano = 2010L,
    municipios_esperados = if (integral) 5565L else NULL
  )

  if (integral) {
    arq_final <- file.path(dirs$bruto, "ECO01_POV3_PPC21_2010.rds")
    arq_audit <- file.path(dirs$intermediario, "auditoria_eco01_2010.rds")
    saveRDS(bruto, arq_final)
    saveRDS(auditoria, arq_audit)
    message("ECO01 2010 | Brasil concluido: 5.565 municipios e 16.695 linhas.")
    message("Resultado: ", arq_final)
    message("Auditoria: ", arq_audit)
  } else {
    message("ECO01 2010 | Teste parcial: somente checkpoints por UF; ",
            "nenhum arquivo nacional foi gravado.")
  }
  invisible(list(
    bruto = bruto,
    auditoria = auditoria,
    limiar_reais_mes = limiar,
    ufs = ufs_execucao,
    integral = integral
  ))
}
