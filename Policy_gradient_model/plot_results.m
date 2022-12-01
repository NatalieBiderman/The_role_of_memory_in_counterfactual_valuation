function plot_results(fig,data,results)
    
    switch fig
        
        case 'choiceprob'
            
            models = {'variable' 'fixed' 'perfect'};
            
            for k = 1:3
                for s = 1:length(data)
                    latents = results(k).latents(s);
                    for i = 1:2
                        for j = 1:2
                            ix = data(s).condition==i-1 & data(s).chosen_pair==j-1;
                            G = latents.p(ix).*data(s).gain(ix) + (1-latents.p(ix)).*(1-data(s).gain(ix));
                            g(s,3-j,i) = nanmean(G);
                        end
                    end
                end
                
                disp(models{k});
                x = squeeze(g(:,1,:));
                v = x(:,2) - x(:,1);
                d = mean(v)/std(v);
                [~,p,~,stat] = ttest(x(:,1),x(:,2));
                disp(['chosen: t(',num2str(stat.df),') = ',num2str(stat.tstat),', p = ',num2str(p),', d = ',num2str(d)]);
                
                x = squeeze(g(:,2,:));
                [~,p,~,stat] = ttest(x(:,1),x(:,2));
                v = x(:,2) - x(:,1);
                d = mean(v)/std(v);
                disp(['unchosen: t(',num2str(stat.df),') = ',num2str(stat.tstat),', p = ',num2str(p),', d = ',num2str(d)]);
                V(:,k) = v;
                m(k) = mean(v);
                se(k) = std(v)./sqrt(length(v));
            end
            
            [~,p,~,stat] = ttest(V(:,1),V(:,2))
            
            barerrorbar(m',se'); colormap bone
            set(gca,'XTickLabel',{'Variable' 'Fixed' 'Perfect'},'FontSize',25);
            ylabel('\Delta P(S+|unchosen)','FontSize',25);


    end