classdef BinaryLogitModel < MleModel
%
% BinaryLogitModel implements MleModel class for the Binary Logit with mixed logit option.
%

properties
    paramlist = {};
    default_startparam = [];
    lhslist = '';
    rhslist = {};
    indiv_unobs_list = {};
    group_unobs_list = {};
    error_list = {'epsilon'};
    dparamlist = {};
    error_distributions = struct('epsilon', @(p)gumbelinv(p));
    error_dimensions = struct('epsilon', 2);

    mixed_logit = true;
    include_constant = true;
end

methods
    function obj = BinaryLogitModel(lhs, rhs, varargin)
        obj = obj@MleModel(varargin{:});
        obj.lhslist = lhs;
        obj.rhslist = rhs;
        obj.paramlist = MleModel.AddCoefficients(obj.paramlist, rhs, obj.include_constant);
        if obj.mixed_logit
            obj.group_unobs_list = {'eta'};
            obj.paramlist = [obj.paramlist  'eta_sd'];
        end
        obj.default_startparam = zeros(obj.nparam, 1);
        assert( IsValidModel(obj) );
    end
end

methods (Access = protected)
    function clik = ComputeConditionalLikelihoodVector(obj, param, data)
        u = obj.MeanUtility(param, data);
        q = exp(u) ./ (1 + exp(u));
        clik = data.var.(obj.lhslist) .* q + (1 - data.var.(obj.lhslist)) .* (1 - q);
    end

    function lhs = ComputeOutcomes(obj, param, data)
        u = obj.MeanUtility(param, data);
        lhs.(obj.lhslist) = (u + data.var.epsilon(:,1)) > data.var.epsilon(:,2);
    end

    function u = MeanUtility(obj, param, data)
        u = obj.XBeta(obj.rhslist, data, param, obj.include_constant);
        if obj.mixed_logit
            u = u + data.var.eta;
        end
    end

    function unobs = TransformUnobservables(obj, param, ~, raw_unobs)
        if obj.mixed_logit
            unobs.eta = raw_unobs.eta * param(obj.indices.eta_sd);
        else
            unobs = struct();
        end
    end
end

end