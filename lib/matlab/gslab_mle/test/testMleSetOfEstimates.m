function testMleSetOfEstimates
%
% Unit test for MleSetOfEstimates class
%

    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'external'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'depend'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'm'))) 
    estopts = MleEstimationOptions('quiet', 1);
   
	data = MleData('File', '../external/data/test_data.csv', 'format', '%f%f%f%f%f%f%f%f', ...
				  'Delimiter', ',', 'ReadVarNames', true);
	data.var = data.var(1:10^4,:);	
    data.groupvar = data.var.group;

    mlmodel = BinaryLogitModel('x1_logit', {'x1','x2'}, 'include_constant', false);

    regmodel = LinearRegressionModel('y_norm', {'x1','x2'});
	
    est_ml = mlmodel.Estimate(data, estopts);
    est_reg = regmodel.Estimate(data, estopts);
    estimates = {est_ml, est_reg};
    set = MleSetOfEstimates(estimates);
	diary('../log/checksum.log')
    set.Play;
    set.Play(2);
	diary off
    
end
