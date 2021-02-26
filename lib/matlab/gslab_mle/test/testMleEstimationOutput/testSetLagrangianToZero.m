function testSetLagrangianToZero
%
% Unit test for IsConstrained method of class MleEstimationOutput
%

    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'external'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'depend'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'm'))) 
    rng(12345)
    estopts = MleEstimationOptions('quiet', 1);
	
	data = MleData('File', '../../external/data/test_data.csv', 'format', '%f%f%f%f%f%f%f%f', ...
				  'Delimiter', ',', 'ReadVarNames', true);
	data.var = data.var(1:10^5,:);	    
	    
    regmodel = LinearRegressionModel('y', {'x1','x2'});
    regtrueparam = [-1; 3; 0.5; 2];	
	
	simdata = regmodel.Simulate(regtrueparam, data);
	
	% Lower and upper bounds
	estopts.constr = MleConstraints([],[],[],[],[0,-Inf,-Inf,-Inf],[1,Inf,Inf,Inf]);
	est = regmodel.Estimate(simdata, estopts);

	assert(est.IsConstrained(regmodel.paramlist(1)) == 1)
	assert(est.IsConstrained(regmodel.paramlist(3)) == 0)
	assert(est.IsConstrained(regmodel.paramlist(3:4)) == 0)
	assert(est.IsConstrained(regmodel.paramlist(2:3)) == 0)
	assert(est.IsConstrained(regmodel.paramlist) == 1)
    
    est_test1 = est.SetLagrangianToZero;
	assert(est_test1.IsConstrained(regmodel.paramlist) == 0)

    est_test2 = est.SetLagrangianToZero(regmodel.paramlist(1));
	assert(est_test2.IsConstrained(regmodel.paramlist) == 0)
    
end	
