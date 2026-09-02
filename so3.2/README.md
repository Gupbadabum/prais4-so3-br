```markdown
# SO3.2 — Exposição da população à seca

Este diretório reúne os procedimentos computacionais e a documentação
referentes ao cálculo da exposição da população à seca no âmbito do
PRAIS 4 — Brasil.

## Objetivo

Quantificar a população exposta às diferentes classes de intensidade de seca,
considerando as desagregações de:

- população total;
- população feminina;
- população masculina.

## Dados principais

### Ameaça

Os dados de ameaça são provenientes do SO3.1 e consistem em GeoTIFFs anuais
do SPEI-12 de dezembro, previamente classificados.

Resolução espacial original:

- 0,1° × 0,1°.

Classes:

| Valor | Classe |
|---:|---|
| 1 | Seca extrema |
| 2 | Seca severa |
| 3 | Seca moderada |
| 4 | Seca fraca |
| 5 | Normal |

O SO3.2 utiliza esses produtos como entrada e não recalcula o SPEI-12.

### População

A base populacional será derivada do WorldPop, com processamento apoiado
pelo Google Earth Engine.

## Ambiente computacional

O processamento do SO3.2 será desenvolvido principalmente utilizando:

- Python;
- Google Colab;
- Google Earth Engine;
- Google Drive.

## Organização

Os notebooks serão incorporados progressivamente conforme as etapas
metodológicas forem desenvolvidas e validadas.
