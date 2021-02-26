function testVaryStartingValues
%
% Unit test for VaryStartingValues method of class MleEstimationOutput
%

    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'external'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'depend'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'm'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'test'))) 
    
    data = MleData('File', '../../external/data/test_data.csv', 'format', '%f%f%f%f%f%f%f%f', ...
				  'Delimiter', ',', 'ReadVarNames', true);
	data.var = data.var(1:1000,:);	
    data.const.const1 = 20;
    data.const.const2 = 100;

    start_test({'ln_sigma'}, data)
    start_test({}, data)
    
end

function start_test(dparamlist, data)
    estopts = MleEstimationOptions('quiet', 1);  
    regmodel = RegressionModelForTesting('y_norm', {'x1','x2'});  
    regmodel.dparamlist = dparamlist;
    
    est = regmodel.Estimate(data, estopts);  
	nstart = 3;
	lb = [0; -1; -1; 0];
	ub = [20; 1; 1; 10];
    start_test = est.VaryStartingValues(data, nstart, lb, ub);
	diary('../../log/checksum.log')
    start_test.Play;
	diary off
    assertAlmostEqual(min(start_test.param_matrix)', est.param, 10^-4);
    assertAlmostEqual(max(start_test.param_matrix)', est.param, 10^-4);
end