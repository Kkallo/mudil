#' ---
#' title: "Mudil"
#' output: github_document
#' date: "2018-10-30"
#' ---

library(tidyverse)
library(viridis)
library(brms)
mudil <- read_csv("../output/andmed_otoliit.csv")
mudil

#' Fish id: location + nr
mudil %>% 
  group_by(nr, age, location) %>% 
  summarise(N = n())

mudil_mod <- mudil %>% 
  mutate(location = str_replace_all(location, "\\s", "_"),
         id = str_c(location, nr, sep = "_"),
         sex = case_when(
           sex == 0 ~ "F",
           sex == 1 ~ "M",
           sex == 3 ~ "juv"
         )) %>% 
  select(id, everything())

#' Only adult fish
mudil_ad <- filter(mudil_mod, sex != "juv")

#' Mean and sd of fish at different age
mudil_ad %>% 
  group_by(age) %>% 
  summarise_at("tl", funs(mean, sd))

#' Individual growth curves
ggplot(data = mudil_ad) +
  geom_line(mapping = aes(x = age, y = tl, group = id, color = sex), alpha = 2/3) +
  facet_wrap(~location) +
  scale_color_viridis_d() +
  labs(x = "Age (year)", y = "Total length (mm)")

#' Weird fish in Saarnaki
fish_id <- mudil_ad %>% 
  filter(location == "Saarnaki") %>% 
  mutate(ad = tl - tl[age == 1]) %>% 
  filter(ad < 0) %>% 
  pull(id)

#' Drop this weird fish
mudil_ad <- filter(mudil_ad, id != fish_id)
ggplot(data = mudil_ad) +
  geom_line(mapping = aes(x = age, y = tl, group = id, color = sex), alpha = 2/3) +
  facet_wrap(~location) +
  scale_color_viridis_d() +
  labs(x = "Age (year)", y = "Total length (mm)")

#' Average length at age in adults
ggplot(data = mudil_ad, mapping = aes(x = age, y = tl)) +
  stat_summary(fun.data = mean_sdl, fun.args = list(mult = 1), geom = "ribbon", alpha = 0.3) +
  geom_point(position = position_jitter(width = 1/3)) +
  stat_summary(fun.y = mean, geom = "line", color = viridis(6)[6]) +
  facet_wrap(~location) +
  labs(x = "Age (year)", y = "Total length (mm)")

#' Starting values for van bertalaffny model coefficients
library(FSA)
svTypical <- vbStarts(tl ~ age, data = mudil_ad)
unlist(svTypical)

# Set up prior with suggested starting values using normal distribution

#' Model with individual variance and different sd per age
get_prior(bf(tl ~ Linf * (1 - exp(-K * (age - t0))), 
             Linf + K + t0 ~ 0 + location + (1 | id), 
             sigma ~ age, nl = TRUE),
          data = mudil_ad)

#' Wiki says that adult gobis can be between 150 and 200 mm long, let's take 200 as prior 
kihnu <- prior(normal(200, 30), nlpar = "Linf") +
  prior(normal(0.7, 0.2), nlpar = "K") +
  prior(normal(0.5, 0.2), nlpar = "t0")

#+ eval=FALSE
fit2 <- brm(bf(tl ~ Linf * (1 - exp(-K * (age - t0))), 
               Linf + K + t0 ~ 0 + location + (1 | id), 
               sigma ~ age, nl = TRUE),
            data = mudil_ad,
            family = gaussian(link = "identity"),
            prior = kihnu,
            chains = 1,
            iter = 4000)
write_rds(fit2, "../output/von_bertalanffy_normal_otol_2.rds")

#+ echo=FALSE
fit2 <- read_rds("../output/von_bertalanffy_normal_otol_2.rds")

#+ 
summary(fit2)

#' Plot out fits for different locations
cond <- make_conditions(data.frame(location = unique(mudil_ad$location)), vars = "location")
p <- plot(marginal_effects(fit2, conditions = cond), points = TRUE, ask = FALSE, plot = FALSE)
p[[1]] + labs(x = "Age (year)", y = "Total length (mm)")
