# PRAIS4 Brasil — Reprodutibilidade computacional

**Estado em 05/11/2026:** inventario das dependencias encontradas no codigo versionado, preparado apos a revisao tecnica dos procedimentos e READMEs informada para 03/11/2026. **Este documento nao atesta reproducao integral independente nem substitui um ambiente congelado.**

O codigo e a documentacao vivem neste repositorio; parte dos dados de entrada e dos produtos raster volumosos e mantida em ambientes operacionais externos. Cada modulo possui condicoes proprias de execucao.

## Dependencias por modulo

| Modulo | Ambiente | Manifesto ou orientacao |
| --- | --- | --- |
| [SO3.1 — Ameaca](so3.1/README.md) | Python e bibliotecas geoespaciais; leitura NetCDF | [so3.1/requirements.txt](so3.1/requirements.txt) |
| [SO3.2 — Exposicao](so3.2/README.md) | Python, Google Colab/Drive, Google Earth Engine; `wget` para transferencia | [so3.2/requirements.txt](so3.2/requirements.txt) |
| [SO3.3 — Vulnerabilidade](so3.3/README.md) | R; bibliotecas tabulares, censitarias, estatisticas e geoespaciais | [so3.3/DEPENDENCIAS_R.md](so3.3/DEPENDENCIAS_R.md) |

Os dois arquivos `requirements.txt` registram as bibliotecas Python identificadas, **sem fixar versoes**. `so3.3/DEPENDENCIAS_R.md` apresenta o inventario R, tambem sem versoes congeladas. Sao listas de preparacao de ambiente, nao evidencias de replicacao bit a bit.

## SO3.1 — Execucao Python

Para preparar um ambiente local a partir da raiz:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r so3.1/requirements.txt
```

O arquivo de dependencias inclui um backend `netCDF4` **sugerido** para leitura dos arquivos `.nc` por `xarray`; ainda deve ser conferido com os dados originais.

**Limite conhecido:** `so3.1/gerar_mapas_spei12.py` define `INPUT_DIR` e `SHAPEFILE` como caminhos absolutos do ambiente em que foi desenvolvido. Para executar em outra maquina, sera necessario ajustar esses caminhos no script ou adaptar a configuracao em uma revisao futura. O script quadrianual `gerar_mapas_spei12_maximos_4anos.py` ja recebe `--input-dir`, `--output-dir` e `--shapefile`. Os arquivos de entrada precisam estar disponiveis e corresponder as fontes/metodologia documentadas.

## SO3.2 — Python e GEE

Para o processamento Python local, em ambiente separado do SO3.1:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r so3.2/requirements.txt
python so3.2/scripts/05_build_population.py --help
```

A ultima linha apenas apresenta os argumentos de um script; nao executa o processamento dos rasters. O modulo de transferencia de arquivos invoca o executavel externo `wget`, que precisa estar instalado e acessivel no sistema quando essa etapa for utilizada.

Os notebooks concebidos para **Google Colab** usam `google.colab` e a montagem do Google Drive. Os scripts `so3.2/scripts/gee/*.js` sao destinados ao **Google Earth Engine Code Editor**, nao ao Node.js. Reproduzir essas etapas requer conta autorizada, projeto GEE configurado, permissao para os assets envolvidos, quotas e acesso aos insumos e destinos de exportacao. A API do Earth Engine e seu servico remoto nao ficam congelados por um arquivo pip.

### Versoes observadas em um notebook

O historico de saida armazenado em `so3.2/notebooks/00_setup_environment.ipynb` registra:

| Componente | Valor observado |
| --- | --- |
| Python | `3.13.15` |
| NumPy | `2.1.3` |
| Pandas | `2.2.3` |
| Earth Engine API | `1.7.39` |

**Nao extrapolar:** esses valores sao evidencias de **uma sessao do notebook**, nao uma especificacao validada de todos os ambientes ou de todos os produtos SO3.2. As demais dependencias e versoes de sistema nao foram recuperadas integralmente.

## SO3.3 — Execucao R

Os pacotes e as instrucoes de preparacao estao em [so3.3/DEPENDENCIAS_R.md](so3.3/DEPENDENCIAS_R.md).

O ponto de entrada `so3.3/main.R` deve ser executado a partir da raiz do repositorio, apos a definicao da dimensao e do ano. Os caminhos locais podem ser ajustados com o exemplo `so3.3/config/config_local.R.example` sem versionar credenciais ou configuracoes especificas da maquina. A instalacao das bibliotecas nao garante, por si so, a disponibilidade dos insumos e intermediarios necessarios a cada etapa.

## O que falta para uma reproducibilidade integral

1. Recuperar de cada ambiente efetivamente validado as versoes completas (Python: `python --version` e `python -m pip freeze`; R: `sessionInfo()`, versoes dos pacotes e bibliotecas geoespaciais).
2. Registrar sistema operacional, versoes de GDAL/GEOS/PROJ, quando aplicavel, e particularidades do ambiente Colab/GEE.
3. Identificar entradas, versoes das fontes, permissoes de acesso, configuracoes, periodos e verificacoes de integridade (hashes) para cada produto publicado.
4. Reexecutar testes e confrontar resultados obtidos com os produtos versionados; so entao considerar um `renv.lock`, lockfiles Python ou imagens de ambiente de referencia.

O registro de uma **GitHub Release** e seu arquivamento no Zenodo devem ocorrer apenas quando o conjunto escolhido estiver definido e verificado; a questao do licenciamento segue tratada separadamente. Os metadados de autoria do software estao em [CITATION.cff](CITATION.cff).
