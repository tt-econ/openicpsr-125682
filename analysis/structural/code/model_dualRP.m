classdef model_dualRP< MleModel
%
%

properties
    paramlist = {'lnpsi', 'transformed_nu', 'lnsigma', 'lngl', 'theta'};
    lhslist = 'final_trip';
    rhslist = {};
    default_startparam = [];
    main_startparam = [-2.01134; 0.37972; -1.38346; 0.60180; 0.788640];
    controls_startparam = [-0.04292; -0.01642; -0.08062;  0.02998; -0.00356; 0.04774;  0.05054;  0.04976;  0.04594;  0.05222;  0.08276; -0.16058; -0.16204; -0.14298; -0.10846; -0.07562; -0.00270;  0.09734;  0.25192; 0.16482; -0.01200;  0.12340; -0.05090; -0.08164; -0.10738; -0.07494; 0.12682;  0.13670;  0.21958;  0.22830;  0.12488; -0.01800; -0.12940; -0.35904];
    indiv_unobs_list = {};
    group_unobs_list = {};
    error_list = {'epsilon'};
    error_distributions = struct('epsilon', @(P)norminv(P,0,1));
    error_dimensions = struct('epsilon', 1);
    dparamlist = {'nu', 'gl', 'sigma'};
    controls = {};
    psis = {};
    include_constant = true;
end

methods
    function obj = model_dualRP(varargin)
        obj = obj@MleModel(varargin{:});
        obj.paramlist = obj.AddCoefficients(obj.paramlist, [obj.controls], obj.include_constant);
        obj.default_startparam = zeros(obj.nparam, 1);
        obj.default_startparam(1:length(obj.main_startparam)) = obj.main_startparam;
        obj.default_startparam(length(obj.main_startparam) + 1 : length(obj.main_startparam) + length(obj.controls_startparam)) = obj.controls_startparam;
    end
end

methods (Access = protected)
    function clik = ComputeConditionalLikelihoodVector(obj, param, data)
        cdf = prob_stop(obj, param, data);

        clik = cdf .^ (data.var.(obj.lhslist) == 1) .* ...
            (1 - cdf) .^ (data.var.(obj.lhslist) == 0);
    end

    function lhs = ComputeOutcomes(obj, param, data)
        utility_difference = compute_utility_difference(obj, param, data);
        if (~isempty(obj.controls))
            xb = obj.Xbeta(obj.controls, data, param, obj.include_constant);
            utility_difference = utility_difference + xb;
        end
        eps = data.var.epsilon * exp(param(obj.indices.lnsigma));
        lhs.(obj.lhslist) = utility_difference > eps;
    end

    function dparam = DerivedParam(obj, param, ~, dparamname)
        switch dparamname
            case 'sigma'
                dparam = exp(param(obj.indices.lnsigma));
            case 'nu'
                dparam = exp(param(obj.indices.transformed_nu)) - 1;
            case 'gl'
                dparam = exp(param(obj.indices.lngl));
            case 'theta'
                dparam = param(obj.indices.theta);
        end
    end
end

methods (Access = public)
    function cdf = prob_stop(obj, param, data)
        utility_difference = compute_utility_difference(obj, param, data);
        if (~isempty(obj.controls))
            if obj.include_constant
                control_param = param(length(obj.main_startparam) + 1 : length(obj.main_startparam) + length(obj.controls));
                xb = data.controls * control_param + param(end);
            end
        utility_difference = utility_difference + xb;
        end
        cdf = normcdf(utility_difference, 0, ...
                      exp(param(obj.indices.lnsigma)));
    end

    function utility_difference = compute_utility_difference(obj, param, data)
        nu = DerivedParam(obj, param, 0, 'nu');
        gl = DerivedParam(obj, param, 0, 'gl');

        psi = exp(param(obj.indices.lnpsi));

        r_income = compute_r_income(obj, param, data);
        r_duration = data.var.r_duration;

        a1 = (data.var.exp_cum_income < r_income) .* (-(abs(data.var.exp_cum_income - r_income))) ...
           - ((data.var.cum_income < r_income) .* (-(abs(data.var.cum_income - r_income))));

        a2 = (data.var.exp_cum_income > r_income) .* ((abs(data.var.exp_cum_income - r_income))) ...
           - ((data.var.cum_income > r_income) .* ((abs(data.var.cum_income - r_income))));

        b1 = ((data.var.cum_total_duration + data.var.exp_duration) > r_duration ) .* ...
            ((abs((data.var.cum_total_duration + data.var.exp_duration) .^ (nu + 1) - r_duration .^ (nu + 1)))) ...
           - (data.var.cum_total_duration > r_duration) .* ...
            ((abs(data.var.cum_total_duration .^ (nu + 1) - r_duration .^ (nu + 1))));

        b2 = ((data.var.cum_total_duration + data.var.exp_duration) < r_duration ) .* ...
            (-(abs((data.var.cum_total_duration + data.var.exp_duration) .^ (nu + 1) - r_duration .^ (nu + 1)))) ...
           - (data.var.cum_total_duration < r_duration ) .* ...
            (-(abs(data.var.cum_total_duration .^ (nu + 1) - r_duration .^ (nu + 1))));

        utility_difference = - ( gl * a1 + a2 - gl * psi / (nu + 1) .* b1 ...
            - psi / (nu + 1) .* b2 );
    end

    function r_income = compute_r_income(obj, param, data)
        theta = param(obj.indices.theta);
        weight = max(0, 1 - theta .^ data.w);
        r_income = data.var.r_income + sum(data.del .* weight, 2);
    end
end

end
