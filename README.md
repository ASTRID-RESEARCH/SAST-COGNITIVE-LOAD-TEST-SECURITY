# SAST Think-Aloud — Análises Estatísticas  

## Estrutura

```
sast-thinkaloud-analysis/
├── data/
│   └── Data_thinkaloud.csv       # Dados brutos do experimento
├── R/
│   ├── 00_setup.R                # Instalação de pacotes e leitura
│   ├── 01_descritivo.R           # Estatística descritiva
│   ├── 02_normalidade.R          # Shapiro-Wilk + Q-Q plots
│   ├── 03_spearman.R             # Correlações de Spearman
│   ├── 04_friedman.R             # Friedman + pós-hoc Wilcoxon
│   ├── 05_mann_whitney.R         # Mann-Whitney U + tamanho de efeito
│   ├── 06_lmm.R                  # Modelo linear misto (lme4)
│   └── 07_gee_logistico.R        # GEE logístico (geepack)
├── output/
│   ├── figures/                  # Gráficos gerados (.png)
│   └── tables/                   # Tabelas exportadas (.csv)
├── analysis_complete.R           # Script único consolidado
└── README.md
```

## Questão de Pesquisa

**RQ1:** Quais são as principais barreiras que testadores novatos enfrentam ao
interpretar relatórios de ferramentas SAST (SonarQube) em cenários de
vulnerabilidades conforme o OWASP Top 10?

## Variáveis

| Variável | Tipo | Escala | Papel |
|---|---|---|---|
| Dificuldade | Ordinal | Likert 0–10 | Desfecho principal (carga cognitiva) |
| Esforço | Ordinal | Likert 0–10 | Preditor / carga intrínseca |
| Interpretação | Ordinal | Likert 0–10 | Preditor |
| Confiança | Ordinal | Likert 0–10 | Preditor |
| Desempenho | Binária | 0 = errou, 1 = acertou | Desfecho (GEE) |
| Issue | Fator | IS01–IS08 | Fator de agrupamento |
| Participante | Fator | P01–P12 | Efeito aleatório |

## Sequência de Análises

| Passo | Script | Método | Justificativa |
|---|---|---|---|
| 1 | `01_descritivo.R` | Mediana + IQR | Variáveis ordinais |
| 2 | `02_normalidade.R` | Shapiro-Wilk | Pressuposto para escolha não-paramétrica |
| 3 | `03_spearman.R` | Correlação de Spearman | Não-normalidade confirmada |
| 4 | `04_friedman.R` | Friedman + Wilcoxon/Holm | Medidas repetidas, comparação entre issues |
| 5 | `05_mann_whitney.R` | Mann-Whitney U + rank-biserial r | Grupos independentes (correto × errado) |
| 6 | `06_lmm.R` | Modelo Linear Misto (lme4) | Preditor de Dificuldade com efeito aleatório |
| 7 | `07_gee_logistico.R` | GEE Binomial (geepack) | Preditor de Desempenho (outcome binário) |

## Pacotes R

```r
c("tidyverse", "lme4", "lmerTest", "geepack",
  "rstatix", "coin", "effectsize", "broom.mixed")
```

## Reprodução

```r
# Executa toda a análise de uma vez
source("analysis_complete.R")

# Ou passo a passo
source("R/00_setup.R")
source("R/01_descritivo.R")
# ...
```

## Dados

- **n = 96 observações** (12 participantes × 8 issues)
- Todos os participantes classificados como noviços (frequência ≤ mensal + autoavaliação 1–2)

## Uso de Inteligência Artificial

Este repositório foi montado com com auxilio de Inteligência Artificial Generativa no que tange a organização dos scripts, construção da documentação e comentários no código para facalitar a compressão dos passos dados. Os autores analisaram criticamente a organização e manipulação do arquivos, averiguando se houve alteração na lógica estatistica do código.
