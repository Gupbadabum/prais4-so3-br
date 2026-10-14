# ============================================================
# PRAIS4 - SO3.3 | DIAGNOSTICO SOCIAL CONSOLIDADO
# SOC01, SOC02 e SOC04 | Censos 2000, 2010 e 2022
#
# Apenas produtos municipais; nao acessa microdados.
# Diagnostico nao altera nem trata indicadores.
# Executar na raiz do repositorio.
# ============================================================

diagnosticar_social_consolidado <- function(
  dir_bruto = file.path("so3.3", "outputs", "bruto"),
  dir_saida = file.path("so3.3", "outputs", "diagnostico", "social")
) {
  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("Pacote data.table necessario.")
  }

  anos <- c(2000L, 2010L, 2022L)
  ids <- c("SOC01_ALF15", "SOC02_RURAL", "SOC04_POP1564")
  grupos <- c("Total", "Masculino", "Feminino")
  dir.create(dir_saida, recursive = TRUE, showWarnings = FALSE)

  resultados <- vector("list", length(anos) * length(ids))
  resumo_integridade <- vector("list", length(resultados))
  ausencias_grupo <- vector("list", length(resultados))
  i <- 0L

  for (ano in anos) {
    for (id in ids) {
      i <- i + 1L
      caminho <- file.path(dir_bruto, "social", as.character(ano),
                            paste0(id, "_", ano, ".rds"))
      if (!file.exists(caminho)) stop("Arquivo ausente: ", caminho)
      d <- data.table::as.data.table(readRDS(caminho))

      colunas <- c("ano", "uf", "cod_mun", "grupo", "dimensao",
                   "indicador", "valor", "numerador", "denominador",
                   "n_amostra", "n_efetivo", "soma_pesos2")
      faltantes <- setdiff(colunas, names(d))
      if (length(faltantes)) {
        stop("Colunas ausentes em ", caminho, ": ", paste(faltantes, collapse=", "))
      }

      if (!nrow(d) || anyNA(d[, .(ano, uf, cod_mun, grupo, indicador)]) ||
          any(d$ano != ano) || any(d$indicador != id) ||
          any(d$dimensao != "Social") ||
          any(!d$grupo %in% grupos)) {
        stop("Identificacao invalida no arquivo: ", caminho)
      }

      duplicadas <- anyDuplicated(d[, .(ano, cod_mun, grupo)])
      municipios <- unique(d$cod_mun)
      grade <- data.table::CJ(cod_mun = municipios, grupo = grupos)
      presentes <- unique(d[, .(cod_mun, grupo)])
      ausencias_grupo[[i]] <- merge(
        grade, presentes,
        by = c("cod_mun", "grupo"), all.x = TRUE
      ) # A checagem exata da grade ocorre abaixo.
      chaves <- paste(presentes$cod_mun, presentes$grupo, sep = ":")
      grade[, ausente := !(paste(cod_mun, grupo, sep = ":") %in% chaves)]
      ausencias_grupo[[i]] <- grade[ausente == TRUE,
        .(ano = ano, indicador = id, cod_mun, grupo)]

      problemas <- sum(is.na(d$valor) | !is.finite(d$valor) |
                       d$valor < 0 | d$valor > 100)
      resumo_integridade[[i]] <- data.table::data.table(
        ano = ano, indicador = id, linhas = nrow(d),
        municipios = data.table::uniqueN(d$cod_mun),
        duplicidades = as.integer(duplicadas > 0),
        grupos_ausentes = nrow(ausencias_grupo[[i]]),
        valores_ausentes = sum(is.na(d$valor)),
        valores_fora_faixa = problemas,
        n_amostra_min = suppressWarnings(min(d$n_amostra, na.rm = TRUE)),
        n_efetivo_min = suppressWarnings(min(d$n_efetivo, na.rm = TRUE))
      )
      resultados[[i]] <- d
      rm(d)
      invisible(gc())
    }
  }

  todos <- data.table::rbindlist(resultados, use.names=TRUE, fill=TRUE)
  rm(resultados)
  invisible(gc())

  controle <- data.table::rbindlist(resumo_integridade)
  ausencias <- data.table::rbindlist(ausencias_grupo)

  # Usa a funcao de auditoria ja existente, incluindo T/M/F.
  diag <- diagnosticar_indicadores(todos, n_extremos = 10L)

  # Checagem estrutural independente de limites de tolerancia.
  grupos_municipio <- todos[, .(n_grupos = data.table::uniqueN(grupo)),
                            by = .(ano, indicador, cod_mun)]
  municipios_incompletos <- grupos_municipio[n_grupos != 3L]

  # Comparacao apenas descritiva de municipios entre indicadores do mesmo ano.
  cobertura <- unique(todos[, .(ano, indicador, cod_mun)])[
    , .(municipios = .N), by = .(ano, indicador)]

  # Saidas pequenas e auditaveis; os nove brutos nao sao alterados.
  salvar <- function(obj, nome) {
    saveRDS(obj, file.path(dir_saida, paste0(nome, ".rds")))
  }
  salvar(controle, "integridade")
  salvar(cobertura, "cobertura")
  salvar(diag$resumo, "resumo")
  salvar(diag$amostra, "amostra")
  salvar(diag$duplicidades, "duplicidades")
  salvar(ausencias, "grupos_ausentes")
  salvar(municipios_incompletos, "municipios_incompletos")
  salvar(diag$problemas_consistencia_sexo, "inconsistencia_sexo")
  salvar(diag$extremos_inferiores, "extremos_inferiores")
  salvar(diag$extremos_superiores, "extremos_superiores")

  data.table::fwrite(controle, file.path(dir_saida, "integridade.csv"))
  data.table::fwrite(diag$resumo, file.path(dir_saida, "resumo.csv"))
  data.table::fwrite(cobertura, file.path(dir_saida, "cobertura.csv"))

  cat("\n=== INTEGRIDADE DOS NOVE RDS ===\n")
  print(controle)
  cat("\n=== RESUMO DOS INDICADORES ===\n")
  print(diag$resumo)
  cat("\n=== CONSISTENCIA T/M/F ===\n")
  cat("Municipios com grupos incompletos:", nrow(municipios_incompletos), "\n")
  cat("Inconsistencias numericas T/M/F:",
      nrow(diag$problemas_consistencia_sexo), "\n")
  cat("\nResultados em:", dir_saida, "\n")

  invisible(list(integridade=controle, cobertura=cobertura,
                 resumo=diag$resumo, amostra=diag$amostra,
                 grupos_ausentes=ausencias,
                 municipios_incompletos=municipios_incompletos,
                 inconsistencias=diag$problemas_consistencia_sexo))
}
