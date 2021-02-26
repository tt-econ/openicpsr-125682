function testIsConsistent
%
% Unit test for IsConsistent method of class MleConstraints
%

    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'external'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'depend'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'm'))) 
    estopts = MleEstimationOptions('quiet', 1);

    [estopts_bds, estopts_lineq, estopts_linineq, estopts_nonlin, estopts_combined] = deal(estopts);
    estopts_bds.constr = MleConstraints([], [], [], [], [-1 2 -5 -Inf], [-1 4 5 Inf]);
    estopts_lineq.constr = MleConstraints([], [], [1,0,0,0;2,1,3,0], [-1;3]);
    estopts_linineq.constr = MleConstraints([1,0,0,0;2,1,3,0], [-1;3]);
    estopts_nonlin.constr = MleConstraints([], [], [], [], [], [], @non_linear_constraints);
    estopts_combined.constr = MleConstraints([1,2,0,1;3,0,0,2], [10;10], [], [], [-4 -Inf -Inf -Inf], [10 Inf 5 Inf], @linear_constraints);
    
    assert( estopts_bds.constr.IsConsistent([-1;2;0;0]) == 1 );
    assert( estopts_bds.constr.IsConsistent([-2;5;6;0]) == 0 );
    assert( estopts_lineq.constr.IsConsistent([-1;2;1;4]) == 1 );
    assert( estopts_lineq.constr.IsConsistent([2;1;0;0]) == 0 );
    assert( estopts_linineq.constr.IsConsistent([-5;0;1;0]) == 1 );
    assert( estopts_linineq.constr.IsConsistent([-1;2;4;4]) == 0 );
    assert( estopts_nonlin.constr.IsConsistent([1;2;1;2]) == 1 );
    assert( estopts_nonlin.constr.IsConsistent([1;2;1;4]) == 0 );
    assert( estopts_combined.constr.IsConsistent([-1;2;0;3]) == 1 );
    assert( estopts_combined.constr.IsConsistent([-4;2;1;1]) == 0 );
end

function [ c, ceq ] = non_linear_constraints( param )
    c = [];
    ceq = zeros(2,1);
    ceq(1) = param(2)/param(1) + param(3)*param(4)^2 - 6; 
    ceq(2) = param(4)*(sqrt(abs(param(1)))-param(3)); 
end

function [ c, ceq ] = linear_constraints( param )
    c = zeros(2,1);
    ceq = zeros(2,1);
    ceq(1) = param(1) + 2*param(2) + param(4) - 6;
    ceq(2) = 3*param(1) + 2*param(4) - 3;
    c(1) = param(1) + 2*param(2) + param(4) - 7;
    c(2) = 3*param(1) + 2*param(4) - 4;
end