version 16
preliminaries, matsize(11000) maxvar(20000)

program main
    global time_controls "i.drf_hour#i.drf_dayofweek i.shift_date"
    global weather_controls "near_rain i.near_temp_c i.near_wind_c"
    global location_controls "i.drf_nta"
    global all_controls_except_id "$time_controls $weather_controls $location_controls"

    use driver_id shift_id trip_id cum_total_duration work_duration_m15 work_duration_p15 using ../input/taxi.dta if cum_total_duration <= 8*60+40, clear
    bysort driver_id shift_id (trip_id): gen cum_work_duration_m15 = sum(work_duration_m15)
    bysort driver_id shift_id (trip_id): gen cum_work_duration_p15 = sum(work_duration_p15)
    keep if cum_total_duration >= 8*60 + 20
    save ../temp/breaks_8h30m.dta, replace

    use ../output_local/taxi_8h30m.dta if cum_total_duration <= 8*60 + 40, clear
    append using ../output_local/taxi_8h.dta
    keep if cum_total_duration <= 8*60 + 40 & cum_total_duration >= 8*60 + 20

    mmerge driver_id shift_id trip_id using ../temp/breaks_8h30m.dta, ukeep(cum_work_duration*) type(1:1) unmatched(master)
    gen cum_break_duration = cum_total_duration - cum_work_duration
    gen cum_break_duration_m15 = cum_total_duration - cum_work_duration_m15
    gen cum_break_duration_p15 = cum_total_duration - cum_work_duration_p15

    areg final_trip incomebin_1-incomebin_8 cum_income cum_total_duration i.dis_ridebin* $all_controls_except_id, absorb(driver_id) vce(cluster driver_id)
    estimates save ../output_local/breaks_8h30m_1, replace
    areg final_trip incomebin_1-incomebin_8 cum_income cum_break_duration_m15 cum_total_duration i.dis_ridebin* $all_controls_except_id, absorb(driver_id) vce(cluster driver_id)
    estimates save ../output_local/breaks_8h30m_2, replace
    areg final_trip incomebin_1-incomebin_8 cum_income cum_break_duration cum_total_duration i.dis_ridebin* $all_controls_except_id, absorb(driver_id) vce(cluster driver_id)
    estimates save ../output_local/breaks_8h30m_3, replace
    areg final_trip incomebin_1-incomebin_8 cum_income cum_break_duration_p15 cum_total_duration i.dis_ridebin* $all_controls_except_id, absorb(driver_id) vce(cluster driver_id)
    estimates save ../output_local/breaks_8h30m_4, replace

end

* Execute
main
