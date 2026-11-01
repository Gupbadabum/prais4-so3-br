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

# Testes adicionais COINr type=2, orcamentos e nao intervencao.
# Exemplo nao limitrofe: assimetria = sqrt(5) e curtose excedente = 5.
# Evita verificar status em skew = 2, que pode ser calculado como
# 1.9999999999999998 e portanto PASSAR pela regra estrita do COINr.
vetor_outlier <- c(0, 0, 0, 0, 10)
m <- estat_so33_momentos_coinr(vetor_outlier)
stopifnot(isTRUE(all.equal(m$assimetria, sqrt(5), tolerance = 1e-12)),
          isTRUE(all.equal(m$curtose_excesso, 5, tolerance = 1e-12)),
          identical(m$status, "INVESTIGAR"),
          isTRUE(m$investigar), identical(m$cauda_assimetria, "superior"))

# Assimetria extrema negativa: apenas o grupo do proprio teste.
m2 <- estat_so33_momentos_coinr(c(10, 10, 10, 10, 0))
stopifnot(isTRUE(all.equal(m2$assimetria, -sqrt(5), tolerance = 1e-12)),
          identical(m2$status, "INVESTIGAR"),
          identical(m2$cauda_assimetria, "inferior"))

# Serie simetrica deve passar; serie constante nao define momentos.
mpassa <- estat_so33_momentos_coinr(c(1, 2, 3, 4, 5))
stopifnot(identical(mpassa$status, "PASSA"),
          identical(mpassa$investigar, FALSE))
m3 <- estat_so33_momentos_coinr(c(0, 0, 0, 0, 0))
stopifnot(grepl("^INDETERMINADO", m3$status),
          is.na(m3$investigar))
m4 <- estat_so33_momentos_coinr(c(1, 2, 3))
stopifnot(grepl("N_INSUFICIENTE", m4$status))
m5 <- estat_so33_momentos_coinr(c(0, 0, 0, 0, 10, NA_real_))
stopifnot(isTRUE(all.equal(m5$assimetria, sqrt(5), tolerance = 1e-12)))

# Fronteira numerica: verifica apenas a precisao do momento,
# NAO presume classificacao independente do arredondamento binario.
mb <- estat_so33_momentos_coinr(c(0, 0, 0, 10))
stopifnot(isTRUE(all.equal(abs(mb$assimetria), 2, tolerance = 1e-12)),
          isTRUE(all.equal(mb$curtose_excesso, 4, tolerance = 1e-12)))
orc <- estat_so33_orcamentos_winsor(16642)
stopifnot(identical(orc$max_modificacoes_total, c(0L, 832L, 832L, 832L)),
          identical(orc$max_modificacoes_inferior, c(0L, 416L, 832L, 0L)),
          identical(orc$max_modificacoes_superior, c(0L, 416L, 0L, 832L)))
stopifnot(inherits(try(estat_so33_orcamentos_winsor(16642, 0.06),
                       silent = TRUE), "try-error"))

# Controle de nao alteracao e de que flags anuais nao estabelecem limites.
serie_teste <- series[["Total"]]
antes_teste <- serie_teste$valor
scon <- estat_so33_resumir(serie_teste, "social", "SOC01_ALF15", "Total")
sano <- estat_so33_resumir(serie_teste[serie_teste$ano == 2000, ],
                          "social", "SOC01_ALF15", "Total",
                          escopo = "descritivo_anual_sem_limiares",
                          ano_descritivo = 2000L)
stopifnot(identical(antes_teste, serie_teste$valor),
          scon$teto_modificacoes_5pct == 0L,
          is.na(sano$teto_modificacoes_5pct),
          identical(sano$triagem_coinr, "APENAS_DESCRITIVO_ANUAL"))

if (all(file.exists(arquivos_soc01))) {
  r_coinr <- estat_so33_diagnosticar("SOC01_ALF15", dir_saida = NULL)
  z <- r_coinr$estatisticas_conjuntas
  stopifnot(nrow(z) == 3L, all(z$triagem_coinr == "PASSA"),
            all(!z$investigar_winsorizacao),
            all(z$teto_modificacoes_5pct == 832L),
            all(z$teto_por_cauda_bilateral_2p5pct == 416L),
            nrow(r_coinr$orcamentos_winsorizacao) == 12L)
  message("Regressao SOC01 e triagem COINr real: OK")
}
# Se o pacote de referencia estiver instalado, verifica equivalencia numerica.
if (requireNamespace("COINr", quietly = TRUE)) {
  z <- vetor_outlier
  stopifnot(isTRUE(all.equal(estat_so33_momentos_coinr(z)$assimetria,
                             COINr::skew(z), tolerance = 1e-12)),
            isTRUE(all.equal(estat_so33_momentos_coinr(z)$curtose_excesso,
                             COINr::kurt(z), tolerance = 1e-12)))
  # Confere tambem a classificacao de fronteira do proprio COINr:
  # o status nao e imposto quando o momento difere por arredondamento.
  ref_fronteira <- COINr::check_SkewKurt(c(0, 0, 0, 10))
  stopifnot(identical(mb$status == "PASSA",
                      isTRUE(ref_fronteira$Pass)))
  message("Comparacao contra COINr instalado (inclusive fronteira): OK")
}

message("Testes estatisticos SO3.3: OK")
