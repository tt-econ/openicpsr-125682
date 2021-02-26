classdef ExampleModel < MleModel
%
% ExampleModel shows how to implement a simple MleModel that estimates the mean and standard 
%   deviation of a normal variable.
%

properties
    paramlist = {'mu', 'sigma'};
    lhslist = '';
    rhslist = {};
    default_startparam = [0; 1];
    indiv_unobs_list = {};
    group_unobs_list = {};
    error_list = {'epsilon'};
    error_distributions = struct('epsilon', @(P)norminv(P,0,1));
    error_dimensions = struct('epsilon', 1);
    dparamlist = {'lnsigma', 'CV'}
    varname;
end

methods
    function obj = ExampleModel(varname, varargin)
        obj = obj@MleModel(varargin{:});
        obj.lhslist = varname;
    end
end

methods (Access = protected)
    function clik = ComputeConditionalLikelihoodVector(obj, param, data)
        clik = normpdf(data.var.(obj.lhslist), param(obj.indices.mu), param(obj.indices.sigma));
    end

    function lhs = ComputeOutcomes(obj, param, data)
        lhs.(obj.lhslist) = param(obj.indices.mu) + param(obj.indices.sigma) * data.var.epsilon;
    end

    function dparam = DerivedParam(obj, param, ~, paramname)
        switch paramname
            case 'lnsigma'
                dparam = log(param(obj.indices.sigma));
            case 'CV'
                dparam = param(obj.indices.sigma)/param(obj.indices.mu);
        end
    end
end

end