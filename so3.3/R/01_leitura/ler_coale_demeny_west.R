# ============================================================
# PRAIS4 - SO3.3
# LEITURA DAS TABUAS-MODELO COALE-DEMENY
# FAMILIA WEST
# ============================================================


ler_coale_demeny_west <- function(
  arquivo = ARQ_COALE_DEMENY_WEST
) {

  # ----------------------------------------------------------
  # 1. Arquivo
  # ----------------------------------------------------------

  if (!file.exists(arquivo)) {

    stop(
      "Arquivo Coale-Demeny West nao encontrado: ",
      arquivo
    )
  }


  # ----------------------------------------------------------
  # 2. Leitura
  # ----------------------------------------------------------

  dados <- data.table::fread(
    arquivo
  )


  # ----------------------------------------------------------
  # 3. Estrutura esperada
  # ----------------------------------------------------------

  colunas_esperadas <- c(
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


  if (!identical(
    names(dados),
    colunas_esperadas
  )) {

    stop(
      "Estrutura inesperada no arquivo ",
      "Coale-Demeny West."
    )
  }


  # ----------------------------------------------------------
  # 4. Dimensao da tabela
  #
  # 25 niveis x 3 grupos = 75 registros
  # ----------------------------------------------------------

  if (nrow(dados) != 75L) {

    stop(
      "Numero inesperado de registros ",
      "na referencia Coale-Demeny West. ",
      "Esperado: 75; encontrado: ",
      nrow(dados),
      "."
    )
  }


  # ----------------------------------------------------------
  # 5. Familia
  # ----------------------------------------------------------

  if (
    !all(
      dados$familia == "West"
    )
  ) {

    stop(
      "Foram encontradas familias diferentes de West."
    )
  }


  # ----------------------------------------------------------
  # 6. Grupos
  # ----------------------------------------------------------

  grupos_esperados <- c(
    "Total",
    "Masculino",
    "Feminino"
  )


  if (
    !setequal(
      unique(dados$grupo),
      grupos_esperados
    )
  ) {

    stop(
      "Grupos inesperados na referencia ",
      "Coale-Demeny West."
    )
  }


  # ----------------------------------------------------------
  # 7. 25 niveis em cada grupo
  # ----------------------------------------------------------

  estrutura <- dados[
    ,
    .(
      n_registros = .N,
      n_niveis = data.table::uniqueN(nivel),
      nivel_min = min(nivel),
      nivel_max = max(nivel)
    ),
    by = grupo
  ]


  if (
    any(
      estrutura$n_registros != 25L |
      estrutura$n_niveis != 25L |
      estrutura$nivel_min != 1L |
      estrutura$nivel_max != 25L
    )
  ) {

    stop(
      "Estrutura incompleta dos niveis ",
      "Coale-Demeny West."
    )
  }


  # ----------------------------------------------------------
  # 8. Dominio das probabilidades
  # ----------------------------------------------------------

  colunas_q <- c(
    "q1",
    "q2",
    "q3",
    "q5",
    "q10",
    "q15",
    "q20"
  )


  for (v in colunas_q) {

    x <- dados[[v]]

    if (
      any(
        is.na(x) |
        !is.finite(x) |
        x < 0 |
        x > 1
      )
    ) {

      stop(
        "Valores invalidos encontrados em ",
        v,
        "."
      )
    }
  }


  # ----------------------------------------------------------
  # 9. e0 deve crescer com o nivel
  # ----------------------------------------------------------

  qa_e0 <- dados[
    order(nivel),
    .(
      crescente =
        all(
          diff(e0) > 0
        )
    ),
    by = grupo
  ]


  if (any(!qa_e0$crescente)) {

    stop(
      "e0 nao cresce monotonicamente ",
      "em alguma tabela West."
    )
  }


  # ----------------------------------------------------------
  # 10. Cada q(x) deve diminuir com o nivel
  # ----------------------------------------------------------

  for (v in colunas_q) {

    qa <- dados[
      order(nivel),
      .(
        decrescente =
          all(
            diff(
              get(v)
            ) < 0
          )
      ),
      by = grupo
    ]


    if (any(!qa$decrescente)) {

      stop(
        "A serie ",
        v,
        " nao e monotonicamente decrescente ",
        "entre os niveis West."
      )
    }
  }


  # ----------------------------------------------------------
  # 11. Ordem acumulada por idade
  #
  # Existe uma anomalia conhecida na fonte:
  #
  # Feminino, nivel 22.
  #
  # Nenhuma outra anomalia deve ser aceita silenciosamente.
  # ----------------------------------------------------------

  anomalias <- dados[
    !(
      q1 <= q2 &
      q2 <= q3 &
      q3 <= q5 &
      q5 <= q10 &
      q10 <= q15 &
      q15 <= q20
    )
  ]


  anomalia_conhecida <-
    nrow(anomalias) == 1L &&
    anomalias$grupo[1L] == "Feminino" &&
    anomalias$nivel[1L] == 22L


  if (!anomalia_conhecida) {

    stop(
      "A estrutura Coale-Demeny apresenta ",
      "anomalias de ordem etaria diferentes ",
      "da ocorrencia conhecida no grupo ",
      "Feminino, nivel 22."
    )
  }


  # ----------------------------------------------------------
  # 12. Ordenacao canonica
  # ----------------------------------------------------------

  dados[
    ,
    grupo_ordem :=
      data.table::fcase(
        grupo == "Total", 1L,
        grupo == "Masculino", 2L,
        grupo == "Feminino", 3L
      )
  ]


  data.table::setorder(
    dados,
    grupo_ordem,
    nivel
  )


  dados[
    ,
    grupo_ordem := NULL
  ]


  dados[]
}
