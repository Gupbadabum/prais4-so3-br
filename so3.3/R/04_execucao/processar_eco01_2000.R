# ============================================================
# PRAIS4 / SO3.3 / ECO01 - EXECUCAO ISOLADA DO CENSO 2000
#
# A partir da raiz do repositorio:
#   source("so3.3/config/config.R")
#   source("so3.3/R/02_indicadores/preparar_referencias_eco01.R")
#   source("so3.3/R/01_leitura/adaptar_censo_2000_economica.R")
#   source("so3.3/R/02_indicadores/eco01_pobreza.R")
#   source("so3.3/R/04_execucao/processar_eco01_2000.R")
#
# Teste: processar_eco01_2000(ufs = 11L)
# Brasil: processar_eco01_2000()
#
# Uma UF por vez em memoria; checkpoints somente agregados.
# Testes parciais nao criam resultado nacional.
# ============================================================

if (!requireNamespace("data.table", quietly = TRUE)) {
  stop("ECO01 2000: o pacote data.table e necessario.")
}

.diretorios_eco01_2000 <- function() {
  bruto <- file.path(DIR_OUTPUT_BRUTO, "economica", "2000")
  inter <- file.path(DIR_OUTPUT_INTERMEDIARIO, "economica", "2000")
  partes <- file.path(inter, "partes_censo_2000")
  for (dir in c(bruto, inter, partes)) {
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  }
  list(bruto = bruto, intermediario = inter, partes = partes)
}

# Impede reutilizar partes calculadas com uma versao diferente
# do adaptador, da regra comum de pobreza ou do executor.
.assinatura_codigo_eco01_2000 <- function() {
  arquivos <- file.path(DIR_R, c(
    "01_leitura/adaptar_censo_2000_economica.R",
    "02_indicadores/eco01_pobreza.R",
    "04_execucao/processar_eco01_2000.R"
  ))
  if (!all(file.exists(arquivos))) {
    stop("ECO01 2000: arquivos de codigo indisponiveis ",
         "para verificar os checkpoints.")
  }
  list(
    arquivos = basename(arquivos),
    md5_codigo = unname(as.character(tools::md5sum(arquivos))),
    versao_censobr = as.character(utils::packageVersion("censobr"))
  )
}

.validar_parte_eco01_2000 <- function(
  bruto, auditoria, auditoria_construcao, uf, limiar, md5
) {
  validar_resultados_eco01(bruto, auditoria, ano = 2000L)
  uf_chr <- sprintf("%02d", as.integer(uf))
  diag <- data.table::as.data.table(auditoria_construcao)

  campos_diag <- c(
    "ano", "uf", "cod_mun", "n_domicilios",
    "n_particulares", "n_coletivos",
    "n_particulares_ajustados", "n_moradores_descontados",
    "n_renda_ausente_domicilios", "n_renda_zero_domicilios",
    "n_pessoas_registradas"
  )
  if (length(setdiff(campos_diag, names(diag)))) {
    stop("ECO01 2000: auditoria do denominador incompleta.")
  }
  if (data.table::uniqueN(bruto$uf) != 1L ||
      data.table::uniqueN(auditoria$uf) != 1L ||
      !identical(unique(bruto$uf), uf_chr) ||
      !identical(unique(auditoria$uf), uf_chr) ||
      any(!is.finite(auditoria$linha_pobreza_mes)) ||
      any(abs(auditoria$linha_pobreza_mes - limiar) > 1e-8) ||
      any(auditoria$md5_fonte_ipca != md5) ||
      nrow(diag) != data.table::uniqueN(bruto$cod_mun) ||
      anyNA(diag[, .(ano, uf, cod_mun)]) ||
      any(diag$ano != 2000L) || any(diag$uf != uf_chr) ||
      anyDuplicated(diag, by = "cod_mun") ||
      !setequal(diag$cod_mun, unique(bruto$cod_mun)) ||
      any(diag$n_domicilios !=
          diag$n_particulares + diag$n_coletivos) ||
      any(diag$n_particulares_ajustados > diag$n_particulares) ||
      any(diag$n_renda_ausente_domicilios < diag$n_coletivos) ||
      any(diag$n_renda_zero_domicilios > diag$n_particulares) ||
      any(diag$n_moradores_descontados < 0)) {
    stop("ECO01 2000: checkpoint da UF ", uf_chr,
         " inconsistente com a RDPC ou a referencia monetaria.")
  }
  invisible(TRUE)
}

processar_eco01_2000 <- function(
  ufs = NULL, showProgress = TRUE, forcar_recalculo = FALSE
) {
  dependencias <- c(
    "preparar_referencias_eco01",
    "abrir_censo_2000_economica",
    "listar_ufs_censo_2000_economica",
    "coletar_uf_censo_2000_economica",
    "adaptar_censo_2000_economica_uf",
    "calcular_eco01_pobreza",
    "validar_resultados_eco01"
  )
  faltantes <- dependencias[!vapply(
    dependencias, exists, logical(1L),
    mode = "function", inherits = TRUE
  )]
  if (length(faltantes)) {
    stop("ECO01 2000: carregue antes os modulos necessarios: ",
         paste(faltantes, collapse = ", "))
  }

  referencias <- preparar_referencias_eco01(salvar = TRUE)
  ref <- referencias[ano_censo == 2000L]
  if (nrow(ref) != 1L) {
    stop("ECO01 2000: referencia monetaria de 2000 ausente.")
  }
  limiar <- ref$linha_reais_mes_censo[[1L]]
  md5 <- as.character(ref$md5_fonte[[1L]])
  assinatura <- .assinatura_codigo_eco01_2000()
  message(sprintf(
    "ECO01 2000 | Limiar em julho/2000: R$ %.6f por pessoa/mes",
    limiar
  ))

  message("ECO01 2000 | Abrindo Pessoas e Domicilios com censobr...")
  censo_arrow <- abrir_censo_2000_economica(
    showProgress = showProgress
  )
  ufs_disponiveis <- listar_ufs_censo_2000_economica(censo_arrow)
  if (is.null(ufs)) {
    ufs_execucao <- ufs_disponiveis
  } else {
    if (!is.numeric(ufs) || !length(ufs) || anyNA(ufs) ||
        any(!is.finite(ufs)) || any(ufs != floor(ufs)) ||
        anyDuplicated(ufs) ||
        !all(ufs %in% ufs_disponiveis)) {
      stop("ECO01 2000: vetor ufs invalido ou repetido.")
    }
    ufs_execucao <- sort(as.integer(ufs))
  }
  integral <- setequal(ufs_execucao, ufs_disponiveis)

  dirs <- .diretorios_eco01_2000()
  brutos <- vector("list", length(ufs_execucao))
  auditorias <- vector("list", length(ufs_execucao))
  auditorias_construcao <- vector("list", length(ufs_execucao))

  for (i in seq_along(ufs_execucao)) {
    uf <- ufs_execucao[[i]]
    uf_chr <- sprintf("%02d", uf)
    arq_bruto <- file.path(
      dirs$partes, paste0("ECO01_POV3_PPC21_2000_UF", uf_chr, ".rds")
    )
    arq_audit <- file.path(
      dirs$partes, paste0("auditoria_eco01_2000_UF", uf_chr, ".rds")
    )
    arq_const <- file.path(
      dirs$partes, paste0("auditoria_rdpc_2000_UF", uf_chr, ".rds")
    )
    pronto <- !isTRUE(forcar_recalculo) &&
      all(file.exists(c(arq_bruto, arq_audit, arq_const)))

    if (pronto) {
      message(sprintf(
        "[%02d/%02d] ECO01 2000 | UF %s: checkpoint",
        i, length(ufs_execucao), uf_chr
      ))
      resultado <- list(
        bruto = readRDS(arq_bruto),
        auditoria = readRDS(arq_audit),
        auditoria_construcao = readRDS(arq_const)
      )
      if (!identical(
        attr(resultado$auditoria, "assinatura_codigo_eco01_2000"),
        assinatura
      )) {
        stop("ECO01 2000: codigo ou versao do censobr ",
             "mudou desde o checkpoint da UF ", uf_chr,
             ". Recalcule explicitamente com ",
             "forcar_recalculo = TRUE.")
      }
    } else {
      message(sprintf(
        "[%02d/%02d] ECO01 2000 | UF %s: processamento",
        i, length(ufs_execucao), uf_chr
      ))
      dados <- coletar_uf_censo_2000_economica(
        censo_arrow, uf = uf
      )
      adaptado <- adaptar_censo_2000_economica_uf(dados, uf)
      resultado <- calcular_eco01_pobreza(
        adaptado$dados,
        linha_pobreza = limiar,
        md5_fonte_ipca = md5
      )
      resultado$auditoria_construcao <-
        adaptado$auditoria_construcao
      rm(dados, adaptado)
      invisible(gc())
    }

    .validar_parte_eco01_2000(
      resultado$bruto, resultado$auditoria,
      resultado$auditoria_construcao,
      uf = uf, limiar = limiar, md5 = md5
    )

    if (!pronto) {
      attr(resultado$auditoria,
           "assinatura_codigo_eco01_2000") <- assinatura
      saveRDS(resultado$bruto, arq_bruto)
      saveRDS(resultado$auditoria, arq_audit)
      saveRDS(resultado$auditoria_construcao, arq_const)
    }

    brutos[[i]] <- resultado$bruto
    auditorias[[i]] <- resultado$auditoria
    auditorias_construcao[[i]] <- resultado$auditoria_construcao
    rm(resultado)
  }

  bruto <- data.table::rbindlist(
    brutos, use.names = TRUE, fill = FALSE
  )
  auditoria <- data.table::rbindlist(
    auditorias, use.names = TRUE, fill = FALSE
  )
  auditoria_construcao <- data.table::rbindlist(
    auditorias_construcao, use.names = TRUE, fill = FALSE
  )
  data.table::setorder(bruto, ano, cod_mun, grupo)
  data.table::setorder(auditoria, ano, cod_mun, grupo)
  data.table::setorder(auditoria_construcao, ano, cod_mun)

  validar_resultados_eco01(
    bruto, auditoria, ano = 2000L,
    municipios_esperados = if (integral) 5507L else NULL
  )

  if (integral) {
    arq_bruto_final <- file.path(
      dirs$bruto, "ECO01_POV3_PPC21_2000.rds"
    )
    arq_audit_final <- file.path(
      dirs$intermediario, "auditoria_eco01_2000.rds"
    )
    arq_const_final <- file.path(
      dirs$intermediario, "auditoria_construcao_rdpc_2000.rds"
    )
    saveRDS(bruto, arq_bruto_final)
    saveRDS(auditoria, arq_audit_final)
    saveRDS(auditoria_construcao, arq_const_final)
    message(
      "ECO01 2000 | Brasil concluido: 5.507 municipios ",
      "e 16.521 registros."
    )
    message("Resultado: ", arq_bruto_final)
    message("Auditoria: ", arq_audit_final)
    message("Auditoria do denominador: ", arq_const_final)
  } else {
    message(
      "ECO01 2000 | Teste parcial: checkpoints apenas para as UFs ",
      "solicitadas; nenhum arquivo nacional foi gravado."
    )
  }

  invisible(list(
    bruto = bruto,
    auditoria = auditoria,
    auditoria_construcao = auditoria_construcao,
    limiar_reais_mes = limiar,
    ufs = ufs_execucao,
    integral = integral
  ))
}
