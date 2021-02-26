classdef LinearModelWithSigmaSq < MleModel
%
% LinearModelWithSigmaSq implements MleModel class for the Linear Regression Model.
% Here the variance sigma2 is our parameter instead of the standard error
% sigma
%

properties
    paramlist = {'sigma_sq'};
    default_startparam = [];
    lhslist = '';
    rhslist = {};
    indiv_unobs_list = {};
    group_unobs_list = {};
    error_list = {'epsilon'};
    error_distributions = struct('epsilon', @(p)norminv(p) );
    error_dimensions = struct('epsilon', 1);
    dparamlist = {};
    include_constant = true;        % Estimate model with constant term
end

methods
    function obj = LinearModelWithSigmaSq(lhs, rhs, varargin)
        obj = obj@MleModel(varargin{:});
        obj.lhslist = lhs;
        obj.rhslist = rhs;
        obj.paramlist = MleModel.AddCoefficients(obj.paramlist, rhs, obj.include_constant);
        obj.default_startparam = zeros(obj.nparam, 1);
        obj.default_startparam(obj.indices.sigma_sq) = 1;
        assert( IsValidModel(obj) );
    end
end

methods (Hidden, Access = protected)
    function clik = ComputeConditionalLikelihoodVector(obj, param, data)
        xb = obj.XBeta(obj.rhslist, data, param, obj.include_constant);
        clik = normpdf(data.var.(obj.lhslist), xb, sqrt(param(obj.indices.sigma_sq)));
    end

    function lhs = ComputeOutcomes(obj, param, data)
        xb = obj.XBeta(obj.rhslist, data, param, obj.include_constant);
        eps = data.var.epsilon * sqrt(param(obj.indices.sigma_sq));
        lhs.(obj.lhslist) = xb+eps;
    end

    function unobs = TransformUnobservables(~, ~, ~, raw_unobs)
        unobs = raw_unobs;
    end
end

end