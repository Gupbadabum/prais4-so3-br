# SO3.3 — Dimensão Infraestrutural

**PRAIS_BRASIL | Documentação conceitual, metodológica e operacional dos indicadores municipais**  
**Referência do projeto:** *Performance Review and Assessment of Implementation System* (PRAIS), Objetivo Estratégico 3 (SO3), produto SO3.3.  
**Estado do documento:** proposta para revisão técnica — outubro de 2026.  
**Localização proposta:** `so3.3/docs/infraestrutural/README.md`.

> **Delimitação.** Este documento descreve a dimensão Infraestrutural e a construção dos seus indicadores **brutos**. O `INF01_REDE_CANALIZADA` foi concluído e integrado ao `main.R` para 2000, 2010 e 2022. O `INF02`, relativo aos recursos hídricos renováveis per capita, possui desenvolvimento independente e ainda não é apresentado aqui como produto concluído. Tratamento estatístico, normalização, ponderação e composição do DVI são etapas posteriores. A presença de infraestrutura de água, isoladamente, **não é medida de segurança hídrica nem de vulnerabilidade à seca**.

## 1. Apresentação da dimensão

A dimensão Infraestrutural reúne informações sobre condições materiais e disponibilidade de recursos associados ao acesso à água. No contexto do SO3.3, tais condições são consideradas componentes da representação multidimensional da vulnerabilidade à seca. A infraestrutura de abastecimento pode influenciar as circunstâncias em que populações enfrentam períodos de deficiência hídrica, mas sua existência não garante continuidade, qualidade ou suficiência da oferta durante uma seca.

A escala de produção dos indicadores é **municipal**, com recortes de referência **2000, 2010 e 2022**. A utilização dos grupos **Total, Masculino e Feminino** depende da natureza e da fonte de cada variável: informações associadas diretamente às pessoas permitem estimativas diferenciadas; atributos exclusivamente territoriais não devem ser interpretados como desagregações efetivas por sexo.

### 1.1. Composição operacional

| Código | Indicador | Unidade | Natureza | Situação |
|---|---|---|---|---|
| `INF01_REDE_CANALIZADA` | População residente em DPP com abastecimento principal pela rede geral e água canalizada internamente | % | Condição domiciliar atribuída à população residente; Total, Masculino e Feminino | **Concluído**: 2000, 2010 e 2022; produção bruta e integração ao `main.R` aprovadas |
| `INF02` | Recursos hídricos renováveis per capita | A documentar com a especificação definitiva | Atributo territorial associado à disponibilidade hídrica | Desenvolvimento metodológico e computacional independente; não concluído neste documento |

A dimensão não corresponde à soma simples desses dois indicadores. Direção, transformações, normalização e agregação serão tratadas no fluxo de composição do DVI.

## 2. INF01 — Acesso à rede geral com canalização interna

### 2.1. Definição operacional

O **INF01** é o percentual de moradores de **domicílios particulares permanentes ocupados (DPP)** cujo abastecimento **principal** de água ocorre pela **rede geral de distribuição** e que possuem **canalização de água dentro da habitação**, segundo as categorias correspondentes de cada Censo Demográfico.

A condição de atendimento requer os dois atributos simultaneamente. Assim, permanecem fora do numerador os moradores de DPP que utilizam outra fonte principal, ainda que exista acesso à rede geral, e aqueles abastecidos principalmente pela rede geral sem a condição de canalização estabelecida no indicador. Domicílios improvisados e coletivos não integram o universo do denominador.

O INF01 representa **cobertura populacional por uma combinação específica de infraestrutura**. Não mede diretamente potabilidade, intermitência do serviço, pressão da rede, consumo, qualidade, segurança hídrica, capacidade adaptativa ou impacto observado de seca.

### 2.2. Formulação matemática

Para município \(m\), ano censitário \(t\) e grupo populacional \(g\):

$$
INF01_{m,t,g}=100\times
\frac{\sum_{d\in DPP_{m,t}} w_d\,N_{d,g}\,I_d}
{\sum_{d\in DPP_{m,t}} w_d\,N_{d,g}},
$$

em que \(w_d\) é o peso do domicílio, \(N_{d,g}\) é o número de moradores pertencentes ao grupo \(g\) e \(I_d\) vale 1 quando o domicílio tem simultaneamente rede geral como fonte principal **e** canalização interna, e 0 caso contrário.

Para 2010 e 2022, o cálculo principal é realizado nos registros de Pessoas, após vinculação às características domiciliares:

$$
INF01_{m,t,g}=100\times
\frac{\sum_{i\in P^{DPP}_{m,t}} w_i\,G_{i,g}\,I_{d(i)}}
{\sum_{i\in P^{DPP}_{m,t}} w_i\,G_{i,g}},
$$

onde \(w_i\) é o peso individual, \(G_{i,g}\) indica pertencimento ao grupo e \(d(i)\) é o domicílio da pessoa. O estimador individual é reconciliado com o estimador domiciliar. Em todos os anos, o valor nacional resulta da **razão entre somas nacionais de numeradores e denominadores**, não da média simples dos percentuais municipais.

### 2.3. Fontes e correspondência das variáveis

Os dados provêm da **amostra dos Censos Demográficos do IBGE**. Para 2000 e 2010, a implementação utiliza o pacote R `censobr`; para 2022, utiliza microdados da amostra em modalidade **de acesso controlado**.

| Informação | 2000 — Domicílios | 2010 — Domicílios/Pessoas | 2022 — Domicílios/Pessoas |
|---|---|---|---|
| Seleção de DPP | `V0201 = 1` | `V4001 = 1` | `D0130 = 1` |
| Rede geral como principal fonte | `V0207 = 1` | `V0208 = 1` | `D0260 = 1` |
| Canalização segundo o critério operacional | `V0208 = 1` | `V0209 = 1` | `D0300 = 1` |
| Total de moradores para auditoria ou cálculo | `V7100` | `V0401` | `D0150` |
| Sexo e desagregação | `V0110` / `V0111` (contagens domiciliares) | `V0601` (Pessoas) | `P0160` (Pessoas) |
| Peso utilizado | `P001` (domiciliar) | `V0010` (individual; reconciliado com domicílios) | `P0111` (individual; reconciliado com `D0111`) |
| Chave domiciliar quando aplicável | Não necessária para o cálculo | Município + `V0300` | `D0080`/`P0080` + `D0100`/`P0100` |
| Código municipal de agregação | `code_muni`, com controle de `V0103` | `code_muni`, com controle de `V0002` | `D0080`/`P0080` |

**Particularidade de 2022.** A variável `D0290` identifica acesso à rede geral quando ela não é a principal forma de abastecimento e **não integra o numerador**. A categoria `D0300 = 1` também inclui canalização até banheiro externo de uso exclusivo, segundo a classificação censitária. Essa particularidade deve acompanhar qualquer interpretação comparativa entre anos; equivalência operacional não implica identidade literal de questionários.

### 2.4. Estimadores por ano

**2000 — estimador domiciliar.** A amostra de Domicílios fornece, para cada DPP, o peso `P001`, o total de moradores `V7100` e as contagens de moradores masculinos `V0110` e femininos `V0111`. Esses componentes são agregados por município. O código municipal harmonizado disponível no `censobr` é conferido contra a identificação censitária original.

**2010 — estimador individual com auditoria domiciliar.** Os arquivos de Pessoas e Domicílios são vinculados pelo município e pelo controle `V0300`. São verificados unicidade da chave, correspondência integral, contagem de moradores e igualdade dos pesos. A apuração por Pessoas é reconciliada com aquela derivada de contagens domiciliares para os seis componentes municipais.

**2022 — estimador individual com auditoria domiciliar.** A vinculação utiliza os códigos de município e os controles domiciliares originais. No piloto da UF 11, foi verificada correspondência integral dos registros de Pessoas e Domicílios, sem normalização adicional das chaves. Os pesos `P0111` e `D0111`, as contagens `D0150` e os seis componentes foram reconciliados; o procedimento foi então ampliado para todas as UFs.

Os pesos originais são preservados. Não se aplica imputação de condições de abastecimento, recálculo arbitrário de fatores de expansão ou correção automática de valores. Denominadores iguais a zero implicam percentual indefinido (`NA`); numeradores iguais a zero são mantidos quando o denominador é válido e positivo.

### 2.5. Componentes preservados

Cada município dispõe dos componentes `numerador_total`, `denominador_total`, `numerador_masculino`, `denominador_masculino`, `numerador_feminino` e `denominador_feminino`. Os controles verificam:

$$
D_{Total}=D_{Masculino}+D_{Feminino},\qquad
N_{Total}=N_{Masculino}+N_{Feminino},
$$

com tolerâncias numéricas compatíveis com os pesos expandidos. O resultado Total é calculado com seu próprio denominador; não é a média simples dos percentuais por sexo.

## 3. Validação e resultados aprovados

A construção foi submetida a inventário das variáveis, verificação de chaves e pesos, pilotos ponderados, auditoria dos seis componentes, consolidação nacional, comparação com checkpoints e execução de produção. Os produtos nacionais e a integração no `main.R` estão aprovados para os três recortes.

| Ano | UFs | Municípios | Registros município–grupo | Validação externa |
|---|---:|---:|---:|---|
| 2000 | 27 | 5.507 | 16.521 | Confronto municipal com a Tabela SIDRA 2420 aprovado para o grupo Total |
| 2010 | 27 | 5.565 | 16.695 | Não realizada; a aprovação computacional não foi condicionada a essa comparação |
| 2022 | 27 | 5.570 | 16.710 | Comparação exploratória com a Tabela SIDRA 6909, **com ressalva na extração dos valores absolutos** |

Em 2000 foram preservados **87 municípios** com numerador Total igual a zero; em 2022, **9 municípios**. Não se utilizou a presença de numerador zero como justificativa automática para exclusão territorial.

### 3.1. Resultados nacionais disponíveis

| Ano | INF01 Brasil — Total | Observação |
|---|---:|---|
| 2000 | **70,30778%** | Produção nacional e confronto SIDRA aprovados |
| 2010 | Consultar o QA nacional aprovado | Não transcrever valor nacional sem recuperar a saída de produção |
| 2022 | **81,84727%** | Produção nacional e integração aprovadas |

Para 2022, os valores expandidos foram aproximadamente **202.112.874 moradores em DPP** (denominador) e **165.423.875 moradores atendidos** (numerador). O denominador estimado difere em aproximadamente **0,0148%** do total nacional de **202.083.020 moradores em DPP** publicado pelo IBGE para o universo censitário.

### 3.2. Ressalva relativa ao diagnóstico externo de 2022

A consulta utilizada à Tabela 6909 apresentou diferenças percentuais municipais reduzidas frente ao INF01 calculado (erro absoluto médio de **0,7368 ponto percentual**; correlação de Pearson de **0,998789**). Entretanto, auditoria complementar mostrou que a soma dos denominadores extraídos correspondia exatamente ao dobro do total publicado pelo IBGE (**404.166.040**, contra **202.083.020**). A causa da duplicação na consulta não foi estabelecida.

Por esse motivo, **a extração não foi aceita para validação dos totais absolutos**. A concordância dos percentuais é registrada como evidência exploratória, **não como validação externa integral**. Não houve correção por divisão automática, alteração de microdados ou reprocessamento do INF01. O produto de produção de 2022 conserva, por isso, `validacao_externa = "PENDENTE"` no QA original; a documentação acrescenta a ressalva do diagnóstico posterior.

## 4. Implementação computacional e execução

A implementação separa os componentes de **leitura/adaptação**, **cálculo**, **diagnóstico**, **execução** e **exportação** em `so3.3/R/01_leitura/` a `so3.3/R/05_exportacao/`. A função comum `montar_inf01_municipal()` padroniza os campos e percentuais. Em 2010 e 2022, a promoção reutiliza diretamente os resultados municipais aprovados dos Testes 12 e 18, respectivamente, evitando recalcular percentuais a partir de outros arquivos CSV de componentes.

Os três processadores são chamados por `so3.3/main.R`, mediante configuração de dimensão e ano:

```r
DIMENSAO_ATIVA <- "infraestrutural"
ANO_ATIVO <- 2022L  # ou 2000L / 2010L
FORCAR_RECALCULO <- FALSE
source("so3.3/main.R")
print(resultado_execucao$status)
print(resultado_execucao$qa)
```

**Escopo do dispatcher:** atualmente, essa chamada executa **somente o INF01**, não a dimensão Infraestrutural completa. A reutilização dos resultados brutos aprovados foi confirmada nas execuções integradas dos três recortes. Reprocessamento destrutivo e sobrescrita silenciosa de arquivos divergentes são bloqueados.

### 4.1. Contrato dos produtos

Os resultados brutos são gravados em `so3.3/outputs/bruto/infraestrutural/{ano}/`, com arquivos `INF01_REDE_CANALIZADA_{ano}.rds` e `.csv`.

O **RDS** mantém `ano`, `uf`, `cod_mun`, `dimensao`, `indicador`, `grupo`, `valor`, `numerador` e `denominador`. O **CSV** adota o contrato:

```text
ano;uf;cod_mun;nm_mun;indicador;grupo;valor
```

Os nomes municipais são associados a uma referência do IBGE de 2025 para identificação nominal e **não** representam harmonização histórica dos limites municipais. Os diretórios de resultados intermediários preservam auditorias e checkpoints, mas não devem ser confundidos com dados brutos versionáveis no Git.

## 5. Limitações e cuidados de interpretação

- **Acesso não equivale a segurança hídrica.** A existência de rede geral e canalização não garante regularidade, potabilidade, suficiência ou disponibilidade do serviço durante uma seca.
- **Amostragem.** Os percentuais derivam dos microdados amostrais. A validação computacional não constitui estimativa de variância e não fornece, por si, intervalos de confiança municipais.
- **Equivalência operacional, não identidade literal.** As categorias censitárias e a forma de observar a canalização possuem particularidades por ano, inclusive no Censo 2022.
- **Comparabilidade territorial.** Os municípios dos três recortes não constituem necessariamente uma malha fixa; análises longitudinais exigem compatibilização territorial específica. O código municipal de sete dígitos, isoladamente, não prova invariância dos limites.
- **Zeros amostrais.** Numerador zero não prova inexistência física da infraestrutura em todo o município.
- **Acesso controlado em 2022.** Os microdados, checkpoints e resultados derivados devem permanecer no ambiente autorizado, com divulgação submetida às regras aplicáveis de confidencialidade. A existência de um CSV municipal não implica autorização automática para publicá-lo em repositório público.

## 6. Relação com as etapas posteriores do DVI

O INF01 bruto mede **acesso**: valores elevados indicam maior cobertura pelo critério operacional. Sua contribuição à vulnerabilidade tem **orientação inversa** e será tratada somente no fluxo posterior de orientação e normalização do DVI. O processamento bruto **não** aplica winsorização, Box-Cox, pesos dimensionais ou classes de vulnerabilidade.

A integração com o INF02 e a construção da dimensão Infraestrutural deverão ocorrer somente após a conclusão e validação próprias desse segundo indicador e da definição comum de tratamento e agregação.

## 7. Rastreabilidade e referências

**Código versionado:** `so3.3/main.R` e os módulos de `so3.3/R/` com prefixo `inf01` ou responsabilidade explícita pelo INF01.  
**Evidências principais:** Testes 01–08 (2000), 09–12 e diagnóstico 14 (2010), 15–19 e auditoria complementar 19B (2022).  
**Fontes:** IBGE — Censos Demográficos de 2000, 2010 e 2022; dicionários e notas metodológicas da amostra censitária; SIDRA, Tabelas 2420 e 6909, utilizadas nas condições descritas acima.

### Situação do desenvolvimento

| Componente | Situação |
|---|---|
| INF01 — definição e construção dos três recortes | **Concluído** |
| INF01 — validação computacional nacional | **Aprovada** |
| INF01 — produção bruta e integração ao `main.R` | **Aprovadas** |
| INF01 — comparação externa | Diferenciada por ano; ressalva registrada para 2022 |
| INF02 — recursos hídricos renováveis per capita | **Desenvolvimento independente, ainda não encerrado aqui** |
| Tratamento, normalização e agregação da dimensão | **Etapas posteriores** |

---

*Proposta documental para revisão. Não constitui publicação automática nem substitui as condições de uso dos dados de origem.*
