
# -----------------------
# General plotting themes
# -----------------------

theme <- theme_classic() + 
  theme(plot.title = element_text(hjust = 0.5, size = 28), 
       text = element_text(size=20,family="Helvetica"),
       axis.title = element_text(size = 24), 
       axis.text = element_text(size = 21, color = "black"), 
       legend.position = "top",
       legend.title = element_blank(),
       legend.spacing.x = unit(0.2,'cm'),
       axis.line = element_line(size = 1), 
       axis.ticks = element_blank(),  
       aspect.ratio = 2/3,
       strip.background=element_blank(),
       panel.grid.major = element_blank())

point_plot_theme <- theme_classic() + 
  theme(text = element_text(size=20,family="Helvetica"),
        axis.title = element_text(size = 24), 
        axis.text = element_text(size = 21, color = "black"),
        panel.spacing.x=unit(1,"line"), 
        axis.line=element_blank(), aspect.ratio=1) + 
  panel_border(colour="black", size=2, linetype=1, remove=FALSE)

# -----------------------------
# Plot Bayesian regression line
# -----------------------------

create_posterior_draws_lines <- function(n_fake_samples, min_x, max_x, model_draws, conditions, conditions_col_names, is_logistic){
  
  library("arm")
  library("dplyr")
  
  # create x fake steps 
  x_steps <- seq(min_x, max_x, length.out=n_fake_samples)
  summary_draws <- c()
  
  for (i in 1:length(conditions)){
    
    # find columns that correspond the current condition
    intercept_col <- which(grepl(paste0("intercept_",conditions[i]),colnames(model_draws)))
    slope_col <- which(grepl(paste0("slope_",conditions[i]),colnames(model_draws)))
    
    # predict the probability for a gain response for each posterior iteration in current x value 
    pred_fake <- as.data.frame(matrix(0,nrow=nrow(model_draws),ncol=n_fake_samples))
    for (x in 1:n_fake_samples){
      if (is_logistic==1){
        pred_fake[,x] <- invlogit(as.numeric(unlist(model_draws[intercept_col] + model_draws[slope_col]*x_steps[x])))
      } else {
        pred_fake[,x] <- as.numeric(unlist(model_draws[intercept_col] + model_draws[slope_col]*x_steps[x]))
      }
    }
    
    # create a table summarizing the draws for each x step 
    df_x <- data.frame(x = x_steps, obs = 1:length(x_steps))
    df_pred <- pred_fake %>% 
      setNames(seq_len(ncol(.))) %>% 
      tibble::rownames_to_column("posterior_sample") %>% 
      tidyr::gather_("obs", "fitted", setdiff(names(.), "posterior_sample")) %>%
      group_by(obs) %>% 
      dplyr::summarise(median = median(fitted),
                       lower = quantile(fitted, 0.025), 
                       upper = quantile(fitted, 0.975)) %>%
      mutate(obs = as.numeric(obs)) %>%
      left_join(df_x, by="obs") %>% 
      arrange(obs) %>%
      mutate(condition = conditions[i])
    
    summary_draws <- bind_rows(summary_draws, df_pred)
  }
  
  summary_draws <- summary_draws %>% separate(condition, conditions_col_names)
  
  return(summary_draws)
}


