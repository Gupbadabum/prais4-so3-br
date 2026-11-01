# =============================================================================
# PRAIS4 / SO3.3 - Inventario somente-leitura dos produtos INF02/E03
#
# Executar a partir da raiz do repositorio:
#   Rscript /tmp/diagnosticar_inf02_e03.R
#
# Este script nao promove, nao recalcula, nao escreve e nao altera arquivos.
# Imprime estrutura, contagens e cabecalhos; nunca imprime valores municipais.
# =============================================================================

if (!file.exists("so3.3/config/config.R")) {
  stop("Execute este diagnostico a partir da raiz do repositorio.")
}

cat("\n=== INF02 / E03: inventario local (somente leitura) ===\n")
cat("Script de execucao E03 presente: ",
    file.exists("so3.3/executar_inf02_etapa03.R"), "\n", sep = "")

todos <- list.files(
  "so3.3",
  pattern = "inf02|etapa03",
  recursive = TRUE,
  full.names = TRUE,
  ignore.case = TRUE
)
cat("\nArquivos com INF02 ou etapa03 no nome (", length(todos),
    " encontrados):\n", sep = "")
if (length(todos)) {
  print(utils::head(todos, 100L))
  if (length(todos) > 100L) cat("... exibidos apenas 100 caminhos\n")
}

inspecionar_tabela <- function(x, prefixo = "  ") {
  cat(prefixo, "classe: ", paste(class(x), collapse = "/"), "\n", sep = "")
  if (!is.data.frame(x)) {
    if (is.list(x)) {
      cat(prefixo, "nomes de componentes: ",
          paste(names(x), collapse = " | "), "\n", sep = "")
    }
    return(invisible(NULL))
  }
  cat(prefixo, "dimensoes: ", nrow(x), " linhas x ", ncol(x),
      " colunas\n", sep = "")
  cat(prefixo, "colunas: ", paste(names(x), collapse = " | "),
      "\n", sep = "")
  tipos <- vapply(x, function(v) paste(class(v), collapse = "/"), character(1))
  cat(prefixo, "tipos: ",
      paste(paste(names(tipos), tipos, sep = "="), collapse = " | "),
      "\n", sep = "")

  if ("cod_mun" %in% names(x)) {
    cat(prefixo, "municipios distintos: ",
        length(unique(as.character(x$cod_mun))), "\n", sep = "")
  }
  if ("grupo" %in% names(x)) {
    cat(prefixo, "registros por grupo:\n", sep = "")
    print(table(x$grupo, useNA = "ifany"))
  }
  if ("valor" %in% names(x)) {
    cat(prefixo, "NA em valor: ", sum(is.na(x$valor)), "\n", sep = "")
    if ("grupo" %in% names(x)) {
      cat(prefixo, "NA em valor por grupo:\n", sep = "")
      print(tapply(is.na(x$valor), x$grupo, sum))
    }
  }
  for (nome in c("status_calculo", "tipo_desagregacao", "unidade")) {
    if (nome %in% names(x)) {
      tab <- table(x[[nome]], useNA = "ifany")
      cat(prefixo, nome, ": ", length(tab), " categoria(s)\n", sep = "")
      print(tab)
    }
  }
  invisible(NULL)
}

base <- file.path("so3.3", "outputs", "bruto", "infraestrutural")
for (ano in c(2000L, 2010L, 2022L)) {
  cat("\n=== ANO ", ano, " ===\n", sep = "")
  prefixo <- paste0("INF02_RECURSOS_HIDRICOS_PC_", ano)
  pasta <- file.path(base, as.character(ano))
  caminhos <- c(
    RDS = file.path(pasta, paste0(prefixo, ".rds")),
    CSV = file.path(pasta, paste0(prefixo, ".csv"))
  )
  for (tipo in names(caminhos)) {
    caminho <- caminhos[[tipo]]
    presente <- file.exists(caminho)
    cat(tipo, " esperado: ", caminho, "\n", sep = "")
    cat("  existe: ", presente, "\n", sep = "")
    if (!presente) next
    tamanho <- file.info(caminho)$size
    cat("  tamanho_bytes: ", tamanho, "\n", sep = "")
    cat("  md5: ", unname(tools::md5sum(caminho)), "\n", sep = "")
    if (tipo == "CSV") {
      cabecalho <- tryCatch(
        readLines(caminho, n = 1L, warn = FALSE, encoding = "UTF-8"),
        error = function(e) paste("ERRO:", conditionMessage(e))
      )
      cat("  cabecalho: ", paste(cabecalho, collapse = ""), "\n", sep = "")
    } else {
      tryCatch({
        x <- readRDS(caminho)
        inspecionar_tabela(x)
        if (is.list(x) && !is.data.frame(x)) {
          for (nm in intersect(
            names(x), c("resultados", "municipal", "dados", "tabela", "qa")
          )) {
            cat("  componente ", nm, ":\n", sep = "")
            inspecionar_tabela(x[[nm]], prefixo = "    ")
          }
        }
      }, error = function(e) {
        cat("  ERRO ao ler RDS: ", conditionMessage(e), "\n", sep = "")
      })
    }
  }
}
cat("\n=== FIM - nenhum arquivo foi modificado ===\n")
