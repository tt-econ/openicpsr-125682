function testGetSubset
%
% Unit test for methods GetParamSubset and GetVCovSubset
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

    model = RegressionModelForTesting('y', {'x1'});
    trueparam = [-1; 3; 1];
        
    data.const.const1 = 20;
    data.const.const2 = 100;
    simdata = model.Simulate(trueparam, data);
    est = model.Estimate(simdata, estopts);
    sparam = est.GetParamSubset({'ln_sigma', 'x1_coeff', 'ratio_sigma_const1'});
	sparam_true = [est.dparam(model.dindices.ln_sigma) est.param(model.indices.x1_coeff) est.dparam(model.dindices.ratio_sigma_const1)]';
	assert(isequal(sparam, sparam_true));
    
    svcov = est.GetVCovSubset({'ln_sigma', 'x1_coeff', 'ratio_sigma_const1'});
    assert( svcov(1,2) ~= 0 );
    sse = sqrt(diag(svcov));
    assertAlmostEqual( sse(2),est.se(model.indices.x1_coeff),10^-6);
    
    % Write checksum
    write_checksum('../../log/checksum.log', 'ReturnSubsetOfParameters', sparam, svcov, sse);
end
