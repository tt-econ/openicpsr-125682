classdef LinearRegressionModel < MleModel
%
% LinearRegressionModel implements MleModel class for the Linear Regression Model.
%

properties
    paramlist = {'sigma'};
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
    function obj = LinearRegressionModel(lhs, rhs, varargin)
        obj = obj@MleModel(varargin{:});
        obj.lhslist = lhs;
        obj.rhslist = rhs;
        obj.paramlist = MleModel.AddCoefficients(obj.paramlist, rhs, obj.include_constant);
        obj.default_startparam = zeros(obj.nparam, 1);
        obj.default_startparam(obj.indices.sigma) = 1;
        assert( IsValidModel(obj) );
    end
end

methods (Hidden, Access = protected)
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
end

methods
    function closedform = ClosedFormEstimate(obj, data, estopts)
    	X = [ones(data.nobs, 1) data.GetArray(obj.rhslist)];
		Y = data.var.(obj.lhslist);
		closedform.beta = (X'*X)^(-1)*(X'*Y);
        ESS = Y'*Y - closedform.beta'*(X'*Y);
        MSE = ESS/(data.nobs - size(obj.rhslist, 1) - 1 );
        closedform.vcov = MSE*(X'*X)^(-1);
        if ~isempty(estopts.constr.Aeq)
            % See Greene and Seaks (1991) for notation and expressions
            b = closedform.beta;
            R = estopts.constr.Aeq(:,1:3);
            r = estopts.constr.beq;
            closedform.betastar = b - ((X'*X)^(-1))*R'*((R*(X'*X)^(-1)*R')^(-1))*(R*b-r);
            closedform.vcovstar = MSE*((X'*X)^(-1) -...
                (X'*X)^(-1)*R'*(R*(X'*X)^(-1)*R')^(-1)*R*(X'*X)^(-1));
        end
	end
	
end

end