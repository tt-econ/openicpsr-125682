classdef model_stochRP< MleModel
%
%

properties
    paramlist = {'lnpsi', 'transformed_nu', 'lnsigma', 'lngl', 'theta', 'lnsd'};
    lhslist = 'final_trip';
    rhslist = {};
    default_startparam = [];
    main_startparam = [-1.330368;  0.538641; -0.604900;  1.573855;  0.779909;  -1.180923];
    controls_startparam = [-0.090077; -0.005727; -0.125982;  0.070400; -0.022618;  0.102436;  0.115423;  0.117873;  0.112455;  0.106623; 0.163045; -0.262550; -0.261336; -0.267732; -0.211468; -0.139505;  0.022895; 0.265177;  0.637082;  0.417145;  0.042145;  0.264682; -0.041136; -0.112036; -0.153395; -0.138909;  0.296105;  0.325264;  0.515105; 0.560636;  0.323973;  0.040391; -0.212214; -0.959773];
    indiv_unobs_list = {};
    group_unobs_list = {};
    error_list = {'epsilon'};
    error_distributions = struct('epsilon', @(P)norminv(P,0,1));
    error_dimensions = struct('epsilon', 1);
    dparamlist = {'nu', 'gl', 'sigma', 'sd'};
    controls = {};
    psis = {};
    include_constant = true;
    normaldist = randn(1, 100);
end

methods
    function obj = model_stochRP(varargin)
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
        utility_difference = so(obj, param, data);
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
            case 'sd'
                dparam = exp(param(obj.indices.lnsd));
        end
    end
end

methods (Access = public)
    function cdf = prob_stop(obj, param, data)
        utility_difference = so(obj, param, data);
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

    function utility_difference = so(obj, param, data)
        nu = DerivedParam(obj, param, 0, 'nu');
        gl = DerivedParam(obj, param, 0, 'gl');
        sd = DerivedParam(obj, param, 0, 'sd');

        psi = exp(param(obj.indices.lnpsi));

        r_income = compute_r_income(obj, param, data);
        r_duration = data.var.r_duration;
        cum_income = repmat(data.var.cum_income, 1, 100);

        distribution = sd * repmat(obj.normaldist, length(r_income), 1) + repmat(r_income, 1, 100);
        distribution_gain = distribution;
        distribution_gain(distribution <= cum_income) = NaN;
        cond_mean_gain = nanmean(distribution_gain, 2);
        distribution_loss = distribution;
        distribution_loss(distribution >= cum_income) = NaN;
        cond_mean_loss = nanmean(distribution_loss, 2);
        pr_gain = mean((distribution > cum_income)', 1)';
        pr_loss = mean((distribution < cum_income)', 1)';

        a1_gain = (data.var.exp_cum_income < cond_mean_gain) .* (-(abs(data.var.exp_cum_income - cond_mean_gain))) ...
           - ((data.var.cum_income < cond_mean_gain) .* (-(abs(data.var.cum_income - cond_mean_gain))));

        a2_gain = (data.var.exp_cum_income > cond_mean_gain) .* ((abs(data.var.exp_cum_income - cond_mean_gain))) ...
           - ((data.var.cum_income > cond_mean_gain) .* ((abs(data.var.cum_income - cond_mean_gain))));

        a1_loss = (data.var.exp_cum_income < cond_mean_loss) .* (-(abs(data.var.exp_cum_income - cond_mean_loss))) ...
           - ((data.var.cum_income < cond_mean_loss) .* (-(abs(data.var.cum_income - cond_mean_loss))));

        a2_loss = (data.var.exp_cum_income > cond_mean_loss) .* ((abs(data.var.exp_cum_income - cond_mean_loss))) ...
           - ((data.var.cum_income > cond_mean_loss) .* ((abs(data.var.cum_income - cond_mean_loss))));

        b1 = ((data.var.cum_total_duration + data.var.exp_duration) > r_duration ) .* ...
            ((abs((data.var.cum_total_duration + data.var.exp_duration) .^ (nu + 1) - r_duration .^ (nu + 1)))) ...
           - (data.var.cum_total_duration > r_duration) .* ...
            ((abs(data.var.cum_total_duration .^ (nu + 1) - r_duration .^ (nu + 1))));

        b2 = ((data.var.cum_total_duration + data.var.exp_duration) < r_duration ) .* ...
            (-(abs((data.var.cum_total_duration + data.var.exp_duration) .^ (nu + 1) - r_duration .^ (nu + 1)))) ...
           - (data.var.cum_total_duration < r_duration ) .* ...
            (-(abs(data.var.cum_total_duration .^ (nu + 1) - r_duration .^ (nu + 1))));

        a1_gain(isnan(a1_gain)) = 0;
        a2_gain(isnan(a2_gain)) = 0;
        a1_loss(isnan(a1_loss)) = 0;
        a2_loss(isnan(a2_loss)) = 0;

        a1 = a1_gain .* pr_gain + a1_loss .* pr_loss;
        a2 = a2_gain .* pr_gain + a2_loss .* pr_loss;

        utility_difference = - ( gl * a1 + a2 - psi / (nu + 1) .* b1 ...
            - psi / (nu + 1) .* b2 );
    end

    function r_income = compute_r_income(obj, param, data)
        theta = param(obj.indices.theta);
        weight = max(0, 1 - theta .^ data.w);
        r_income = data.var.r_income + sum(data.del .* weight, 2);
    end

end

end
