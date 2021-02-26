addpath(genpath(fullfile(fileparts(fileparts(fileparts(pwd))), 'lib')))

fid = fopen('controls.txt');
control_names = textscan(fid,'%s','Delimiter',',');
fclose(fid);

fid = fopen('psis.txt');
psi_names = textscan(fid,'%s','Delimiter',',');
fclose(fid);

model_adaptive = model_adaptiveRP('controls', control_names, 'psis', psi_names);
model_trip = model_tripRP('controls', control_names, 'psis', psi_names);
model_hour = model_hourRP('controls', control_names, 'psis', psi_names);

data_0 = extract_data('taxi_sim_', control_names{1}, psi_names{1}, 0);
data_1 = extract_data('taxi_sim_', control_names{1}, psi_names{1}, 1);
data_2 = extract_data('taxi_sim_', control_names{1}, psi_names{1}, 2);
data_3 = extract_data('taxi_sim_', control_names{1}, psi_names{1}, 3);
data_4 = extract_data('taxi_sim_', control_names{1}, psi_names{1}, 4);
data_5 = extract_data('taxi_sim_', control_names{1}, psi_names{1}, 5);
data_6 = extract_data('taxi_sim_', control_names{1}, psi_names{1}, 6);
data_7 = extract_data('taxi_sim_', control_names{1}, psi_names{1}, 7);
data_8 = extract_data('taxi_sim_', control_names{1}, psi_names{1}, 8);

interval_sim = data_0.var.cum_total_duration > 8.5 & data_0.var.cum_total_duration < 8.5+10/60;

param = readtable('../output/adaptiveRP.csv', 'ReadRowNames', true).Var1;
prob_0 = model_adaptive.prob_stop(param, data_0);
base_0 = nanmean(prob_0(interval_sim));

prob_1 = model_adaptive.prob_stop(param, data_1);
base_1 = nanmean(prob_1(interval_sim));

prob_2 = model_adaptive.prob_stop(param, data_2);
base_2 = nanmean(prob_2(interval_sim));

prob_3 = model_adaptive.prob_stop(param, data_3);
base_3 = nanmean(prob_3(interval_sim));

prob_4 = model_adaptive.prob_stop(param, data_4);
base_4 = nanmean(prob_4(interval_sim));

prob_5 = model_adaptive.prob_stop(param, data_5);
base_5 = nanmean(prob_5(interval_sim));

prob_6 = model_adaptive.prob_stop(param, data_6);
base_6 = nanmean(prob_6(interval_sim));

prob_7 = model_adaptive.prob_stop(param, data_7);
base_7 = nanmean(prob_7(interval_sim));

prob_8 = model_adaptive.prob_stop(param, data_8);
base_8 = nanmean(prob_8(interval_sim));

header = {'parm', 'arp'};
fid = fopen('../output/arp.csv', 'w');
fprintf(fid, '%s\n', strjoin(header, ','));
fprintf(fid, '%s,%g\n', 'incomebin_8', (base_8-base_0)/base_0*26*100);
fprintf(fid, '%s,%g\n', 'incomebin_7', (base_7-base_0)/base_0*26*100);
fprintf(fid, '%s,%g\n', 'incomebin_6', (base_6-base_0)/base_0*26*100);
fprintf(fid, '%s,%g\n', 'incomebin_5', (base_5-base_0)/base_0*26*100);
fprintf(fid, '%s,%g\n', 'incomebin_4', (base_4-base_0)/base_0*26*100);
fprintf(fid, '%s,%g\n', 'incomebin_3', (base_3-base_0)/base_0*26*100);
fprintf(fid, '%s,%g\n', 'incomebin_2', (base_2-base_0)/base_0*26*100);
fprintf(fid, '%s,%g\n', 'incomebin_1', (base_1-base_0)/base_0*26*100);
fclose(fid);


param = readtable('../output/tripRP.csv', 'ReadRowNames', true).Var1;
prob_0 = model_trip.prob_stop(param, data_0);
base_0t = nanmean(prob_0(interval_sim));

prob_1 = model_trip.prob_stop(param, data_1);
base_1t = nanmean(prob_1(interval_sim));

prob_2 = model_trip.prob_stop(param, data_2);
base_2t = nanmean(prob_2(interval_sim));

prob_3 = model_trip.prob_stop(param, data_3);
base_3t = nanmean(prob_3(interval_sim));

prob_4 = model_trip.prob_stop(param, data_4);
base_4t = nanmean(prob_4(interval_sim));

prob_5 = model_trip.prob_stop(param, data_5);
base_5t = nanmean(prob_5(interval_sim));

prob_6 = model_trip.prob_stop(param, data_6);
base_6t = nanmean(prob_6(interval_sim));

prob_7 = model_trip.prob_stop(param, data_7);
base_7t = nanmean(prob_7(interval_sim));

prob_8 = model_trip.prob_stop(param, data_8);
base_8t = nanmean(prob_8(interval_sim));


param = readtable('../output/hourRP.csv', 'ReadRowNames', true).Var1;
prob_0 = model_hour.prob_stop(param, data_0);
base_0h = nanmean(prob_0(interval_sim));

prob_1 = model_hour.prob_stop(param, data_1);
base_1h = nanmean(prob_1(interval_sim));

prob_2 = model_hour.prob_stop(param, data_2);
base_2h = nanmean(prob_2(interval_sim));

prob_3 = model_hour.prob_stop(param, data_3);
base_3h = nanmean(prob_3(interval_sim));

prob_4 = model_hour.prob_stop(param, data_4);
base_4h = nanmean(prob_4(interval_sim));

prob_5 = model_hour.prob_stop(param, data_5);
base_5h = nanmean(prob_5(interval_sim));

prob_6 = model_hour.prob_stop(param, data_6);
base_6h = nanmean(prob_6(interval_sim));

prob_7 = model_hour.prob_stop(param, data_7);
base_7h = nanmean(prob_7(interval_sim));

prob_8 = model_hour.prob_stop(param, data_8);
base_8h = nanmean(prob_8(interval_sim));

header = {'parm', 'trip', 'hour'};
fid = fopen('../output/compare.csv', 'w');
fprintf(fid, '%s\n', strjoin(header, ','));
fprintf(fid, '%s,%g,%g\n', 'incomebin_8', (base_8t-base_0t)/base_0t*26*100, (base_8h-base_0h)/base_0h*26*100);
fprintf(fid, '%s,%g,%g\n', 'incomebin_7', (base_7t-base_0t)/base_0t*26*100, (base_7h-base_0h)/base_0h*26*100);
fprintf(fid, '%s,%g,%g\n', 'incomebin_6', (base_6t-base_0t)/base_0t*26*100, (base_6h-base_0h)/base_0h*26*100);
fprintf(fid, '%s,%g,%g\n', 'incomebin_5', (base_5t-base_0t)/base_0t*26*100, (base_5h-base_0h)/base_0h*26*100);
fprintf(fid, '%s,%g,%g\n', 'incomebin_4', (base_4t-base_0t)/base_0t*26*100, (base_4h-base_0h)/base_0h*26*100);
fprintf(fid, '%s,%g,%g\n', 'incomebin_3', (base_3t-base_0t)/base_0t*26*100, (base_3h-base_0h)/base_0h*26*100);
fprintf(fid, '%s,%g,%g\n', 'incomebin_2', (base_2t-base_0t)/base_0t*26*100, (base_2h-base_0h)/base_0h*26*100);
fprintf(fid, '%s,%g,%g\n', 'incomebin_1', (base_1t-base_0t)/base_0t*26*100, (base_1h-base_0h)/base_0h*26*100);
fclose(fid);
