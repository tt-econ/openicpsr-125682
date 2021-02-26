classdef model_separateRP< MleModel
%
%

properties
    paramlist = {'lnpsi', 'transformed_nu', 'lnsigma', 'lngl1', 'lngl2', 'theta'};
    lhslist = 'final_trip';
    rhslist = {};
    default_startparam = [];
    main_startparam = [-1.85525; 0.39887; -1.17403; 0.74186; 0.54869; 0.705310];
    controls_startparam = [-0.01715;  0.01391; -0.06264;  0.06021; -0.00586; 0.05902;  0.06314;  0.06046;  0.05643;  0.06047;  0.09679; -0.19305; -0.19434; -0.17893; -0.13309; -0.09198; -0.00355;  0.12106;  0.31375; 0.20512; -0.00437;  0.15041; -0.05701; -0.09881; -0.13133; -0.09598; 0.15540;  0.16723;  0.26422;  0.29120;  0.15880; -0.01517; -0.15294; -0.50223];
    indiv_unobs_list = {};
    group_unobs_list = {};
    error_list = {'epsilon'};
    error_distributions = struct('epsilon', @(P)norminv(P,0,1));
    error_dimensions = struct('epsilon', 1);
    dparamlist = {'nu', 'gl1', 'gl2', 'sigma'};
    controls = {};
    psis = {};
    include_constant = true;
end

methods
    function obj = model_separateRP(varargin)
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
            case 'gl1'
                dparam = exp(param(obj.indices.lngl1));
            case 'gl2'
                dparam = exp(param(obj.indices.lngl2));
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
        gl1 = DerivedParam(obj, param, 0, 'gl1');
        gl2 = DerivedParam(obj, param, 0, 'gl2');

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

        utility_difference = - ( gl1 * a1 + a2 - gl2 * psi / (nu + 1) .* b1 ...
            - psi / (nu + 1) .* b2 );
    end

    function r_income = compute_r_income(obj, param, data)
        theta = param(obj.indices.theta);
        weight = max(0, 1 - theta .^ data.w);
        r_income = data.var.r_income + sum(data.del .* weight, 2);
    end
end

end
