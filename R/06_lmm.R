# =============================================================================
# 06_lmm.R
# Modelo Linear Misto — preditores de Dificuldade percebida
# Reproduz Tabela 5 do artigo (lme4 + lmerTest / Satterthwaite)
# =============================================================================

source("R/00_setup.R")

# --- 6.1 Ajuste do modelo ----------------------------------------------------
modelo_lmm <- lmer(
  Dificuldade ~ Interpretação + Esforço + Confiança + (1 | Participante),
  data = df,
  REML = TRUE
)

summary(modelo_lmm)

# --- 6.2 Tabela limpa dos efeitos fixos --------------------------------------
tabela_fixos <- tidy(modelo_lmm, effects = "fixed") |>
  mutate(across(where(is.numeric), \(x) round(x, 3))) |>
  select(term, estimate, std.error, statistic, df, p.value) |>
  rename(Preditor = term, Beta = estimate, SE = std.error,
         t = statistic, p = p.value)

print(tabela_fixos)

# --- 6.3 R² marginal e condicional -------------------------------------------
# R² manual (sem dependência de pacote extra)
var_random   <- as.numeric(VarCorr(modelo_lmm)$Participante)
var_residual <- sigma(modelo_lmm)^2
fitted_fixos <- model.matrix(modelo_lmm) %*% fixef(modelo_lmm)
r2_marginal  <- var(fitted_fixos) / (var(fitted_fixos) + var_random + var_residual)

cat("\nR² marginal (só efeitos fixos):", round(r2_marginal, 3), "\n")

# --- 6.4 Diagnóstico dos resíduos --------------------------------------------
residuos <- residuals(modelo_lmm)
sw        <- shapiro.test(residuos)
cat("Shapiro-Wilk resíduos: W =", round(sw$statistic, 4),
    "| p =", round(sw$p.value, 4), "\n")

p_diag <- plot(modelo_lmm)
print(p_diag)

# --- 6.5 Exporta -------------------------------------------------------------
write_csv(tabela_fixos, "output/tables/06_lmm_efeitos_fixos.csv")
