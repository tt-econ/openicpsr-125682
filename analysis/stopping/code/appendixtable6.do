version 16
preliminaries, matsize(11000) maxvar(20000)

program main
    global time_controls "i.drf_hour#i.drf_dayofweek i.shift_date"
    global weather_controls "near_rain i.near_temp_c i.near_wind_c"
    global location_controls "i.drf_nta"
    global all_controls_except_id "$time_controls $weather_controls $location_controls"

    matrix appendixtable6 = J(10, 4, .)

    use ../input/taxi_shift.dta, clear
    egen var_shift_total_hours = sd(shift_total_hours), by(driver_id)
    save ../temp/taxi_shift_withvar.dta, replace

    use ../output_local/taxi_8h30m.dta, clear
    append using ../output_local/taxi_8h.dta
    keep if cum_total_duration >= 8*60 + 20 & cum_total_duration <= 8*60 + 40
    mmerge driver_id shift_id using ../temp/taxi_shift_withvar.dta, ///
        type(n:1) unmatched(master) ukeep(var_shift_total_hours)

    bysort driver_id (shift_id trip_id): gen tag_driver = (_n == 1)
    sum var_shift_total_hours if tag_driver, d
    egen p10 = pctile(var_shift_total_hours), p(10)
    egen p25 = pctile(var_shift_total_hours), p(25)
    egen p75 = pctile(var_shift_total_hours), p(75)
    egen p90 = pctile(var_shift_total_hours), p(90)

    run_regressions 1 "if var_shift_total_hours <= p10 & var_shift_total_hours != ."
    run_regressions 2 "if var_shift_total_hours <= p25 & var_shift_total_hours != ."
    run_regressions 3 "if var_shift_total_hours > p75 & var_shift_total_hours != ."
    run_regressions 4 "if var_shift_total_hours > p90 & var_shift_total_hours != ."

    matrix_to_txt, matrix(appendixtable6) saving(../output/appendixtable6.txt) title(<tab:appendixtable6>) replace
end

program run_regressions
    args column cond

    sum final_trip `cond'
    local base = r(mean)
    sum cum_income `cond'
    local inc = r(mean)

    areg final_trip cum_income cum_total_duration i.dis_ridebin* $all_controls_except_id `cond', absorb(driver_id) vce(cluster driver_id)
    lincom _b[cum_income] * `inc' / `base'
    matrix appendixtable6[1, `column'] = r(estimate)
    matrix appendixtable6[2, `column'] = r(se)

    areg final_trip incomebin_1-incomebin_8 cum_income cum_total_duration i.dis_ridebin* $time_controls $location_controls $weather_controls `cond', absorb(driver_id) vce(cluster driver_id)
    lincom (_b[incomebin_2] + _b[cum_income]) * `inc' / `base'
    matrix appendixtable6[3, `column'] = r(estimate)
    matrix appendixtable6[4, `column'] = r(se)
    lincom (_b[incomebin_4] + _b[cum_income]) * `inc' / `base'
    matrix appendixtable6[5, `column'] = r(estimate)
    matrix appendixtable6[6, `column'] = r(se)
    lincom (_b[incomebin_6] + _b[cum_income]) * `inc' / `base'
    matrix appendixtable6[7, `column'] = r(estimate)
    matrix appendixtable6[8, `column'] = r(se)
    lincom (_b[incomebin_8] + _b[cum_income]) * `inc' / `base'
    matrix appendixtable6[9, `column'] = r(estimate)
    matrix appendixtable6[10, `column'] = r(se)

end

* Execute
main
