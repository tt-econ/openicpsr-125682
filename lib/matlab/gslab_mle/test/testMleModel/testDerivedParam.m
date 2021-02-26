function testDerivedParam
%
% Unit test for the implementation of derived parameters
%
    % Preliminaries
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'external'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'depend'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'm'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'test'))) 
    rng(12345)
    
    % Set options, define data and model
    estopts = MleEstimationOptions('quiet', 1);
	data = MleData('File', '../../external/data/test_data.csv', 'format', '%f%f%f%f%f%f%f%f', ...
				  'Delimiter', ',', 'ReadVarNames', true);
	data.var = data.var(1:10^5,:);

    testmodel = RegressionModelForTesting('y', {'x1','x2'});
    trueparam = [-1; 3; 0.5; 1];
    
    % The following two sets of tests only differ by the value of data
    % constants. The purpose is to ensure that as we vary data constants,
    % the derived parameters will change accordingly.
    
    % First test
    data.const.const1 = 20;
    data.const.const2 = 100;
    simdata1 = testmodel.Simulate(trueparam, data);
    est1 = testmodel.Estimate(simdata1, estopts);
    assertDerivedParams(testmodel, simdata1, est1);
    
    
    % Second test
    data.const.const1 = 10;
    data.const.const2 = 50;
    simdata2 = testmodel.Simulate(trueparam, data);
    est2 = testmodel.Estimate(simdata2, estopts);
    assertDerivedParams(testmodel, simdata2, est2);
    
    % Test to make sure that the derived parameters indeed change as data.const changes
    assert(all(est1.dparam(2:4)~=est2.dparam(2:4)));
    
    % Write checksum
    write_checksum('../../log/checksum.log', 'derived_params', est1.dparam, est2.dparam);
end

function assertDerivedParams(model, data, est)
    assert( est.dparam(model.dindices.ln_sigma) == log(est.param(model.indices.sigma)) );
    assert( est.dparam(model.dindices.sq_const1) == data.const.const1^2 );
    assert( est.dparam(model.dindices.sum_const1_const2) == ...
           (data.const.const1 + data.const.const2) );
    assert( est.dparam(model.dindices.ratio_sigma_const1) == ...
           (est.param(model.indices.sigma)/data.const.const1) );
end