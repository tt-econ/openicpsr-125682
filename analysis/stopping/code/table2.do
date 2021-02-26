version 16
preliminaries, matsize(11000) maxvar(20000) loadglob(../temp/basefile.txt)

program main
    global time_controls "i.drf_hour#i.drf_dayofweek i.shift_date"
    global weather_controls "near_rain i.near_temp_c i.near_wind_c"
    global location_controls "i.drf_nta"
    global all_controls_except_id "$time_controls $weather_controls $location_controls"

    matrix table2 = J(16, 5, .)

    use ../output_local/taxi_8h30m.dta, clear
    append using ../output_local/taxi_8h.dta
    keep if cum_total_duration >= 8*60 + 20 & cum_total_duration <= 8*60 + 40

    regressions table2 $baseincome8h30m $base8h30m

    matrix_to_txt, matrix(table2) saving(../output/table2.txt) title(<tab:table2>) replace
end

program regressions
    args matname inc base

    reg final_trip incomebin_1-incomebin_8 cum_income cum_total_duration i.dis_ridebin*, vce(cluster driver_id)
    lincom (_b[incomebin_1] + _b[cum_income]) * `inc' / `base'
    matrix `matname'[1, 1] = r(estimate)
    matrix `matname'[2, 1] = r(se)
    lincom (_b[incomebin_2] + _b[cum_income]) * `inc' / `base'
    matrix `matname'[3, 1] = r(estimate)
    matrix `matname'[4, 1] = r(se)
    lincom (_b[incomebin_3] + _b[cum_income]) * `inc' / `base'
    matrix `matname'[5, 1] = r(estimate)
    matrix `matname'[6, 1] = r(se)
    lincom (_b[incomebin_4] + _b[cum_income]) * `inc' / `base'
    matrix `matname'[7, 1] = r(estimate)
    matrix `matname'[8, 1] = r(se)
    lincom (_b[incomebin_5] + _b[cum_income]) * `inc' / `base'
    matrix `matname'[9, 1] = r(estimate)
    matrix `matname'[10, 1] = r(se)
    lincom (_b[incomebin_6] + _b[cum_income]) * `inc' / `base'
    matrix `matname'[11, 1] = r(estimate)
    matrix `matname'[12, 1] = r(se)
    lincom (_b[incomebin_7] + _b[cum_income]) * `inc' / `base'
    matrix `matname'[13, 1] = r(estimate)
    matrix `matname'[14, 1] = r(se)
    lincom (_b[incomebin_8] + _b[cum_income]) * `inc' / `base'
    matrix `matname'[15, 1] = r(estimate)
    matrix `matname'[16, 1] = r(se)

    areg final_trip incomebin_1-incomebin_8 cum_income cum_total_duration i.dis_ridebin*, absorb(driver_id) vce(cluster driver_id)
    lincom (_b[incomebin_1] + _b[cum_income]) * `inc' / `base'
    matrix `matname'[1, 2] = r(estimate)
    matrix `matname'[2, 2] = r(se)
    lincom (_b[incomebin_2] + _b[cum_income]) * `inc' / `base'
    matrix `matname'[3, 2] = r(estimate)
    matrix `matname'[4, 2] = r(se)
    lincom (_b[incomebin_3] + _b[cum_income]) * `inc' / `base'
    matrix `matname'[5, 2] = r(estimate)
    matrix `matname'[6, 2] = r(se)
    lincom (_b[incomebin_4] + _b[cum_income]) * `inc' / `base'
    matrix `matname'[7, 2] = r(estimate)
    matrix `matname'[8, 2] = r(se)
    lincom (_b[incomebin_5] + _b[cum_income]) * `inc' / `base'
    matrix `matname'[9, 2] = r(estimate)
    matrix `matname'[10, 2] = r(se)
    lincom (_b[incomebin_6] + _b[cum_income]) * `inc' / `base'
    matrix `matname'[11, 2] = r(estimate)
    matrix `matname'[12, 2] = r(se)
    lincom (_b[incomebin_7] + _b[cum_income]) * `inc' / `base'
    matrix `matname'[13, 2] = r(estimate)
    matrix `matname'[14, 2] = r(se)
    lincom (_b[incomebin_8] + _b[cum_income]) * `inc' / `base'
    matrix `matname'[15, 2] = r(estimate)
    matrix `matname'[16, 2] = r(se)

    areg final_trip incomebin_1-incomebin_8 cum_income cum_total_duration i.dis_ridebin* $time_controls, absorb(driver_id) vce(cluster driver_id)
    lincom (_b[incomebin_1] + _b[cum_income]) * `inc' / `base'
    matrix `matname'[1, 3] = r(estimate)
    matrix `matname'[2, 3] = r(se)
    lincom (_b[incomebin_2] + _b[cum_income]) * `inc' / `base'
    matrix `matname'[3, 3] = r(estimate)
    matrix `matname'[4, 3] = r(se)
    lincom (_b[incomebin_3] + _b[cum_income]) * `inc' / `base'
    matrix `matname'[5, 3] = r(estimate)
    matrix `matname'[6, 3] = r(se)
    lincom (_b[incomebin_4] + _b[cum_income]) * `inc' / `base'
    matrix `matname'[7, 3] = r(estimate)
    matrix `matname'[8, 3] = r(se)
    lincom (_b[incomebin_5] + _b[cum_income]) * `inc' / `base'
    matrix `matname'[9, 3] = r(estimate)
    matrix `matname'[10, 3] = r(se)
    lincom (_b[incomebin_6] + _b[cum_income]) * `inc' / `base'
    matrix `matname'[11, 3] = r(estimate)
    matrix `matname'[12, 3] = r(se)
    lincom (_b[incomebin_7] + _b[cum_income]) * `inc' / `base'
    matrix `matname'[13, 3] = r(estimate)
    matrix `matname'[14, 3] = r(se)
    lincom (_b[incomebin_8] + _b[cum_income]) * `inc' / `base'
    matrix `matname'[15, 3] = r(estimate)
    matrix `matname'[16, 3] = r(se)

    areg final_trip incomebin_1-incomebin_8 cum_income cum_total_duration i.dis_ridebin* $time_controls $location_controls, absorb(driver_id) vce(cluster driver_id)
    lincom (_b[incomebin_1] + _b[cum_income]) * `inc' / `base'
    matrix `matname'[1, 4] = r(estimate)
    matrix `matname'[2, 4] = r(se)
    lincom (_b[incomebin_2] + _b[cum_income]) * `inc' / `base'
    matrix `matname'[3, 4] = r(estimate)
    matrix `matname'[4, 4] = r(se)
    lincom (_b[incomebin_3] + _b[cum_income]) * `inc' / `base'
    matrix `matname'[5, 4] = r(estimate)
    matrix `matname'[6, 4] = r(se)
    lincom (_b[incomebin_4] + _b[cum_income]) * `inc' / `base'
    matrix `matname'[7, 4] = r(estimate)
    matrix `matname'[8, 4] = r(se)
    lincom (_b[incomebin_5] + _b[cum_income]) * `inc' / `base'
    matrix `matname'[9, 4] = r(estimate)
    matrix `matname'[10, 4] = r(se)
    lincom (_b[incomebin_6] + _b[cum_income]) * `inc' / `base'
    matrix `matname'[11, 4] = r(estimate)
    matrix `matname'[12, 4] = r(se)
    lincom (_b[incomebin_7] + _b[cum_income]) * `inc' / `base'
    matrix `matname'[13, 4] = r(estimate)
    matrix `matname'[14, 4] = r(se)
    lincom (_b[incomebin_8] + _b[cum_income]) * `inc' / `base'
    matrix `matname'[15, 4] = r(estimate)
    matrix `matname'[16, 4] = r(se)

    areg final_trip incomebin_1-incomebin_8 cum_income cum_total_duration i.dis_ridebin* $time_controls $location_controls $weather_controls, absorb(driver_id) vce(cluster driver_id)
    lincom (_b[incomebin_1] + _b[cum_income]) * `inc' / `base'
    matrix `matname'[1, 5] = r(estimate)
    matrix `matname'[2, 5] = r(se)
    lincom (_b[incomebin_2] + _b[cum_income]) * `inc' / `base'
    matrix `matname'[3, 5] = r(estimate)
    matrix `matname'[4, 5] = r(se)
    lincom (_b[incomebin_3] + _b[cum_income]) * `inc' / `base'
    matrix `matname'[5, 5] = r(estimate)
    matrix `matname'[6, 5] = r(se)
    lincom (_b[incomebin_4] + _b[cum_income]) * `inc' / `base'
    matrix `matname'[7, 5] = r(estimate)
    matrix `matname'[8, 5] = r(se)
    lincom (_b[incomebin_5] + _b[cum_income]) * `inc' / `base'
    matrix `matname'[9, 5] = r(estimate)
    matrix `matname'[10, 5] = r(se)
    lincom (_b[incomebin_6] + _b[cum_income]) * `inc' / `base'
    matrix `matname'[11, 5] = r(estimate)
    matrix `matname'[12, 5] = r(se)
    lincom (_b[incomebin_7] + _b[cum_income]) * `inc' / `base'
    matrix `matname'[13, 5] = r(estimate)
    matrix `matname'[14, 5] = r(se)
    lincom (_b[incomebin_8] + _b[cum_income]) * `inc' / `base'
    matrix `matname'[15, 5] = r(estimate)
    matrix `matname'[16, 5] = r(se)
end

* Execute
main
