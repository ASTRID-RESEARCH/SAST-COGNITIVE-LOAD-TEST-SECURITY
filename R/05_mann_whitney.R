# =============================================================================
# 05_mann_whitney.R
# Mann-Whitney U: corretos × errados em cada variável cognitiva
# CORRIGIDO — artigo original reportou apenas Confiança
# Inclui tamanho de efeito rank-biserial r
# =============================================================================

source("R/00_setup.R")

df_num <- df |> mutate(acerto = as.numeric(Desempenho == "Correto"))

# --- 5.1 Teste para todas as variáveis + effect size -------------------------
mw_results <- variaveis |>
  map_dfr(function(v) {
    correto <- df_num[df_num$acerto == 1, v, drop = TRUE]
    errado  <- df_num[df_num$acerto == 0, v, drop = TRUE]

    teste <- wilcox.test(correto, errado, exact = FALSE)
    r     <- rank_biserial(correto, errado)

    tibble(
      variavel    = v,
      med_correto = median(correto),
      IQR_correto = IQR(correto),
      med_errado  = median(errado),
      IQR_errado  = IQR(errado),
      U           = round(teste$statistic, 0),
      p           = round(teste$p.value, 3),
      r_rb        = round(r$r_rank_biserial, 3),
      magnitude   = r$interpret,
      sig         = ifelse(teste$p.value < .05, "*", "ns")
    )
  })

print(mw_results)

# --- 5.2 Exporta -------------------------------------------------------------
write_csv(mw_results, "output/tables/05_mann_whitney.csv")
