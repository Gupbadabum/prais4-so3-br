# SO3.3 — Vulnerabilidade à seca

Este diretório reúne o fluxo computacional e a documentação operacional do **SO3.3 — Trends in the degree of drought vulnerability** do PRAIS 4 para o Brasil.

## Escopo temporal e espacial

A vulnerabilidade é calculada em escala **municipal** para três recortes censitários:

- 2000;
- 2010;
- 2022.

Quando aplicável, os indicadores e o DVI são produzidos para:

- Total;
- Masculino;
- Feminino.

## Dimensões e indicadores incorporados

### Social

- Taxa de alfabetização da população de 15 anos ou mais;
- População rural (%);
- Expectativa de vida ao nascer;
- População de 15 a 64 anos (%).

### Econômica

- População abaixo da linha internacional de pobreza;
- PIB per capita;
- Agricultura, silvicultura e pesca no PIB.

### Infraestrutural

- Água potável gerida de forma segura — proxy censitária;
- Recursos hídricos renováveis per capita.

## Indicadores não operacionalizados nesta versão

- Eficiência governamental;
- População de refugiados;
- Consumo de energia per capita;
- Área cultivada equipada para irrigação.

A não operacionalização refere-se à versão atual do DVI e não impede desenvolvimento posterior.

## Arquitetura computacional

O fluxo separa explicitamente as diferenças entre fontes censitárias das regras de cálculo dos indicadores.

```text
fonte original
    |
    v
adaptador específico do recorte
    |
    v
estrutura canônica
    |
    v
funções comuns dos indicadores
    |
    v
base municipal bruta 2000 + 2010 + 2022
    |
    v
diagnóstico temporal e amostral
    |
    v
winsorização / Box-Cox
    |
    v
orientação e normalização
    |
    v
componentes das dimensões
    |
    v
DVI
```

O arquivo `main.R` atua como **orquestrador** do fluxo. A lógica detalhada permanece em arquivos específicos dentro de `R/`.

## Estrutura inicial

```text
so3.3/
├── main.R
├── README.md
├── config/
│   ├── config.R
│   └── config_local.R.example
└── R/
    ├── 01_leitura/
    │   └── adaptar_censo_2022.R
    ├── 02_indicadores/
    │   └── social.R
    └── 03_diagnostico/
        └── diagnostico_indicadores.R
```

A estrutura será ampliada conforme os blocos 2000/2010, dimensões Econômica e Infraestrutural, tratamento estatístico, normalização e agregação forem implementados.

## Microdados censitários

Os microdados brutos **não são versionados neste repositório**.

- Censos 2000 e 2010: acesso programático por meio do pacote `censobr` e das fontes disponibilizadas pelo IBGE.
- Censo 2022: microdados da amostra em modalidade de acesso controlado, disponibilizados pelo IBGE mediante protocolo próprio.

O repositório contém apenas código, metadados operacionais e resultados agregados compatíveis com as condições de uso das fontes.

## Censo 2022 — estado atual

O adaptador inicial utiliza, no registro de Pessoas:

- `P0080` — Município;
- `P0111` — Peso amostral do acesso controlado;
- `P0140` — Situação urbana/rural;
- `P0160` — Sexo;
- `P0181` — Idade calculada em anos;
- `P0640` — Alfabetização.

Os três primeiros indicadores sociais diretos implementados são:

- `SOC01_ALF15` — taxa de alfabetização da população 15+;
- `SOC02_RURAL` — percentual da população rural;
- `SOC04_POP1564` — percentual da população de 15 a 64 anos.

Além dos valores municipais ponderados, são preservados `n_amostra` e `n_efetivo` para diagnóstico de possíveis extremos e avaliação da robustez amostral antes de qualquer tratamento estatístico.

## Tratamento temporal

A winsorização e a transformação Box-Cox serão avaliadas somente após a consolidação dos três recortes censitários. O tratamento será realizado com os anos combinados dentro de cada indicador, mantendo separação entre os grupos Total, Masculino e Feminino.


## Execução por dimensão + ano

A unidade operacional do processamento é uma combinação de dimensão e ano. Isso reduz o uso de memória e evita manter múltiplos censos e objetos intermediários simultaneamente na sessão.

Exemplo de chamada:

    DIMENSAO_ATIVA <- "social"
    ANO_ATIVO <- 2010L
    source("so3.3/main.R")

Para 2010, o Censo é mantido como Arrow Dataset e apenas uma UF é materializada por vez. Após o cálculo dos resultados municipais, os microdados da UF são removidos da memória.

Os resultados são gravados em checkpoints sob outputs/bruto/<dimensao>/<ano>/ e outputs/intermediario/<dimensao>/<ano>/. O tratamento estatístico temporal continua separado: winsorização e Box-Cox só devem ser avaliadas depois que 2000, 2010 e 2022 estiverem reduzidos a bases municipais.