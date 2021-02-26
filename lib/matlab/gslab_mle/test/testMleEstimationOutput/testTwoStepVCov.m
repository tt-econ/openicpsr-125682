function testTwoStepVCov
%
% Unit test for handling of two-step VCov in class MleEstimationOutput
%

    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'external'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'depend'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'm'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'test'))) 
    rng(12345)
    
	data = MleData('File', '../../external/data/test_data.csv', 'format', '%f%f%f%f%f%f%f%f', ...
				  'Delimiter', ',', 'ReadVarNames', true);
	data.var = data.var(1:10^5,:);
    data.const.const1 = 10;
    data.const.const2 = 12;
    
    regmodel = RegressionModelForTesting('y', {'x1','x2'});
    regtrueparam = [-1; 3; 0.5; 2];	
    simdata = regmodel.Simulate(regtrueparam, data);
    [est_fiml_reg est_liml_reg] = fiml_vs_liml(regmodel, simdata, {'constant'});
    [~] = fiml_vs_liml(regmodel, simdata, {'x1_coeff'});
    [~] = fiml_vs_liml(regmodel, simdata, {'x2_coeff'});
    [~] = fiml_vs_liml(regmodel, simdata, {'sigma'});
    [~] = fiml_vs_liml(regmodel, simdata, {'x2_coeff', 'x1_coeff'});
    
    simdata.var.ybinary = simdata.var.y>mean(simdata.var.y);
    logitmodel = BinaryLogitModel('ybinary', {'x1'}, 'mixed_logit', 0);
    [est_fiml_logit est_liml_logit] = fiml_vs_liml(logitmodel, simdata, {'constant'});
    [~] = fiml_vs_liml(logitmodel, simdata, {'x1_coeff'});
    
    toymodel = ExampleModel('y');
    [est_fiml_toy est_liml_toy] = fiml_vs_liml(toymodel, simdata, {'mu'});
    
    check_syntax(est_fiml_reg);
    
    write_checksum('../../log/checksum.log', 'TwoStepVCov', est_fiml_reg.vcov,...
        est_fiml_reg.se, est_liml_reg.vcov_twostep, est_liml_reg.se_twostep,...
        est_fiml_logit.vcov, est_liml_logit.vcov_twostep,...
        est_fiml_toy.dvcov, est_liml_toy.dvcov_twostep);
end

function [est_fiml est_liml] = fiml_vs_liml(model, data, first_step_paramlist)
    
    reltol = 10^-2;
    abstol = 10^-4;

    estopts_fiml = MleEstimationOptions('quiet', 1);
    est_fiml = model.Estimate(data, estopts_fiml);
    assertTrue(isempty(est_fiml.vcov_twostep)&~isempty(est_fiml.vcov));
    assertTrue(((isempty(est_fiml.dvcov_twostep)&~isempty(est_fiml.dvcov)) | isempty(model.dparamlist)));
    
    estopts_liml = estopts_fiml;
    estopts_liml.first_step_paramlist = first_step_paramlist;
    estopts_liml.first_step_param = est_fiml.GetParamSubset(estopts_liml.first_step_paramlist);
    estopts_liml.first_step_vcov = est_fiml.GetVCovSubset(estopts_liml.first_step_paramlist);
    
    est_liml = model.Estimate(data, estopts_liml);
    assertFalse(any(est_liml.se>=est_liml.se_twostep))
    assertFalse(isequal(est_liml.vcov, est_liml.vcov_twostep));
    assertFalse(isequal(est_fiml.vcov, est_liml.vcov_twostep));
    assertElementsAlmostEqual(est_fiml.vcov, est_liml.vcov_twostep, 'relative', reltol);
    assertElementsAlmostEqual(est_fiml.vcov, est_liml.vcov_twostep, 'absolute', abstol);
    assertElementsAlmostEqual(est_fiml.dvcov, est_liml.dvcov_twostep, 'relative', reltol);
    assertElementsAlmostEqual(est_fiml.dvcov, est_liml.dvcov_twostep, 'absolute', abstol);    
end

function check_syntax(est)
    bad_paramlist = {'blah'};
    bad_vcov = [];
    good_paramlist = {'constant'};
    good_vcov = [];
    est.TwoStepVCov(good_vcov, good_paramlist);
    assertbad('est_fiml_reg.TwoStepVCov(good_vcov,bad_paramlist)');
    assertbad('est_fiml_reg.TwoStepVCov(bad_vcov,good_paramlist)');
    assertbad('est_fiml_reg.TwoStepVCov(bad_vcov,bad_paramlist)');
end