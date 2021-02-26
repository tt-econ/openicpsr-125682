function testRemoveBound

%
% Unit test for RemoveBound
%

    % Preliminaries
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'external'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'depend'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'm')))

    % Define constraint
    constr = MleConstraints([], [], [], [], [], []);
    
    constr.paramlist = {'a', 'b', 'c', 'd', 'e', 'f'};

    constr = constr.lb = [10, -Inf, -Inf, 1, 2, -Inf];
    constr = constr.ub = [Inf, Inf, 30, 20, Inf, 1];
    
    constr = constr.RemoveBound('a');    
    assertElementsAlmostEqual(constr.ub, [Inf, Inf, 30, 20, Inf, 1]);
    assertElementsAlmostEqual(constr.lb, [-Inf, -Inf, -Inf, 1, 2, -Inf]);   
    
    constr = constr.RemoveBound({'a', 'b', 'c'});    
    assertElementsAlmostEqual(constr.ub, [Inf, Inf, Inf, 20, Inf, 1]);
    assertElementsAlmostEqual(constr.lb, [-Inf, -Inf, -Inf, 1, 2, -Inf]);
    
    constr = constr.RemoveBound({'b', 'f'});    
    assertElementsAlmostEqual(constr.ub, [Inf, Inf, Inf, 20, Inf, Inf]);
    assertElementsAlmostEqual(constr.lb, [-Inf, -Inf, -Inf, 1, 2, -Inf]);
    
    constr = constr.RemoveBound({'a', 'd', 'e'});    
    assertElementsAlmostEqual(constr.ub, [Inf, Inf, Inf, Inf, Inf, Inf]);
    assertElementsAlmostEqual(constr.lb, [-Inf, -Inf, -Inf, -Inf, -Inf, -Inf]);
    
    bad_command = 'constr = constr.RemoveBound({''a'', ''e'', ''g''})';
    assertbad(bad_command);        
end