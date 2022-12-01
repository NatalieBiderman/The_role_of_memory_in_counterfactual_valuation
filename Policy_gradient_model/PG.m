function [p1, p2] = PG(x,data,model)
    
    % Probabilities of making same choice as the subject, using the policy gradient model.
    
    beta = x(:,1)';
    alpha_chosen = x(:,2)';
    alpha_unchosen = x(:,3)';
    
    % deliberation phase
    theta_chosen = data.rating_chosen;            % initial policy parameters
    theta_unchosen = data.rating_unchosen;
    
    p1 = 1./(1+exp(-beta.*(theta_chosen-theta_unchosen))); % choice probability
    
    % memory score
    if model == 1
        mem_unchosen = data.memscore_unchosen;%scaled_memscore_unchosen;
    elseif model == 2
        mem_unchosen = mean(data.memscore_unchosen);%scaled_memscore_unchosen);
    else
        mem_unchosen = 1;
    end
    
    % outcome phase
    V = mean(data.reward);
    grad_chosen = (data.reward - V).*beta.*p1.*(1-p1);
    theta_chosen = theta_chosen + alpha_chosen.*grad_chosen;
    theta_unchosen = theta_unchosen - alpha_unchosen.*grad_chosen.*mem_unchosen;
    
    % final choice probabilities
    p2 = zeros(size(data.chosen_pair,1),size(x,1));
    for i = 1:length(data.chosen_pair)
        if data.chosen_pair(i)
            ix1 = data.chosen_obj==data.final_chosen_obj(i);
            ix2 = data.chosen_obj==data.final_unchosen_obj(i);
            p2(i,:) = 1./(1+exp(-beta.*(theta_chosen(ix1,:)-theta_chosen(ix2,:))));
        else
            ix1 = data.unchosen_obj==data.final_chosen_obj(i);
            ix2 = data.unchosen_obj==data.final_unchosen_obj(i);
            p2(i,:) = 1./(1+exp(-beta.*(theta_unchosen(ix1,:)-theta_unchosen(ix2,:))));
        end
    end