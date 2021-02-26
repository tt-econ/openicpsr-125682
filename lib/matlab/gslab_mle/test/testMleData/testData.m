function testMleData
%
% Unit test for MleData class
%
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'external'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'depend'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'm'))) 

    % Set up data
	data = MleData('File', '../../external/data/test_data.csv', 'format', '%f%f%f%f%f%f%f%f', ...
				  'Delimiter', ',', 'ReadVarNames', true);
	data.var = data.var(1:10,:);
    x1 = (0:0.1:0.9)';
    x2 = data.var.x1;
    x3 = data.var.x2;
    rhs.x1 = x1;
    rhs.x2 = x2;
    lhs.y = [zeros(5,1); ones(5,1)];
    unobs.epsilon0 = data.var.x3;
    unobs.epsilon1 = data.var.x4;
    group = [1;1;2;2;2;3;3;4;5;6];
    group2 = [1;1;1;1;1;2;2;2;2;2];
    badgroup1 = [1;1;2;2;2;3;3;4;6;5];
    badgroup2 = [1;1;2;2;2;3;3];

    % Basic data creation
    data = MleData(rhs, lhs, unobs);
    data = data.AddData(x3);
    data = data.AddData(x1);
	
    % Groups
    data.groupvar = group;
    assert(data.nvars==7);
    assert(data.ngroups==6);
    data.groupvar = group2;
    assert(data.ngroups==2);
    assertbad('data.groupvar = badgroup1');
    assertbad('data.groupvar = badgroup2');
end



