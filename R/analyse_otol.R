
library(tidyverse)
library(brms)
mudil <- read_csv("output/andmed_otoliit.csv")
mudil

max(mudil$tl, na.rm = TRUE)
sd(mudil$tl, na.rm = TRUE)

ggplot(data = mudil) +
  geom_point(mapping = aes(x = age, y = tl))

prior2 <- prior(normal(212, 48), nlpar = "Linf") +
  prior(student_t(3, 0, 2), nlpar = "K", lb = 0) +
  prior(student_t(3, 0, 2), nlpar = "t0", ub = 0)

fit <- brm(bf(tl ~ Linf * (1 - exp(-K * (age - t0))), 
               Linf + K + t0 ~ 1, nl = TRUE),
            data = mudil, 
            prior = prior2,
            chains = 4,
            iter = 2400)
write_rds(fit, "output/von_bertalanffy_student_otol.rds")


fit <- read_rds("output/von_bertalanffy_student_otol.rds")
summary(fit)
plot(marginal_effects(fit), points = TRUE)


# t0 is almost 0, let's remove t0 from model
prior0 <- prior(normal(212, 48), nlpar = "Linf") +
  prior(student_t(3, 0, 2), nlpar = "K", lb = 0)
fit0 <- brm(bf(tl ~ Linf * (1 - exp(-K * (age))), 
              Linf + K ~ 1, nl = TRUE),
           data = mudil, 
           prior = prior0,
           chains = 4,
           iter = 2400)
fit_file <- "output/von_bertalanffy_student_otol_0.rds"
write_rds(fit0, fit_file)
fit0 <- read_rds(fit_file)
summary(fit0)
plot(marginal_effects(fit0), points = TRUE)