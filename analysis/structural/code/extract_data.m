function data = extract_data(filename, control_names, psi_names, sample)
    data = TaxiData('File', strcat('../input/', filename, num2str(sample), '.csv'), 'format', ...
                    '%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f', ...
                    'Delimiter', ',', 'ReadVarNames', true);

    data.var = data.var(data.var.sample_id==sample, :);
    data.var.exp_cum_income = data.var.cum_income + data.var.exp_income;
    data.var.exp_cum_duration = data.var.cum_total_duration + data.var.exp_duration;
    data.var.r_income = data.var.r_income_driverdow_all;
    data.var.r_income_fixed = data.var.r_income_driver_all;
    data.var.r_income_trip = data.var.pred_total_income_trip_m1;
    data.var.r_income_hour = data.var.pred_total_income_hour;
    data.var.r_duration = data.var.r_hours_driverdow_all;
    data.nshifts = sum(data.var.final_trip);
    data.maxntrips = max(data.var.trip_id);
    data.var(isnan(data.var.r_income), :) = [];

    data.controls = [];
    data.control_names = control_names;
    for i = 1:numel(control_names)
        data.controls = [data.controls data.var.([control_names{i}])];
    end
    data.controls = double(data.controls);

    data.psis = [];
    data.psi_names = psi_names;
    for i = 1:numel(psi_names)
        data.psis = [data.psis data.var.([psi_names{i}])];
    end
    data.psis = double(data.psis);

    data.del = [];
    for i = 2 : 62
        name = strcat('delta_', num2str(i));
        data.del = [data.del double(data.var.(name))];
        data.var.(name) = [];
    end
    data.del(isnan(data.del)) = 0;
    nlags = size(data.del, 2);
    data.w = repmat(data.var.trip_id, 1, nlags) - ...
        repmat(1 : nlags, data.nobs, 1);
end
