# =============================================================================
# 03_spearman.R
# Correlações de Spearman entre variáveis cognitivas
# Reproduz Tabela 4 do artigo
# =============================================================================

source("R/00_setup.R")

# --- 3.1 Função auxiliar: matriz rho + p via R base -------------------------
spearman_matrix <- function(data, vars) {
  n       <- length(vars)
  mat_rho <- matrix(NA, n, n, dimnames = list(vars, vars))
  mat_p   <- matrix(NA, n, n, dimnames = list(vars, vars))

  for (i in seq_along(vars)) {
    for (j in seq_along(vars)) {
      if (i == j) {
        mat_rho[i, j] <- 1
      } else {
        t <- cor.test(data[[vars[i]]], data[[vars[j]]],
                      method = "spearman", exact = FALSE)
        mat_rho[i, j] <- round(t$estimate, 4)
        mat_p[i, j]   <- round(t$p.value, 4)
      }
    }
  }
  list(rho = mat_rho, p = mat_p)
}

resultado <- spearman_matrix(df, variaveis)

cat("=== Matriz de rho (Spearman) ===\n"); print(resultado$rho)
cat("\n=== Matriz de p-values ===\n");      print(resultado$p)

# --- 3.2 Tabela de pares com magnitude --------------------------------------
pares_spearman <- combn(variaveis, 2, simplify = FALSE) |>
  map_dfr(function(par) {
    t <- cor.test(df[[par[1]]], df[[par[2]]],
                  method = "spearman", exact = FALSE)
    tibble(
      V1        = par[1],
      V2        = par[2],
      rho       = round(t$estimate, 3),
      p         = round(t$p.value, 4),
      sig       = ifelse(t$p.value < .001, "***",
                  ifelse(t$p.value < .01,  "**",
                  ifelse(t$p.value < .05,  "*", "ns"))),
      magnitude = case_when(
        abs(t$estimate) >= 0.7 ~ "forte",
        abs(t$estimate) >= 0.4 ~ "moderada",
        TRUE                   ~ "fraca"
      )
    )
  }) |>
  arrange(desc(abs(rho)))

print(pares_spearman)

# --- 3.3 Exporta -------------------------------------------------------------
write_csv(pares_spearman, "output/tables/03_correlacoes_spearman.csv")
