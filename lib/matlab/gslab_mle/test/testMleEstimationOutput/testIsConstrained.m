function testIsConstrained
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
	
	% No parameters constrained
	est = regmodel.Estimate(simdata, estopts);
	
	assert(est.IsConstrained(regmodel.paramlist(1)) == 0)
	assert(est.IsConstrained(regmodel.paramlist(3)) == 0)
	assert(est.IsConstrained(regmodel.paramlist(1:2)) == 0)
	assert(est.IsConstrained(regmodel.paramlist(3:4)) == 0)
	assert(est.IsConstrained(regmodel.paramlist) == 0)
	
	% Linear equality constraint
	I = eye(4);
	estopts.constr = MleConstraints([],[],I(1:2,:),regtrueparam(1:2),[],[]);
	est = regmodel.Estimate(simdata, estopts);
	
	assert(est.IsConstrained(regmodel.paramlist(1)) == 1)
	assert(est.IsConstrained(regmodel.paramlist(3)) == 0)
	assert(est.IsConstrained(regmodel.paramlist(3:4)) == 0)
	assert(est.IsConstrained(regmodel.paramlist(2:3)) == 1)
	assert(est.IsConstrained(regmodel.paramlist) == 1)
	
	% Linear inequality constraint
	I = eye(4);
	estopts.constr = MleConstraints(I(1:2,:),regtrueparam(1:2),[],[],[],[]);
	est = regmodel.Estimate(simdata, estopts);
	
	assert(est.IsConstrained(regmodel.paramlist(1)) == 1)
	assert(est.IsConstrained(regmodel.paramlist(3)) == 0)
	assert(est.IsConstrained(regmodel.paramlist(3:4)) == 0)
	assert(est.IsConstrained(regmodel.paramlist(2:3)) == 1)
	assert(est.IsConstrained(regmodel.paramlist) == 1)
	
	% Non-linear equality constraint
	estopts.constr = MleConstraints([],[],[],[],[],[],@eqcon);
	est = regmodel.Estimate(simdata, estopts);

	assert(est.IsConstrained(regmodel.paramlist(1)) == 1)
	assert(est.IsConstrained(regmodel.paramlist(3)) == 0)
	assert(est.IsConstrained(regmodel.paramlist(3:4)) == 0)
	assert(est.IsConstrained(regmodel.paramlist(2:3)) == 1)
	assert(est.IsConstrained(regmodel.paramlist) == 1)
	
	% Non-linear inequality constraint
	estopts.constr = MleConstraints([],[],[],[],[],[],@ineqcon);
	est = regmodel.Estimate(simdata, estopts);

	assert(est.IsConstrained(regmodel.paramlist(1)) == 1)
	assert(est.IsConstrained(regmodel.paramlist(3)) == 0)
	assert(est.IsConstrained(regmodel.paramlist(3:4)) == 0)
	assert(est.IsConstrained(regmodel.paramlist(2:3)) == 1)
	assert(est.IsConstrained(regmodel.paramlist) == 1)
	
	% Lower and upper bounds
	estopts.constr = MleConstraints([],[],[],[],[0,-Inf,-Inf,-Inf],[1,Inf,Inf,Inf]);
	est = regmodel.Estimate(simdata, estopts);

	assert(est.IsConstrained(regmodel.paramlist(1)) == 1)
	assert(est.IsConstrained(regmodel.paramlist(3)) == 0)
	assert(est.IsConstrained(regmodel.paramlist(3:4)) == 0)
	assert(est.IsConstrained(regmodel.paramlist(2:3)) == 0)
	assert(est.IsConstrained(regmodel.paramlist) == 1)

end	

function [c, ceq] = eqcon(x)
    ceq = [sqrt(x(1)) - sqrt(10) * x(2);...
           x(1)^3 - 10^3 * x(2)];
    c = [];
end

function [c, ceq] = ineqcon(x)
    c = x(1)^2 - sqrt(10) * x(2);
	ceq = [];
end