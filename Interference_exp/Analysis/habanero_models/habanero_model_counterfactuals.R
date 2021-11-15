# This code loads data and runs stan models on habanero

# add rpackages path
.libPaths("/rigel/dslab/users/nb2869/rpackages")

# Load libraries 
list_of_packages <- c("dplyr", "rstanarm", "loo", "tidyr")
new_packages <- list_of_packages[!(list_of_packages %in% installed.packages()[,"Package"])]
if(length(new_packages)) install.packages(new_packages)
lapply(list_of_packages, require, character.only = TRUE)

# Stan parameters
options(mc.cores = parallel::detectCores())

params <- list()
params$iterations <- 4000
params$chains <- 4
params$warmup <- 2000
params$adapt_delta <- 0.99

# Load data 
#df_final_decisions <- read.csv("../Data/Summary_data/final_decisions.csv")
df_final_decisions <- read.csv("../../Data/Summary_data/non_outlier_subs/final_decisions.csv")
#df_memory <- read.csv("../Data/Summary_data/memory.csv")
df_memory <- read.csv("../../Data/Summary_data/non_outlier_subs/memory.csv")

# Create relevant columns for modeling 
df_final_decisions <- df_final_decisions %>% 
  mutate(condition_center = ifelse(condition==0, -1, 1),
         choice_center = ifelse(chosen_trial==0, -1, 1))

# Remove Non responses
df_final_decisions <- subset(df_final_decisions, !is.nan(rt))

# Run choice model and save it
M_choice_delta_val <- stan_glmer(data = df_final_decisions, 
                                 higher_outcome_chosen ~ condition_center*choice_center*zscored_delta_ratings + (condition_center*choice_center*zscored_delta_ratings | PID),
                                 family = binomial(link="logit"), 
                                 adapt_delta = params$adapt_delta, 
                                 iter = params$iterations, 
                                 chains = params$chains, 
                                 warmup = params$warmup,
                                 seed = 12345)

save(list = "M_choice_delta_val",
     file = "../../Data/Models/M_choice_delta_val.RData")

# Save posterior draws matrix
M_draws <- as.data.frame(M_choice_delta_val)
write.csv(M_draws,"../../Data/Models/M_choice_delta_val_draws.csv")

# Run memory and inverse bias model 
# create behavioral matrix 
p_gain <- df_final_decisions %>% 
  mutate(choice = ifelse(chosen_trial==1, "chosen", "unchosen")) %>%
  group_by(PID, choice, condition) %>% 
  dplyr::summarise(p_gain = mean(higher_outcome_chosen, na.rm=1)) %>% 
  spread(choice, p_gain) %>%
  mutate(inverse_bias = chosen - unchosen)
pairs_acc <- df_memory %>%
  group_by(PID, condition) %>% 
  dplyr::summarise(pairs_acc = mean(pairs_acc, na.rm=1))
bias_memory <- merge(p_gain, pairs_acc, by=c("PID", "condition")) %>%
  mutate(condition_center = ifelse(condition == 0, -1, 1))

M_memory_bias <- stan_glm(data = bias_memory, 
                             inverse_bias ~ condition_center*pairs_acc,
                             family = gaussian(), 
                             adapt_delta = params$adapt_delta, 
                             iter = params$iterations, 
                             chains = params$chains, 
                             warmup = params$warmup,
                             seed = 12345)

save(list = "M_memory_bias",
     file = "../Data/Models/M_memory_bias.RData")

as.data.frame(M_memory_bias) %>%
  gather(coef, value, `(Intercept)`:sigma) %>%
  group_by(coef) %>%
  dplyr::summarize(HDI95_low = posterior_interval(as.matrix(value), prob=0.95)[1],
                   HDI95_high = posterior_interval(as.matrix(value), prob=0.95)[2],
                   median = median(value)) %>%
  mutate(value = sprintf("%.2f [%.2f, %.2f]",median, HDI95_low, HDI95_high)) %>%
  dplyr::select(coef, value)

