function testWaldTest
%
% Unit test for WaldTest method of class MleEstimationOutput
%

    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'external'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'depend'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'm'))) 
    rng(12345)
    estopts = MleEstimationOptions('quiet', 1);
    
	data = MleData('File', '../../external/data/test_data.csv', 'format', '%f%f%f%f%f%f%f%f', ...
				  'Delimiter', ',', 'ReadVarNames', true);
	data.var = data.var(1:10^5,:);
    
    regmodel = LinearRegressionModel('y', {'x1','x2'});
    regtrueparam = [-1; 3; 0.5; 2];
	
    simdata = regmodel.Simulate(regtrueparam, data);
    est = regmodel.Estimate(simdata, estopts);
    
    wald_failrej_lin = est.WaldTest(eye(4),[],regtrueparam);
    assert(wald_failrej_lin.pvalue>0.5);
    assert(wald_failrej_lin.dof == 4);
    
    wald_failrej_fun = est.WaldTest([],@linear_transform,regtrueparam);
    assertElementsAlmostEqual(wald_failrej_lin.pvalue, wald_failrej_fun.pvalue, 'relative', 10^-4);
    assertElementsAlmostEqual(wald_failrej_lin.wald_statistic, wald_failrej_fun.wald_statistic, 'relative', 10^-4);
    assert(wald_failrej_lin.dof == wald_failrej_fun.dof);
    
    wald_rej_lin = est.WaldTest([2,0,0,1;3,1,0,4],[],rand(2,1));
    assertElementsAlmostEqual(wald_rej_lin.pvalue, 0, 'relative', 10^-4);
    assert(wald_rej_lin.dof == 2);
    
    wald_failrej_comb_lin = est.WaldTest([0,1,2,-2;3,1,2,1],[],[0;3]);
    assert(wald_failrej_comb_lin.pvalue>0.5);
    assert(wald_failrej_comb_lin.dof == 2);
    
    wald_failrej_comb_both = est.WaldTest([0,1,2,1],@non_linear_transform,[6;-1;1]);
    assert(wald_failrej_comb_both.pvalue>0.5);
    assert(wald_failrej_comb_both.dof == 3);
    
    wald_rej_comb_both = est.WaldTest([0,1,2,1],@non_linear_transform,[0;-6;6]);
    assertElementsAlmostEqual(wald_rej_comb_both.pvalue, 0, 'relative', 10^-4);
    assert(wald_rej_comb_both.dof == 3);
    
    
    %test WaldTest on constrained model where pvalue>.001
	data = MleData('File', '../../external/data/test_data.csv', 'format', '%f%f%f%f%f%f%f%f', ...
				  'Delimiter', ',', 'ReadVarNames', true);
	data.var = data.var(1:10^2,:);	 

    estopts.constr.Aeq = [0, 1, -1, 0];
    estopts.constr.beq = 0;
    simdata = regmodel.Simulate(regtrueparam, data);       
    est_constr = regmodel.Estimate(simdata, estopts);
    
    %confirm that param1=param2 => tests for param1=param2=0 and param1=0 are identical
    wald_test_both = est_constr.WaldTest([0,1,0,0;0,0,1,0],[],[0;0],10^-8);
    wald_test_single = est_constr.WaldTest([0,1,0,0],[],0,10^-8);   
    assertElementsAlmostEqual(wald_test_both.wald_statistic, wald_test_single.wald_statistic, 'relative', 10^-4)
    assertEqual(wald_test_both.dof, wald_test_single.dof)
    assertElementsAlmostEqual(wald_test_both.pvalue, wald_test_single.pvalue, 'relative', 10^-4)   
    
    write_checksum('../../log/checksum.log', 'WaldTest', wald_failrej_lin.wald_statistic, wald_failrej_lin.pvalue,...
                                                            wald_failrej_fun.wald_statistic, wald_failrej_fun.pvalue,...
                                                            wald_rej_lin.wald_statistic, wald_rej_lin.pvalue,...
                                                            wald_failrej_comb_lin.wald_statistic, wald_failrej_comb_lin.pvalue,...
                                                            wald_failrej_comb_both.wald_statistic, wald_failrej_comb_both.pvalue,...
                                                            wald_rej_comb_both.wald_statistic, wald_rej_comb_both.pvalue);
end

function [ linear_transform ] = linear_transform( param )
    linear_transform = zeros(4,1);
    for i = 1:4
        linear_transform(i) = param(i);
    end
end

function [ non_linear_transform ] = non_linear_transform( param )
    non_linear_transform = zeros(2,1);
    non_linear_transform(1) = param(2)/param(1) + param(3)*param(4)^2; 
    non_linear_transform(2) = param(4)*(sqrt(abs(param(1)))-param(3)); 
end
