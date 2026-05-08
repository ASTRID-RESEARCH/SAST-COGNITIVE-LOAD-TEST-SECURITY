pkgs <- c("tidyverse", "lme4", "lmerTest", "geepack",
          "rstatix", "coin", "effectsize", "broom.mixed", "purrr")
install.packages(setdiff(pkgs, rownames(installed.packages())))

suppressPackageStartupMessages({
  library(tidyverse); library(lme4); library(lmerTest)
  library(geepack);   library(coin); library(effectsize)
  library(broom.mixed); library(purrr)
})

df <- read_csv("data/Data_thinkaloud.csv") |>
  mutate(
    Issue        = factor(Issue),
    Participante = factor(Participante),
    Desempenho   = factor(Desempenho, levels = c(0, 1),
                          labels = c("Errado", "Correto"))
  )

variaveis <- c("Dificuldade", "Interpretação", "Esforço", "Confiança")

dir.create("output/tables",  recursive = TRUE, showWarnings = FALSE)
dir.create("output/figures", recursive = TRUE, showWarnings = FALSE)

cat("=== SETUP CONCLUÍDO | n =", nrow(df), "obs. ===\n\n")

cat("=== 1. ESTATÍSTICA DESCRITIVA ===\n")

desc_global <- df |>
  summarise(across(all_of(variaveis), list(
    mediana = median, Q1 = ~quantile(., 0.25),
    Q3 = ~quantile(., 0.75), IQR = IQR, media = mean, dp = sd
  ))) |>
  pivot_longer(everything(), names_to = c("variavel", ".value"), names_sep = "_")

print(desc_global, n = Inf)

acerto_issue <- df |>
  mutate(acerto = as.numeric(Desempenho == "Correto")) |>
  group_by(Issue) |>
  summarise(n = n(), acertos = sum(acerto),
            taxa_pct = round(mean(acerto) * 100, 1), .groups = "drop") |>
  arrange(taxa_pct)

print(acerto_issue)

write_csv(desc_global,  "output/tables/01_descritivo_global.csv")
write_csv(acerto_issue, "output/tables/01_acerto_por_issue.csv")

cat("\n=== 2. SHAPIRO-WILK ===\n")

shapiro_results <- variaveis |>
  map_dfr(function(v) {
    t <- shapiro.test(df[[v]])
    tibble(variavel = v, W = round(t$statistic, 4),
           p_valor = round(t$p.value, 4),
           normal = ifelse(t$p.value > 0.05, "Sim", "Não"))
  })

print(shapiro_results)
write_csv(shapiro_results, "output/tables/02_shapiro_wilk.csv")

p_qq <- df |>
  select(all_of(variaveis)) |>
  pivot_longer(everything(), names_to = "variavel", values_to = "valor") |>
  ggplot(aes(sample = valor)) +
  stat_qq(size = 1.5, alpha = 0.6) +
  stat_qq_line(color = "steelblue", linewidth = 0.8) +
  facet_wrap(~variavel, scales = "free") +
  labs(title = "Q-Q plots — avaliação de normalidade",
       x = "Quantis teóricos", y = "Quantis observados") +
  theme_minimal(base_size = 12)

ggsave("output/figures/02_qq_plots.png", p_qq, width = 8, height = 6, dpi = 300)

cat("\n=== 3. CORRELAÇÕES DE SPEARMAN ===\n")

spearman_matrix <- function(data, vars) {
  n <- length(vars)
  mat_rho <- matrix(NA, n, n, dimnames = list(vars, vars))
  mat_p   <- matrix(NA, n, n, dimnames = list(vars, vars))
  for (i in seq_along(vars)) for (j in seq_along(vars)) {
    if (i == j) { mat_rho[i,j] <- 1 } else {
      t <- cor.test(data[[vars[i]]], data[[vars[j]]],
                    method = "spearman", exact = FALSE)
      mat_rho[i,j] <- round(t$estimate, 4)
      mat_p[i,j]   <- round(t$p.value, 4)
    }
  }
  list(rho = mat_rho, p = mat_p)
}

resultado <- spearman_matrix(df, variaveis)
cat("Matriz rho:\n"); print(resultado$rho)
cat("\nMatriz p:\n");  print(resultado$p)

pares_spearman <- combn(variaveis, 2, simplify = FALSE) |>
  map_dfr(function(par) {
    t <- cor.test(df[[par[1]]], df[[par[2]]], method = "spearman", exact = FALSE)
    tibble(V1 = par[1], V2 = par[2], rho = round(t$estimate, 3),
           p = round(t$p.value, 4),
           sig = ifelse(t$p.value < .001, "***",
                 ifelse(t$p.value < .01, "**",
                 ifelse(t$p.value < .05, "*", "ns"))),
           magnitude = case_when(abs(t$estimate) >= 0.7 ~ "forte",
                                 abs(t$estimate) >= 0.4 ~ "moderada",
                                 TRUE ~ "fraca"))
  }) |> arrange(desc(abs(rho)))

print(pares_spearman)
write_csv(pares_spearman, "output/tables/03_correlacoes_spearman.csv")

cat("\n=== 4. FRIEDMAN ===\n")

friedman_results <- variaveis |>
  map_dfr(function(v) {
    mat <- df |>
      select(Participante, Issue, valor = all_of(v)) |>
      pivot_wider(names_from = Issue, values_from = valor) |>
      select(-Participante) |> as.matrix()
    t <- friedman.test(mat)
    tibble(variavel = v, statistic = round(t$statistic, 3),
           df = t$parameter, p = round(t$p.value, 4),
           sig = ifelse(t$p.value < .001, "***",
                 ifelse(t$p.value < .01, "**",
                 ifelse(t$p.value < .05, "*", "ns"))))
  })

print(friedman_results)
write_csv(friedman_results, "output/tables/04_friedman.csv")

vars_sig <- friedman_results |> filter(p < 0.05) |> pull(variavel)

posthoc_results <- vars_sig |>
  map_dfr(function(v) {
    issues <- sort(unique(df$Issue))
    pares  <- combn(issues, 2, simplify = FALSE)
    brutos <- pares |>
      map_dfr(function(par) {
        g1 <- df |> filter(Issue == par[1]) |> pull(all_of(v))
        g2 <- df |> filter(Issue == par[2]) |> pull(all_of(v))
        t  <- wilcox.test(g1, g2, paired = TRUE, exact = FALSE)
        tibble(variavel = v, issue1 = par[1], issue2 = par[2],
               W = round(t$statistic, 1), p_raw = t$p.value)
      })
    brutos |> mutate(p_adj = round(p.adjust(p_raw, method = "holm"), 4),
                     p_raw = round(p_raw, 4),
                     sig   = ifelse(p_adj < .05, "*", "ns"))
  })

write_csv(posthoc_results, "output/tables/04_posthoc_wilcoxon_holm.csv")

p_heat <- posthoc_results |>
  filter(variavel == "Dificuldade") |>
  ggplot(aes(x = issue1, y = issue2, fill = p_raw)) +
  geom_tile(color = "white") +
  geom_text(aes(label = round(p_raw, 3)), size = 3) +
  scale_fill_gradient(low = "#B5D4F4", high = "#F1EFE8", name = "p bruto") +
  labs(title = "Dificuldade — p-values brutos entre pares de issues",
       x = NULL, y = NULL) +
  theme_minimal(base_size = 11)

ggsave("output/figures/04_heatmap_dificuldade.png", p_heat,
       width = 7, height = 6, dpi = 300)

cat("\n=== 5. MANN-WHITNEY U ===\n")

df_num <- df |> mutate(acerto = as.numeric(Desempenho == "Correto"))

mw_results <- variaveis |>
  map_dfr(function(v) {
    correto <- df_num[df_num$acerto == 1, v, drop = TRUE]
    errado  <- df_num[df_num$acerto == 0, v, drop = TRUE]
    t <- wilcox.test(correto, errado, exact = FALSE)
    r <- rank_biserial(correto, errado)
    tibble(variavel = v, med_correto = median(correto), IQR_correto = IQR(correto),
           med_errado = median(errado), IQR_errado = IQR(errado),
           U = round(t$statistic, 0), p = round(t$p.value, 3),
           r_rb = round(r$r_rank_biserial, 3), magnitude = r$interpret,
           sig = ifelse(t$p.value < .05, "*", "ns"))
  })

print(mw_results)
write_csv(mw_results, "output/tables/05_mann_whitney.csv")

cat("\n=== 6. MODELO LINEAR MISTO ===\n")

modelo_lmm <- lmer(
  Dificuldade ~ Interpretação + Esforço + Confiança + (1 | Participante),
  data = df, REML = TRUE
)

summary(modelo_lmm)

tabela_fixos <- tidy(modelo_lmm, effects = "fixed") |>
  mutate(across(where(is.numeric), \(x) round(x, 3))) |>
  select(term, estimate, std.error, statistic, df, p.value) |>
  rename(Preditor = term, Beta = estimate, SE = std.error, t = statistic, p = p.value)

print(tabela_fixos)
write_csv(tabela_fixos, "output/tables/06_lmm_efeitos_fixos.csv")

cat("\n=== 7. GEE LOGÍSTICO ===\n")

df_gee <- df |>
  mutate(Desempenho_num  = as.numeric(Desempenho == "Correto"),
         Participante_id = as.integer(factor(Participante))) |>
  arrange(Participante_id, Issue)

modelo_gee <- geeglm(
  Desempenho_num ~ Dificuldade + Interpretação + Esforço + Confiança,
  data = df_gee, id = Participante_id,
  family = binomial(link = "logit"), corstr = "exchangeable"
)

summary(modelo_gee)

coefs    <- coef(summary(modelo_gee))
OR_table <- tibble(
  preditor = rownames(coefs),
  OR       = round(exp(coefs[, "Estimate"]), 3),
  IC_inf   = round(exp(coefs[, "Estimate"] - 1.96 * coefs[, "Std.err"]), 3),
  IC_sup   = round(exp(coefs[, "Estimate"] + 1.96 * coefs[, "Std.err"]), 3),
  p        = round(coefs[, "Pr(>|W|)"], 3),
  sig      = ifelse(coefs[, "Pr(>|W|)"] < .05, "*", "ns")
)

print(OR_table)
write_csv(OR_table, "output/tables/07_gee_odds_ratios.csv")

cat("\n=== ANÁLISE COMPLETA | Outputs em output/ ===\n")
