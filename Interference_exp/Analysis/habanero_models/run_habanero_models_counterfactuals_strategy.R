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
params$chains <- 6
params$warmup <- 2000
params$adapt_delta <- 0.99

# Load data 
load_data <- function(phase_types, exps){
  all_dfs = list()
  for (phase in 1:length(phase_types)){
    data = c()
    for (exp in 1:length(exps)){
      curr_data <- c()
      if (phase_types[phase]=="all_data_all_subs"){
        curr_data <- read.csv(sprintf("../Data/%s/Summary_data/all_subs/all_data.csv",exps[exp]))
      } else if (file.exists(sprintf("../Data/%s/Summary_data/non_outlier_subs/%s.csv",exps[exp],phase_types[phase]))) {
        curr_data <- read.csv(sprintf("../Data/%s/Summary_data/non_outlier_subs/%s.csv",exps[exp],phase_types[phase]))
      }
      if (phase_types[phase] == "debrief"){
        curr_data$art_time_spent <- as.numeric(curr_data$art_time_spent)
      }
      data <- bind_rows(data,curr_data)
    }
    all_dfs[[phase]] <- data
  }
  names(all_dfs) <- phase_types
  
  return(all_dfs)
}
phase_types = c("ratings","deliberation", "interference", "reward_learning",
                "final_decisions","memory", "outcome_evaluation","debrief",
                "all_data","all_interaction_data","all_data_all_subs")
exps = c("Pilot","Exp1")
dfs <- load_data(phase_types, exps)

run_models = 1

### Testing whether the results hold when removing explicit strategy participants

# These are the people who explictly mentioned an inverse strategy
#inverse_strategy_PID <- subset(dfs$debrief, Strategy==1)$PID
inverse_strategy_PID <- c("0fnsb","cqMpS", "eoRdQ", "kYxEv", "l2ASo", "pjqfS", "2te35", "3sSYQ", "8pRjy", "9s8ph", "BxrGU", "DqtDo", "FZLzn", "HAvkp", "HSqqB", "HgayM", "JJKmU","JY6WO", "Jt02R", "QS6kW", "RLJAU", "V2T2h", "d3y2u", "eKQrN", "hXAw3", "ny1bP", "pcdhA" ,"x4Vzv", "y1DzQ")

#### Memory performance 

# if (run_models==1){
#   
#   dfs$memory <- dfs$memory %>%
#     mutate(condition_centered = ifelse(condition==1, 1, -1),
#            strategy = ifelse(PID %in% inverse_strategy_PID, 1, 0))
#   
#   # run model
#   M_memory_strategy_Exp1 <- stan_glmer(data = subset(dfs$memory, Exp=="Exp1" & strategy==0), 
#                                        pairs_acc ~ condition_centered + (condition_centered | PID),
#                                        family = binomial(link="logit"), 
#                                        adapt_delta = params$adapt_delta, 
#                                        iter = params$iterations, 
#                                        chains = params$chains, 
#                                        warmup = params$warmup,
#                                        seed = 12345)
#   
#   save(list = "M_memory_strategy_Exp1",
#        file = "../Data/Exp1/Models/M_memory_strategy_Exp1.RData")
#   
#   # pilot
#   M_memory_Pilot_strategy <- stan_glmer(data = subset(dfs$memory, Exp=="Pilot" & strategy==0), 
#                                         pairs_acc ~ condition_centered + (condition_centered | PID),
#                                         family = binomial(link="logit"), 
#                                         adapt_delta = params$adapt_delta, 
#                                         iter = params$iterations, 
#                                         chains = params$chains, 
#                                         warmup = params$warmup,
#                                         seed = 12345)
#   
#   save(list = "M_memory_Pilot_strategy",
#        file = "../Data/Pilot/Models/M_memory_Pilot_strategy.RData")
#   
# } 

### Final Decisions phase 

# ======================================
# Model choices as a function of ratings  
# ======================================

if (run_models==1){
  
  # Create relevant columns for modeling 
  dfs$final_decisions <- dfs$final_decisions %>% 
    mutate(condition_center = ifelse(condition==0, -1, 1),
           choice_center = ifelse(chosen_trial==0, -1, 1),
           strategy = ifelse(PID %in% inverse_strategy_PID, 1, 0))
  
  # Remove Non responses
  dfs$final_decisions <- subset(dfs$final_decisions, !is.nan(rt))
  
  # # Run choice model and save it
  # M_choice_delta_val_strategy_Exp1 <- stan_glmer(data = subset(dfs$final_decisions, Exp=="Exp1" & strategy==0), 
  #                                                higher_outcome_chosen ~ 
  #                                                  condition_center*choice_center*zscored_delta_ratings + 
  #                                                  (condition_center*choice_center*zscored_delta_ratings | PID),
  #                                                family = binomial(link="logit"), 
  #                                                adapt_delta = params$adapt_delta, 
  #                                                iter = params$iterations, 
  #                                                chains = params$chains, 
  #                                                warmup = params$warmup,
  #                                                seed = 12345)
  # 
  # save(list = "M_choice_delta_val_strategy_Exp1",
  #      file = "../Data/Exp1/Models/M_choice_delta_val_strategy_Exp1.RData")
  
  # Pilot
  M_choice_delta_val_strategy_Pilot <- stan_glmer(data = subset(dfs$final_decisions, Exp=="Pilot" & strategy==0), 
                                                  higher_outcome_chosen ~ 
                                                    condition_center*choice_center*zscored_delta_ratings + 
                                                    (condition_center*choice_center*zscored_delta_ratings | PID),
                                                  family = binomial(link="logit"), 
                                                  adapt_delta = params$adapt_delta, 
                                                  iter = params$iterations, 
                                                  chains = params$chains, 
                                                  warmup = params$warmup,
                                                  seed = 12345)
  
  save(list = "M_choice_delta_val_strategy_Pilot",
       file = "../Data/Pilot/Models/M_choice_delta_val_strategy_Pilot.RData")
  
} 

### RT analysis in Final Decisions phase

# =================================================
# p(gain) as a function of zscored RT and pair type
# =================================================

# # run model 
# if (run_models==1){
#   
#   dfs$final_decisions <- dfs$final_decisions %>% 
#     mutate(condition_center = ifelse(condition==0, -1, 1),
#            strategy = ifelse(PID %in% inverse_strategy_PID, 1, 0))
#   
#   # run model and use function to rearrange the coefficients
#   M_zscored_RT_FD_strategy_Exp1 <- stan_glmer(data=subset(dfs$final_decisions, !is.na(left_chosen) & chosen_trial==0 & Exp=="Exp1" & strategy==0),
#                                               higher_outcome_chosen ~ condition_center*zscored_rt + 
#                                                 (condition_center*zscored_rt | PID),
#                                               family = binomial(link="logit"),
#                                               adapt_delta = params$adapt_delta,
#                                               iter = params$iterations,
#                                               chains = params$chains,
#                                               warmup = params$warmup,
#                                               seed = 12345)
#   
#   save(list = "M_zscored_RT_FD_strategy_Exp1",
#        file = "../Data/Exp1/Models/M_zscored_RT_FD_strategy_Exp1.RData")
#   
#   # Pilot
#   M_zscored_RT_FD_strategy_Pilot <- stan_glmer(data=subset(dfs$final_decisions, !is.na(left_chosen) & chosen_trial==0 & Exp=="Pilot" & strategy==0),
#                                                higher_outcome_chosen ~ condition_center*zscored_rt + 
#                                                  (condition_center*zscored_rt | PID),
#                                                family = binomial(link="logit"),
#                                                adapt_delta = params$adapt_delta,
#                                                iter = params$iterations,
#                                                chains = params$chains,
#                                                warmup = params$warmup,
#                                                seed = 12345)
#   
#   save(list = "M_zscored_RT_FD_strategy_Pilot",
#        file = "../Data/Pilot/Models/M_zscored_RT_FD_strategy_Pilot.RData")
#   
# } 

if (run_models==1){

  dfs$final_decisions <- dfs$final_decisions %>%
    mutate(condition_center = ifelse(condition==0, -1, 1),
           higher_outcome_chosen_centered = ifelse(higher_outcome_chosen==1,1,-1), 
           strategy = ifelse(PID %in% inverse_strategy_PID, 1, 0))

  # run model and use function to rearrange the coefficients
  M_zscored_RT_gain_cond_FD_strategy_Exp1 <- stan_glmer(data=subset(dfs$final_decisions, !is.na(left_chosen) & chosen_trial==0 & Exp=="Exp1" & strategy==0),
                                             zscored_rt ~ condition_center*higher_outcome_chosen_centered +
                                               (condition_center*higher_outcome_chosen_centered | PID),
                                             family = gaussian(),
                                             adapt_delta = params$adapt_delta,
                                             iter = params$iterations,
                                             chains = params$chains,
                                             warmup = params$warmup,
                                             seed = 12345)

  save(list = "M_zscored_RT_gain_cond_FD_strategy_Exp1",
       file = "../Data/Exp1/Models/M_zscored_RT_gain_cond_FD_strategy_Exp1.RData")

  # Pilot
  M_zscored_RT_gain_cond_FD_strategy_Pilot <- stan_glmer(data=subset(dfs$final_decisions, !is.na(left_chosen) & chosen_trial==0 & Exp=="Pilot" & strategy==0),
                                               zscored_rt ~ condition_center*higher_outcome_chosen_centered +
                                                 (condition_center*higher_outcome_chosen_centered | PID),
                                               family = gaussian(),
                                               adapt_delta = params$adapt_delta,
                                               iter = params$iterations,
                                               chains = params$chains,
                                               warmup = params$warmup,
                                               seed = 12345)

  save(list = "M_zscored_RT_gain_cond_FD_strategy_Pilot",
       file = "../Data/Pilot/Models/M_zscored_RT_gain_cond_FD_strategy_Pilot.RData")
}

# =======================
# Memory and Inverse bias 
# =======================

pairs_acc <- dfs$memory %>%
  mutate(Condition = ifelse(condition==1, "Interference", "Repetition")) %>%
  group_by(Exp, PID, Condition) %>%
  dplyr::summarise(pairs_acc = mean(pairs_acc, na.rm=1),
                   zscored_rt = mean(zscored_rt_pairs, na.rm=1))

# Compute measures of interest
memory_bias <- dfs$final_decisions %>%
  mutate(Choice = ifelse(chosen_trial==1, "Chosen", "Unchosen"),
         Condition = ifelse(condition==1, "Interference", "Repetition")) %>%
  group_by(Exp, PID, Choice, Condition) %>%
  dplyr::summarize(p_gain = mean(higher_outcome_chosen, na.rm=1)) %>%
  spread(Choice,p_gain) %>%
  mutate(inverse_bias = Chosen - Unchosen) %>%
  merge(pairs_acc, by=c("Exp","PID","Condition"))

# Model inverse decision bias and pairs memory
if (run_models==1){
  
  memory_bias <- memory_bias %>%
    mutate(condition_centered = ifelse(Condition=="Interference", 1, -1),
           strategy = ifelse(PID %in% inverse_strategy_PID, 1, 0))
  
  # run model
  M_memory_bias_strategy_Exp1 <- stan_glm(data=subset(memory_bias, Exp=="Exp1" & strategy==0),
                                          inverse_bias ~ pairs_acc*condition_centered,
                                          family = gaussian(),
                                          adapt_delta = params$adapt_delta,
                                          iter = params$iterations,
                                          chains = params$chains,
                                          warmup = params$warmup,
                                          seed = 12345)
  
  save(list = "M_memory_bias_strategy_Exp1",
       file = "../Data/Exp1/Models/M_memory_bias_strategy_Exp1.RData")
  
  # pilot
  M_memory_bias_strategy_Pilot <- stan_glm(data=subset(memory_bias, Exp=="Pilot" & strategy==0),
                                           inverse_bias ~ pairs_acc*condition_centered,
                                           family = gaussian(),
                                           adapt_delta = params$adapt_delta,
                                           iter = params$iterations,
                                           chains = params$chains,
                                           warmup = params$warmup,
                                           seed = 12345)
  
  save(list = "M_memory_bias_strategy_Pilot",
       file = "../Data/Pilot/Models/M_memory_bias_strategy_Pilot.RData")
  
} 



