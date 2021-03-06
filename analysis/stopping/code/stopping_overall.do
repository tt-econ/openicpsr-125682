version 16
preliminaries, matsize(11000) maxvar(20000)

program main
    global time_controls "i.drf_hour#i.drf_dayofweek i.shift_date"
    global weather_controls "near_rain i.near_temp_c i.near_wind_c"
    global location_controls "i.drf_nta"
    global all_controls_except_id "$time_controls $weather_controls $location_controls"

    forval i = 5 / 10 {
        local j = `i' - 1
        use ../output_local/taxi_`i'h.dta if cum_total_duration <= `i'*60+10, clear
        append using ../output_local/taxi_`j'h30m.dta
        keep if cum_total_duration <= `i'*60 + 10 & cum_total_duration >= `i'*60 - 10

        areg final_trip cum_income cum_total_duration i.dis_ridebin* $all_controls_except_id, absorb(driver_id) vce(cluster driver_id)
        estimates save ../output_local/overall_`i'h, replace
    }

    forval i = 5 / 10 {
        local j = `i' - 1
        use ../output_local/taxi_`i'h.dta if cum_total_duration <= `i'*60+25, clear
        keep if cum_total_duration <= `i'*60 + 25 & cum_total_duration >= `i'*60 + 5

        areg final_trip cum_income cum_total_duration i.dis_ridebin* $all_controls_except_id, absorb(driver_id) vce(cluster driver_id)
        estimates save ../output_local/overall_`i'h15m, replace
    }

    forval i = 5 / 10 {
        use ../output_local/taxi_`i'h30m.dta if cum_total_duration <= `i'*60+40, clear
        append using ../output_local/taxi_`i'h.dta
        keep if cum_total_duration <= `i'*60 + 40 & cum_total_duration >= `i'*60 + 20

        areg final_trip cum_income cum_total_duration i.dis_ridebin* $all_controls_except_id, absorb(driver_id) vce(cluster driver_id)
        estimates save ../output_local/overall_`i'h30m, replace
    }

    forval i = 5 / 10 {
        use ../output_local/taxi_`i'h30m.dta if cum_total_duration <= `i'*60+55, clear
        keep if cum_total_duration <= `i'*60 + 55 & cum_total_duration >= `i'*60 + 35

        areg final_trip cum_income cum_total_duration i.dis_ridebin* $all_controls_except_id, absorb(driver_id) vce(cluster driver_id)
        estimates save ../output_local/overall_`i'h45m, replace
    }

end

* Execute
main
