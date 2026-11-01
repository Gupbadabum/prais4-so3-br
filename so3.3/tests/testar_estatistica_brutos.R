# PRAIS4 / SO3.3 - Testes do modulo de diagnostico estatistico
# Executar da raiz: Rscript so3.3/tests/testar_estatistica_brutos.R
# Usa R base; nao modifica CSVs ou outros arquivos do projeto.

source("so3.3/R/03_diagnostico/estatistica_brutos_conjuntos.R")

catalogo <- estat_so33_catalogo()
stopifnot(nrow(catalogo) == 9L,
          length(unique(catalogo$indicador)) == 9L,
          identical(estat_so33_anos(), c(2000L, 2010L, 2022L)))

anos <- estat_so33_anos()
grupos <- estat_so33_grupos()
base <- data.frame(
  ano = rep(anos, each = 3L),
  cod_mun = rep("1100015", 9L),
  grupo = rep(grupos, 3L),
  valor = c(80, 70, 90, 85, 75, 95, 90, 80, 100),
  stringsAsFactors = FALSE
)
series <- estat_so33_series(base, "populacional")
stopifnot(identical(names(series), grupos),
          all(vapply(series, nrow, integer(1)) == 3L))

medianas <- vapply(names(series), function(g) {
  estat_so33_resumir(series[[g]], "social", "SOC01_ALF15", g)$mediana
}, numeric(1))
stopifnot(identical(unname(medianas), c(85, 75, 95)))

compartilhado <- base
compartilhado$valor <- rep(c(4, 5, 6), each = 3L)
serie_unica <- estat_so33_series(compartilhado,
                                 "territorial_compartilhado")
stopifnot(identical(names(serie_unica), "Compartilhado"),
          nrow(serie_unica[[1L]]) == 3L)
compartilhado$valor[2L] <- 999
falhou <- inherits(try(estat_so33_series(compartilhado,
                                        "territorial_compartilhado"),
                       silent = TRUE), "try-error")
stopifnot(falhou)

# Regressao com os CSVs publicos da dimensao Social, caso disponiveis.
arquivos_soc01 <- file.path("so3.3", "outputs", "bruto", "social",
                            as.character(anos),
                            paste0("SOC01_ALF15_", anos, ".csv"))
if (all(file.exists(arquivos_soc01))) {
  r <- estat_so33_diagnosticar("SOC01_ALF15", dir_saida = NULL)
  stopifnot(nrow(r$inventario) == 3L,
            nrow(r$estatisticas_conjuntas) == 3L,
            nrow(r$estatisticas_anuais_descritivas) == 9L,
            all(r$estatisticas_conjuntas$n_observacoes == 16642L),
            all(r$estatisticas_conjuntas$n_validos == 16642L),
            setequal(r$estatisticas_conjuntas$grupo_referencia, grupos))
  message("Regressao SOC01 com CSVs reais: OK")
} else {
  message("CSVs SOC01 ausentes; teste sintetico concluido sem regressao real.")
}

message("Testes estatisticos SO3.3: OK")
