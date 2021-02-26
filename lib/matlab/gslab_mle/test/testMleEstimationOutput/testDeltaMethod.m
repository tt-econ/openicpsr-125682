function testDeltaMethod
%
% Unit test for DeltaMethod method of class MleEstimationOutput
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
    
    % this matrix corresponds to the linear transform defined in
    % linear_transform
    matrix_for_test = [1,1,0,0;0,-1,3,0];
	
    simdata = regmodel.Simulate(regtrueparam, data);
    est = regmodel.Estimate(simdata, estopts);
    
    dm_square = struct();
    [dm_square.param, dm_square.vcov] = est.DeltaMethod([],@square_of_constant);
    assertElementsAlmostEqual(dm_square.param(1) , est.param(1)^2, 'relative', 10^-4);
    assertElementsAlmostEqual(dm_square.vcov(1) , 4*est.param(1)^2*est.vcov(1), 'relative', 10^-4);
    
    dm_squareandfirst = struct();
    [dm_squareandfirst.param, dm_squareandfirst.vcov] = est.DeltaMethod([],@square_and_firstcoef);
    assertElementsAlmostEqual(dm_squareandfirst.vcov(1,2) , 2*est.param(1)*est.vcov(1,2), 'relative', 10^-4);
    
    dm_linear = struct();
    [dm_linear.param, dm_linear.vcov] = est.DeltaMethod(matrix_for_test,@linear_transform);
    assertElementsAlmostEqual(dm_linear.param(1:2),dm_linear.param(3:4), 'relative', 10^-4);
    assertElementsAlmostEqual(dm_linear.vcov(1:2,1:2),dm_linear.vcov(3:4,3:4), 'relative', 10^-4);
    
    dm_matrix = struct();
    [dm_matrix.param, dm_matrix.vcov] = est.DeltaMethod(matrix_for_test,[]);
    assertElementsAlmostEqual(dm_linear.param(1:2),dm_matrix.param, 'relative', 10^-4);
    assertElementsAlmostEqual(dm_linear.vcov(1:2,1:2),dm_matrix.vcov, 'relative', 10^-4);
    
    % can supply vcov explicitly
    [~, explicit_vcov] = est.DeltaMethod(matrix_for_test,[], est.vcov);
    assertElementsAlmostEqual(dm_matrix.vcov,explicit_vcov, 'relative', 10^-4);    
    
    % when vcov supplied is empty, dmvcov should be empty
    [~, should_be_empty1] = est.DeltaMethod(matrix_for_test,[],[]);
    [~, should_not_be_empty1] = est.DeltaMethod(matrix_for_test,[],eye(4));
    est_emptyhessian = est;
    est_emptyhessian.hessian = [];
    [~, should_be_empty2] = est_emptyhessian.DeltaMethod(matrix_for_test,[]);
    assert(isempty(should_be_empty1));
    assert(~isempty(should_not_be_empty1));
    assert(isempty(should_be_empty2));
end

function [ square_of_constant ] = square_of_constant( param )
    square_of_constant = param(1)^2; 
end

function [ square_and_firstcoef ] = square_and_firstcoef( param )
    square_and_firstcoef = zeros(2,1);
    square_and_firstcoef(1) = param(1)^2; 
    square_and_firstcoef(2) = param(2); 
end

function [ linear_transform ] = linear_transform( param )
    linear_transform = zeros(2,1);
    linear_transform(1) = param(1) + param(2);
    linear_transform(2) = -param(2) + 3*param(3);
end
