# =============================================================================
# 01_descritivo.R
# Estatística descritiva: medianas, IQR, taxas de acerto por issue
# Referência: Tabela 4 (parcial) do artigo
# =============================================================================

source("R/00_setup.R")

# --- 1.1 Descritivo global ---------------------------------------------------
desc_global <- df |>
  summarise(across(all_of(variaveis), list(
    mediana = median,
    Q1      = ~quantile(., 0.25),
    Q3      = ~quantile(., 0.75),
    IQR     = IQR,
    media   = mean,
    dp      = sd,
    min     = min,
    max     = max
  ))) |>
  pivot_longer(everything(),
               names_to  = c("variavel", ".value"),
               names_sep = "_")

print(desc_global, n = Inf)

# --- 1.2 Medianas por issue --------------------------------------------------
desc_issue <- df |>
  group_by(Issue) |>
  summarise(across(all_of(variaveis), median), .groups = "drop")

print(desc_issue, n = Inf)

# --- 1.3 Taxa de acerto por issue --------------------------------------------
acerto_issue <- df |>
  mutate(acerto = as.numeric(Desempenho == "Correto")) |>
  group_by(Issue) |>
  summarise(
    n        = n(),
    acertos  = sum(acerto),
    taxa_pct = round(mean(acerto) * 100, 1),
    .groups  = "drop"
  ) |>
  arrange(taxa_pct)

print(acerto_issue)

# --- 1.4 Descritivo por grupo (Desempenho) -----------------------------------
df |>
  group_by(Desempenho) |>
  summarise(across(all_of(variaveis), list(
    mediana = median,
    IQR     = IQR
  )), .groups = "drop")

# --- 1.5 Exporta tabelas -----------------------------------------------------
write_csv(desc_global,  "output/tables/01_descritivo_global.csv")
write_csv(desc_issue,   "output/tables/01_descritivo_por_issue.csv")
write_csv(acerto_issue, "output/tables/01_acerto_por_issue.csv")

cat("\nTabelas salvas em output/tables/\n")
