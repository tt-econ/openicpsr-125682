function testHessianJacobianOption
%
% Unit test for the option to suppress the computation of Hessian and Jacobian
%

% Preliminaries
addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'external'))) 
addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'depend'))) 
addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'm'))) 

% Generate data, define model, and estimate
data = MleData('File', '../../external/data/test_data.csv', 'format', '%f%f%f%f%f%f%f%f', ...
			  'Delimiter', ',', 'ReadVarNames', true);
data.var = data.var(1:100,:);	
data.var.Properties.VarNames{6} = 'y';
model = ExampleModel('y');

estopts_full = MleEstimationOptions('quiet', 1);
estopts_nohess = MleEstimationOptions('quiet', 1, 'compute_hessian', 0);
estopts_nojac = MleEstimationOptions('quiet', 1, 'compute_jacobian', 0);
estopts_nohess_nojac = MleEstimationOptions('quiet', 1, 'compute_hessian', 0, 'compute_jacobian', 0);

est_full = model.Estimate(data, estopts_full);
est_nohess = model.Estimate(data, estopts_nohess);
est_nojac = model.Estimate(data, estopts_nojac);
est_nohess_nojac = model.Estimate(data, estopts_nohess_nojac);

assert(~isempty(est_full.hessian) && ~isempty(est_full.jacobian));
assert(isempty(est_nohess.hessian) && ~isempty(est_nohess.jacobian));
assert(~isempty(est_nojac.hessian) && isempty(est_nojac.jacobian));
assert(isempty(est_nohess_nojac.hessian) && isempty(est_nohess_nojac.jacobian));

% test handling in ParametricBootstrap
reps = 2;
model.ParametricBootstrap(data, est_full.param, reps, estopts_nohess_nojac);

end
