classdef MleSetOfEstimates
%
% MleSetOfEstimates holds an array of estimation results.
%

properties
    estimates       % Cell array of MleEstimationOutput objects
end

properties (Dependent = true)
    nest            % number of estimates
    param_array     % Cell array of parameter estimates
    dparam_array    % Cell array of derived parameter estimates
    startparam_array  % Cell array of starting parameters
    dstartparam_array % Cell array of derived parameters implied by starts
end

methods (Access = private)
    function bool = IsValidSetOfEstimates(obj)
        bool = true;
        for i=1:obj.nest
            bool = bool && obj.estimates{i}.IsValidEstimate;
        end
    end
end


methods
    function obj = MleSetOfEstimates(estimates)
        if nargin>0
            obj.estimates = estimates;
        end
        assert(obj.IsValidSetOfEstimates);
    end
    
    function nest = get.nest(obj)
        nest = length(obj.estimates);
    end
    
    function param_array = get.param_array(obj)
        param_array = cell(obj.nest, 1);
        for i=1:obj.nest
            param_array{i} = obj.estimates{i}.param;
        end
    end
    
    function dparam_array = get.dparam_array(obj)
        dparam_array = cell(obj.nest, 1);
        for i=1:obj.nest
            dparam_array{i} = obj.estimates{i}.dparam;
        end
    end
    
    function startparam_array = get.startparam_array(obj)
        startparam_array = cell(obj.nest, 1);
        for i=1:obj.nest
            startparam_array{i} = obj.estimates{i}.estopts.startparam;
        end
    end
    
    function dstartparam_array = get.dstartparam_array(obj)
        dstartparam_array = cell(obj.nest, 1);
        for i=1:obj.nest
            dstartparam_array{i} = obj.estimates{i}.model.GetDerivedParam(...
                obj.estimates{i}.estopts.startparam, obj.estimates{i}.const);
        end
    end
    
    function Play( obj, indices )
        % 
        % PLAY Outputs human-readable summary of estimates specified in
        % indices
        
        % INPUTS
        %
        %    - indices: Positional indices of the estimates to play.
        %

        if nargin==1
            indices = 1:obj.nest;
        end
        
        for i=indices
            obj.estimates{i}.Play
        end
        
    end

end


end
