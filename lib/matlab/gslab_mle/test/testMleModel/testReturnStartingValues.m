function testReturnStartingValues
%
% Unit test for ReturnStartingValues method of class MleModel
%

    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'external'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'depend'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'm'))) 
    estopts = MleEstimationOptions('quiet', 1);    
    
    data = MleData('File', '../../external/data/test_data.csv', 'format', '%f%f%f%f%f%f%f%f', ...
                   'Delimiter', ',', 'ReadVarNames', true);
    data.var = data.var(1:10^4,:);
    
    regtrueparam = [-1; 3; 0.5; 2];
    regmodel_partial = LinearRegressionModel('y', {'x1','x2'});
    regmodel_full = LinearRegressionModel('y', {'x1','x2','x3'});     
    
    simdata = regmodel_partial.Simulate(regtrueparam, data);
    est_partial = regmodel_partial.Estimate(simdata, estopts);
    
    estopts.startparam = regmodel_full.ReturnStartingValues(est_partial.model.paramlist,est_partial.param);
    est_full = regmodel_full.Estimate(simdata, estopts);
    
    for i = 1:length(est_partial.model.paramlist)
        [tf, loc] = ismember(est_partial.model.paramlist{i},est_full.model.paramlist);
        assert(tf==1 && est_full.estopts.startparam(loc)==est_partial.param(i));
    end
    
    assertbad('regmodel_full.ReturnStartingValues({''x1_coef'',''fakeparam''},[0,0])');
end

