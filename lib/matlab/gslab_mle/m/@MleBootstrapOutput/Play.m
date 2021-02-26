function Play( obj )
    % 
    % PLAY Outputs a human-readable readable summary of MleBootstrapOutput
    %

    PlayHeader(obj, 'PARAMETRIC BOOTSTRAP RESULTS');

    disp('PARAMETER ESTIMATES');
    display_header
    stats = obj.BootstrapStats(obj.param_matrix, obj.param_true);
    for r = 1 : obj.model.nparam    
        print_line(obj.model.paramlist{r}, ...
            obj.param_true(r), obj.se_bstrap(r), stats.z(r), stats.p(r), ...
            stats.ci_low(r), stats.ci_high(r)); 
    end
    if ~isempty(obj.model.dparamlist)
        disp(' ');
        disp('DERIVED PARAMETER ESTIMATES');
        display_header
        dstats = obj.BootstrapStats(obj.dparam_matrix, obj.dparam_true);
        for r = 1 : obj.model.ndparam    
            print_line(obj.model.dparamlist{r}, ... 
                obj.dparam_true(r), obj.dse_bstrap(r), dstats.z(r), dstats.p(r), ...
                dstats.ci_low(r), dstats.ci_high(r)); 
        end
    end
    disp(' ');
    
end

function display_header
    disp(' ');
    disp('       Parameter         ');        
    disp('------------------------ ');
    disp('                             Observed    Bootstrap                             Normal-based     ');
    disp('                               Est.      Std. Err.       Z        P>|z|    [95% Conf. Interval] ');
end

function print_line(paramname, param_true, se, z, p, ci_low, ci_high)
    fprintf('%-25s %10.4f %12.4f %11.4f %9.4f %10.4f %12.4f\n', paramname, ... 
        [param_true se z p ci_low ci_high]); 
end
