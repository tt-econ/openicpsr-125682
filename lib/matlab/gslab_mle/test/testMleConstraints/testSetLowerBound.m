function testSetLowerBound

%
% Unit test for SetLowerBound
%

    % Preliminaries
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'external'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'depend'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'm')))  

    % Define constraint
    constr = MleConstraints([], [], [], [], [], []);    
    constr.paramlist = {'a', 'b', 'c', 'd', 'e', 'f'};
    
    constr = constr.SetLowerBound('c', 5);   
    assertElementsAlmostEqual(constr.lb, [-Inf, -Inf, 5, -Inf, -Inf, -Inf]);    
    
    constr = constr.SetLowerBound({'c', 'd'}, [1, 2]);   
    assertElementsAlmostEqual(constr.lb, [-Inf, -Inf, 1, 2, -Inf, -Inf]);

    constr = constr.SetLowerBound({'c', 'd'}, [10, 20]);   
    assertElementsAlmostEqual(constr.lb, [-Inf, -Inf, 10, 20, -Inf, -Inf]);    

    constr = constr.SetLowerBound({'d', 'e', 'f'}, [1, 2, 3]);   
    assertElementsAlmostEqual(constr.lb, [-Inf, -Inf, 10, 1, 2, 3]);        
    
    bad_command = 'constr = constr.SetLowerBound({''d'', ''e'', ''f''}, [1, 2])';
    assertbad(bad_command);

    bad_command = 'constr = constr.SetLowerBound({''a'', ''e'', ''g''}, [1, 2, 3])';
    assertbad(bad_command);    
end