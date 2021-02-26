function testModel
%
% Unit test for MleModel class
%

    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'external'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'depend'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'm'))) 
    addpath(genpath(fileparts(fileparts(pwd)))) 
    rng(12345)
    estopts_base = MleEstimationOptions('quiet', 1);
    
	data = MleData('File', '../../external/data/test_data.csv', 'format', '%f%f%f%f%f%f%f%f', ...
				  'Delimiter', ',', 'ReadVarNames', true);
	data.var = data.var(1:10^4,:);	
    data.groupvar = data.var.group;
    data.const.const1 = 1;
    data.const.const2 = 1;

    mlmodel = BinaryLogitModel('y', {'x1','x2'}, 'include_constant', false);
    mltrueparam = [1; -2; 0.5];

    regmodel = LinearRegressionModel('y', {'x1','x2'});
    regtrueparam = [-1; 3; 0.5; 2];
	
    regtestmodel = RegressionModelForTesting('y', {'x1','x2'});
    regtesttrueparam = [-1; 3; 0.5; 2];
    
    testmodel(mlmodel, mltrueparam, data, estopts_base)
    testmodel(regmodel, regtrueparam, data, estopts_base)
    testmodel(regtestmodel, regtesttrueparam, data, estopts_base)
    testclosedform(regmodel, regtrueparam, data, estopts_base)
    testclosedform(regtestmodel, regtesttrueparam, data, estopts_base)
    testequalityconstraints(mlmodel, mltrueparam, data, estopts_base)
    testequalityconstraints(regmodel, regtrueparam, data, estopts_base)
    testequalityconstraints(regtestmodel, regtesttrueparam, data, estopts_base)
    
    estopts_constr = MleEstimationOptions('quiet', 1);
    estopts_constr.constr = MleConstraints([], [], [0 1 -1 0], 0);
    testmodel(regmodel, regtrueparam, data, estopts_constr)
    testmodel(regtestmodel, regtesttrueparam, data, estopts_constr)
    testclosedform(regmodel, regtrueparam, data, estopts_constr)
    testclosedform(regtestmodel, regtesttrueparam, data, estopts_constr)
end

function testmodel(model, trueparam, data, estopts, varargin)
    simdata = model.Simulate(trueparam, data);
    est = model.Estimate(simdata, estopts);
    p = model.GetConditionalLikelihoods(trueparam, simdata);
    glik = model.GetGroupLikelihoods(trueparam, simdata, estopts);
    loglik = model.GetSumLogLik(trueparam, simdata, estopts);
        
    write_checksum('../../log/checksum.log', class(model), simdata.var.y(1:10),...
        est.param, est.vcov, est.se, p(1:10), glik(1:10), loglik);
        
    assertElementsAlmostEqual(est.vcov, est.vcov_opg, 'absolute', 10^-2);
    assertElementsAlmostEqual(est.vcov, est.vcov_sandwich, 'absolute', 10^-2);
    assertElementsAlmostEqual(est.vcov_opg, est.vcov_sandwich, 'absolute', 10^-2);    
end

function testclosedform(model, trueparam, data, estopts)
    normtol = 10^(-3);
    simdata = model.Simulate(trueparam, data);
    est = model.Estimate(simdata, estopts);
    closedform = model.ClosedFormEstimate(simdata, estopts);
    if isempty(estopts.constr.Aeq)
        assert( norm(closedform.beta-est.param(1:3, :) ) < normtol );
        assert( norm(closedform.vcov-est.vcov(1:3, 1:3) ) < normtol );
    else
        assert( norm(closedform.betastar-est.param(1:3, :) ) < normtol );
        assert( norm(closedform.vcovstar-est.vcov(1:3, 1:3) ) < normtol );
    end
end

function testequalityconstraints(model, trueparam, data, estopts)
    simdata = model.Simulate(trueparam, data);
    constraint_vec = zeros(1,length(trueparam));
    ub = ones(1,length(trueparam))*Inf;
    lb = ones(1,length(trueparam))*-Inf;
    constraint_vec(1) = 1;
    ub(1) = trueparam(1);
    lb(1) = trueparam(1);
    estopts.constr = MleConstraints([], [], constraint_vec, trueparam(1));
    est_lin = model.Estimate(simdata, estopts);
    estopts.constr = MleConstraints([], [], [], [], lb, ub);
    est_bds = model.Estimate(simdata, estopts);
    estopts.constr = MleConstraints([], [], constraint_vec, trueparam(1), lb, ub);
    est_both = model.Estimate(simdata, estopts);
    assertElementsAlmostEqual(abs(est_lin.vcov), abs(est_bds.vcov), 'absolute', 10^-4);
    assertElementsAlmostEqual(abs(est_bds.vcov), abs(est_both.vcov), 'absolute', 10^-4);
end
