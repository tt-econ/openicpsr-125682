function testParametricBootstrap
%
% Unit test for ParametricBootstrap method of class MleModel
%

    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'external'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'depend'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'm'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'test'))) 
    estopts = MleEstimationOptions('quiet', 1);
	
	checksum_log = '../../log/checksum.log';
    
    regtrueparam = [-1; 3; 0.5; 2];          
    regmodel = RegressionModelForTesting('y', {'x1','x2'});  
    regmodel.dparamlist = {'ln_sigma'};
    
    nobs = 1000;
    reps = 150;
    [data, est] = create_test(nobs, regtrueparam, regmodel, estopts, 12345);        
    bootstrap_est = regmodel.ParametricBootstrap(data, est.param, reps, estopts);
	diary(checksum_log)
    bootstrap_est.Play;
    bootstrap_est.PlayDetailed;
	diary off
    compare_estimates(est, bootstrap_est, checksum_log);
    bootstrap_small = regmodel.ParametricBootstrap(data, est.param, 2, estopts);
	diary(checksum_log)
    bootstrap_small.PlayDetailed;
	diary off
end

function [data, est] = create_test(nobs, regtrueparam, regmodel, estopts, seed)    
    rng(seed)
	data = MleData('File', '../../external/data/test_data.csv', 'format', '%f%f%f%f%f%f%f%f', ...
				  'Delimiter', ',', 'ReadVarNames', true);
	data.var = data.var(1:nobs,:);	
    data.const.const1 = 20;
    data.const.const2 = 100;
    simdata = regmodel.Simulate(regtrueparam, data);
    est = regmodel.Estimate(simdata, estopts);
end

function compare_estimates(est, bootstrap_est, checksum_log)
    assertElementsAlmostEqual( est.param , bootstrap_est.param_bstrap, 'absolute', 10^-1 );
    assertElementsAlmostEqual( est.vcov , bootstrap_est.vcov_bstrap, 'absolute', 10^-2 );
    assertElementsAlmostEqual( est.se , bootstrap_est.se_bstrap, 'absolute', 10^-1 );
    
    write_checksum(checksum_log, 'Parametric Bootstrap', ...
        bootstrap_est.param_bstrap, bootstrap_est.vcov_bstrap, bootstrap_est.se_bstrap);    
end