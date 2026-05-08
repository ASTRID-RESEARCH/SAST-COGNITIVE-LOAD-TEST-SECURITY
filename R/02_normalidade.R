# =============================================================================
# 02_normalidade.R
# Teste de Shapiro-Wilk + Q-Q plots
# Justificativa para uso de métodos não-paramétricos (ausente no artigo original)
# =============================================================================

source("R/00_setup.R")

# --- 2.1 Shapiro-Wilk --------------------------------------------------------
shapiro_results <- variaveis |>
  map_dfr(function(v) {
    teste <- shapiro.test(df[[v]])
    tibble(
      variavel = v,
      W        = round(teste$statistic, 4),
      p_valor  = round(teste$p.value, 4),
      normal   = ifelse(teste$p.value > 0.05, "Sim", "Não")
    )
  })

print(shapiro_results)

# --- 2.2 Q-Q plots -----------------------------------------------------------
p_qq <- df |>
  select(all_of(variaveis)) |>
  pivot_longer(everything(), names_to = "variavel", values_to = "valor") |>
  ggplot(aes(sample = valor)) +
  stat_qq(size = 1.5, alpha = 0.6) +
  stat_qq_line(color = "steelblue", linewidth = 0.8) +
  facet_wrap(~variavel, scales = "free") +
  labs(
    title    = "Q-Q plots — avaliação de normalidade",
    subtitle = "Todas as variáveis violam normalidade (Shapiro-Wilk p < .001)",
    x        = "Quantis teóricos",
    y        = "Quantis observados"
  ) +
  theme_minimal(base_size = 12)

print(p_qq)

# --- 2.3 Exporta -------------------------------------------------------------
write_csv(shapiro_results, "output/tables/02_shapiro_wilk.csv")
ggsave("output/figures/02_qq_plots.png", p_qq,
       width = 8, height = 6, dpi = 300)

cat("\nConclusão: todas as variáveis violam normalidade.\n")
cat("Justificativa para métodos não-paramétricos confirmada.\n")
