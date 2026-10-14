# ============================================================
# PRAIS4 - SO3.3
# DIAGNOSTICO EXPLORATORIO DAS CAUDAS - SOCIAL
#
# SOC01, SOC02, SOC04 | 2000, 2010, 2022 | Total, M, F
#
# Seleciona pelo menos 5% de cada cauda POR DISTRIBUICAO,
# preservando TODOS os empates nos limites de corte.
#
# IMPORTANTE:
# - selecao para investigacao, NAO deteccao de erros;
# - NAO altera indicadores ou microdados;
# - NAO executa winsorizacao, exclusao ou normalizacao.
# ============================================================

diagnosticar_caudas_sociais <- function(
    proporcao = 0.05,
    dir_bruto = file.path("so3.3", "outputs", "bruto"),
    dir_saida = file.path("so3.3", "outputs", "diagnostico", "social")
) {

  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("Pacote 'data.table' necessario.")
  }
  if (!is.numeric(proporcao) || length(proporcao) != 1L ||
      is.na(proporcao) || proporcao <= 0 || proporcao > 0.5) {
    stop("'proporcao' deve estar em (0, 0.5].")
  }

  anos <- c(2000L, 2010L, 2022L)
  indicadores <- c("SOC01_ALF15", "SOC02_RURAL", "SOC04_POP1564")
  grupos <- c("Total", "Masculino", "Feminino")
  partes <- vector("list", length(anos) * length(indicadores))
  i <- 0L

  # Apenas os nove RDS municipais; nenhuma leitura de microdados.
  for (ano in anos) {
    for (indicador_atual in indicadores) {
      i <- i + 1L
      arq <- file.path(
        dir_bruto, "social", as.character(ano),
        paste0(indicador_atual, "_", ano, ".rds")
      )
      if (!file.exists(arq)) stop("Arquivo nao encontrado: ", arq)

      d <- data.table::as.data.table(readRDS(arq))
      obrigatorias <- c(
        "ano", "uf", "cod_mun", "indicador", "grupo", "valor",
        "numerador", "denominador", "n_amostra", "n_efetivo"
      )
      faltantes <- setdiff(obrigatorias, names(d))
      if (length(faltantes)) {
        stop("Colunas ausentes em ", arq, ": ",
             paste(faltantes, collapse = ", "))
      }
      if (anyNA(d[, .(ano, uf, cod_mun, indicador, grupo)]) ||
          any(d$ano != ano) ||
          any(d$indicador != indicador_atual) ||
          any(!d$grupo %in% grupos)) {
        stop("Identificadores inesperados em ", arq)
      }
      partes[[i]] <- d[!is.na(valor) & is.finite(valor)]
      rm(d)
    }
  }

  base <- data.table::rbindlist(partes, use.names = TRUE, fill = TRUE)
  rm(partes)
  invisible(gc())
  if (nrow(base) == 0L) stop("Nenhum valor municipal valido encontrado.")

  # Limites empiricos pelos valores ordenados:
  # k = teto(0,05 * N), incluindo todos os empates no valor k.
  # O limite superior e o k-esimo valor a partir do maior.
  limites <- base[
    ,
    {
      valores <- sort(valor)
      n <- length(valores)
      k <- as.integer(ceiling(proporcao * n))
      .(
        n_validos = n,
        n_minimo_por_cauda = k,
        limite_inferior = valores[k],
        limite_superior = valores[n - k + 1L],
        n_zero = sum(valores == 0),
        n_cem = sum(valores == 100)
      )
    },
    by = .(ano, indicador, grupo)
  ]

  # O join apenas adiciona os limites a cada registro municipal.
  # Os resultados originais sao preservados.
  avaliacao <- merge(
    base, limites,
    by = c("ano", "indicador", "grupo"),
    all.x = TRUE, sort = FALSE
  )
  rm(base)
  invisible(gc())

  avaliacao[
    ,
    `:=`(
      cauda_inferior = valor <= limite_inferior,
      cauda_superior = valor >= limite_superior
    )
  ]

  resumo <- avaliacao[
    ,
    .(
      n_validos = .N,
      n_minimo_por_cauda = n_minimo_por_cauda[1L],
      limite_inferior = limite_inferior[1L],
      limite_superior = limite_superior[1L],
      n_inferior = sum(cauda_inferior),
      n_superior = sum(cauda_superior),
      n_ambas = sum(cauda_inferior & cauda_superior),
      pct_inferior = 100 * mean(cauda_inferior),
      pct_superior = 100 * mean(cauda_superior),
      n_zero = n_zero[1L],
      n_cem = n_cem[1L],
      n_efetivo_mediana_inferior = {
        x <- n_efetivo[cauda_inferior & is.finite(n_efetivo)]
        if (length(x)) as.numeric(stats::median(x)) else NA_real_
      },
      n_efetivo_mediana_superior = {
        x <- n_efetivo[cauda_superior & is.finite(n_efetivo)]
        if (length(x)) as.numeric(stats::median(x)) else NA_real_
      }
    ),
    by = .(ano, indicador, grupo)
  ]

  selecionados <- avaliacao[cauda_inferior | cauda_superior]
  selecionados[
    ,
    cauda := data.table::fcase(
      cauda_inferior & cauda_superior, "Ambas",
      cauda_inferior, "Inferior",
      cauda_superior, "Superior",
      default = NA_character_
    )
  ]

  data.table::setorder(resumo, ano, indicador, grupo)
  data.table::setorder(selecionados, ano, indicador, grupo, valor)

  dir.create(dir_saida, recursive = TRUE, showWarnings = FALSE)
  arquivo_resumo <- file.path(dir_saida, "resumo_caudas_5pct.csv")
  arquivo_detalhe <- file.path(dir_saida, "municipios_caudas_5pct.csv")
  data.table::fwrite(resumo, arquivo_resumo)
  data.table::fwrite(selecionados, arquivo_detalhe)
  saveRDS(resumo, file.path(dir_saida, "resumo_caudas_5pct.rds"))
  saveRDS(selecionados, file.path(dir_saida, "municipios_caudas_5pct.rds"))

  cat("\\n=== CAUDAS SOCIAIS: SELECAO PARA INVESTIGACAO ===\\n")
  print(resumo)
  cat("\\nEmpates nos limites podem elevar a proporcao selecionada.\\n")
  cat("Nenhum indicador bruto foi alterado.\\n")
  cat("Resumo: ", arquivo_resumo, "\\n", sep = "")
  cat("Municipios: ", arquivo_detalhe, "\\n", sep = "")

  invisible(list(resumo = resumo, municipios = selecionados))
}
