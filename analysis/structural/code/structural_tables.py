#! /usr/bin/env python
import glob
import os
import numpy as np
import pandas as pd


def update_res(res, modelcol, log_path, temp_path, file_pattern):
    path = os.path.join(log_path, file_pattern)
    files = glob.glob(path)
    num_sample = 0
    for file in files:
        with open(file) as f:
            block = ""
            found = False

            for line in f:
                if found:
                    if any(char.isdigit() for char in line):
                        line = line.replace("NUMBER OF OBS:", "numobs")
                        block += line
                        if line.strip()[:8] == "constant":
                            break
                else:
                    if line.strip()[:15] == "LOG LIKELIHOOD:":
                        found = True
                        num_sample += 1
                        block = line.replace(
                            "LOG LIKELIHOOD:", "loglikelihood")
                    else:
                        found = False

            if found:
                output_file = open(os.path.join(
                    temp_path, os.path.basename(file)), "w+")
                output_file.write(block)
                output_file.close()

    path = os.path.join(temp_path, file_pattern)
    files = glob.glob(path)
    numfile = 0
    for file in files:
        numfile += 1
        if (numfile == 1):
            df = pd.read_table(os.path.join(temp_path, file),
                               header=None, names=['model', 1], sep='\s+')
        else:
            df_next = pd.read_table(os.path.join(
                temp_path, file), header=None, names=['model', numfile], sep='\s+')
            df = df.merge(df_next, how='outer')

    df = df.transpose()
    new_header = df.iloc[0]  # grab the first row for the header
    df = df[1:]  # take the data less the header row
    df.columns = new_header  # set the header row as the df header
    df = df.apply(pd.to_numeric)
    df = df[df.lnsigma < -.3]

    coefs = df.mean(axis=0)
    coefs = coefs.iloc[2:]
    sd = df.std(axis=0)
    sd = sd.iloc[2:]

    if 'I_psi_ctd6_coeff' in df:
        df['psi'] = np.exp(df['lnpsi'] + df['I_psi_ctd6_coeff'])
    else:
        df['psi'] = np.exp(df['lnpsi'])
    df['nu'] = np.exp(df['transformed_nu'])-1
    df['sigma'] = np.exp(df['lnsigma'])
    if 'lngl' in df:
        df['gl'] = np.exp(df['lngl'])
    if 'lngl1' in df:
        df['gl1'] = np.exp(df['lngl1'])
    if 'lngl2' in df:
        df['gl2'] = np.exp(df['lngl2'])
    if 'lnsd' in df:
        df['sd'] = np.exp(df['lnsd'])

    res.at['psi', modelcol] = df.mean(axis=0)['psi']
    res.at['psi_sd', modelcol] = df.std(axis=0)['psi']
    res.at['nu', modelcol] = df.mean(axis=0)['nu']
    res.at['nu_sd', modelcol] = df.std(axis=0)['nu']
    res.at['sigma', modelcol] = df.mean(axis=0)['sigma']
    res.at['sigma_sd', modelcol] = df.std(axis=0)['sigma']
    res.at['loglikelihood', modelcol] = - df.mean(axis=0)['loglikelihood']

    if ('gl' in df) and (df.max(axis=0)['gl'] != df.min(axis=0)['gl']):
        res.at['gl', modelcol] = df.mean(axis=0)['gl']
        res.at['gl_sd', modelcol] = df.std(axis=0)['gl']

    if ('gl1' in df) and (df.max(axis=0)['gl1'] != df.min(axis=0)['gl1']):
        res.at['gl1', modelcol] = df.mean(axis=0)['gl1']
        res.at['gl1_sd', modelcol] = df.std(axis=0)['gl1']

    if ('gl2' in df) and (df.max(axis=0)['gl2'] != df.min(axis=0)['gl2']):
        res.at['gl2', modelcol] = df.mean(axis=0)['gl2']
        res.at['gl2_sd', modelcol] = df.std(axis=0)['gl2']

    if ('theta' in df) and (df.max(axis=0)['theta'] != df.min(axis=0)['theta']):
        res.at['theta', modelcol] = df.mean(axis=0)['theta']
        res.at['theta_sd', modelcol] = df.std(axis=0)['theta']

    if ('sd' in df) and (df.max(axis=0)['sd'] != df.min(axis=0)['sd']):
        res.at['sd', modelcol] = df.mean(axis=0)['sd']
        res.at['sd_sd', modelcol] = df.std(axis=0)['sd']

    return res, coefs, sd


log_path = '../log'
temp_path = '../temp'

res = pd.DataFrame(index=['psi', 'psi_sd', 'nu', 'nu_sd', 'gl', 'gl_sd',
                          'theta', 'theta_sd', 'sigma', 'sigma_sd',
                          'loglikelihood'],
                   columns=['m1', 'm2', 'm3'])
res, _, _ = update_res(res, 'm1', log_path, temp_path, 'run_noRP*.log')
res, _, _ = update_res(res, 'm2', log_path, temp_path, 'run_staticRP*.log')
res, coefs, sd = update_res(res, 'm3', log_path, temp_path, 'run_adaptiveRP*.log')
coefs.to_csv('../output/adaptiveRP.csv', header=False)
sd.to_csv('../output/adaptiveRP_sd.csv', header=False)

np.savetxt('../output/table3.txt', res.fillna(''), fmt='%s',
           header='<tab:table3>', delimiter='\t', comments='')

res = pd.DataFrame(index=['psi', 'psi_sd', 'nu', 'nu_sd', 'gl', 'gl_sd',
                          'theta', 'theta_sd',
                          'sd', 'sd_sd',
                          'sigma', 'sigma_sd',
                          'loglikelihood'],
                   columns=['m1', 'm2', 'm3', 'm4', 'm5'])
res, _, _ = update_res(res, 'm1', log_path, temp_path, 'run_fixedRP*.log')
res, _, _ = update_res(res, 'm2', log_path, temp_path, 'run_tripRP*.log')
res, _, _ = update_res(res, 'm3', log_path, temp_path, 'run_dualRP*.log')
res, _, _ = update_res(res, 'm4', log_path, temp_path, 'run_curvatureRP*.log')
res, _, _ = update_res(res, 'm5', log_path, temp_path, 'run_stochRP*.log')

np.savetxt('../output/table4.txt', res.fillna(''), fmt='%s',
           header='<tab:table4>', delimiter='\t', comments='')

res = pd.DataFrame(index=['psi', 'psi_sd', 'nu', 'nu_sd', 'gl', 'gl_sd',
                          'sigma', 'sigma_sd',
                          'loglikelihood'],
                   columns=['m1', 'm2', 'm3', 'm4'])
res, _, _ = update_res(res, 'm1', log_path, temp_path, 'run_fixedRP*.log')
res, _, _ = update_res(res, 'm2', log_path, temp_path, 'run_staticRP*.log')
res, coefs, _ = update_res(res, 'm3', log_path, temp_path, 'run_hourRP*.log')
coefs.to_csv('../output/hourRP.csv', header=False)
res, coefs, _ = update_res(res, 'm4', log_path, temp_path, 'run_tripRP*.log')
coefs.to_csv('../output/tripRP.csv', header=False)

np.savetxt('../output/appendixtable13.txt', res.fillna(''), fmt='%s',
           header='<tab:appendixtable13>', delimiter='\t', comments='')

res = pd.DataFrame(index=['psi', 'psi_sd', 'nu', 'nu_sd',
                          'gl', 'gl_sd',
                          'gl1', 'gl1_sd',
                          'gl2', 'gl2_sd',
                          'theta', 'theta_sd',
                          'sigma', 'sigma_sd',
                          'loglikelihood'],
                   columns=['m1', 'm2'])
res, _, _ = update_res(res, 'm1', log_path, temp_path, 'run_dualRP*.log')
res, _, _ = update_res(res, 'm2', log_path, temp_path, 'run_separateRP*.log')
res.at['gl1', 'm1'] = res.at['gl', 'm1']
res.at['gl2', 'm1'] = res.at['gl', 'm1']
res.at['gl1_sd', 'm1'] = res.at['gl_sd', 'm1']
res.at['gl2_sd', 'm1'] = res.at['gl_sd', 'm1']
res = res.drop(index=['gl', 'gl_sd'])

np.savetxt('../output/appendixtable14.txt', res.fillna(''), fmt='%s',
           header='<tab:appendixtable14>', delimiter='\t', comments='')


