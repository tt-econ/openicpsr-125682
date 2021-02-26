function testSave_Load
%
% Unit test for MleData class
%

    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'external'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'depend'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'm'))) 

    % Set up data
	data = MleData('File', '../../external/data/test_data.csv', 'format', '%f%f%f%f%f%f%f%f', ...
				  'Delimiter', ',', 'ReadVarNames', true);
	data.groupvar = data.var.group;
    data.var.arrayvar = ones(data.nobs, 3);

    % Test save/load feature
    data.SaveToDisk('../', 'outtest', 12);
    data_reload = MleData();
    data_reload = data_reload.LoadFromDisk('../', 'outtest');
    
    assertEqual(data.var.Properties.VarNames, data_reload.var.Properties.VarNames);
    varnames = data.var.Properties.VarNames;
    for i = 1:length(varnames)
        assertElementsAlmostEqual(data.var.(varnames{i}), data_reload.var.(varnames{i}), 'absolute', 1e-12);
    end
    
    metadata = ?MleData;
    for i = 1:length(properties(MleData))
		if ~strcmp(metadata.PropertyList(i).Name, 'var')
			assertEqual(data.(metadata.PropertyList(i).Name), data_reload.(metadata.PropertyList(i).Name));
		end
	end
    delete('../outtest.csv')    
    delete('../outtest.mat')
    
    % Cell array save fails
    data.var.cellvar = repmat({{1,2,3}}, data.nobs,1);
    assertbad('data.SaveToDisk(''../'', ''outtest'')')
end



