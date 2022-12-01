function [lik,latents] = likfun_PG(x,data,model)
    
    % Likelihood function for the policy gradient model.
    
    [p1, p2] = PG(x,data,model);       % 2 learning rates
    %[p1, p2] = PG_1LR(x,data,model);    % 1 learning rate
    
    lik = sum(safelog(p1));  % log-likelihood
    
    if nargout > 1
        latents.p1 = p1;
        latents.p2 = p2;
    end