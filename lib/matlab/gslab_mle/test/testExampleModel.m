function testExampleModel
%
% Unit test for ExampleModel, designed as a simple illustration of
% the implementation of an MleModel
%

% Preliminaries
addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'external'))) 
addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'depend'))) 
addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'm'))) 
estopts = MleEstimationOptions('quiet', 1);

% Generate data, define model, and estimate
data = MleData('File', '../external/data/test_data.csv', 'format', '%f%f%f%f%f%f%f%f', ...
			  'Delimiter', ',', 'ReadVarNames', true);
data.var = data.var(1:100,:);	
data.var.Properties.VarNames{6} = 'y';
model = ExampleModel('y');
est = model.Estimate(data, estopts);

% write result est.param to checksum file
write_checksum('../log/checksum.log', 'ExampleModel', est.param, est.vcov, est.se);
end
