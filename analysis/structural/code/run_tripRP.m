function run_tripRP(sample)
    addpath(genpath(fullfile(fileparts(fileparts(fileparts(pwd))), 'lib')))

    fid = fopen('controls.txt');
    control_names = textscan(fid,'%s','Delimiter',',');
    fclose(fid);

    fid = fopen('psis.txt');
    psi_names = textscan(fid,'%s','Delimiter',',');
    fclose(fid);

    data = extract_data('taxi_rhours25p75p_', control_names{1}, psi_names{1}, sample);

    est_model = model(data, control_names, psi_names);
end

function est = model(data, control_names, psi_names)
    format long
    estopts = MleEstimationOptions();
    estopts.ktr = optimset('Display', 'iter', 'MaxFunEvals', 1e10);
    estopts.compute_hessian = 0;
    estopts.compute_jacobian = 0;

    rpmodel = model_tripRP('controls', control_names, 'psis', psi_names);
    disp(rpmodel.paramlist)
    estopts.constr = MleConstraints([], [], [], [], ...
        [-Inf; -Inf; -Inf; -Inf], [Inf; Inf; Inf; Inf]);
    est = rpmodel.Estimate(data, estopts);
end

