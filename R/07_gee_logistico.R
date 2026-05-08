source("R/00_setup.R")

df_gee <- df |>
  mutate(
    Desempenho_num  = as.numeric(Desempenho == "Correto"),
    Participante_id = as.integer(factor(Participante))
  ) |>
  arrange(Participante_id, Issue)

modelo_gee <- geeglm(
  Desempenho_num ~ Dificuldade + Interpretação + Esforço + Confiança,
  data   = df_gee,
  id     = Participante_id,
  family = binomial(link = "logit"),
  corstr = "exchangeable"
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
