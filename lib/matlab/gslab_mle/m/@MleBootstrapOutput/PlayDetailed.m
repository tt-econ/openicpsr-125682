function PlayDetailed( obj )
    % 
    % PLAYDETAILED Outputs a human-readable readable summary of 
    % different bootstrap confidence intervals from MleBootstrapOutput

    PlayHeader(obj, 'PARAMETRIC BOOTSTRAP DETAILED RESULTS');

    disp('PARAMETER ESTIMATES AND BOOTSTRAP CONFIDENCE INTERVALS');
    display_header
    
    stats = obj.BootstrapStats(obj.param_matrix, obj.param_true);
    for r = 1 : obj.model.nparam    
        print_line(obj.model.paramlist{r}, ... 
            obj.param_true(r), obj.bias_bstrap(r), obj.se_bstrap(r),...
            stats.ci_low(r), stats.ci_high(r),... 
            stats.pci_low(r), stats.pci_high(r),...
            stats.bci_low(r), stats.bci_high(r)); 
    end
    if ~isempty(obj.model.dparamlist)
        disp(' ');
        disp('DERIVED PARAMETER ESTIMATES AND BOOTSTRAP CONFIDENCE INTERVALS');
        display_header
        dstats = obj.BootstrapStats(obj.dparam_matrix, obj.dparam_true);
        for r = 1 : obj.model.ndparam
            print_line(obj.model.dparamlist{r}, ... 
                obj.dparam_true(r), obj.dbias_bstrap(r), obj.dse_bstrap(r),...
                dstats.ci_low(r), dstats.ci_high(r),...
                dstats.pci_low(r), dstats.pci_high(r),...
                dstats.bci_low(r), dstats.bci_high(r)); 
        end
    end
    disp(' ');
    disp('(N)    normal confidence interval');
    disp('(P)    percentile confidence interval');
    disp('(BC)   bias-corrected confidence interval');
    disp(' ');
end    

function display_header
    disp(' ');
    disp('        Parameter        ');
    disp('------------------------ ');
    disp('                             Observed                   Bootstrap                             ');
    disp('                               Est.          Bias       Std. Err.        [95% Conf. Interval] ');
end

function print_line(paramname, param_true, bias, se, ci_low, ci_high, pci_low, pci_high, bci_low, bci_high)
        fprintf('%-25s %10.4f %13.4f %13.4f %15.4f %12.4f %8s\n', paramname, ... 
            [param_true bias se ci_low ci_high],'(N)'); 
        fprintf('%-64s %15.4f %12.4f %8s\n', '', ... 
            [pci_low pci_high], '(P)'); 
        fprintf('%-64s %15.4f %12.4f %8s\n', '', ... 
            [bci_low bci_high], '(BC)'); 
end
