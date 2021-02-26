function [est, bootstrap_reps] = ParametricBootstrap(obj, data, param_true, reps, estopts)
%
% Repeatedly simulate data from the model, estimate the parameters on the
% simulated data and report statistics on the sample of estimates
%
% INPUTS
%   - data: An MleData object.
%
%   - param: Vector of parameters at which to simulate data.
%
%   - reps: number of independent datasets generated
%
%   - estopts: An MleEstimationOptions object.
%
% OUTPUTS
%   - est: An MleBootstrapOutput object
%
%   - bootstrap_reps: reps x 1 cell array of simulation data (MleData)
%
% OPTIONS
%   See header comment for MleEstimationOptions
%
    if nargin == 3           
        estopts = MleEstimationOptions();
    end
    
    [simopts simdata est_sim] = deal( cell(reps, 1) );
    
    rng(123)
    for i = 1 : reps
        simopts{i} = MleSimulationOptions('seed', round(rand * 1000));
    end
    
    for i = 1 : reps
        simdata{i} = Simulate(obj, param_true, data, simopts{i});
        est_sim{i} = Estimate(obj, simdata{i}, estopts);        
    end
    
    dparam_true = obj.GetDerivedParam(param_true, data.const);
    
    est = MleBootstrapOutput(est_sim, param_true, obj, dparam_true);
    if nargout == 2
        bootstrap_reps = simdata;
    end
end
