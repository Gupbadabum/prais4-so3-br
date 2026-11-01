#!/usr/bin/env Rscript
# PRAIS4/SO3.3 - Diagnostico estatistico reproduzivel.
# Executar a partir da raiz do repositorio:
# Rscript so3.3/executar_diagnostico_estatistico.R social SOC01_ALF15
# Rscript so3.3/executar_diagnostico_estatistico.R social todos
# Parametros estatisticos NAO sao estimados nem aplicados nesta fase.

executar_diagnostico_estatistico_so33 <- function(
    args = commandArgs(trailingOnly = TRUE)) {
  caminho_modulo <- "so3.3/R/03_diagnostico/estatistica_brutos_conjuntos.R"
  if (!file.exists(caminho_modulo)) {
    stop("Execute a partir da raiz do repositorio; modulo ausente.",
         call. = FALSE)
  }
  source(caminho_modulo, local = TRUE)
  if (length(args) > 2L) {
    stop("Uso: Rscript so3.3/executar_diagnostico_estatistico.R DIMENSAO INDICADOR|todos",
         call. = FALSE)
  }
  dimensao <- if (length(args)) tolower(args[[1L]]) else "social"
  indicador <- if (length(args) >= 2L) args[[2L]] else "SOC01_ALF15"
  catalogo <- estat_so33_catalogo()
  if (!dimensao %in% catalogo$dimensao) {
    stop("Dimensao desconhecida: ", dimensao, call. = FALSE)
  }
  ids <- catalogo$indicador[catalogo$dimensao == dimensao]
  if (identical(tolower(indicador), "todos")) {
    selecionados <- ids
  } else {
    if (!indicador %in% ids) {
      stop("Indicador nao pertence a dimensao ", dimensao,
           ": ", indicador, call. = FALSE)
    }
    selecionados <- indicador
  }
  identificador_execucao <- format(Sys.time(), "%Y%m%dT%H%M%S")
  retorno <- list()
  for (id in selecionados) {
    destino <- file.path(
      "so3.3", "outputs", "intermediario", "estatistica",
      "diagnostico", dimensao, id, identificador_execucao
    )
    message("SO3.3/Estatistica | Diagnostico: ", id)
    retorno[[id]] <- estat_so33_diagnosticar(
      indicador = id, dir_saida = destino
    )
    print(retorno[[id]]$estatisticas_conjuntas[
      , c("indicador", "grupo_referencia", "n_observacoes",
          "n_validos", "n_ausentes", "mediana", "p99", "max"),
      drop = FALSE
    ], row.names = FALSE)
    message("Saida: ", normalizePath(destino, winslash = "/"))
  }
  message("Diagnostico concluido. Produtos brutos preservados.")
  invisible(retorno)
}

# Tambem funciona com source() no RStudio, como os demais executores.
resultado_diagnostico_estatistico <- executar_diagnostico_estatistico_so33()
