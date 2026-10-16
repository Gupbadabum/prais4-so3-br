# ============================================================
# PRAIS4 / SO3.3 / ECO01 - EXECUCAO ISOLADA DO CENSO 2022
#
# Executar na raiz do repositorio, apos carregar:
#   so3.3/config/config.R
#   so3.3/config/config_local.R (se existir: DIR_CENSO_2022)
#   so3.3/R/02_indicadores/preparar_referencias_eco01.R
#   so3.3/R/01_leitura/adaptar_censo_2022_economica.R
#   so3.3/R/02_indicadores/eco01_pobreza.R
#   este arquivo
#
# processar_eco01_2022(ufs = 11L): checkpoint somente RO.
# processar_eco01_2022(): 27 UFs; RDS nacional apos validacao.
# Os microdados controlados nao sao salvos nos outputs.
# ============================================================

if (!requireNamespace("data.table", quietly = TRUE)) {
  stop("ECO01 2022: o pacote data.table e necessario.")
}

.diretorios_eco01_2022 <- function() {
  dir_bruto <- file.path(DIR_OUTPUT_BRUTO, "economica", "2022")
  dir_intermediario <- file.path(
    DIR_OUTPUT_INTERMEDIARIO, "economica", "2022"
  )
  dir_partes <- file.path(dir_intermediario, "partes_censo_2022")
  for (dir in c(dir_bruto, dir_intermediario, dir_partes)) {
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  }
  list(
    bruto = dir_bruto,
    intermediario = dir_intermediario,
    partes = dir_partes
  )
}

# Detecta alteracoes de arquivos locais ao reutilizar checkpoints,
# sem recalcular MD5 de microdados muito grandes.
.assinatura_fontes_eco01_2022 <- function(caminhos) {
  info <- file.info(caminhos)
  if (nrow(info) != 2L ||
      anyNA(info[, c("size", "mtime")])) {
    stop("ECO01 2022: nao foi possivel verificar os dois arquivos fonte.")
  }
  list(
    caminhos = unname(normalizePath(
      caminhos, winslash = "/", mustWork = TRUE
    )),
    tamanhos = unname(as.numeric(info$size)),
    modificados = unname(as.numeric(info$mtime))
  )
}

.validar_parte_eco01_2022 <- function(
  bruto, auditoria, uf, limiar, md5
) {
  validar_resultados_eco01(
    bruto, auditoria, ano = 2022L
  )
  uf_chr <- sprintf("%02d", as.integer(uf))
  if (data.table::uniqueN(bruto$uf) != 1L ||
      data.table::uniqueN(auditoria$uf) != 1L ||
      unique(bruto$uf) != uf_chr ||
      unique(auditoria$uf) != uf_chr ||
      any(!is.finite(auditoria$linha_pobreza_mes)) ||
      any(abs(auditoria$linha_pobreza_mes - limiar) > 1e-8) ||
      any(auditoria$md5_fonte_ipca != md5)) {
    stop("ECO01 2022: UF ", uf_chr,
         " incompatível com os parâmetros monetários atuais.")
  }
  invisible(TRUE)
}

processar_eco01_2022 <- function(
  ufs = NULL, dir_censo = DIR_CENSO_2022,
  forcar_recalculo = FALSE
) {
  dependencias <- c(
    "preparar_referencias_eco01",
    "listar_pares_eco01_2022",
    "adaptar_censo_2022_economica_uf",
    "calcular_eco01_pobreza",
    "validar_resultados_eco01"
  )
  faltantes <- dependencias[!vapply(
    dependencias, exists, logical(1L),
    mode = "function", inherits = TRUE
  )]
  if (length(faltantes)) {
    stop("ECO01 2022: carregue antes os modulos necessarios: ",
         paste(faltantes, collapse = ", "))
  }

  referencias <- preparar_referencias_eco01(salvar = TRUE)
  ref <- referencias[ano_censo == 2022L]
  if (nrow(ref) != 1L) {
    stop("ECO01 2022: referencia monetaria de 2022 indisponivel.")
  }
  limiar <- ref$linha_reais_mes_censo[[1L]]
  md5 <- as.character(ref$md5_fonte[[1L]])
  message(sprintf(
    "ECO01 2022 | Limiar de pobreza: R$ %.6f por pessoa/mes",
    limiar
  ))

  pares <- listar_pares_eco01_2022(dir_censo = dir_censo)
  if (is.null(ufs)) {
    selecionados <- pares
  } else {
    if (!is.numeric(ufs) || !length(ufs) || anyNA(ufs) ||
        any(!is.finite(ufs)) || any(ufs != floor(ufs)) ||
        anyDuplicated(ufs) ||
        !all(sprintf("%02d", as.integer(ufs)) %in% pares$uf)) {
      stop("ECO01 2022: informe UFs validas e nao repetidas.")
    }
    selecionados <- pares[
      uf %in% sprintf("%02d", as.integer(ufs))
    ]
  }
  integral <- nrow(selecionados) == 27L

  dirs <- .diretorios_eco01_2022()
  brutos <- vector("list", nrow(selecionados))
  auditorias <- vector("list", nrow(selecionados))

  for (i in seq_len(nrow(selecionados))) {
    uf_chr <- selecionados$uf[[i]]
    arquivo_p <- selecionados$arquivo_pessoas[[i]]
    arquivo_d <- selecionados$arquivo_domicilios[[i]]
    assinatura <- .assinatura_fontes_eco01_2022(
      c(arquivo_p, arquivo_d)
    )

    arq_bruto <- file.path(
      dirs$partes,
      paste0("ECO01_POV3_PPC21_2022_UF", uf_chr, ".rds")
    )
    arq_auditoria <- file.path(
      dirs$partes,
      paste0("auditoria_eco01_2022_UF", uf_chr, ".rds")
    )
    reutilizar <- !isTRUE(forcar_recalculo) &&
      file.exists(arq_bruto) && file.exists(arq_auditoria)

    if (reutilizar) {
      message(sprintf(
        "[%02d/%02d] ECO01 2022 | UF %s: checkpoint",
        i, nrow(selecionados), uf_chr
      ))
      resultado <- list(
        bruto = readRDS(arq_bruto),
        auditoria = readRDS(arq_auditoria)
      )
      if (!identical(
        attr(resultado$auditoria, "fontes_eco01_2022"),
        assinatura
      )) {
        stop("ECO01 2022: arquivos fonte da UF ", uf_chr,
             " mudaram desde o checkpoint. ",
             "Reprocessar com forcar_recalculo = TRUE.")
      }
    } else {
      message(sprintf(
        "[%02d/%02d] ECO01 2022 | UF %s: processamento",
        i, nrow(selecionados), uf_chr
      ))
      dados_uf <- adaptar_censo_2022_economica_uf(
        arquivo_p, arquivo_d, uf = as.integer(uf_chr)
      )
      resultado <- calcular_eco01_pobreza(
        dados_uf, linha_pobreza = limiar, md5_fonte_ipca = md5
      )
      rm(dados_uf)
      invisible(gc())
    }

    .validar_parte_eco01_2022(
      resultado$bruto, resultado$auditoria,
      uf = as.integer(uf_chr), limiar = limiar, md5 = md5
    )

    if (!reutilizar) {
      attr(resultado$auditoria, "fontes_eco01_2022") <- assinatura
      saveRDS(resultado$bruto, arq_bruto)
      saveRDS(resultado$auditoria, arq_auditoria)
    }

    brutos[[i]] <- resultado$bruto
    auditorias[[i]] <- resultado$auditoria
    rm(resultado)
  }

  bruto <- data.table::rbindlist(
    brutos, use.names = TRUE, fill = FALSE
  )
  auditoria <- data.table::rbindlist(
    auditorias, use.names = TRUE, fill = FALSE
  )
  data.table::setorder(bruto, ano, cod_mun, grupo)
  data.table::setorder(auditoria, ano, cod_mun, grupo)

  validar_resultados_eco01(
    bruto, auditoria, ano = 2022L,
    municipios_esperados = if (integral) 5570L else NULL
  )

  if (integral) {
    arq_final <- file.path(
      dirs$bruto, "ECO01_POV3_PPC21_2022.rds"
    )
    arq_aud_final <- file.path(
      dirs$intermediario, "auditoria_eco01_2022.rds"
    )
    saveRDS(bruto, arq_final)
    saveRDS(auditoria, arq_aud_final)
    message(
      "ECO01 2022 | Brasil concluido: 5.570 municipios e 16.710 linhas."
    )
    message("Resultado: ", arq_final)
    message("Auditoria: ", arq_aud_final)
  } else {
    message(
      "ECO01 2022 | Teste parcial: apenas checkpoints por UF; ",
      "nenhum arquivo nacional foi gravado."
    )
  }

  invisible(list(
    bruto = bruto,
    auditoria = auditoria,
    limiar_reais_mes = limiar,
    ufs = selecionados$uf,
    integral = integral
  ))
}
