# ============================================================
# PRAIS4 - SO3.3
# Vulnerabilidade a seca - Brasil
# Arquivo principal de orquestracao
# ============================================================

# ============================================================
# 0. RAIZ DO MODULO
# ============================================================

resolver_raiz_so33 <- function() {
  wd <- normalizePath(getwd(), mustWork = TRUE)

  if (basename(wd) == "so3.3") {
    return(wd)
  }

  candidato <- file.path(wd, "so3.3")
  if (dir.exists(candidato)) {
    return(normalizePath(candidato, mustWork = TRUE))
  }

  stop(
    "Execute o main.R a partir da raiz do repositorio ou do diretorio so3.3/."
  )
}

DIR_SO33 <- resolver_raiz_so33()


# ============================================================
# 1. CONFIGURACAO
# ============================================================

source(file.path(DIR_SO33, "config", "config.R"))


# ============================================================
# 2. FUNCOES
# ============================================================

source(file.path(DIR_SO33, "R", "01_leitura", "adaptar_censo_2022.R"))
source(file.path(DIR_SO33, "R", "02_indicadores", "social.R"))
source(file.path(DIR_SO33, "R", "03_diagnostico", "diagnostico_indicadores.R"))

# Futuras inclusoes:
# source(file.path(DIR_SO33, "R", "01_leitura", 	"adaptar_censo_2000.R"))
# source(file.path(DIR_SO33, "R", "01_leitura", 	"adaptar_censo_2010.R"))
# source(file.path(DIR_SO33, "R", "02_indicadores", "economica.R"))
# source(file.path(DIR_SO33, "R", "02_indicadores", "infraestrutura.R"))
# source(file.path(DIR_SO33, "R", "04_tratamento", 	"winsorizacao.R"))
# source(file.path(DIR_SO33, "R", "04_tratamento", 	"boxcox.R"))
# source(file.path(DIR_SO33, "R", "05_normalizacao", "normalizacao.R"))
# source(file.path(DIR_SO33, "R", "06_agregacao", 	"componentes.R"))
# source(file.path(DIR_SO33, "R", "06_agregacao", 	"dvi.R"))
# source(file.path(DIR_SO33, "R", "07_exportacao", 	"exportar_resultados.R"))


# ============================================================
# 3. CHAMADA DOS DADOS
# ============================================================

# ------------------------------------------------------------
# 3.1 Censo 2000
# ------------------------------------------------------------
# O acesso sera feito via censobr.
# O adaptador devera devolver a mesma estrutura canonica usada
# por 2010 e 2022.

# censo_2000 <- adaptar_censo_2000(...)


# ------------------------------------------------------------
# 3.2 Censo 2010
# ------------------------------------------------------------
# O acesso sera feito via censobr.

# censo_2010 <- adaptar_censo_2010(...)


# ------------------------------------------------------------
# 3.3 Censo 2022 - acesso controlado
# ------------------------------------------------------------

if (is.na(DIR_CENSO_2022) || !dir.exists(DIR_CENSO_2022)) {
  stop(
    paste0(
      "Diretorio do Censo 2022 nao configurado. ",
      "Crie config/config_local.R a partir do arquivo de exemplo."
    )
  )
}

arquivos_pessoas_2022 <- listar_arquivos_pessoas_2022(DIR_CENSO_2022)


# ============================================================
# 4. DIMENSAO SOCIAL
# ============================================================

# ------------------------------------------------------------
# 4.1 Social - 2000
# ------------------------------------------------------------

# social_2000 <- calcular_social_direto(censo_2000, ano = 2000L)


# ------------------------------------------------------------
# 4.2 Social - 2010
# ------------------------------------------------------------

# social_2010 <- calcular_social_direto(censo_2010, ano = 2010L)


# ------------------------------------------------------------
# 4.3 Social - 2022
# ------------------------------------------------------------
# Os arquivos sao processados UF a UF para evitar manter o
# microdado nacional completo em memoria.

social_2022 <- data.table::rbindlist(
  lapply(
    arquivos_pessoas_2022,
    function(arq) {
      dados_padronizados <- adaptar_censo_2022(arq)
      calcular_social_direto(dados_padronizados, ano = 2022L)
    }
  ),
  use.names = TRUE,
  fill = TRUE
)


# ============================================================
# 5. DIMENSAO ECONOMICA
# ============================================================

# economica_2000 <- calcular_economica(...)
# economica_2010 <- calcular_economica(...)
# economica_2022 <- calcular_economica(...)


# ============================================================
# 6. DIMENSAO INFRAESTRUTURAL
# ============================================================

# infraestrutura_2000 <- calcular_infraestrutura(...)
# infraestrutura_2010 <- calcular_infraestrutura(...)
# infraestrutura_2022 <- calcular_infraestrutura(...)


# ============================================================
# 7. CONSOLIDACAO DOS INDICADORES BRUTOS
# ============================================================

# Nesta etapa, quando os tres censos estiverem implementados:
#
# social_bruto <- data.table::rbindlist(
#   list(
#     social_2000,
#     social_2010,
#     social_2022
#   ),
#   use.names = TRUE,
#   fill = TRUE
# )
#
# indicadores_brutos <- data.table::rbindlist(
#   list(
#     social_bruto,
#     economica_bruto,
#     infraestrutura_bruto
#   ),
#   use.names = TRUE,
#   fill = TRUE
# )


# ============================================================
# 8. CONTROLE DE QUALIDADE E DIAGNOSTICO
# ============================================================

# Enquanto apenas 2022 esta implementado, o diagnostico e feito
# sobre social_2022. Quando 2000 e 2010 entrarem, o mesmo fluxo
# sera aplicado sobre social_bruto / indicadores_brutos.

diagnostico_social_2022 	<- diagnosticar_indicadores(social_2022)
diagnostico_amostra_2022 	<- diagnosticar_amostra(social_2022)
consistencia_sexo_2022 		<- verificar_consistencia_sexo(social_2022)
extremos_social_2022 		<- extrair_extremos(social_2022, n = 10L)

print(diagnostico_social_2022)
print(diagnostico_amostra_2022)
print(consistencia_sexo_2022$resumo)


# ============================================================
# 9. TRATAMENTO ESTATISTICO
# ============================================================
# O tratamento sera executado somente apos a consolidacao dos
# recortes 2000, 2010 e 2022.
#
# Regra metodologica ja definida:
#   - anos combinados dentro de cada indicador;
#   - Total, Masculino e Feminino tratados separadamente.

# indicadores_winsor <- aplicar_winsorizacao(indicadores_brutos, ...)
# indicadores_boxcox <- aplicar_boxcox(indicadores_winsor, ...)


# ============================================================
# 10. ORIENTACAO E NORMALIZACAO
# ============================================================

# indicadores_normalizados <- normalizar_indicadores(...)


# ============================================================
# 11. COMPONENTES DAS DIMENSOES
# ============================================================

# componentes <- calcular_componentes(indicadores_normalizados)


# ============================================================
# 12. DVI
# ============================================================

# dvi <- calcular_dvi(componentes)


# ============================================================
# 13. EXPORTACAO
# ============================================================
# Nenhum microdado individual deve ser exportado ou versionado.
# Apenas resultados municipais agregados e produtos derivados.

# exportar_resultados(...)
