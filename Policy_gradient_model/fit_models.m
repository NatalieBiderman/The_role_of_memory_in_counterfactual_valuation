function [results, bms_results] = fit_models(data)
    
    % Fit models using importance sampling and perform random-effects
    % Bayesian model comparison.
    
    rng(2); % set random seed for reproducibility
    
    K = 9000;   % number of samples
    x = [unifrnd(0,15,K,1) unifrnd(0,1,K,2)];  % 2 learning rates
    %x = [unifrnd(0,15,K,1) unifrnd(0,1,K,1)];   % 1 learning rate
    
    models = {'variable' 'fixed' 'perfect'};
    
    for m = 1:length(models)
        
        disp(models{m})
        
        switch models{m}
            case 'variable'
                likfun = @(x,data) likfun_PG(x,data,1);
                
            case 'fixed'
                likfun = @(x,data) likfun_PG(x,data,2);
                
            case 'perfect'
                likfun = @(x,data) likfun_PG(x,data,3);
        end
        
        for s = 1:length(data)
            [lik, latents] = likfun(x,data(s));
            lme(s,m) = logsumexp(lik);
            w = exp(lik-lme(s,m));  % importance weights
            results(m).latents(s).p = latents.p2*w'; % choice probabilities
            results(m).x(s,:) = w*x;                % parameter estimates
            lik_pred(s,m) = sum(safelog(results(m).latents(s).p));
        end
        
        % model comparison
        [bms_results.alpha,bms_results.exp_r,bms_results.xp,bms_results.pxp,bms_results.bor,bms_results.g] = bms(lik_pred);
        bms_results.lik_pred = lik_pred;
        
    end