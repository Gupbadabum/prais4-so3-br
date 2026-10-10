# ============================================================
# PRAIS4 - SO3.3
# EXTRAÇÃO DAS TÁBUAS COALE-DEMENY WEST
# A PARTIR DO OBJETO coale_demeny_ltm DO u5mr 0.1.1
# ============================================================

library(data.table)

DIR_CD <- file.path(
  "so3.3",
  "inputs",
  "referencias",
  "coale_demeny"
)

dir.create(
  DIR_CD,
  recursive = TRUE,
  showWarnings = FALSE
)


# ------------------------------------------------------------
# Função auxiliar
# ------------------------------------------------------------

preparar_west <- function(
  tabela,
  sexo_modelo,
  grupo
) {

  dt <- as.data.table(
    copy(tabela)
  )

  dt[
    ,
    `:=`(
      familia = "West",
      sexo_modelo = sexo_modelo,
      grupo = grupo,
      nivel = seq_len(.N)
    )
  ]

  setcolorder(
    dt,
    c(
      "familia",
      "sexo_modelo",
      "grupo",
      "nivel",
      "e0",
      "q1",
      "q2",
      "q3",
      "q5",
      "q10",
      "q15",
      "q20"
    )
  )

  dt[]
}


# ------------------------------------------------------------
# Consolidação
# ------------------------------------------------------------

west <- rbindlist(
  list(

    preparar_west(
      obj$west_both,
      sexo_modelo = "both",
      grupo = "Total"
    ),

    preparar_west(
      obj$west_male,
      sexo_modelo = "male",
      grupo = "Masculino"
    ),

    preparar_west(
      obj$west_female,
      sexo_modelo = "female",
      grupo = "Feminino"
    )
  ),
  use.names = TRUE
)


# ------------------------------------------------------------
# QA estrutural
# ------------------------------------------------------------

stopifnot(
  nrow(west) == 75L
)

qa_estrutura <- west[
  ,
  .(
    n_linhas = .N,
    n_niveis = uniqueN(nivel),
    e0_crescente = all(diff(e0) > 0)
  ),
  by = grupo
]

print(qa_estrutura)


# ------------------------------------------------------------
# QA de domínio
# ------------------------------------------------------------

col_q <- c(
  "q1",
  "q2",
  "q3",
  "q5",
  "q10",
  "q15",
  "q20"
)

qa_dominio <- melt(
  west,
  id.vars = c(
    "grupo",
    "nivel"
  ),
  measure.vars = col_q,
  variable.name = "qx",
  value.name = "valor"
)[
  ,
  .(
    n_fora_0_1 =
      sum(
        valor < 0 |
        valor > 1 |
        is.na(valor)
      )
  ),
  by = qx
]

print(qa_dominio)


# ------------------------------------------------------------
# QA de monotonicidade entre níveis
#
# Com o aumento do nível de mortalidade/modelo,
# q(x) deve diminuir.
# ------------------------------------------------------------

qa_monotonia_nivel <- rbindlist(
  lapply(
    col_q,
    function(v) {

      west[
        order(nivel),
        .(
          monotono_decrescente =
            all(
              diff(
                get(v)
              ) < 0
            )
        ),
        by = grupo
      ][
        ,
        qx := v
      ]
    }
  )
)

setcolorder(
  qa_monotonia_nivel,
  c(
    "grupo",
    "qx",
    "monotono_decrescente"
  )
)

print(qa_monotonia_nivel)


# ------------------------------------------------------------
# QA de ordem acumulada por idade
#
# Em condições regulares:
#
# q1 <= q2 <= q3 <= q5 <= q10 <= q15 <= q20
# ------------------------------------------------------------

west[
  ,
  ordem_etaria_ok :=
    q1 <= q2 &
    q2 <= q3 &
    q3 <= q5 &
    q5 <= q10 &
    q10 <= q15 &
    q15 <= q20
]


qa_ordem_etaria <- west[
  ordem_etaria_ok == FALSE
]

cat(
  "\n============================================\n"
)

cat(
  "ANOMALIAS DE ORDEM ETARIA\n"
)

cat(
  "============================================\n"
)

print(
  qa_ordem_etaria
)


# ------------------------------------------------------------
# Controle da anomalia conhecida da fonte
#
# A publicação da ONU apresenta uma inconsistência em
# West/Feminino/Nível 22.
#
# Preservamos o valor publicado, mas não aceitamos que surjam
# outras inconsistências silenciosamente.
# ------------------------------------------------------------

if (
  nrow(qa_ordem_etaria) != 1L ||
  qa_ordem_etaria$grupo != "Feminino" ||
  qa_ordem_etaria$nivel != 22L
) {

  stop(
    "Foram encontradas inconsistencias adicionais ",
    "nas tabuas Coale-Demeny West."
  )
}


# ------------------------------------------------------------
# Remove coluna auxiliar antes da exportação
# ------------------------------------------------------------

west[
  ,
  ordem_etaria_ok := NULL
]


# ------------------------------------------------------------
# Exportação
# ------------------------------------------------------------

arquivo_west <- file.path(
  DIR_CD,
  "coale_demeny_west_qx.csv"
)

fwrite(
  west,
  file = arquivo_west,
  sep = ",",
  dec = ".",
  quote = FALSE,
  na = "NA"
)

cat(
  "\nArquivo criado:\n",
  arquivo_west,
  "\n"
)
