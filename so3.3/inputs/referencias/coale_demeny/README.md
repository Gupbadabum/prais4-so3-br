# Tábuas-modelo Coale-Demeny — família West

Este diretório contém a referência operacional utilizada no SO3.3
para harmonizar as estimativas indiretas de mortalidade na infância
obtidas pelo método Brass-Trussell.

## Arquivo

`coale_demeny_west_qx.csv`

O arquivo contém 75 registros correspondentes a:

- 25 níveis de mortalidade;
- ambos os sexos;
- sexo masculino;
- sexo feminino.

As variáveis disponibilizadas são:

- `e0`: esperança de vida ao nascer associada ao nível da tábua-modelo;
- `q1`: probabilidade de morrer antes de completar 1 ano;
- `q2`: probabilidade de morrer antes de completar 2 anos;
- `q3`: probabilidade de morrer antes de completar 3 anos;
- `q5`: probabilidade de morrer antes de completar 5 anos;
- `q10`: probabilidade de morrer antes de completar 10 anos;
- `q15`: probabilidade de morrer antes de completar 15 anos;
- `q20`: probabilidade de morrer antes de completar 20 anos.

Além das variáveis originais, o arquivo operacional registra:

- `familia`: família da tábua-modelo (`West`);
- `sexo_modelo`: `both`, `male` ou `female`;
- `grupo`: harmonização utilizada no DVI (`Total`, `Masculino`, `Feminino`);
- `nivel`: nível de mortalidade Coale-Demeny, de 1 a 25.

## Fonte primária

United Nations. Department of International Economic and Social Affairs.
*Step-by-Step Guide to the Estimation of Child Mortality*.
Population Studies No. 107.
New York: United Nations, 1990.
ST/ESA/SER.A/107.

Fonte:
https://digitallibrary.un.org/record/129922

Para a família West foram utilizadas as tabelas:

- Table A.I.4 — West model values for male probabilities of dying, q(x);
- Table A.I.8 — West model values for female probabilities of dying, q(x);
- Table A.I.12 — West model values for probabilities of dying, q(x), both sexes combined.

## Fonte operacional da transcrição

Os valores foram extraídos do objeto `coale_demeny_ltm`
distribuído no pacote R `u5mr`, versão 0.1.1.

O pacote `u5mr` é utilizado apenas como fonte operacional para
extração e conferência das tábuas-modelo. O SO3.3 não possui
dependência de execução desse pacote.

Somente as três tábuas da família West necessárias ao método
foram incorporadas ao repositório.

## Controle de qualidade

As três séries possuem 25 níveis.

Para cada sexo/modelo:

- `e0` aumenta com o nível;
- cada série individual `q(x)` diminui com o aumento do nível;
- todas as probabilidades encontram-se no intervalo [0,1].

Foi identificada uma única inconsistência na ordenação acumulada
das probabilidades por idade:

- sexo: feminino;
- nível: 22;
- e0: 72.5;
- q1: 0.02262;
- q2: 0.02740;
- q3: 0.02575;
- q5: 0.02714;
- q10: 0.02928;
- q15: 0.03102;
- q20: 0.03386.

Nesse registro, a condição esperada

q1 <= q2 <= q3 <= q5 <= q10 <= q15 <= q20

não é satisfeita entre q2, q3 e q5.

Os valores foram preservados sem correção porque correspondem aos
valores publicados na fonte primária. A ocorrência é tratada
explicitamente como uma anomalia conhecida da tabela de referência,
e não como erro de processamento do SO3.3.

## Uso no SO3.3

A família West é utilizada como escala comum para converter as
estimativas municipais q2, q3 e q5 derivadas pelo método
Brass-Trussell em probabilidades comparáveis de mortalidade até
os cinco anos.

A síntese municipal posterior não altera este arquivo de referência.

As tábuas completas de mortalidade utilizadas para a obtenção final
da esperança de vida ao nascer são provenientes das Projeções da
População do IBGE — Revisão 2024 e constituem uma fonte independente.
