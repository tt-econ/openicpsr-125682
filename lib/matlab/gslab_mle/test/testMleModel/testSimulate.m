function testSimulate
%
% Unit test for Simulate method of class MleModel
%

    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'external'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'depend'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'm'))) 
    rng(12345)
    simopts = MleSimulationOptions();
    simopts_reps = MleSimulationOptions('replications', 3);
    
    data = MleData('File', '../../external/data/test_data.csv', 'format', '%f%f%f%f%f%f%f%f', ...
                  'Delimiter', ',', 'ReadVarNames', true);
    data.var = data.var(1:10^4,:);    
    data.groupvar = data.var.group;
    data.const.const1 = 1;
    data.const.const2 = 1;

    model = BinaryLogitModel('y', {'x1','x2'}, 'include_constant', false);
    param = [1; -2; 0.5];

    simdata = model.Simulate(param, data, simopts);
    simdata_reps = model.Simulate(param, data, simopts_reps);
    simdata_set = model.Simulate(param, simdata_reps, simopts);
        
    testsimdata(simdata);
    for i = 1:simopts_reps.replications
        testsimdata(simdata_reps.datasets{i});
        testsimdata(simdata_set.datasets{i});
    end
    
    assert(length(simdata_reps.datasets)==simopts_reps.replications);
    assert(isa(simdata_reps.datasets, 'cell'));
    
    assert(isequal(simdata.var, simdata_reps.datasets{1}.var) == 1);
    assert(isequal(simdata.var, simdata_reps.datasets{2}.var) == 0);
    assert(isequal(simdata.var, simdata_reps.datasets{3}.var) == 0);
    
    assert(length(simdata_set.datasets)==length(simdata_reps.datasets));
    assert(isa(simdata_set.datasets, 'cell'));
    
    assert(isequal(simdata_set.datasets{1}.var, simdata_reps.datasets{1}.var) == 1);
    assert(isequal(simdata_set.datasets{2}.var, simdata_reps.datasets{2}.var) == 1);
    assert(isequal(simdata_set.datasets{3}.var, simdata_reps.datasets{3}.var) == 1);
    
    write_checksum('../../log/checksum.log', 'Simulate',...
                   mean(mean(double(simdata.var(:,11:12)))),...
                   mean(mean(double(simdata_reps.datasets{2}.var(:,11:12)))),...
                   mean(mean(double(simdata_reps.datasets{3}.var(:,11:12)))));
end


function testsimdata(simdata)
    assert(simdata.nvars ==12);
    assert(simdata.unique_group_sizes == 2);
    assert(simdata.nobs == 10000);
    assertEqual(size(simdata.var), [10000, 12]);
    assert(isa(simdata, 'MleData'))
 end

