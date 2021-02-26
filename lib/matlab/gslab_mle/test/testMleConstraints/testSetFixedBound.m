function testSetFixedBound

%
% Unit test for SetFixedBound
%

    % Preliminaries
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'external'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'depend'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'm'))) 

    % Define constraint
    constr = MleConstraints([], [], [], [], [], []);    
    constr.paramlist = {'a', 'b', 'c', 'd', 'e', 'f'};
    
    constr = constr.SetFixedBound('c', 5);  
    assertElementsAlmostEqual(constr.ub, [Inf, Inf, 5, Inf, Inf, Inf]);
    assertElementsAlmostEqual(constr.lb, [-Inf, -Inf, 5, -Inf, -Inf -Inf]);
       
    constr = constr.SetFixedBound({'c', 'd'}, [1, 2]);  
    assertElementsAlmostEqual(constr.ub, [Inf, Inf, 1, 2, Inf, Inf]);
    assertElementsAlmostEqual(constr.lb, [-Inf, -Inf, 1, 2, -Inf -Inf]);

    constr = constr.SetFixedBound({'c', 'f'}, [5, 10]);  
    assertElementsAlmostEqual(constr.ub, [Inf, Inf, 5, 2, Inf, 10]);
    assertElementsAlmostEqual(constr.lb, [-Inf, -Inf, 5, 2, -Inf 10]);

    constr = constr.SetFixedBound({'a'}, 1);  
    assertElementsAlmostEqual(constr.ub, [1, Inf, 5, 2, Inf, 10]);
    assertElementsAlmostEqual(constr.lb, [1, -Inf, 5, 2, -Inf 10]);

    bad_command = 'constr = constr.SetFixedBound({''d'', ''e'', ''f''}, [1, 2])';
    assertbad(bad_command);
    
    bad_command = 'constr = constr.SetFixedBound({''a'', ''e'', ''g''}, [1, 2, 3])';
    assertbad(bad_command);      
end