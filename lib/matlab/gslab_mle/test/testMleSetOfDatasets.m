function testMleSetOfDatasets
%
% Unit test for testMleSetOfDatasets class
%

    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'external'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'depend'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'm'))) 

    rng(12345)
    simopts_reps = MleSimulationOptions('replications', 3);
    
    data = MleData('File', '../external/data/test_data.csv', 'format', '%f%f%f%f%f%f%f%f', ...
                  'Delimiter', ',', 'ReadVarNames', true);
    data.var = data.var(1:10^4,:);    
    data.groupvar = data.var.group;
    data.const.const1 = 1;
    data.const.const2 = 1;

    model = BinaryLogitModel('y', {'x1','x2'}, 'include_constant', false);
    param = [1; -2; 0.5];

    simdata_set = model.Simulate(param, data, simopts_reps);
    
    %check dimensions of object
	assert(strcmp(class(simdata_set.datasets) , 'cell'));
    assert(length(simdata_set.datasets) == simdata_set.ndatasets);
    
    %save/load
    simdata_set.SaveToDisk('./', 'outtest', 12, [1:3]);
    simdata_set.SaveToDisk('./', 'outtest2', 12);
    simdata_set_out = MleSetOfDatasets();
    simdata_set_out = simdata_set_out.LoadFromDisk('./', 'outtest', [1:3]);
    simdata_set_out2 = MleSetOfDatasets();
    simdata_set_out2 = simdata_set_out.LoadFromDisk('./', 'outtest2', 3);
   
    %compare each replication with original data
    for j = 1:simopts_reps.replications
        assertEqual(simdata_set_out.datasets{j}.var.Properties.VarNames, simdata_set.datasets{j}.var.Properties.VarNames);
        varnames = simdata_set_out.datasets{j}.var.Properties.VarNames;
        for i = 1:length(varnames)
            assertElementsAlmostEqual(double(simdata_set_out.datasets{j}.var.(varnames{i})),...
                double(simdata_set.datasets{j}.var.(varnames{i})), 'absolute', 1e-12);
        end
        
        metadata = ?MleData;
        for i = 2:length(properties(MleData))
			if ~strcmp(metadata.PropertyList(i).Name, 'var')	
				assertEqual(simdata_set_out.datasets{j}.(metadata.PropertyList(i).Name), ...
							simdata_set.datasets{j}.(metadata.PropertyList(i).Name));
			end
		end
        delete(strcat('./outtest_', num2str(j), '.csv'))    
        delete(strcat('./outtest_', num2str(j), '.mat'))    
        delete(strcat('./outtest2_', num2str(j), '.csv'))    
        delete(strcat('./outtest2_', num2str(j), '.mat'))           
    end
    
end
