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

# ===== Memory =====

if (run_models==1){
  
  dfs$memory <- dfs$memory %>%
    mutate(condition_centered = ifelse(condition==1, 1, -1))
  
  # run model
  M_memory_Exp1 <- stan_glmer(data = subset(dfs$memory, Exp=="Exp1"), 
                              pairs_acc ~ condition_centered + (condition_centered | PID),
                              family = binomial(link="logit"), 
                              adapt_delta = params$adapt_delta, 
                              iter = params$iterations, 
                              chains = params$chains, 
                              warmup = params$warmup,
                              seed = 12345)
  
  save(list = "M_memory_Exp1",
       file = "../Data/Exp1/Models/M_memory_Exp1.RData")
  
  # pilot
  M_memory_Pilot <- stan_glmer(data = subset(dfs$memory, Exp=="Pilot"), 
                               pairs_acc ~ condition_centered + (condition_centered | PID),
                               family = binomial(link="logit"), 
                               adapt_delta = params$adapt_delta, 
                               iter = params$iterations, 
                               chains = params$chains, 
                               warmup = params$warmup,
                               seed = 12345)
  
  save(list = "M_memory_Pilot",
       file = "../Data/Pilot/Models/M_memory_Pilot.RData")
  
} else {
  load("../Data/Pilot/Models/M_memory_Pilot.RData")
  load("../Data/Exp1/Models/M_memory_Exp1.RData")
  
}

# ===== Choice =====

# if (run_models==1){
#   
#   # Create relevant columns for modeling 
#   dfs$final_decisions <- dfs$final_decisions %>% 
#     mutate(condition_center = ifelse(condition==0, -1, 1),
#            choice_center = ifelse(chosen_trial==0, -1, 1))
#   
#   # Remove Non responses
#   dfs$final_decisions <- subset(dfs$final_decisions, !is.nan(rt))
#   
#   # Run choice model and save it
#   M_choice_delta_val_Exp1 <- stan_glmer(data = subset(dfs$final_decisions, Exp=="Exp1"),
#                                    higher_outcome_chosen ~
#                                      condition_center*choice_center*zscored_delta_ratings +
#                                      (condition_center*choice_center*zscored_delta_ratings | PID),
#                                    family = binomial(link="logit"),
#                                    adapt_delta = params$adapt_delta,
#                                    iter = params$iterations,
#                                    chains = params$chains,
#                                    warmup = params$warmup,
#                                    seed = 12345)
# 
#   save(list = "M_choice_delta_val_Exp1",
#        file = "../Data/Exp1/Models/M_choice_delta_val_Exp1.RData")
# 
#   # Pilot
#   M_choice_delta_val_Pilot <- stan_glmer(data = subset(dfs$final_decisions, Exp=="Pilot"),
#                                         higher_outcome_chosen ~
#                                           condition_center*choice_center*zscored_delta_ratings +
#                                           (condition_center*choice_center*zscored_delta_ratings | PID),
#                                         family = binomial(link="logit"),
#                                         adapt_delta = params$adapt_delta,
#                                         iter = params$iterations,
#                                         chains = params$chains,
#                                         warmup = params$warmup,
#                                         seed = 12345)
# 
#   save(list = "M_choice_delta_val_Pilot",
#        file = "../Data/Pilot/Models/M_choice_delta_val_Pilot.RData")
# 
# } else {
#   load("../Data/Exp1/Models/M_choice_delta_val_Exp1.RData")
#   load("../Data/Pilot/Models/M_choice_delta_val_Pilot.RData")
# }


# ========= RT =========

# if (run_models==1){
#   
#   dfs$final_decisions <- dfs$final_decisions %>% 
#     mutate(condition_center = ifelse(condition==0, -1, 1))
#   
#   # run model and use function to rearrange the coefficients
#   M_zscored_RT_FD_Exp1 <- stan_glmer(data=subset(dfs$final_decisions, !is.na(left_chosen) & chosen_trial==0 & Exp=="Exp1"),
#                                      higher_outcome_chosen ~ condition_center*zscored_rt + 
#                                        (condition_center*zscored_rt | PID),
#                                      family = binomial(link="logit"),
#                                      adapt_delta = params$adapt_delta,
#                                      iter = params$iterations,
#                                      chains = params$chains,
#                                      warmup = params$warmup,
#                                      seed = 12345)
#   
#   save(list = "M_zscored_RT_FD_Exp1",
#        file = "../Data/Exp1/Models/M_zscored_RT_FD_Exp1.RData")
#   
#   # Pilot
#   M_zscored_RT_FD_Pilot <- stan_glmer(data=subset(dfs$final_decisions, !is.na(left_chosen) & chosen_trial==0 & Exp=="Pilot"),
#                                       higher_outcome_chosen ~ condition_center*zscored_rt + 
#                                         (condition_center*zscored_rt | PID),
#                                       family = binomial(link="logit"),
#                                       adapt_delta = params$adapt_delta,
#                                       iter = params$iterations,
#                                       chains = params$chains,
#                                       warmup = params$warmup,
#                                       seed = 12345)
#   
#   save(list = "M_zscored_RT_FD_Pilot",
#        file = "../Data/Pilot/Models/M_zscored_RT_FD_Pilot.RData")
#   
# } else {
#   load("../Data/Exp1/Models/M_zscored_RT_FD_Exp1.RData")
#   load("../Data/Pilot/Models/M_zscored_RT_FD_Pilot.RData")
# }

# if (run_models==1){
# 
#   dfs$final_decisions <- dfs$final_decisions %>%
#     mutate(condition_center = ifelse(condition==0, -1, 1),
#            higher_outcome_chosen_centered = ifelse(higher_outcome_chosen==1,1,-1))
# 
#   # run model and use function to rearrange the coefficients
#   M_zscored_RT_gain_cond_FD_Exp1 <- stan_glmer(data=subset(dfs$final_decisions, !is.na(left_chosen) & chosen_trial==0 & Exp=="Exp1"),
#                                              zscored_rt ~ condition_center*higher_outcome_chosen_centered +
#                                                (condition_center*higher_outcome_chosen_centered | PID),
#                                              family = gaussian(),
#                                              adapt_delta = params$adapt_delta,
#                                              iter = params$iterations,
#                                              chains = params$chains,
#                                              warmup = params$warmup,
#                                              seed = 12345)
# 
#   save(list = "M_zscored_RT_gain_cond_FD_Exp1",
#        file = "../Data/Exp1/Models/M_zscored_RT_gain_cond_FD_Exp1.RData")
# 
#   # Pilot
#   M_zscored_RT_gain_cond_FD_Pilot <- stan_glmer(data=subset(dfs$final_decisions, !is.na(left_chosen) & chosen_trial==0 & Exp=="Pilot"),
#                                                zscored_rt ~ condition_center*higher_outcome_chosen_centered +
#                                                  (condition_center*higher_outcome_chosen_centered | PID),
#                                                family = gaussian(),
#                                                adapt_delta = params$adapt_delta,
#                                                iter = params$iterations,
#                                                chains = params$chains,
#                                                warmup = params$warmup,
#                                                seed = 12345)
#   
#   save(list = "M_zscored_RT_gain_cond_FD_Pilot",
#        file = "../Data/Pilot/Models/M_zscored_RT_gain_cond_FD_Pilot.RData")
# 
# } else {
#   load("../Data/Exp1/Models/M_zscored_RT_FD_Exp1.RData")
#   load("../Data/Pilot/Models/M_zscored_RT_FD_Pilot.RData")
# }
# 

# # ===== Outcome Estimation =====
# 
# if (run_models==1){
#   dfs$outcome_evaluation <- mutate(dfs$outcome_evaluation,
#                                    chosen_obj_centered = ifelse(is_chosen==0,-1,1),
#                                    condition_centered = ifelse(condition==1, 1, -1))
#   
#   M_outcome_estimation <- stan_glmer(data=subset(dfs$outcome_evaluation, is_novel==0), 
#                                      outcome_eval_gain ~ chosen_obj_centered * condition_centered * outcome + 
#                                        (chosen_obj_centered * condition_centered * outcome | PID),
#                                      family = binomial(link="logit"), 
#                                      adapt_delta = params$adapt_delta, 
#                                      iter = params$iterations, 
#                                      chains = params$chains, 
#                                      warmup = params$warmup)
#   save(M_outcome_estimation, file = "../Data/Exp1/Models/M_outcome_estimation.RData")
#   
#   # include novel type in the model
#   dfs$outcome_evaluation <- mutate(dfs$outcome_evaluation,
#                                    stim_type_centered = ifelse(stim_type=="chosen",-1,ifelse(stim_type=="unchosen",1, 0)))
#   
#   M_outcome_estimation_novel_included <- stan_glmer(data=dfs$outcome_evaluation, 
#                                                     outcome_eval_gain ~ stim_type_centered * condition_centered * outcome + 
#                                                       (stim_type_centered * condition_centered * outcome | PID),
#                                                     family = binomial(link="logit"), 
#                                                     adapt_delta = params$adapt_delta, 
#                                                     iter = params$iterations, 
#                                                     chains = params$chains, 
#                                                     warmup = params$warmup)
#   save(M_outcome_estimation_novel_included, file = "../Data/Exp1/Models/M_outcome_estimation_novel_included.RData")
#   
# } else {
#   load("../Data/Exp1/Models/M_outcome_estimation_novel_included.RData")
#   load("../Data/Exp1/Models/M_outcome_estimation.RData")
# }

# # ===== Outcome Estimation by Inverse bias =====
# 
# # compute mean probabiltiy to choose gain - for chosen and unchosen alone
# p_gain <- dfs$final_decisions %>% 
#   mutate(choice = ifelse(chosen_trial==1, "Chosen", "Unchosen"),
#          condition = ifelse(condition==1, "Interference", "Repetition")) %>%
#   group_by(Exp, PID, choice, condition) %>% 
#   dplyr::summarize(p_gain = mean(higher_outcome_chosen, na.rm=1)) 
# 
# outcome_estimation <- dfs$outcome_evaluation %>%
#   mutate(choice = ifelse(stim_type=="chosen", "Chosen", ifelse(stim_type=="unchosen","Unchosen","Novel")),
#          reward = ifelse(outcome==1, "Rewarded", "Unrewarded"),
#          condition = ifelse(condition==1, "Interference", "Repetition")) %>% 
#   group_by(PID, condition, choice, reward) %>%
#   dplyr::summarise(gain_eval = mean(outcome_eval_gain, na.rm=1)) 
# 
# reward <- outcome_estimation %>%
#   subset(reward=="Rewarded") %>%
#   rename(rewarded = gain_eval) %>%
#   select(-reward)
# inverse_decision_estimation <- outcome_estimation %>%
#   subset(reward=="Unrewarded") %>%
#   rename(unrewarded = gain_eval) %>%
#   select(-reward) %>%
#   merge(reward, by=c("PID","condition","choice")) %>%
#   mutate(reward_diff = rewarded-unrewarded) %>%
#   merge(subset(p_gain, Exp=="Exp1"), by=c("PID","choice", "condition")) %>%
#   mutate(choice_centered = ifelse(choice=="Chosen", 1, -1),
#          condition_centered = ifelse(condition=="Interference", 1, -1),
#          p_gain_centered = p_gain - 0.5)
# 
# if (run_models==1){
#   M_inverse_decision_estimation <- stan_glm(data = inverse_decision_estimation, 
#                                             p_gain_centered ~ choice_centered * reward_diff * condition_centered,
#                                             family = gaussian(), 
#                                             adapt_delta = params$adapt_delta, 
#                                             iter = params$iterations, 
#                                             chains = params$chains, 
#                                             warmup = params$warmup)
#   save(M_inverse_decision_estimation, file = "../Data/Exp1/Models/M_inverse_decision_estimation.RData")
# } else {
#   load("../Data/Exp1/Models/M_inverse_decision_estimation.RData")
# }
# 
# # ===== Memory and Inverse bias =====
# 
# pairs_acc <- dfs$memory %>%
#   mutate(Condition = ifelse(condition==1, "Interference", "Repetition")) %>%
#   group_by(Exp, PID, Condition) %>%
#   dplyr::summarise(pairs_acc = mean(pairs_acc, na.rm=1),
#                    zscored_rt = mean(zscored_rt_pairs, na.rm=1))
# 
# # =======================
# # Memory and Inverse bias 
# # =======================
# 
# # Compute measures of interest
# memory_bias <- dfs$final_decisions %>%
#   mutate(Choice = ifelse(chosen_trial==1, "Chosen", "Unchosen"),
#          Condition = ifelse(condition==1, "Interference", "Repetition")) %>%
#   group_by(Exp, PID, Choice, Condition) %>%
#   dplyr::summarize(p_gain = mean(higher_outcome_chosen, na.rm=1)) %>%
#   spread(Choice,p_gain) %>%
#   mutate(inverse_bias = Chosen - Unchosen) %>%
#   merge(pairs_acc, by=c("Exp","PID","Condition"))
# 
# # Model inverse decision bias and pairs memory
# if (run_models==1){
#   
#   memory_bias <- memory_bias %>%
#     mutate(condition_centered = ifelse(Condition=="Interference", 1, -1))
#   
#   # run model
#   M_memory_bias_Exp1 <- stan_glm(data=subset(memory_bias, Exp=="Exp1"),
#                                  inverse_bias ~ pairs_acc*condition_centered,
#                                  family = gaussian(),
#                                  adapt_delta = params$adapt_delta,
#                                  iter = params$iterations,
#                                  chains = params$chains,
#                                  warmup = params$warmup,
#                                  seed = 12345)
#   
#   save(list = "M_memory_bias_Exp1",
#        file = "../Data/Exp1/Models/M_memory_bias_Exp1.RData")
#   
#   # pilot
#   M_memory_bias_Pilot <- stan_glm(data=subset(memory_bias, Exp=="Pilot"),
#                                   inverse_bias ~ pairs_acc*condition_centered,
#                                   family = gaussian(),
#                                   adapt_delta = params$adapt_delta,
#                                   iter = params$iterations,
#                                   chains = params$chains,
#                                   warmup = params$warmup,
#                                   seed = 12345)
#   
#   save(list = "M_memory_bias_Pilot",
#        file = "../Data/Pilot/Models/M_memory_bias_Pilot.RData")
#   
# } else {
#   
#   load("../Data/Pilot/Models/M_memory_bias_Pilot.RData")
#   load("../Data/Exp1/Models/M_memory_bias_Exp1.RData")
#   
# }
# 


