version 16
preliminaries, matsize(11000) maxvar(20000) loadglob(../temp/basefile.txt)

program main
    global time_controls "i.drf_hour#i.drf_dayofweek i.shift_date"
    global weather_controls "near_rain i.near_temp_c i.near_wind_c"
    global location_controls "i.drf_nta"
    global all_controls_except_id "$time_controls $weather_controls $location_controls"

    use ../temp/table1.dta, clear
    mkmat c1 c2 c3 c4, matrix(table1)
    use ../temp/appendixtable5.dta, clear
    mkmat c1 c2 c3 c4, matrix(appendixtable5)

    use ../temp/twofifteenths.dta, clear

    sum ridebin_1, d
    keep if ridebin_1 < `r(p90)'
    sum ridebin_2, d
    keep if ridebin_2 > `r(p5)'

    Farber2015 table1 0 $baseincome8h30m $base8h30m
    FarberBoth table1 0 $baseincome8h30m $base8h30m
    Farber2005 table1 0 $baseincome8h30m $base8h30m

    preserve
    keep if shift_start >= 4 & shift_start < 10
    Farber2015 appendixtable5 0 $baseincome8h30m_day $base8h30m_day
    FarberBoth appendixtable5 0 $baseincome8h30m_day $base8h30m_day
    Farber2005 appendixtable5 0 $baseincome8h30m_day $base8h30m_day
    restore

    keep if shift_start >= 14 & shift_start < 20
    Farber2015 appendixtable5 10 $baseincome8h30m_night $base8h30m_night
    FarberBoth appendixtable5 10 $baseincome8h30m_night $base8h30m_night
    Farber2005 appendixtable5 10 $baseincome8h30m_night $base8h30m_night

    matrix_to_txt, matrix(table1) saving(../output/table1.txt) title(<tab:table1>) replace
    matrix_to_txt, matrix(appendixtable5) saving(../output/appendixtable5.txt) title(<tab:appendixtable5>) replace
end

program Farber2015
    args matname rowshift inc base

    reg final_trip 1.(HF_total_bin0)#1.(HF_income_bin1-HF_income_bin9) 1.(HF_total_bin1-HF_total_bin9)#1.(HF_income_bin0) 1.(HF_total_bin1-HF_total_bin9)#1.(HF_income_bin1-HF_income_bin9), cluster(driver_id)
    lincom (_b[1.HF_total_bin4#1.HF_income_bin6] - _b[1.HF_total_bin4#1.HF_income_bin5]) * `inc' / 25 * 1/`base'
    matrix `matname'[1 + `rowshift', 4] = r(estimate)
    matrix `matname'[2 + `rowshift', 4] = r(se)
    areg final_trip 1.(HF_total_bin0)#1.(HF_income_bin1-HF_income_bin9) 1.(HF_total_bin1-HF_total_bin9)#1.(HF_income_bin0) 1.(HF_total_bin1-HF_total_bin9)#1.(HF_income_bin1-HF_income_bin9), absorb(driver_id) cluster(driver_id)
    lincom (_b[1.HF_total_bin4#1.HF_income_bin6] - _b[1.HF_total_bin4#1.HF_income_bin5]) * `inc' / 25 * 1/`base'
    matrix `matname'[3 + `rowshift', 4] = r(estimate)
    matrix `matname'[4 + `rowshift', 4] = r(se)
    areg final_trip 1.(HF_total_bin0)#1.(HF_income_bin1-HF_income_bin9) 1.(HF_total_bin1-HF_total_bin9)#1.(HF_income_bin0) 1.(HF_total_bin1-HF_total_bin9)#1.(HF_income_bin1-HF_income_bin9) $time_controls, absorb(driver_id) cluster(driver_id)
    lincom (_b[1.HF_total_bin4#1.HF_income_bin6] - _b[1.HF_total_bin4#1.HF_income_bin5]) * `inc' / 25 * 1/`base'
    matrix `matname'[5 + `rowshift', 4] = r(estimate)
    matrix `matname'[6 + `rowshift', 4] = r(se)
    areg final_trip 1.(HF_total_bin0)#1.(HF_income_bin1-HF_income_bin9) 1.(HF_total_bin1-HF_total_bin9)#1.(HF_income_bin0) 1.(HF_total_bin1-HF_total_bin9)#1.(HF_income_bin1-HF_income_bin9) $time_controls $location_controls, absorb(driver_id) cluster(driver_id)
    lincom (_b[1.HF_total_bin4#1.HF_income_bin6] - _b[1.HF_total_bin4#1.HF_income_bin5]) * `inc' / 25 * 1/`base'
    matrix `matname'[7 + `rowshift', 4] = r(estimate)
    matrix `matname'[8 + `rowshift', 4] = r(se)
    areg final_trip 1.(HF_total_bin0)#1.(HF_income_bin1-HF_income_bin9) 1.(HF_total_bin1-HF_total_bin9)#1.(HF_income_bin0) 1.(HF_total_bin1-HF_total_bin9)#1.(HF_income_bin1-HF_income_bin9) $time_controls $location_controls $weather_controls, absorb(driver_id) cluster(driver_id)
    lincom (_b[1.HF_total_bin4#1.HF_income_bin6] - _b[1.HF_total_bin4#1.HF_income_bin5]) * `inc' / 25 * 1/`base'
    matrix `matname'[9 + `rowshift', 4] = r(estimate)
    matrix `matname'[10 + `rowshift', 4] = r(se)
end

program FarberBoth
    args matname rowshift inc base

    reg final_trip HF_income_bin1-HF_income_bin9 HF_total_bin1-HF_total_bin9, cluster(driver_id)
    lincom (_b[HF_income_bin6] - _b[HF_income_bin5]) * `inc' / 25 * 1/`base'
    matrix `matname'[1 + `rowshift', 3] = r(estimate)
    matrix `matname'[2 + `rowshift', 3] = r(se)
    areg final_trip HF_income_bin1-HF_income_bin9 HF_total_bin1-HF_total_bin9, absorb(driver_id) cluster(driver_id)
    lincom (_b[HF_income_bin6] - _b[HF_income_bin5]) * `inc' / 25 * 1/`base'
    matrix `matname'[3 + `rowshift', 3] = r(estimate)
    matrix `matname'[4 + `rowshift', 3] = r(se)
    areg final_trip HF_income_bin1-HF_income_bin9 HF_total_bin1-HF_total_bin9 $time_controls, absorb(driver_id) cluster(driver_id)
    lincom (_b[HF_income_bin6] - _b[HF_income_bin5]) * `inc' / 25 * 1/`base'
    matrix `matname'[5 + `rowshift', 3] = r(estimate)
    matrix `matname'[6 + `rowshift', 3] = r(se)
    areg final_trip HF_income_bin1-HF_income_bin9 HF_total_bin1-HF_total_bin9 $time_controls $location_controls, absorb(driver_id) cluster(driver_id)
    lincom (_b[HF_income_bin6] - _b[HF_income_bin5]) * `inc' / 25 * 1/`base'
    matrix `matname'[7 + `rowshift', 3] = r(estimate)
    matrix `matname'[8 + `rowshift', 3] = r(se)
    areg final_trip HF_income_bin1-HF_income_bin9 HF_total_bin1-HF_total_bin9 $time_controls $location_controls $weather_controls, absorb(driver_id) cluster(driver_id)
    lincom (_b[HF_income_bin6] - _b[HF_income_bin5]) * `inc' / 25 * 1/`base'
    matrix `matname'[9 + `rowshift', 3] = r(estimate)
    matrix `matname'[10 + `rowshift', 3] = r(se)
end

program Farber2005
    args matname rowshift inc base

    reg final_trip cum_income cum_total_duration cum_work_duration cum_ride_duration, cluster(driver_id)
    lincom _b[cum_income] * `inc' / `base'
    matrix `matname'[1 + `rowshift', 2] = r(estimate)
    matrix `matname'[2 + `rowshift', 2] = r(se)
    areg final_trip cum_income cum_total_duration cum_work_duration cum_ride_duration, absorb(driver_id) cluster(driver_id)
    lincom _b[cum_income] * `inc' / `base'
    matrix `matname'[3 + `rowshift', 2] = r(estimate)
    matrix `matname'[4 + `rowshift', 2] = r(se)
    areg final_trip cum_income cum_total_duration cum_work_duration cum_ride_duration $time_controls, absorb(driver_id) cluster(driver_id)
    lincom _b[cum_income] * `inc' / `base'
    matrix `matname'[5 + `rowshift', 2] = r(estimate)
    matrix `matname'[6 + `rowshift', 2] = r(se)
    areg final_trip cum_income cum_total_duration cum_work_duration cum_ride_duration $time_controls $location_controls, absorb(driver_id) cluster(driver_id)
    lincom _b[cum_income] * `inc' / `base'
    matrix `matname'[7 + `rowshift', 2] = r(estimate)
    matrix `matname'[8 + `rowshift', 2] = r(se)
    areg final_trip cum_income cum_total_duration cum_work_duration cum_ride_duration $time_controls $location_controls $weather_controls, absorb(driver_id) cluster(driver_id)
    lincom _b[cum_income] * `inc' / `base'
    matrix `matname'[9 + `rowshift', 2] = r(estimate)
    matrix `matname'[10 + `rowshift', 2] = r(se)
end

* Execute
main
