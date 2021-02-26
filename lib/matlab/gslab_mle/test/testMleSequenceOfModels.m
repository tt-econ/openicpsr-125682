function testMleSequenceOfModels
%
% Unit test for MleSequenceOfModels class
%

    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'external'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'depend'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'm'))) 
    rng(12345)
    estopts = MleEstimationOptions('quiet', 1);
    estopts_nohess = MleEstimationOptions('quiet', 1, 'compute_hessian',0);
    
	data = MleData('File', '../external/data/test_data.csv', 'format', '%f%f%f%f%f%f%f%f', ...
				  'Delimiter', ',', 'ReadVarNames', true);
	data.var = data.var(1:10^4,:);	
    data.groupvar = data.var.group;
    data.const.const1 = 1;
    data.const.const2 = 1;

    mlmodel = BinaryLogitModel('y', {'x1','x2'}, 'include_constant', false);
    mltrueparam = [1; -2; 0.5];

    regmodel = LinearRegressionModel('y', {'x1','x2'});
    regtrueparam = [-1; 3; 0.5; 2];
	
    simdata_ml = mlmodel.Simulate(mltrueparam, data);
    simdata_reg = regmodel.Simulate(regtrueparam, data);
    
    est_ml = mlmodel.Estimate(simdata_ml, estopts);
    est_reg = regmodel.Estimate(simdata_reg, estopts);
    
    modelarray = MleSequenceOfModels();
    modelarray.models = {mlmodel, regmodel};
    
    est = modelarray.Estimate({simdata_ml, simdata_reg}, {estopts, estopts});
    assertElementsAlmostEqual(est{1}.param, est_ml.param, 'absolute', 10^-6);
    assertElementsAlmostEqual(est{2}.param, est_reg.param, 'absolute', 10^-6);    
    
    estopts_secondstep = estopts;
    estopts_secondstep.first_step_paramlist = {'x1_coeff'};
    
    estopts_secondstep_notarray = estopts_secondstep;
    estopts_secondstep_notarray.first_step_param = est_ml.param(1);
    estopts_secondstep_notarray.first_step_vcov = est_ml.vcov(1,1);
    
    est_reg_twostep = regmodel.Estimate(simdata_reg, estopts_secondstep_notarray);
    est_twostep = modelarray.Estimate({simdata_ml, simdata_reg}, {estopts, estopts_secondstep});
    assertElementsAlmostEqual(est_twostep{2}.param, est_reg_twostep.param, 'absolute', 10^-6);    
    assertElementsAlmostEqual(est_twostep{2}.vcov_twostep, est_reg_twostep.vcov_twostep, 'absolute', 10^-6);   
    
    % test handling for case where first step does not compute a hessian
    modelarray.Estimate({simdata_ml, simdata_reg}, {estopts_nohess, estopts_secondstep});

end
