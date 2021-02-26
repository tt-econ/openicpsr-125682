function testConstraints
%
% Unit test for MleConstraints
%

    % Preliminaries
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'external'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'depend'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'm'))) 
    estopts = MleEstimationOptions('quiet', 1);

    % Generate data, define model
	data = MleData('File', '../../external/data/test_data.csv', 'format', '%f%f%f%f%f%f%f%f', ...
				  'Delimiter', ',', 'ReadVarNames', true);
	data.var = data.var(1:100,:);
	data.var.Properties.VarNames{6} = 'y';
    model = ExampleModel('y');

    % Define constraints
    constraints.lin_ineq9 = MleConstraints([1 0], 9);
    constraints.lin_ineq11 = MleConstraints([1 0], 11);
    constraints.lin_eq7 = MleConstraints([], [], [1 0], 7);
    constraints.lin_eq10 = MleConstraints([], [], [1 0], 10);
    constraints.lb11 = MleConstraints([], [], [], [], [11 0.5]);
    constraints.ub11 = MleConstraints([], [], [], [], [], [11 1.1]);
    constraints.nlinineq = MleConstraints([], [], [], [], [], [], @myconineq);
    constraints.nlineq = MleConstraints([], [], [], [], [], [], @myconeq);

    % Run main tests
    for thisconst = fieldnames(constraints)'
        estopts.constr = constraints.(thisconst{:});
        est = model.Estimate(data, estopts);
        write_checksum('../../log/checksum.log', thisconst{:}, est.param);
    end

    % Test Jacobian output
    assertEqual(constraints.lb11.JacobianOfConstraints([10;1]).lower, ...
        eye(2));
    assertEqual(constraints.lb11.JacobianOfConstraints([10;1]).upper, ...
       []);
   
    assertEqual(constraints.ub11.JacobianOfConstraints([10;1]).upper, ...
        eye(2));
    assertEqual(constraints.ub11.JacobianOfConstraints([10;1]).lower, ...
        []);
    
    assertEqual(constraints.lin_eq7.JacobianOfConstraints([10;1]).eqlin, ...
        [1 0]);
    assertEqual(constraints.lin_eq7.JacobianOfConstraints([10;1]).upper, ...
        []);
    
    assertEqual(constraints.lin_ineq9.JacobianOfConstraints([10;1]).ineqlin,...
        [1 0]);
    assertEqual(constraints.lin_ineq9.JacobianOfConstraints([10;1]).eqlin,...
        []);
    
    % Test Jacobian calculation
    Jacobian = constraints.nlineq.JacobianOfConstraints([10;1]);
    J = Jacobian.eqnonlin;
    assertElementsAlmostEqual(J(1,1) , (1/2) / sqrt(10), 'relative', 10^-4);
    assertElementsAlmostEqual(J(1,2) , -sqrt(10), 'relative', 10^-4);
    assertElementsAlmostEqual(J(2,1) , 3*(10)^2, 'relative', 10^-4);
    assertElementsAlmostEqual(J(2,2) , -10^3, 'relative', 10^-4);
    write_checksum('../../log/checksum.log', 'JacobianOfNonlinearEqualityConstraints', J);

end

function [c, ceq] = myconineq(x)
    c = sqrt(x(1)) - sqrt(10) * x(2);
    ceq = [];
end

function [c, ceq] = myconeq(x)
    ceq = [sqrt(x(1)) - sqrt(10) * x(2);...
           x(1)^3 - 10^3 * x(2)];
    c = [];
end

