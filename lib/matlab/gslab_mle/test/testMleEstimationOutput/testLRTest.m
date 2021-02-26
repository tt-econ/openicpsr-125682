function testLRTest
%
% Unit test for LRTest method of class MleEstimationOutput
%

    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'external'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'depend'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'm'))) 
    rng(12345)
    estopts = MleEstimationOptions('quiet', 1);
    warning off all;

    [estopts_lin_true, estopts_lin_false, estopts_ml_true, estopts_ml_false, ...
    estopts_fail, estopts_fail_nonnest, estopts_fail_nonlin, estopts_fail_nonlin_nonnest] = deal(estopts);
    estopts_lin_true.constr = MleConstraints([], [], [], [], [-1 -Inf -Inf -Inf], [-1 Inf Inf Inf]);
    estopts_lin_false.constr = MleConstraints([], [], [], [], [-1.2 2 -Inf -Inf], [-1.2 2 Inf Inf]);
    estopts_ml_true.constr = MleConstraints([], [], [], [], [1 -Inf -Inf], [1 Inf Inf]);
    estopts_ml_false.constr = MleConstraints([], [], [], [], [1.2 -1 -Inf], [1.2 -1 Inf]);
    estopts_fail.constr = MleConstraints([], [], [1,0,0,0;0,1,0,0], [-1;3], [], []);
    estopts_fail_nonnest.constr = MleConstraints([], [], [1,0,0,0;0,1,0,0;2,1,2,0], [-1;2;2], [], []);
    estopts_fail_nonlin.constr = MleConstraints([], [], [], [], [], [], @non_linear_constraints);
    estopts_fail_nonlin_nonnest.constr = MleConstraints([], [], [], [], [], [], @non_linear_constraints_nonnest);
    
	data = MleData('File', '../../external/data/test_data.csv', 'format', '%f%f%f%f%f%f%f%f', ...
				  'Delimiter', ',', 'ReadVarNames', true);
	data.var = data.var(1:10^4,:);
    data.groupvar = data.var.group;
    
    regmodel = LinearRegressionModel('y', {'x1','x2'});
    regtrueparam = [-1; 3; 0.5; 2];
    simdata_lin = regmodel.Simulate(regtrueparam, data);
    
    mlmodel = BinaryLogitModel('y', {'x1','x2'}, 'include_constant', false);
    mltrueparam = [1; -2; 0.5];
    simdata_ml = mlmodel.Simulate(mltrueparam, data);
	
    est_lin = regmodel.Estimate(simdata_lin, estopts);
    est_lin_constr_true = regmodel.Estimate(simdata_lin, estopts_lin_true);
    est_lin_constr_false = regmodel.Estimate(simdata_lin, estopts_lin_false);
    est_lin_fail_lin = regmodel.Estimate(simdata_lin, estopts_fail);
    est_lin_fail_lin_nonnest = regmodel.Estimate(simdata_lin, estopts_fail_nonnest);
    est_lin_fail_nonlin = regmodel.Estimate(simdata_lin, estopts_fail_nonlin);
    est_lin_fail_nonlin_nonnest = regmodel.Estimate(simdata_lin, estopts_fail_nonlin_nonnest);
    
    est_ml = mlmodel.Estimate(simdata_ml, estopts);
    est_ml_constr_true = mlmodel.Estimate(simdata_ml, estopts_ml_true);
    est_ml_constr_false = mlmodel.Estimate(simdata_ml, estopts_ml_false);

    lr_lin_true = est_lin_constr_true.LRTest(est_lin);
    assert(lr_lin_true.pvalue > 0.1);
    assert(lr_lin_true.dof == 1);
    
    lr_lin_false = est_lin_constr_false.LRTest(est_lin);
    assert(lr_lin_false.pvalue < 0.01);
    assert(lr_lin_false.dof == 2);
    
    ml_lin_true = est_ml_constr_true.LRTest(est_ml);
    assert(ml_lin_true.pvalue > 0.1);
    assert(ml_lin_true.dof == 1);
    
    ml_lin_false = est_ml_constr_false.LRTest(est_ml);
    assert(ml_lin_false.pvalue < 0.01);
    assert(ml_lin_false.dof == 2);
    
    for failtests = {'est_lin_fail_nonlin_nonnest.LRTest(est_lin_fail_nonlin);', ...
                     'est_lin_fail_lin_nonnest.LRTest(est_lin_fail_lin);'}
        test = failtests{:};
        lastwarn('');
        eval(test);
        assert( isequal(lastwarn, 'Restricted model is not nested.') );
    end
    
    write_checksum('../../log/checksum.log', 'LRTest', lr_lin_true.log_likelihood_ratio, lr_lin_true.lr_statistic, lr_lin_true.pvalue,...
                                                       lr_lin_false.log_likelihood_ratio, lr_lin_false.lr_statistic, lr_lin_false.pvalue,...
                                                       ml_lin_true.log_likelihood_ratio, ml_lin_true.lr_statistic, ml_lin_true.pvalue,...
                                                       ml_lin_false.log_likelihood_ratio, ml_lin_false.lr_statistic, ml_lin_false.pvalue);
end

function [c, ceq] = non_linear_constraints(param)
    ceq = zeros(2,1);
    ceq(1) = param(1)^2 + param(2)^2 + param(3)^2 - 10;
    ceq(2) = param(1)^2-1;
    c = [];
end

function [ c, ceq] = non_linear_constraints_nonnest(param)
    ceq = zeros(2,1);
    ceq(1) = param(1)^2 + param(2)^2 + param(3)^2 - 10;
    ceq(2) = param(1)^2-4;
    ceq(3) = param(2)^2 - 2;
    c = [];
end                                                   
    