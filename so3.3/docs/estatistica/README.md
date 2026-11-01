# SO3.3 — Diagnóstico estatístico dos indicadores brutos (Bloco A)

**Estado:** primeira implementação pública do diagnóstico conjunto, iniciando pela dimensão Social e pelo indicador SOC01. **Nenhuma transformação aprovada ou aplicada nesta etapa.**

## 1. Escopo e princípio metodológico

A unidade de avaliação é **indicador × grupo populacional**, considerando conjuntamente as observações municipais de **2000, 2010 e 2022**. Cada série utiliza somente os valores do seu próprio indicador. Não existe compartilhamento de percentis, limiares, Box–Cox ou limites de normalização entre indicadores diferentes.

Para SOC01, SOC02, SOC03, SOC04, ECO01 e INF01 são avaliadas três séries independentes: **Total, Masculino e Feminino**. Para ECO02, ECO03 e INF02, atributos territoriais replicados nos três grupos, utiliza-se **uma única série Compartilhado**; os registros não são triplicados.

Os anos são reunidos para o diagnóstico conjunto; as saídas anuais são **apenas descritivas** e não representam parâmetros calculados ano a ano. Cada observação município–ano recebe o mesmo peso na descrição estatística, sem ponderação populacional. Isso não equivale a uma estimativa de média nacional populacional nem demonstra independência entre municípios/períodos.

As relações diretas e inversas permanecem definidas no **PRAIS4**; sua aplicação ocorrerá em etapa própria. Nenhum indicador ou dimensão, isoladamente, corresponde a uma medida de vulnerabilidade à seca.

## 2. Interface pública e reprodução

Executar sempre a partir da raiz do repositório:

```bash
Rscript so3.3/tests/testar_estatistica_brutos.R
Rscript so3.3/executar_diagnostico_estatistico.R social SOC01_ALF15
```

A primeira chamada testa as regras de separação por grupo e os CSVs SOC01, quando disponíveis; a segunda produz o diagnóstico do SOC01. Para realizar o diagnóstico dos quatro indicadores da dimensão Social:

```bash
Rscript so3.3/executar_diagnostico_estatistico.R social todos
```

A mesma interface admite as outras dimensões (por exemplo, `economica ECO02_PIBPC` ou `infraestrutural INF02_RECURSOS_HIDRICOS_PC`) quando os respectivos CSVs estiverem presentes. **Ainda não constitui aprovação estatística dessas dimensões.**

No RStudio, também é possível usar:

```r
source("so3.3/executar_diagnostico_estatistico.R")
```

Sem argumentos, a execução utiliza exclusivamente `social SOC01_ALF15`.

Dependência: **R base**. A rotina lê os arquivos municipais `so3.3/outputs/bruto/<dimensao>/<ano>/<indicador>_<ano>.csv`, com separador `;`. Não acessa microdados censitários nem refaz qualquer cálculo dos indicadores.

As funções reutilizáveis encontram-se em:

- [`R/03_diagnostico/estatistica_brutos_conjuntos.R`](../../R/03_diagnostico/estatistica_brutos_conjuntos.R): catálogo, leitura validada, separação de séries, estatísticas, extremos, gravação e diagnóstico.
- [`executar_diagnostico_estatistico.R`](../../executar_diagnostico_estatistico.R): interface por dimensão e indicador.
- [`tests/testar_estatistica_brutos.R`](../../tests/testar_estatistica_brutos.R): testes sintéticos e regressão opcional com SOC01.

É possível importar apenas as funções, sem disparar a execução:

```r
source("so3.3/R/03_diagnostico/estatistica_brutos_conjuntos.R")
resultado <- estat_so33_diagnosticar("SOC01_ALF15", dir_saida = NULL)
print(resultado$estatisticas_conjuntas)
```

## 3. Produtos

Cada execução grava um diretório novo sob:

`so3.3/outputs/intermediario/estatistica/diagnostico/<dimensao>/<indicador>/<AAAAMMDDThhmmss>/`

Os arquivos são:

| Arquivo | Finalidade |
| --- | --- |
| `01_inventario.csv` | Fontes, MD5, quantidade de municípios e ausências |
| `02_estatisticas_conjuntas.csv` | Estatísticas e quantis **dos três anos reunidos por série** |
| `03_descritivas_anuais.csv` | Evolução descritiva por ano, **sem limiares anuais** |
| `04_extremos_inspecao.csv` | Municípios nos extremos inferior e superior, somente para inspeção |
| `05_status_INF02.csv` | Quando aplicável, frequência de status e ressalvas do INF02 |
| `LEIA_ME.txt` / `sessao_R.txt` | Condições de execução e ambiente R |

A rotina valida o contrato dos CSVs, cardinalidade territorial, os três grupos, chaves município–ano–grupo, valores numéricos, percentuais fisicamente delimitados e a identidade dos atributos territoriais compartilhados. Para INF02, preserva as ausências e verifica a correspondência com o estado de cálculo. Não força valores ausentes para zero; não corta ECO03 em 100%.

As **cercas de Tukey** e os extremos são exclusivamente diagnósticos. Não são limites aprovados para winsorização. O campo `boxcox_sem_deslocamento_admissivel` indica apenas se existem zeros/negativos que impedem a Box–Cox convencional, não recomenda a transformação.

**Não publicar automaticamente** os diretórios de diagnóstico nem detalhes municipais derivados de dados sujeitos a condições de divulgação: conferir as regras aplicáveis às fontes do IBGE antes de tornar esses resultados públicos. Os arquivos de código e a documentação são públicos; os dados permanecem nos diretórios locais pertinentes.

## 4. Próximas decisões, ainda não implementadas

Após interpretação e aprovação do diagnóstico Social, serão documentados **por indicador e por grupo populacional**:

1. Necessidade e limites de winsorização, quando justificáveis.
2. Necessidade e parâmetro de transformação (incluindo a escolha fundamentada de não transformar).
3. Referências de normalização para [0,1], constantes nos três anos de cada série.
4. Orientação já estabelecida pelo manual PRAIS4.
5. Testes de sensibilidade, rastreabilidade e validação de cada fase.

Os futuros módulos de transformação utilizarão parâmetros explícitos e próprios de cada série; **não serão aplicados durante o Bloco A**. Os produtos brutos permanecem imutáveis.
