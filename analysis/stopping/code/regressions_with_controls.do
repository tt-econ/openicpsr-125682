version 16
preliminaries, matsize(11000) maxvar(20000) loadglob(../temp/basefile.txt)

program main
    global time_controls "i.drf_hour#i.drf_dayofweek i.shift_date"
    global weather_controls "near_rain i.near_temp_c i.near_wind_c"
    global location_controls "i.drf_nta"
    global all_controls_except_id "$time_controls $weather_controls $location_controls"

    matrix table1 = J(10, 4, .)
    matrix appendixtable5 = J(20, 4, .)

    use ../output_local/taxi_8h30m.dta, clear
    append using ../output_local/taxi_8h.dta
    keep if cum_total_duration >= 8*60 + 20 & cum_total_duration <= 8*60 + 40

    regressions table1 0 $baseincome8h30m $base8h30m

    preserve
    keep if shift_start >= 4 & shift_start < 10
    regressions appendixtable5 0 $baseincome8h30m_day $base8h30m_day
    restore

    keep if shift_start >= 14 & shift_start < 20
    regressions appendixtable5 10 $baseincome8h30m_night $base8h30m_night

    clear
    svmat double table1, names(col)
    save ../temp/table1.dta, replace
    clear
    svmat double appendixtable5, names(col)
    save ../temp/appendixtable5, replace
end

program regressions
    args matname rowshift inc base

    reg final_trip cum_income cum_total_duration i.dis_ridebin*, vce(cluster driver_id)
    lincom _b[cum_income] * `inc' / `base'
    matrix `matname'[1 + `rowshift', 1] = r(estimate)
    matrix `matname'[2 + `rowshift', 1] = r(se)
    areg final_trip cum_income cum_total_duration i.dis_ridebin*, absorb(driver_id) vce(cluster driver_id)
    lincom _b[cum_income] * `inc' / `base'
    matrix `matname'[3 + `rowshift', 1] = r(estimate)
    matrix `matname'[4 + `rowshift', 1] = r(se)
    areg final_trip cum_income cum_total_duration i.dis_ridebin* $time_controls, absorb(driver_id) vce(cluster driver_id)
    lincom _b[cum_income] * `inc' / `base'
    matrix `matname'[5 + `rowshift', 1] = r(estimate)
    matrix `matname'[6 + `rowshift', 1] = r(se)
    areg final_trip cum_income cum_total_duration i.dis_ridebin* $time_controls $location_controls, absorb(driver_id) vce(cluster driver_id)
    lincom _b[cum_income] * `inc' / `base'
    matrix `matname'[7 + `rowshift', 1] = r(estimate)
    matrix `matname'[8 + `rowshift', 1] = r(se)
    areg final_trip cum_income cum_total_duration i.dis_ridebin* $time_controls $location_controls $weather_controls, absorb(driver_id) vce(cluster driver_id)
    lincom _b[cum_income] * `inc' / `base'
    matrix `matname'[9 + `rowshift', 1] = r(estimate)
    matrix `matname'[10 + `rowshift', 1] = r(se)
end

* Execute
main
