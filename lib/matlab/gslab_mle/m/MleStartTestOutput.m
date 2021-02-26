classdef MleStartTestOutput < MleSetOfEstimates
%
% MleBootstrapOutput holds bootstrap estimates of the MLE model.
%

properties
    est_init         % baseline estimates
    lb               % lower bound for starting values
    ub               % upper bound for starting values
end

properties (Dependent = true)
    param_init       % parameters at baseline estimates
    dparam_init      % derived parameters at baseline estimates
    param_matrix     % Rectangular array of parameters
    dparam_matrix    % Rectangular array of derived parameters
    startparam_matrix     % Rectangular array of starting values
    dstartparam_matrix    % Rectangular array of derived parameters implied by starting values
end

methods (Access = private)
    function bool = IsValidStartTestOutput(obj)
        bool = true;
        for i=1:obj.nest
            bool = bool &...
                isequal(size(obj.estimates{i}.estopts.startparam),size(obj.param_init));
        end
    end
end

methods
    function obj = MleStartTestOutput(estimates, est_init, lb, ub)
        obj = obj@MleSetOfEstimates(estimates);
        obj.est_init = est_init;
        obj.lb = lb;
        obj.ub = ub;
        assert(obj.IsValidStartTestOutput);
    end
    
    function param_init = get.param_init(obj)
        param_init = obj.est_init.param;
    end
    
    function dparam_init = get.dparam_init(obj)
        dparam_init = obj.est_init.dparam;
    end
    
    function param_matrix = get.param_matrix(obj)
        param_matrix = cell2mat(obj.param_array')';
    end

    function dparam_matrix = get.dparam_matrix(obj)
        dparam_matrix = cell2mat(obj.dparam_array')';
    end
    
    function startparam_matrix = get.startparam_matrix(obj)
        startparam_matrix = cell2mat(obj.startparam_array')';
    end
    
    function dstartparam_matrix = get.dstartparam_matrix(obj)
        dstartparam_matrix = cell2mat(obj.dstartparam_array')';
    end
        
    function Play( obj )
        % 
        % PLAY Outputs human-readable summary of start value test
        %
        disp(' ');
        disp(' ');
        disp('OUTPUT FROM RANDOMLY VARYING STARTING VALUES');
        disp(' ');
        fprintf('MODEL: %10s\n', class(obj.est_init.model));
        disp(' ');
        fprintf('NUMBER OF STARTS:     %15.0f\n', obj.nest);
        disp(' ');
        disp(' ');
        disp('       Parameter         ');        
        disp('------------------------ ');
        disp('                             Initial       Start Value Bounds    Start Value Draws            Estimates    ');
        disp('                               Est.          Min       Max        Min        Max            Min        Max   ');

        
        pmin = min(obj.param_matrix)';
        pmax = max(obj.param_matrix)';
        startmin = min(obj.startparam_matrix)';
        startmax = max(obj.startparam_matrix)';
        
        for i=1:obj.est_init.model.nparam
            fprintf('%-25s %10.4f %12.4f %11.4f %9.4f %10.4f %12.4f %12.4f\n', obj.est_init.model.paramlist{i}, ... 
                [obj.param_init(i) obj.lb(i) obj.ub(i) startmin(i) startmax(i) pmin(i) pmax(i)]); 
        end
        
        
        if ~isempty(obj.est_init.model.dparamlist)      
            dmin = min(obj.dparam_matrix)';
            dmax = max(obj.dparam_matrix)';
            dstartmin = min(obj.dstartparam_matrix)';
            dstartmax = max(obj.dstartparam_matrix)';
            disp(' ');
            disp(' Derived Parameter       ');        
            disp('------------------------ ');
        disp('                             Initial         Start Value Draws             Estimates    ');
        disp('                               Est.           Min        Max            Min        Max   ');
            for i=1:obj.est_init.model.ndparam
                fprintf('%-25s %10.4f %12.4f %12.4f %12.4f %12.4f\n', obj.est_init.model.dparamlist{i}, ... 
                    [obj.dparam_init(i) dstartmin(i) dstartmax(i) dmin(i) dmax(i)]); 
            end
        end     
         
    end
        
end

end
