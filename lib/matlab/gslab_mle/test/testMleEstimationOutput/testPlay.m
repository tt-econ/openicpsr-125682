function testPlay
%
% Unit test for Play method
%

    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'external'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'depend'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'm'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'test'))) 
	
	checksum_log = '../../log/checksum.log';
    
    rng(12345)
	data = MleData('File', '../../external/data/test_data.csv', 'format', '%f%f%f%f%f%f%f%f', ...
				  'Delimiter', ',', 'ReadVarNames', true);
	data.var = data.var(1:10^4,:);	
    data.groupvar = data.var.group;
    data.const.const1 = 20;
    data.const.const2 = 100;
    
    model = RegressionModelForTesting('y', {'x1','x2'}, 'include_constant', false);
    model_no_derived = LinearRegressionModel('y', {'x1','x2'}, 'include_constant', false);
    trueparam = [1; -2; 0.5];
    simdata = model.Simulate(trueparam, data);
    estopts = MleEstimationOptions('quiet', 0);
    
    est = model.Estimate(simdata, estopts);
	diary(checksum_log)
    est.Play;
    est.Play(est.vcov, est.dvcov);
    est.Play(est.vcov_opg);
    est.Play(est.vcov_sandwich);
	diary off
    
    est_no_derived = model_no_derived.Estimate(simdata, estopts);
	diary(checksum_log)
    est_no_derived.Play;
    est_no_derived.Play(est_no_derived.vcov, est_no_derived.dvcov);
    est_no_derived.Play(est_no_derived.vcov_opg);
    est_no_derived.Play(est_no_derived.vcov_sandwich);
    diary off
	
    estopts_nohess = estopts;
    estopts_nohess.compute_hessian=0;
    est_nohess = model.Estimate(simdata, estopts_nohess);
	diary(checksum_log)
    est_nohess.Play;
	diary off
    assertbad('est_nohess.PlayFull')
    
    estopts_con = estopts_nohess;
    estopts_con.constr = MleConstraints([], [], [1 -1 0], 7);
	estopts_con.ktr = optimset(estopts_con.ktr, 'Display', 'off');
    est_con = model.Estimate(simdata, estopts_con);
	diary(checksum_log)
    est_con.Play;
	diary off
end

