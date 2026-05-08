# =============================================================================
# 04_friedman.R
# Teste de Friedman + pós-hoc Wilcoxon com correção Holm
# NOVO — ausente no artigo original
# Compara as 8 issues em cada variável cognitiva (medidas repetidas)
# =============================================================================

source("R/00_setup.R")

# --- 4.1 Friedman para cada variável -----------------------------------------
friedman_results <- variaveis |>
  map_dfr(function(v) {
    mat <- df |>
      select(Participante, Issue, valor = all_of(v)) |>
      pivot_wider(names_from = Issue, values_from = valor) |>
      select(-Participante) |>
      as.matrix()

    t <- friedman.test(mat)

    tibble(
      variavel  = v,
      statistic = round(t$statistic, 3),
      df        = t$parameter,
      p         = round(t$p.value, 4),
      sig       = ifelse(t$p.value < .001, "***",
                  ifelse(t$p.value < .01,  "**",
                  ifelse(t$p.value < .05,  "*", "ns")))
    )
  })

print(friedman_results)

# --- 4.2 Pós-hoc Wilcoxon pareado com Holm -----------------------------------
# Aplicado apenas às variáveis com Friedman significativo (p < .05)
vars_sig <- friedman_results |> filter(p < 0.05) |> pull(variavel)

posthoc_results <- vars_sig |>
  map_dfr(function(v) {
    issues <- sort(unique(df$Issue))
    pares  <- combn(issues, 2, simplify = FALSE)

    # Calcula todos os 28 p-values brutos primeiro
    brutos <- pares |>
      map_dfr(function(par) {
        g1 <- df |> filter(Issue == par[1]) |> pull(all_of(v))
        g2 <- df |> filter(Issue == par[2]) |> pull(all_of(v))
        t  <- wilcox.test(g1, g2, paired = TRUE, exact = FALSE)
        tibble(variavel = v,
               issue1   = par[1], issue2 = par[2],
               W        = round(t$statistic, 1),
               p_raw    = t$p.value)
      })

    # Ajusta o vetor completo de uma vez
    brutos |>
      mutate(
        p_adj = round(p.adjust(p_raw, method = "holm"), 4),
        p_raw = round(p_raw, 4),
        sig   = ifelse(p_adj < .05, "*", "ns")
      )
  })

cat("\n=== Pares significativos após correção Holm ===\n")
posthoc_results |> filter(sig == "*") |> arrange(variavel, p_adj) |> print(n = Inf)

cat("\n=== Resumo por variável ===\n")
posthoc_results |>
  group_by(variavel) |>
  summarise(total = n(), sig = sum(sig == "*"), ns = sum(sig == "ns")) |>
  print()

# --- 4.3 Heatmap p-values brutos (Dificuldade) -------------------------------
p_heat <- posthoc_results |>
  filter(variavel == "Dificuldade") |>
  ggplot(aes(x = issue1, y = issue2, fill = p_raw)) +
  geom_tile(color = "white") +
  geom_text(aes(label = round(p_raw, 3)), size = 3) +
  scale_fill_gradient(low = "#B5D4F4", high = "#F1EFE8", name = "p bruto") +
  labs(title    = "Dificuldade — p-values brutos entre pares de issues",
       subtitle = "Pós-hoc Wilcoxon pareado (correção Holm, 28 pares)",
       x = NULL, y = NULL) +
  theme_minimal(base_size = 11)

print(p_heat)

# --- 4.4 Exporta -------------------------------------------------------------
write_csv(friedman_results, "output/tables/04_friedman.csv")
write_csv(posthoc_results,  "output/tables/04_posthoc_wilcoxon_holm.csv")
ggsave("output/figures/04_heatmap_dificuldade.png", p_heat,
       width = 7, height = 6, dpi = 300)
