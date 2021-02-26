classdef RegressionModelForTesting < LinearRegressionModel
%
% RegressionModelForTesting tests the implementation of the derived parameters
%

methods
    function obj = RegressionModelForTesting(lhs, rhs, varargin)
        obj = obj@LinearRegressionModel(lhs, rhs, varargin{:});
        obj.dparamlist = {'ln_sigma','sq_const1','sum_const1_const2','ratio_sigma_const1'};    
    end
end

methods (Access = protected)
    function clik = ComputeConditionalLikelihoodVector(obj, param, data)
        xb = obj.XBeta(obj.rhslist, data, param, obj.include_constant);
        clik = normpdf(data.var.(obj.lhslist), xb, param(obj.indices.sigma));
    end

    function lhs = ComputeOutcomes(obj, param, data)
        xb = obj.XBeta(obj.rhslist, data, param, obj.include_constant);
        eps = data.var.epsilon * param(obj.indices.sigma);
        lhs.(obj.lhslist) = xb+eps;
    end

    function unobs = TransformUnobservables(~, ~, ~, raw_unobs)
        unobs = raw_unobs;
    end
        
    function dparam = DerivedParam(obj, param, const, paramname)
        switch paramname
            case 'ln_sigma'
                dparam = log(param(obj.indices.sigma));
            case 'sq_const1'
                dparam = const.const1^2;
            case 'sum_const1_const2'
                dparam = const.const1+const.const2;
            case 'ratio_sigma_const1'
                dparam = param(obj.indices.sigma)/const.const1;
        end
    end
end


end