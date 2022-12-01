# function to preprocess data from mturk experiments

def process_mturk_csv(data_folder, condition_col, Exp):
    
    import glob
    import pandas as pd
    import numpy as np

    # Load individual csvs and combine into a single csv
    
    # experimental data
    data_files = glob.glob(data_folder + '/Individual_data/*.csv')
    if (len(data_files)!=0):
        raw_data = pd.concat([ pd.read_csv(f) for f in data_files ]).assign(Exp = Exp)
        raw_data = raw_data.rename(columns={"index": "trial"})
    else: 
        raw_data = []
    
    # interactive data
    int_data_files = glob.glob(data_folder + '/Interactive_data/*.csv')
    if (len(int_data_files)!=0):
        raw_int_data = pd.concat([ pd.read_csv(f) for f in int_data_files ]).assign(Exp = Exp)
    else: 
        raw_int_data = []
        
   
    # Add experimental group (sorted by date of experiment) to raw_data 
    exp_groups = raw_data.loc[raw_data.trial_index==0,["PID","start_time"]].reset_index().drop(columns="index")
    exp_groups["group"] = exp_groups["start_time"].str.slice(0,9)
    exp_groups = exp_groups.drop(columns="start_time")
    raw_data = raw_data.merge(exp_groups, on="PID", how="left")

    # turn rt to integer
    raw_data.loc[~np.isnan(raw_data["rt"]),"rt"]=raw_data.loc[~np.isnan(raw_data["rt"]),"rt"].astype(int)/1000

    # add phase info to trials
    phases = pd.unique(raw_data.category[raw_data.category.str.contains("instructions")]).tolist()
    phases.remove("debreif_clear_instructions")
    phases.extend(["debreif_intro", "debreif_end"])
    phases.insert(0, "full_screen")
    start_ind = 0;
    for sub in np.unique(raw_data.PID):
        for i in range(0, len(phases)-1):
            start_ind = raw_data.index[(raw_data.PID == sub) & (raw_data.category == phases[i])].tolist()
            end_ind = raw_data.index[(raw_data.PID == sub) & (raw_data.category == phases[i+1])].tolist()
            if start_ind and end_ind: 
                raw_data.loc[range(start_ind[0],end_ind[0]),"phase"] = pd.Series(phases[i]).str.replace("_instructions","")[0]
    
    # add phase info to interactions data frame
    raw_int_data = raw_int_data.reset_index().drop(columns="index");
    #for index, row in raw_int_data.iterrows(): 
    #    curr_trial = raw_int_data.loc[index, "trial"]
    #    raw_int_data.loc[index, "phase"] = list(raw_data.loc[(raw_data.PID == raw_int_data.loc[index, "PID"]) & (raw_data.trial_index == raw_int_data.loc[index, "trial"]), "phase"])
 
    # build a function to compute zscored rt 
    def compute_zscored_column(data, zscored_col, zscored_col_name):
        mean_by_sub = data.groupby("PID").agg(mean_col=(zscored_col,'mean'), std_col=(zscored_col,'std')).reset_index()
        data = data.merge(mean_by_sub, on="PID")
        data[zscored_col_name] = (data[zscored_col] - data.mean_col)/data.std_col
        data = data.drop(columns=["mean_col","std_col"])
        return data
    
    # build a function to compute zscored ratings for the left and right stims 
    def compute_zscored_ratings_per_stim(data):      
        for index, row in data.iterrows():
            data.loc[index, "zcored_rating_left"] = ratings.loc[(ratings.PID == data.loc[index, "PID"]) & (ratings.stimulus_id == data.loc[index, "stimulus_left"]),"zscored_rating"].mean()
            data.loc[index, "zcored_rating_right"] = ratings.loc[(ratings.PID == data.loc[index, "PID"]) & (ratings.stimulus_id == data.loc[index, "stimulus_right"]),"zscored_rating"].mean()
        data["zscored_delta_ratings"] = data["zcored_rating_left"] - data["zcored_rating_right"]
        return data
    
    
    # ==== Ratings ====
    
    ratings_columns = ["Exp", "group", "PID", "phase", "trial", "stimulus_id", "painting", "rt", "response"]
    ratings = raw_data.loc[raw_data["category"] == "rating"].reindex(columns = ratings_columns)
    ratings = ratings.reset_index().drop("index", axis=1)
    ratings = ratings.rename(columns = {'response': 'rating'})

    
    # compute zscored rt and ratings
    ratings = compute_zscored_column(ratings,"rt","zscored_rt")
    ratings = compute_zscored_column(ratings,"rating","zscored_rating")
    
    # ==== Deliberation ====
    
    deliberation_columns = ["Exp", "group", "PID","phase","block","trial","stimulus_left", "stimulus_right", "painting_left", "painting_right", "rating_left", "rating_right", "explain_trial", "reward_type", "left_chosen", "chosen_obj", "unchosen_obj", "rt"];
    if condition_col: 
        deliberation_columns.insert(4, condition_col)
    deliberation = raw_data.loc[raw_data["category"] == "deliberation"].reindex(columns = deliberation_columns)
    deliberation = deliberation.reset_index().drop("index", axis=1)
    
    # add explain responses
    #deliberation.loc[deliberation.explain_trial==1, "explain_response"] = raw_data.loc[(raw_data.category == "explain_trial") & (raw_data.phase == "deliberation"), "responses"].tolist()
    #deliberation["explain_response"] = deliberation.explain_response.str.replace('{"Q0":','').str.replace('}','').str.replace('"','')

    # compute zscored rt
    deliberation = compute_zscored_column(deliberation,"rt","zscored_rt")
    
    # add normalized ratings 
    deliberation["delta_ratings"] = deliberation["rating_left"] - deliberation["rating_right"]
    deliberation = compute_zscored_ratings_per_stim(deliberation)
  
    
    # ==== Interference ====

    if 'interference' in pd.unique(raw_data.phase):
        
        interference_columns = ["Exp","group", "PID","phase","condition","block","trial","stimulus_left", "stimulus_right", "painting_left", "painting_right", "rating_left", "rating_right", "explain_trial", "explain_response", "novel_left", "left_chosen", "chosen_obj", "unchosen_obj", "rt"];
        interference = raw_data.loc[raw_data["category"] == "interference"].reindex(columns = interference_columns)
        interference = interference.reset_index().drop("index", axis=1)
        
        # add explain responses
        #interference.loc[interference.explain_trial==1, "explain_response"] = raw_data.loc[(raw_data.category == "explain_trial") & (raw_data.phase == "interference"), "responses"].tolist()
        #interference["explain_response"] = interference.explain_response.str.replace('{"Q0":','').str.replace('}','').str.replace('"','')

        # compute zscored rt
        interference = compute_zscored_column(interference,"rt","zscored_rt")
        
        # add normalized ratings 
        interference["delta_ratings"] = interference["rating_left"] - interference["rating_right"]
        interference = compute_zscored_ratings_per_stim(interference)

    
    # ==== Reward Learning ====
    
    reward_columns = ["Exp","group", "PID","phase","block","trial","stimulus_id","reward_type","reward_amount","see_reward_rt"];
    reward_learning = raw_data.loc[raw_data["category"] == "see_reward"].reindex(columns = reward_columns)
    reward_learning = reward_learning.reset_index().drop("index", axis=1)
    reward_learning = compute_zscored_column(reward_learning,"see_reward_rt","zscored_see_reward_rt")

    # add registered response and rt   
    reward_learning["register_reward_response"] = raw_data.loc[raw_data.category == "reward_outcome", "register_reward_response"].tolist()
    reward_learning["register_reward_rt"] = raw_data.loc[raw_data.category == "reward_outcome", "register_reward_rt"].tolist()
    reward_learning = compute_zscored_column(reward_learning,"register_reward_rt","zscored_register_reward_rt")
    
    # add registration accuracy
    reward_learning["register_reward_acc"] = (reward_learning["register_reward_response"] == reward_learning["reward_type"]).astype(int)

    # ==== Final Decisions ====
    
    fd_columns = ["Exp", "group", "PID", "phase", "block", "trial", "chosen_trial", "gain_left", "stimulus_left", "stimulus_right", "painting_left", "painting_right", "rating_left", "rating_right", "left_chosen", "chosen_obj", "unchosen_obj", "higher_outcome_chosen","rt"];
    if condition_col: 
        fd_columns.insert(6, condition_col)

    # choose relevant columns
    final_decisions = raw_data.loc[raw_data["category"] == "final_decisions"].reindex(columns = fd_columns)
    final_decisions = final_decisions.reset_index().drop("index", axis=1)
    
    # compute zscored rt
    final_decisions = compute_zscored_column(final_decisions,"rt","zscored_rt")

    # add normalized ratings 
    final_decisions["delta_ratings"] = final_decisions["rating_left"] - final_decisions["rating_right"]
    final_decisions = compute_zscored_ratings_per_stim(final_decisions)    
    
    # ==== Memory ====
    
    memory_columns = ["Exp", "group", "PID", "phase", "trial", "old_pair", "stimulus_left", "stimulus_right", "old_response", "rt_pairs", "chosen_object", "left_object_chosen", "rt_object"];
    if condition_col: 
        memory_columns.insert(5, condition_col)
        
    # choose relevant columns
    memory = raw_data.loc[raw_data["category"] == "memory_pairs"].reindex(columns = memory_columns)
    memory = memory.reset_index().drop("index", axis=1)
    
    # add choice memory trials to mat
    memory.loc[memory.old_response == 1, "left_object_chosen"] = raw_data.loc[raw_data.category == "memory_chosen_object", "left_object_chosen"].tolist()
    memory.loc[memory.old_response == 1, "rt_object"] = raw_data.loc[raw_data.category == "memory_chosen_object", "rt_object"].tolist()
    
    # add pairs acc 
    memory["pairs_acc"] = (memory["old_response"] == memory["old_pair"]).astype(int)
    
    # normalize rt
    memory = compute_zscored_column(memory,"rt_pairs","zscored_rt_pairs")
    memory = compute_zscored_column(memory,"rt_object","zscored_rt_object")

    
    # ==== Outcome evaluation ====
    
    if 'outcome_evaluation' in pd.unique(raw_data.phase):
        outcome_eval_columns = ["Exp", "group", "PID", "phase", "trial", "stimulus_id", "painting", "rating",  "is_chosen", "outcome", "is_novel", "stim_type","outcome_eval_gain","outcome_eval_acc","outcome_eval_rt"];
        if condition_col: 
            outcome_eval_columns.insert(5, condition_col)
        outcome_evaluation = raw_data.loc[raw_data["category"] == "outcome_evaluation"].reindex(columns = outcome_eval_columns)
        outcome_evaluation = outcome_evaluation.reset_index().drop("index", axis=1)
        outcome_evaluation = compute_zscored_column(outcome_evaluation,"outcome_eval_rt","zscored_outcome_eval_rt")
    
        # add outcome evaluation confidence and rt  
        outcome_evaluation["outcome_eval_confidence"] = raw_data.loc[raw_data.category == "outcome_evaluation_confidence", "outcome_eval_confidence"].tolist()
        outcome_evaluation["outcome_eval_confidence_rt"] = raw_data.loc[raw_data.category == "outcome_evaluation_confidence", "outcome_eval_confidence_rt"].tolist()
        outcome_evaluation = compute_zscored_column(outcome_evaluation,"outcome_eval_confidence_rt","zscored_outcome_eval_confidence_rt")
    

    # ==== Debreif data ====
    
    debreif_columns = list(filter(lambda x: "debreif" in x, np.unique(raw_data.category)))
    debreif_columns = [ele for ele in debreif_columns if ele not in ["debreif_intro", "debreif_end"]]
    debrief = raw_data.loc[raw_data["category"].isin(debreif_columns)].reindex(columns = ["PID","category","responses"])
    # remove irrelevant substrings 
    debrief["response"] = debrief.responses.str.replace('{"Q0":','').str.replace('}','').str.replace('"','')
    debrief["category"] = debrief.category.str.replace('debreif_','')
    debrief = debrief.reset_index().drop(columns=["responses","index"],axis=1)
    
    # move to wide format
    debrief = debrief.pivot(index='PID', columns='category', values='response')
    
    # add experiment parameter
    debrief["Exp"] = Exp

    
    # ==== Save data frames ====
    
    ratings.to_csv("../../Data/" + Exp + "/Summary_data/all_subs/ratings.csv")
    deliberation.to_csv("../../Data/" + Exp + "/Summary_data/all_subs/deliberation.csv")
    reward_learning.to_csv("../../Data/" + Exp + "/Summary_data/all_subs/reward_learning.csv")
    final_decisions.to_csv("../../Data/" + Exp + "/Summary_data/all_subs/final_decisions.csv")
    memory.to_csv("../../Data/" + Exp + "/Summary_data/all_subs/memory.csv")
    raw_data.to_csv("../../Data/" + Exp + "/Summary_data/all_subs/all_data.csv")
    raw_int_data.to_csv("../../Data/" + Exp + "/Summary_data/all_subs/all_interaction_data.csv")
    debrief.to_csv("../../Data/" + Exp + "/Summary_data/all_subs/debrief.csv")
    if 'outcome_evaluation' in pd.unique(raw_data.phase):
        outcome_evaluation.to_csv("../../Data/" + Exp + "/Summary_data/all_subs/outcome_evaluation.csv")
    if 'interference' in pd.unique(raw_data.phase): 
        interference.to_csv("../../Data/" + Exp + "/Summary_data/all_subs/interference.csv")

    

def find_outlier_subs(final_decisions, all_data, all_int_data, blur_focus_criterion, missed_instructions_criterion, final_decisions_non_responses_criterion, full_screen_criterion, below_chance_chosen_final_decisions_criterion):
    
    import pandas as pd
    import numpy as np

    # assess warnings from information collected during the task and the interactions data
    warnings = all_data.loc[all_data["warning"]==1, ["PID", "category","phase"]].groupby(["PID","phase","category"]).agg(n = ("PID", "count")).reset_index()
    warnings = warnings.rename(columns={"category": "event"})
    interactions = all_int_data.groupby(["PID", "event"]).agg(n = ("PID", "count")).reset_index()

    #interactions = all_int_data.groupby(["PID", "phase","event"]).agg(n = ("PID", "count")).reset_index()
    all_events = pd.concat([warnings, interactions]).sort_values(by=["PID", "phase", "event", "n"], ascending = False).reset_index()
    
    # compute performance in final decisions phase for chosen pairs
    p_gain = final_decisions[(final_decisions.chosen_trial==1) & (~pd.isnull(final_decisions["rt"]))].groupby("PID").agg(p_gain = ("higher_outcome_chosen","mean")).reset_index()
    chosen_pairs_perf = pd.DataFrame();
    for index, row in p_gain.iterrows():
        chosen_pairs_perf.loc[index, "index"] = 0;
        chosen_pairs_perf.loc[index, "PID"] = p_gain.loc[index, "PID"];
        chosen_pairs_perf.loc[index, "phase"] = "final_decisions";
        chosen_pairs_perf.loc[index, "event"] = "chosen_pairs_p_gain";
        chosen_pairs_perf.loc[index, "n"] = p_gain.loc[index, "p_gain"];

    all_events = all_events.append(chosen_pairs_perf).sort_values(by="PID")

    # find outlier subjects     
    all_events["outlier"] = sum(
        (((all_events.event=="respond_faster") & (all_events.n > final_decisions_non_responses_criterion)),                         
         ((all_events.event=="blur") & (all_events.n > blur_focus_criterion)),
         ((all_events.event=="focus") & (all_events.n > blur_focus_criterion)),
         ((all_events.event=="fullscreenenter") & (all_events.n > full_screen_criterion)), 
         ((all_events.event=="fullscreenexit") & (all_events.n > full_screen_criterion)),
         ((all_events.event=="missed_instruction_checkup") & (all_events.n > missed_instructions_criterion)),
         ((all_events.event=="chosen_pairs_p_gain") & (all_events.n < below_chance_chosen_final_decisions_criterion))))
         
                    
    outlier_subs = np.unique(all_events.PID[all_events.outlier==1])
    
    # return warnings mat 
    return all_events, outlier_subs

def remove_outlier_subs(outliers, df, df_name, Exp):        
        
    # remove outliers from df
    df = df[~df["PID"].isin(outliers)]
    
    # save new df 
    df.to_csv("../../Data/" + Exp + "/Summary_data/non_outlier_subs/" + df_name + ".csv")


    return df

    

