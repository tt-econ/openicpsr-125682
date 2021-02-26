function testSetUpperBound

%
% Unit test for SetUpperBound
%

    % Preliminaries
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'external'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'depend'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'm'))) 

    % Define constraint
    constr = MleConstraints([], [], [], [], [], []);
    constr.paramlist = {'a', 'b', 'c', 'd', 'e', 'f'};
    
    constr = constr.SetUpperBound('c', 5);   
    assertElementsAlmostEqual(constr.ub, [Inf, Inf, 5, Inf, Inf, Inf]);
    
    constr = constr.SetUpperBound({'c', 'd'}, [1, 2]);   
    assertElementsAlmostEqual(constr.ub, [Inf, Inf, 1, 2, Inf, Inf]);

    constr = constr.SetUpperBound({'c', 'd'}, [10, 20]);   
    assertElementsAlmostEqual(constr.ub, [Inf, Inf, 10, 20, Inf, Inf]);

    constr = constr.SetUpperBound({'d', 'e', 'f'}, [1, 2, 3]);   
    assertElementsAlmostEqual(constr.ub, [Inf, Inf, 10, 1, 2, 3]);
    
    bad_command = 'constr = constr.SetUpperBound({''d'', ''e'', ''f''}, [1, 2])';
    assertbad(bad_command);

    bad_command = 'constr = constr.SetUpperBound({''a'', ''e'', ''g''}, [1, 2, 3])';
    assertbad(bad_command);    
end