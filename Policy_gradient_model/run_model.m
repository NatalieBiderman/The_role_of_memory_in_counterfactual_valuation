
% =========================================================================
% fit models
% =========================================================================

% load data
data = load_data("Exp1");

% fit models for exp1 and plot
[results_exp1,bms_results_exp1] = fit_models(data([data.exp] == 2));
plot_results('choiceprob',data([data.exp] == 2),results_exp1)

%[results_pilot,bms_results_pilot] = fit_models(data([data.exp] == 1));
%[results_all_exps,bms_results_all_exps] = fit_models(data);
%plot_results('choiceprob',data,results_all_exps)
%plot_results('choiceprob',data([data.exp] == 1),results_pilot)

% =========================================================================
% save results in csv
% =========================================================================

% load data
delib = readtable('data/deliberation_choices.csv');%readtable('delib.csv');
decision = readtable('data/final_decisions_choices.csv');%readtable('decision.csv');
    
% use data from exp1 only 
decision = decision(decision.Exp == "Exp1",:);
delib = delib(delib.Exp == "Exp1",:);

% remove nans from decision table 
decision_clean = sortrows(decision(~isnan(decision.chosen_obj),:),"PID");
S = sort(unique(delib.PID));
gain_choice_prob = zeros(height(decision_clean),3);
for m=1:3
    i=1;
    for s=1:length(S)
        sub_data = results_exp1(m).latents(s).p;
        gain_choice_prob(i:i+length(sub_data)-1,m) = sub_data;
        i = i+length(sub_data);
    end
end
% add columns to table
decision_clean.gain_prob_variable = gain_choice_prob(:,1);
decision_clean.gain_prob_fixed = gain_choice_prob(:,2);
decision_clean.gain_prob_perfect = gain_choice_prob(:,3);
% save to csv
writetable(decision_clean,"data/fd_predictions.csv")
