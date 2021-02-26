addpath(genpath(fullfile(fileparts(fileparts(fileparts(pwd))), 'lib')))
rng(54);
rand(1000);

clear

param = readtable('../output/adaptiveRP.csv', 'ReadRowNames', true);
sd = readtable('../output/adaptiveRP_sd.csv', 'ReadRowNames', true);
paramval = param.Var1;

fid = fopen('controls.txt');
control_names = textscan(fid,'%s','Delimiter',',');
fclose(fid);

fid = fopen('psis.txt');
psi_names = textscan(fid,'%s','Delimiter',',');
fclose(fid);

model = model_adaptiveRP('controls', control_names, 'psis', psi_names, 'main_startparam', paramval(1:5), 'controls_startparam', paramval(6:end));


mean_lnpsi = param({'lnpsi'}, :).Var1;
sd_lnpsi = sd({'lnpsi'}, :).Var1;

mean_transformed_nu = param({'transformed_nu'}, :).Var1;
sd_transformed_nu = sd({'transformed_nu'}, :).Var1;

mean_lnsigma = param({'lnsigma'}, :).Var1;
sd_lnsigma = sd({'lnsigma'}, :).Var1;

mean_lngl = param({'lngl'}, :).Var1;
sd_lngl = sd({'lngl'}, :).Var1;

mean_theta = param({'theta'}, :).Var1;
sd_theta = sd({'theta'}, :).Var1;


vary_psi = cell(21, 7);
for i = 1 : 21
    for j = 1 : 7
        vary_psi{i, j} = paramval;
    end
end

for i = 1 : 21
    vary_psi{i, 1}(1) = mean_lnpsi - sd_lnpsi + (i-1)/10*sd_lnpsi;
    for j = 2 : 7
        vary_psi{i, j}(1) = mean_lnpsi - sd_lnpsi + (i-1)/10*sd_lnpsi;

        vary_psi{i, j}(2) = mean_transformed_nu;
        vary_psi{i, j}(3) = mean_lnsigma;
        vary_psi{i, j}(4) = mean_lngl;
        vary_psi{i, j}(5) = mean_theta;
    end
end

vary_nu = cell(21, 7);
for i = 1 : 21
    for j = 1 : 7
        vary_nu{i, j} = paramval;
    end
end

for i = 1 : 21
    vary_nu{i, 1}(2) = mean_transformed_nu - sd_transformed_nu + (i-1)/10*sd_transformed_nu;
    for j = 2 : 7
        vary_nu{i, j}(2) = mean_transformed_nu - sd_transformed_nu + (i-1)/10*sd_transformed_nu;

        vary_nu{i, j}(1) = mean_lnpsi;
        vary_nu{i, j}(3) = mean_lnsigma;
        vary_nu{i, j}(4) = mean_lngl;
        vary_nu{i, j}(5) = mean_theta;
    end
end

vary_lambda = cell(21, 7);
for i = 1 : 21
    for j = 1 : 7
        vary_lambda{i, j} = paramval;
    end
end

for i = 1 : 21
    vary_lambda{i, 1}(4) = mean_lngl - sd_lngl + (i-1)/10*sd_lngl;
    for j = 2 : 7
        vary_lambda{i, j}(4) = mean_lngl - sd_lngl + (i-1)/10*sd_lngl;

        vary_lambda{i, j}(1) = mean_lnpsi;
        vary_lambda{i, j}(2) = mean_transformed_nu;
        vary_lambda{i, j}(3) = mean_lnsigma;
        vary_lambda{i, j}(5) = mean_theta;
    end
end

vary_theta = cell(21, 7);
for i = 1 : 21
    for j = 1 : 7
        vary_theta{i, j} = paramval;
    end
end

for i = 1 : 21
    vary_theta{i, 1}(5) = mean_theta - sd_theta + (i-1)/10*sd_theta;
    for j = 2 : 7
        vary_theta{i, j}(5) = mean_theta - sd_theta + (i-1)/10*sd_theta;

        vary_theta{i, j}(1) = mean_lnpsi;
        vary_theta{i, j}(2) = mean_transformed_nu;
        vary_theta{i, j}(3) = mean_lnsigma;
        vary_theta{i, j}(4) = mean_lngl;
    end
end

data = extract_data('taxi_rhours25p75p_', control_names{1}, psi_names{1}, 9);

data_extra10min = extract_data('taxi_rhours25p75p_', control_names{1}, psi_names{1}, 9);
data_extra10min.var.cum_total_duration = data_extra10min.var.cum_total_duration + 10/60;
data_extra10min.var.exp_cum_duration = data_extra10min.var.cum_total_duration + data_extra10min.var.exp_duration;

data_extra10wage = extract_data('taxi_rhours25p75p_', control_names{1}, psi_names{1}, 9);
data_extra10wage.var.exp_income = data_extra10wage.var.exp_income * 1.10;
data_extra10wage.var.exp_duration = data_extra10wage.var.exp_duration * 1;
data_extra10wage.var.exp_cum_income = data_extra10wage.var.cum_income + data_extra10wage.var.exp_income;
data_extra10wage.var.exp_cum_duration = data_extra10wage.var.cum_total_duration + data_extra10wage.var.exp_duration;

data_extra10inc = extract_data('taxi_rhours25p75p_', control_names{1}, psi_names{1}, 9);
data_extra10inc.var.cum_income = data_extra10inc.var.cum_income + .10;
data_extra10inc.var.exp_cum_income = data_extra10inc.var.exp_cum_income + .10;

data_5 = extract_data('taxi_sim_', control_names{1}, psi_names{1}, 5);
data_8 = extract_data('taxi_sim_', control_names{1}, psi_names{1}, 8);

prob_psi = cell(21, 7);
prob_psi_extra10min = cell(21, 7);
prob_psi_extra10wage = cell(21, 7);
prob_psi_extra10inc = cell(21, 7);
prob_psi_5 = cell(21, 7);
prob_psi_8 = cell(21, 7);
base_psi = cell(21, 7);
base_psi_extra10min = cell(21, 7);
base_psi_extra10wage = cell(21, 7);
base_psi_extra10inc = cell(21, 7);
base_psi_5 = cell(21, 7);
base_psi_8 = cell(21, 7);
psi_extra10min = zeros(21, 7);
psi_extra10wage = zeros(21, 7);
psi_extra10inc = zeros(21, 7);
psi_8_5 = zeros(21, 7);
for i = 1 : 21
    for j = 1 : 7
        prob_psi{i, j} = model.prob_stop(vary_psi{i, j}, data);
        prob_psi_extra10min{i, j} = model.prob_stop(vary_psi{i, j}, data_extra10min);
        prob_psi_extra10wage{i, j} = model.prob_stop(vary_psi{i, j}, data_extra10wage);
        prob_psi_extra10inc{i, j} = model.prob_stop(vary_psi{i, j}, data_extra10inc);
        prob_psi_5{i, j} = model.prob_stop(vary_psi{i, j}, data_5);
        prob_psi_8{i, j} = model.prob_stop(vary_psi{i, j}, data_8);

        base_psi{i, j} = nanmean(prob_psi{i, j});
        base_psi_extra10min{i, j} = nanmean(prob_psi_extra10min{i, j});
        base_psi_extra10wage{i, j} = nanmean(prob_psi_extra10wage{i, j});
        base_psi_extra10inc{i, j} = nanmean(prob_psi_extra10inc{i, j});
        base_psi_5{i, j} = nanmean(prob_psi_5{i, j});
        base_psi_8{i, j} = nanmean(prob_psi_8{i, j});

        psi_extra10min(i, j) = (base_psi_extra10min{i, j} - base_psi{i, j}) / base_psi{i, j};
        psi_extra10wage(i, j) = (base_psi_extra10wage{i, j} - base_psi{i, j}) / base_psi{i, j};
        psi_extra10inc(i, j) = (base_psi_extra10inc{i, j} - base_psi{i, j}) / base_psi{i, j};
        psi_8_5(i, j) = (base_psi_8{i, j} - base_psi{i, j}) / (base_psi_5{i, j} - base_psi{i, j});
    end
end

prob_nu = cell(21, 7);
prob_nu_extra10min = cell(21, 7);
prob_nu_extra10wage = cell(21, 7);
prob_nu_extra10inc = cell(21, 7);
prob_nu_5 = cell(21, 7);
prob_nu_8 = cell(21, 7);
base_nu = cell(21, 7);
base_nu_extra10min = cell(21, 7);
base_nu_extra10wage = cell(21, 7);
base_nu_extra10inc = cell(21, 7);
base_nu_5 = cell(21, 7);
base_nu_8 = cell(21, 7);
nu_extra10min = zeros(21, 7);
nu_extra10wage = zeros(21, 7);
nu_extra10inc = zeros(21, 7);
nu_8_5 = zeros(21, 7);
for i = 1 : 21
    for j = 1 : 7
        prob_nu{i, j} = model.prob_stop(vary_nu{i, j}, data);
        prob_nu_extra10min{i, j} = model.prob_stop(vary_nu{i, j}, data_extra10min);
        prob_nu_extra10wage{i, j} = model.prob_stop(vary_nu{i, j}, data_extra10wage);
        prob_nu_extra10inc{i, j} = model.prob_stop(vary_nu{i, j}, data_extra10inc);
        prob_nu_5{i, j} = model.prob_stop(vary_nu{i, j}, data_5);
        prob_nu_8{i, j} = model.prob_stop(vary_nu{i, j}, data_8);

        base_nu{i, j} = nanmean(prob_nu{i, j});
        base_nu_extra10min{i, j} = nanmean(prob_nu_extra10min{i, j});
        base_nu_extra10wage{i, j} = nanmean(prob_nu_extra10wage{i, j});
        base_nu_extra10inc{i, j} = nanmean(prob_nu_extra10inc{i, j});
        base_nu_5{i, j} = nanmean(prob_nu_5{i, j});
        base_nu_8{i, j} = nanmean(prob_nu_8{i, j});

        nu_extra10min(i, j) = (base_nu_extra10min{i, j} - base_nu{i, j}) / base_nu{i, j};
        nu_extra10wage(i, j) = (base_nu_extra10wage{i, j} - base_nu{i, j}) / base_nu{i, j};
        nu_extra10inc(i, j) = (base_nu_extra10inc{i, j} - base_nu{i, j}) / base_nu{i, j};
        nu_8_5(i, j) = (base_nu_8{i, j} - base_nu{i, j}) / (base_nu_5{i, j} - base_nu{i, j});
    end
end

prob_lambda = cell(21, 7);
prob_lambda_extra10min = cell(21, 7);
prob_lambda_extra10wage = cell(21, 7);
prob_lambda_extra10inc = cell(21, 7);
prob_lambda_5 = cell(21, 7);
prob_lambda_8 = cell(21, 7);
base_lambda = cell(21, 7);
base_lambda_extra10min = cell(21, 7);
base_lambda_extra10wage = cell(21, 7);
base_lambda_extra10inc = cell(21, 7);
base_lambda_5 = cell(21, 7);
base_lambda_8 = cell(21, 7);
lambda_extra10min = zeros(21, 7);
lambda_extra10wage = zeros(21, 7);
lambda_extra10inc = zeros(21, 7);
lambda_8_5 = zeros(21, 7);
for i = 1 : 21
    for j = 1 : 7
        prob_lambda{i, j} = model.prob_stop(vary_lambda{i, j}, data);
        prob_lambda_extra10min{i, j} = model.prob_stop(vary_lambda{i, j}, data_extra10min);
        prob_lambda_extra10wage{i, j} = model.prob_stop(vary_lambda{i, j}, data_extra10wage);
        prob_lambda_extra10inc{i, j} = model.prob_stop(vary_lambda{i, j}, data_extra10inc);
        prob_lambda_5{i, j} = model.prob_stop(vary_lambda{i, j}, data_5);
        prob_lambda_8{i, j} = model.prob_stop(vary_lambda{i, j}, data_8);

        base_lambda{i, j} = nanmean(prob_lambda{i, j});
        base_lambda_extra10min{i, j} = nanmean(prob_lambda_extra10min{i, j});
        base_lambda_extra10wage{i, j} = nanmean(prob_lambda_extra10wage{i, j});
        base_lambda_extra10inc{i, j} = nanmean(prob_lambda_extra10inc{i, j});
        base_lambda_5{i, j} = nanmean(prob_lambda_5{i, j});
        base_lambda_8{i, j} = nanmean(prob_lambda_8{i, j});

        lambda_extra10min(i, j) = (base_lambda_extra10min{i, j} - base_lambda{i, j}) / base_lambda{i, j};
        lambda_extra10wage(i, j) = (base_lambda_extra10wage{i, j} - base_lambda{i, j}) / base_lambda{i, j};
        lambda_extra10inc(i, j) = (base_lambda_extra10inc{i, j} - base_lambda{i, j}) / base_lambda{i, j};
        lambda_8_5(i, j) = (base_lambda_8{i, j} - base_lambda{i, j}) / (base_lambda_5{i, j} - base_lambda{i, j});
    end
end

prob_theta = cell(21, 7);
prob_theta_extra10min = cell(21, 7);
prob_theta_extra10wage = cell(21, 7);
prob_theta_extra10inc = cell(21, 7);
prob_theta_5 = cell(21, 7);
prob_theta_8 = cell(21, 7);
base_theta = cell(21, 7);
base_theta_extra10min = cell(21, 7);
base_theta_extra10wage = cell(21, 7);
base_theta_extra10inc = cell(21, 7);
base_theta_5 = cell(21, 7);
base_theta_8 = cell(21, 7);
theta_extra10min = zeros(21, 7);
theta_extra10wage = zeros(21, 7);
theta_extra10inc = zeros(21, 7);
theta_8_5 = zeros(21, 7);
for i = 1 : 21
    for j = 1 : 7
        prob_theta{i, j} = model.prob_stop(vary_theta{i, j}, data);
        prob_theta_extra10min{i, j} = model.prob_stop(vary_theta{i, j}, data_extra10min);
        prob_theta_extra10wage{i, j} = model.prob_stop(vary_theta{i, j}, data_extra10wage);
        prob_theta_extra10inc{i, j} = model.prob_stop(vary_theta{i, j}, data_extra10inc);
        prob_theta_5{i, j} = model.prob_stop(vary_theta{i, j}, data_5);
        prob_theta_8{i, j} = model.prob_stop(vary_theta{i, j}, data_8);

        base_theta{i, j} = nanmean(prob_theta{i, j});
        base_theta_extra10min{i, j} = nanmean(prob_theta_extra10min{i, j});
        base_theta_extra10wage{i, j} = nanmean(prob_theta_extra10wage{i, j});
        base_theta_extra10inc{i, j} = nanmean(prob_theta_extra10inc{i, j});
        base_theta_5{i, j} = nanmean(prob_theta_5{i, j});
        base_theta_8{i, j} = nanmean(prob_theta_8{i, j});

        theta_extra10min(i, j) = (base_theta_extra10min{i, j} - base_theta{i, j}) / base_theta{i, j};
        theta_extra10wage(i, j) = (base_theta_extra10wage{i, j} - base_theta{i, j}) / base_theta{i, j};
        theta_extra10inc(i, j) = (base_theta_extra10inc{i, j} - base_theta{i, j}) / base_theta{i, j};
        theta_8_5(i, j) = (base_theta_8{i, j} - base_theta{i, j}) / (base_theta_5{i, j} - base_theta{i, j});
    end
end

plot(-10:10, psi_extra10min(:, 1), 'color', [89, 38, 11]/255, 'LineWidth', 4)
hold on
plot(-10:10, nu_extra10min(:, 1), ':', 'color', [219, 109, 0]/255, 'LineWidth', 2)
hold on
plot(-10:10, lambda_extra10min(:, 1), '-.', 'color', [0, 77, 62]/255, 'LineWidth', 2)
hold on
plot(-10:10, theta_extra10min(:, 1), '--', 'color', [0, 109, 219]/255, 'LineWidth', 2)
ylabel('Change in stopping probability')
set(gca,'FontSize',20)
saveas(gcf,'../output/appendixfigure10_psi.png')
hold off

plot(-10:10, psi_extra10wage(:, 1), 'color', [89, 38, 11]/255, 'LineWidth', 2)
hold on
plot(-10:10, nu_extra10wage(:, 1), ':', 'color', [219, 109, 0]/255, 'LineWidth', 4)
hold on
plot(-10:10, lambda_extra10wage(:, 1), '-.', 'color', [0, 77, 62]/255, 'LineWidth', 2)
hold on
plot(-10:10, theta_extra10wage(:, 1), '--', 'color', [0, 109, 219]/255, 'LineWidth', 2)
ylabel('Change in stopping probability')
set(gca,'FontSize',20)
saveas(gcf,'../output/appendixfigure10_nu.png')
hold off

plot(-10:10, psi_extra10inc(:, 1), 'color', [89, 38, 11]/255, 'LineWidth', 2)
hold on
plot(-10:10, nu_extra10inc(:, 1), ':', 'color', [219, 109, 0]/255, 'LineWidth', 2)
hold on
plot(-10:10, lambda_extra10inc(:, 1), '-.', 'color', [0, 77, 62]/255, 'LineWidth', 4)
hold on
plot(-10:10, theta_extra10inc(:, 1), '--', 'color', [0, 109, 219]/255, 'LineWidth', 2)
ylabel('Change in stopping probability')
set(gca,'FontSize',20)
saveas(gcf,'../output/appendixfigure10_lambda.png')
hold off

plot(-10:10, psi_8_5(:, 1), 'color', [89, 38, 11]/255, 'LineWidth', 2)
hold on
plot(-10:10, nu_8_5(:, 1), ':', 'color', [219, 109, 0]/255, 'LineWidth', 2)
hold on
plot(-10:10, lambda_8_5(:, 1), '-.', 'color', [0, 77, 62]/255, 'LineWidth', 2)
hold on
plot(-10:10, theta_8_5(:, 1), '--', 'color', [0, 109, 219]/255, 'LineWidth', 4)
ylabel('Ratio of stopping probabilities')
set(gca,'FontSize',20)
saveas(gcf,'../output/appendixfigure10_theta.png')
hold off

