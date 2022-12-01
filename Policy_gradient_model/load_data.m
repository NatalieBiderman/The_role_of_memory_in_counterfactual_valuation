function data = load_data(exp)
    
    % read in data files
    delib = readtable('data/deliberation_choices.csv');%readtable('delib.csv');
    decision = readtable('data/final_decisions_choices.csv');%readtable('decision.csv');
    
    % filter data
    if nargin == 1        
        delib = delib(strcmp(delib.Exp,exp),:);
        decision = decision(strcmp(decision.Exp,exp),:);
    end

    % NB - add scaled memory score
    delib.scaled_memory_score_chosen = (delib.memory_score_chosen + 1)/2;
    delib.scaled_memory_score_unchosen = (delib.memory_score_unchosen + 1)/2;
    
    % sort table by PID
    delib = sortrows(delib, 3);
    decision = sortrows(decision,3);

    % identify unique subjects
    S = sort(unique(delib.PID));
    
    % create data structure
    for s = 1:length(S)
        ix = strcmp(delib.PID,S{s});
        data(s).chosen_obj = delib.chosen_obj(ix);
        data(s).unchosen_obj = delib.unchosen_obj(ix);
        data(s).rating_chosen = delib.rating_chosen(ix)/100;
        data(s).rating_unchosen = delib.rating_unchosen(ix)/100;
        data(s).zrating_chosen = delib.zscored_rating_chosen(ix); % NB - add zscored ratings
        data(s).zrating_unchosen = delib.zscored_rating_unchosen(ix); % NB - add zscored ratings
        data(s).memscore_chosen = delib.memory_score_chosen(ix);
        data(s).memscore_unchosen = delib.memory_score_unchosen(ix);
        data(s).scaled_memscore_chosen = delib.scaled_memory_score_chosen(ix);
        data(s).scaled_memscore_unchosen = delib.scaled_memory_score_unchosen(ix);
        data(s).reward = delib.reward(ix);
        data(s).zreward = zscore(delib.reward(ix));
        
        experiment = delib.Exp(ix);
        if strcmp(experiment{1},'Pilot')
            data(s).exp = 1;
        else
            data(s).exp = 2;
        end
        
        ix = strcmp(decision.PID,S{s}) & ~isnan(decision.chosen_obj);
        data(s).final_chosen_obj = decision.chosen_obj(ix);
        data(s).final_unchosen_obj = decision.unchosen_obj(ix);
        data(s).chosen_pair = strcmp(decision.choice_type(ix),'chosen_pair');
        data(s).gain = decision.gain_item_chosen(ix);
        data(s).condition = strcmp(decision.condition(ix),'interference');
        
        data(s).N = length(data(s).chosen_pair);    % number of final choice trials
        data(s).C = 2;                              % number of choices
    end
end  