function simdata = Simulate(obj, param, data, simopts)
%
% Simulates data from an MleModel.
%
% INPUTS
%   - param: Vector of parameters at which to simulate data.
%   - data: An MleData or MleSetOfDatasets object.
%   - simopts: An MleSimulationOptions object.
%
% OUTPUTS
%   - simdata: If simopts.replications==1: An MleData object. Includes data input, and dependent 
%                   variables, errors, and unobservables are all populated using random draws.
%              If simopts.replications>1: A cell array of MleData objects. Each includes data input, 
%                   with dependent variables, errors, and unobservables all populated according to
%                   varying seed for each replication.
%              If input data is an MleSetOfDatasets object: A cell array of MleData objects as above.
%                   Note that one replication is performed for each of the datasets in the input data,
%                   regardless of the value of simopts.replications.  The seed is incremented between 
%                   each replication.
%

if nargin==3
    simopts = MleSimulationOptions();
end
assert( obj.IsValidParameterVector(param) );

if strcmp(class(data), 'MleSetOfDatasets')
    simdata = MleSetOfDatasets;
    for i = 1:data.ndatasets
        simoptsrep = simopts;
        simoptsrep.seed = simoptsrep.seed + (i-1);
        simdata.datasets{i} = single_simulation(obj, param, data.datasets{i}, simoptsrep);
    end
elseif simopts.replications > 1
    simdata = MleSetOfDatasets;
    for i = 1:simopts.replications
        simoptsrep = simopts;
        simoptsrep.seed = simoptsrep.seed + (i-1);
        simdata.datasets{i} = single_simulation(obj, param, data, simoptsrep);
    end
else
    simdata = single_simulation(obj, param, data, simopts);
end
end


function simdata = single_simulation(obj, param, data, simopts)
    [raw_error raw_unobs] = obj.DrawErrorsAndRawUnobs(data, simopts);
    error = obj.TransformErrors(param, data, raw_error);
    simdata = data.AddData(error);
    if ~isempty(obj.group_unobs_list)||~isempty(obj.indiv_unobs_list)
        unobs = obj.TransformUnobservables(param, data, raw_unobs);
        simdata = simdata.AddData(unobs);
    end
    lhs = obj.ComputeOutcomes(param, simdata);
    simdata = simdata.AddData(lhs);
end

