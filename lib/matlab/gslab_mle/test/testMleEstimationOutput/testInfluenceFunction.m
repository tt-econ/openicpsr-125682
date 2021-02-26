function testInfluenceFunction
%
% Unit test for InfluenceFunction method of class MleEstimationOutput
%

    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'external')))
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'depend')))
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'm')))
    addpath(genpath(fullfile(fileparts(pwd))))
    rng(12345)
    estopts = MleEstimationOptions('quiet', 1);

    data = MleData('File', '../../external/data/test_data.csv', 'format', '%f%f%f%f%f%f%f%f', ...
                  'Delimiter', ',', 'ReadVarNames', true);
    data.var = data.var(1:10^5,:);    
    
    % Test outlier
    regmodel = LinearRegressionModel('y', {'x1'});
    regtrueparam = [-1; 3; 2];
    simdata = regmodel.Simulate(regtrueparam, data);    
    simdata.var.y(1) = 50;
    est = regmodel.Estimate(simdata, estopts);
    influence_function = est.InfluenceFunction;
    write_checksum('../../log/checksum.log', 'InfluenceFunction', influence_function(1:10,:));
    assert(abs(influence_function(1, 2)) > max(abs(influence_function(2:end, 2))))
    assert(abs(influence_function(1, 3)) > max(abs(influence_function(2:end, 3))))
    
    % Compare to a normal distribution with mu and sigma^2 parameters
    regmodel = LinearModelWithSigmaSq('y', {});
    regtrueparam = [-1; 2];
    simdata = regmodel.Simulate(regtrueparam, data);
    est = regmodel.Estimate(simdata, estopts);

    influence_function = est.InfluenceFunction;

    inf_func_mean = simdata.var.y - est.param(est.model.indices.constant);
    inf_func_var = inf_func_mean.^2 - est.param(est.model.indices.sigma_sq);

    assertElementsAlmostEqual(influence_function(:, 1), inf_func_mean, 'absolute', 10^-2);
    assertElementsAlmostEqual(influence_function(:, 2), inf_func_var, 'absolute', 10^-2);    
   
    % Output size check
    % influence_function size = ngroups (if available) or nobs x nparam
    regmodel = LinearRegressionModel('y', {'x1','x2'});
    regtrueparam = [-1; 3; 0.5; 2];
    simdata = regmodel.Simulate(regtrueparam, data);
    est = regmodel.Estimate(simdata, estopts);
    influence_function = est.InfluenceFunction;
    assert(size(influence_function, 1) == simdata.nobs && size(influence_function, 2) == 4);    

    % Bad case
    estopts = MleEstimationOptions('quiet', 1, 'compute_hessian', 0);
    est = regmodel.Estimate(simdata, estopts);
    assertbad('influence_function = est.InfluenceFunction;');    
  