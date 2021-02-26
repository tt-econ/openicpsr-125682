classdef MleBootstrapOutput < MleSetOfEstimates
%
% MleBootstrapOutput holds bootstrap estimates of the MLE model.
%

properties
    param_true       % true parameters used to perform simulations
    model            % model that was bootstrapped
    param_matrix     % matrix of parameters: nest x nparam
    dparam_matrix    % matrix of derived parameters: nest x ndparam
    reps             % number of bootstrap replications
    dparam_true      % derived parameters implied by param_true
end

properties (Dependent = true)
    param_bstrap     % mean of bootstrap estimates
    bias_bstrap      % mean bias of bootstrap estimates
    vcov_bstrap      % empirical variance-covariance matrix of bootstrap estimates
    se_bstrap        % empirical standard error of bootstrap estimates
    dparam_bstrap    % mean of bootstrap estimates of derived parameters
    dbias_bstrap     
    dvcov_bstrap 
    dse_bstrap
end

methods (Access = private)
    function bool = IsValidBootstrapOutput(obj)
        bool = true;
        for i=1:obj.nest
            bool = bool & obj.estimates{i}.model.nparam==obj.model.nparam;
        end
    end
end

methods
    function obj = MleBootstrapOutput(est_sim, param_true, model, dparam_true)
        obj = obj@MleSetOfEstimates(est_sim);
        obj.param_true = param_true;
        obj.model = model;
        obj.dparam_true = dparam_true;
        obj.reps = obj.nest; % intentional duplicate for intuitive naming %
        obj.param_matrix = zeros(obj.reps, obj.model.nparam);
        for i = 1 : obj.reps
            obj.param_matrix(i, :) = obj.estimates{i}.param';
        end
        if ~isempty(obj.model.dparamlist)            
            obj.dparam_matrix = zeros(obj.reps, obj.model.ndparam);
           for i = 1 : obj.reps
                obj.dparam_matrix(i, :) = obj.estimates{i}.dparam';
           end 
        end
        assert(obj.IsValidBootstrapOutput);
    end
       
    function param_bstrap = get.param_bstrap(obj)     
        param_bstrap = mean(obj.param_matrix)';
    end

    function vcov_bstrap = get.vcov_bstrap(obj)    
        vcov_bstrap = cov(obj.param_matrix);
    end      
    
    function se_bstrap = get.se_bstrap(obj)    
        se_bstrap = sqrt(diag(obj.vcov_bstrap));
    end        
    
    function bias_bstrap = get.bias_bstrap(obj)
        bias_bstrap = obj.param_bstrap - obj.param_true;
    end
    
    function dparam_bstrap = get.dparam_bstrap(obj)     
        dparam_bstrap = mean(obj.dparam_matrix)';
    end

    function dvcov_bstrap = get.dvcov_bstrap(obj)    
        dvcov_bstrap = cov(obj.dparam_matrix);
    end      
    
    function dse_bstrap = get.dse_bstrap(obj)    
        dse_bstrap = sqrt(diag(obj.dvcov_bstrap));
    end        
    
    function dbias_bstrap = get.dbias_bstrap(obj)
        dbias_bstrap = obj.dparam_bstrap - obj.dparam_true;
    end
    
    Play( obj )
    PlayDetailed( obj )
end

methods (Static)
    stats = BootstrapStats(param_matrix, param_true)
end

methods (Hidden, Access = private)
	PlayHeader( obj, header )        
end

end
