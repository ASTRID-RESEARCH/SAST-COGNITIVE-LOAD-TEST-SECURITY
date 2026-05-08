pkgs <- c("tidyverse", "lme4", "lmerTest", "geepack",
          "rstatix", "coin", "effectsize", "broom.mixed", "purrr")

install.packages(setdiff(pkgs, rownames(installed.packages())))

library(tidyverse)
library(lme4)
library(lmerTest)
library(geepack)
library(rstatix)
library(coin)
library(effectsize)
library(broom.mixed)
library(purrr)

# Leitura e tipagem das variáveis
df <- read_csv("data/Data_thinkaloud.csv") |>
  mutate(
    Issue        = factor(Issue),
    Participante = factor(Participante),
    Desempenho   = factor(Desempenho, levels = c(0, 1),
                          labels = c("Errado", "Correto"))
  )

# Vetor de variáveis cognitivas (reutilizado em todos os scripts)
variaveis <- c("Dificuldade", "Interpretação", "Esforço", "Confiança")

glimpse(df)
cat("\nN observações:", nrow(df), "\n")
cat("N participantes:", n_distinct(df$Participante), "\n")
cat("N issues:", n_distinct(df$Issue), "\n")
cat("Taxa de acerto global:",
    round(mean(df$Desempenho == "Correto") * 100, 1), "%\n")
