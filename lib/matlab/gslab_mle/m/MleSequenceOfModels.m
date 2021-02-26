classdef MleSequenceOfModels
%
% Abstract class to handle operations performed on an ordered sequence of models.
%

properties
    models                 = {}     % Cell array of models
end

methods
    function obj = MleSequenceOfModels(varargin)
        if nargin > 0
            obj = obj.AssignOptions(varargin{:});
        end
    end
end

properties (Dependent = true)
    nmodel      % Number of models
end

methods
    function nmodel = get.nmodel(obj)
        nmodel = length(obj.models);
    end
    function est = Estimate(obj, dataarray, estoptsarray)    
        est = cell(1, obj.nmodel);
        est{1} = obj.models{1}.Estimate(dataarray{1}, estoptsarray{1});
        for i=2:obj.nmodel
            estoptsarray{i}.first_step_param = est{i-1}.GetParamSubset(estoptsarray{i}.first_step_paramlist);
            if ~isempty(est{i-1}.vcov)
                estoptsarray{i}.first_step_vcov = est{i-1}.GetVCovSubset(estoptsarray{i}.first_step_paramlist);
            end
            est{i} = obj.models{i}.Estimate(dataarray{i}, estoptsarray{i});
        end
    end
end

methods (Hidden, Access = protected)
    function obj = AssignOptions(obj, varargin)
        option_struct = parse_option_list(varargin{:});
        for field = fieldnames(option_struct)'
            obj.(field{:}) = option_struct.(field{:});
        end
    end
end

end
