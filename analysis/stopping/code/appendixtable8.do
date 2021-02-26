version 16
preliminaries, matsize(11000) maxvar(20000) loadglob(../temp/basefile.txt)

program main
    global time_controls "i.drf_hour#i.drf_dayofweek i.shift_date"
    global weather_controls "near_rain i.near_temp_c i.near_wind_c"
    global location_controls "i.drf_nta"
    global all_controls_except_id "$time_controls $weather_controls $location_controls"

    matrix appendixtable8 = J(16, 3, .)

    use ../temp/twofifteenths.dta, clear

    Farber2015 "appendixtable8" $baseincome8h30m $base8h30m
    FarberBoth "appendixtable8" $baseincome8h30m $base8h30m
    Farber2005 "appendixtable8" $baseincome8h30m $base8h30m

    matrix_to_txt, matrix(appendixtable8) saving(../output/appendixtable8.txt) title(<tab:appendixtable8>) replace
end

program Farber2015
    args matname inc base

    areg final_trip incomebin_* 1.(HF_total_bin0)#1.(HF_income_bin1-HF_income_bin9) 1.(HF_total_bin1-HF_total_bin9)#1.(HF_income_bin0) 1.(HF_total_bin1-HF_total_bin9)#1.(HF_income_bin1-HF_income_bin9) $time_controls $location_controls $weather_controls, absorb(driver_id) cluster(driver_id)

    lincom _b[incomebin_1] * `inc' / `base'
    matrix `matname'[1, 3] = r(estimate)
    matrix `matname'[2, 3] = r(se)

    lincom _b[incomebin_2] * `inc' / `base'
    matrix `matname'[3, 3] = r(estimate)
    matrix `matname'[4, 3] = r(se)

    lincom _b[incomebin_3] * `inc' / `base'
    matrix `matname'[5, 3] = r(estimate)
    matrix `matname'[6, 3] = r(se)

    lincom _b[incomebin_4] * `inc' / `base'
    matrix `matname'[7, 3] = r(estimate)
    matrix `matname'[8, 3] = r(se)

    lincom _b[incomebin_5] * `inc' / `base'
    matrix `matname'[9, 3] = r(estimate)
    matrix `matname'[10, 3] = r(se)

    lincom _b[incomebin_6] * `inc' / `base'
    matrix `matname'[11, 3] = r(estimate)
    matrix `matname'[12, 3] = r(se)

    lincom _b[incomebin_7] * `inc' / `base'
    matrix `matname'[13, 3] = r(estimate)
    matrix `matname'[14, 3] = r(se)

    lincom _b[incomebin_8] * `inc' / `base'
    matrix `matname'[15, 3] = r(estimate)
    matrix `matname'[16, 3] = r(se)

end

program FarberBoth
    args matname inc base

    areg final_trip incomebin_* HF_income_bin1-HF_income_bin9 HF_total_bin1-HF_total_bin9 $time_controls $location_controls $weather_controls, absorb(driver_id) cluster(driver_id)

    lincom _b[incomebin_1] * `inc' / `base'
    matrix `matname'[1, 2] = r(estimate)
    matrix `matname'[2, 2] = r(se)

    lincom _b[incomebin_2] * `inc' / `base'
    matrix `matname'[3, 2] = r(estimate)
    matrix `matname'[4, 2] = r(se)

    lincom _b[incomebin_3] * `inc' / `base'
    matrix `matname'[5, 2] = r(estimate)
    matrix `matname'[6, 2] = r(se)

    lincom _b[incomebin_4] * `inc' / `base'
    matrix `matname'[7, 2] = r(estimate)
    matrix `matname'[8, 2] = r(se)

    lincom _b[incomebin_5] * `inc' / `base'
    matrix `matname'[9, 2] = r(estimate)
    matrix `matname'[10, 2] = r(se)

    lincom _b[incomebin_6] * `inc' / `base'
    matrix `matname'[11, 2] = r(estimate)
    matrix `matname'[12, 2] = r(se)

    lincom _b[incomebin_7] * `inc' / `base'
    matrix `matname'[13, 2] = r(estimate)
    matrix `matname'[14, 2] = r(se)

    lincom _b[incomebin_8] * `inc' / `base'
    matrix `matname'[15, 2] = r(estimate)
    matrix `matname'[16, 2] = r(se)

end

program Farber2005
    args matname inc base

    areg final_trip incomebin_* cum_total_duration cum_work_duration cum_ride_duration $time_controls $location_controls $weather_controls, absorb(driver_id) cluster(driver_id)

    lincom _b[incomebin_1] * `inc' / `base'
    matrix `matname'[1, 1] = r(estimate)
    matrix `matname'[2, 1] = r(se)

    lincom _b[incomebin_2] * `inc' / `base'
    matrix `matname'[3, 1] = r(estimate)
    matrix `matname'[4, 1] = r(se)

    lincom _b[incomebin_3] * `inc' / `base'
    matrix `matname'[5, 1] = r(estimate)
    matrix `matname'[6, 1] = r(se)

    lincom _b[incomebin_4] * `inc' / `base'
    matrix `matname'[7, 1] = r(estimate)
    matrix `matname'[8, 1] = r(se)

    lincom _b[incomebin_5] * `inc' / `base'
    matrix `matname'[9, 1] = r(estimate)
    matrix `matname'[10, 1] = r(se)

    lincom _b[incomebin_6] * `inc' / `base'
    matrix `matname'[11, 1] = r(estimate)
    matrix `matname'[12, 1] = r(se)

    lincom _b[incomebin_7] * `inc' / `base'
    matrix `matname'[13, 1] = r(estimate)
    matrix `matname'[14, 1] = r(se)

    lincom _b[incomebin_8] * `inc' / `base'
    matrix `matname'[15, 1] = r(estimate)
    matrix `matname'[16, 1] = r(se)

end

* Execute
main
