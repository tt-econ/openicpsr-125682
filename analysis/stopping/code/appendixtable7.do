version 16
preliminaries, matsize(11000) maxvar(20000) loadglob(../temp/basefile.txt)

program main
    global time_controls "i.drf_hour#i.drf_dayofweek i.shift_date"
    global weather_controls "near_rain i.near_temp_c i.near_wind_c"
    global location_controls "i.drf_nta"
    global all_controls_except_id "$time_controls $weather_controls $location_controls"

    matrix appendixtable7 = J(14, 3, .)

    locationXindividual
    previous_day_income
    medallion_owners

    matrix_to_txt, matrix(appendixtable7) saving(../output/appendixtable7.txt) title(<tab:appendixtable7>) replace
end

program locationXindividual
    use ../output_local/taxi_8h30m.dta if cum_total_duration <= 8*60 + 40, clear
    append using ../output_local/taxi_8h.dta
    keep if cum_total_duration <= 8*60 + 40 & cum_total_duration >= 8*60 + 20

    gen locationXindividual = 1000 * driver_id + drf_nta

    areg final_trip cum_income cum_total_duration i.dis_ridebin* $time_controls $weather_controls, absorb(locationXindividual) vce(cluster driver_id)
    lincom _b[cum_income] * $baseincome8h30m / $base8h30m
    matrix appendixtable7[1, 1] = r(estimate)
    matrix appendixtable7[2, 1] = r(se)

    areg final_trip incomebin_1-incomebin_8 cum_income cum_total_duration i.dis_ridebin* $time_controls $weather_controls, absorb(locationXindividual) vce(cluster driver_id)
    forval j = 2(2)8 {
        lincom (_b[cum_income] + _b[incomebin_`j']) * $baseincome8h30m / $base8h30m
        matrix appendixtable7[3 + `j', 1] = r(estimate)
        matrix appendixtable7[4 + `j', 1] = r(se)

   }
end

program previous_day_income
    use ../input/taxi_shift.dta, clear
    foreach var in total_income total_hours work_hours ride_hours {
        gen previous_`var' = shift_`var'[_n-1]
    }
    save ../temp/taxi_shift_withprev.dta, replace

    use ../output_local/taxi_8h30m.dta, clear
    append using ../output_local/taxi_8h.dta
    keep if cum_total_duration >= 8*60 + 20 & cum_total_duration <= 8*60 + 40

    mmerge driver_id shift_id using ../temp/taxi_shift_withprev.dta, ///
        type(n:1) unmatched(master) ukeep(previous_*)

    xtile prev_hrs1 = previous_total_hours, n(10)
    xtile prev_hrs2 = previous_work_hours, n(10)
    xtile prev_hrs3 = previous_ride_hours, n(10)

    areg final_trip cum_income cum_total_duration previous_total_income i.prev_hrs* i.dis_ridebin* $all_controls_except_id, absorb(driver_id) vce(cluster driver_id)
    lincom _b[cum_income] * $baseincome8h30m / $base8h30m
    matrix appendixtable7[1, 2] = r(estimate)
    matrix appendixtable7[2, 2] = r(se)
    lincom (_b[previous_total_income]) * $baseincome8h30m / $base8h30m
    matrix appendixtable7[3, 2] = r(estimate)
    matrix appendixtable7[4, 2] = r(se)

    areg final_trip incomebin_1-incomebin_8 cum_income cum_total_duration previous_total_income i.prev_hrs* i.dis_ridebin* $all_controls_except_id, absorb(driver_id) vce(cluster driver_id)
    forval j = 2(2)8 {
        lincom (_b[cum_income] + _b[incomebin_`j']) * $baseincome8h30m / $base8h30m
        matrix appendixtable7[3 + `j', 2] = r(estimate)
        matrix appendixtable7[4 + `j', 2] = r(se)
   }

    lincom (_b[previous_total_income]) * $baseincome8h30m / $base8h30m
    matrix appendixtable7[13, 2] = r(estimate)
    matrix appendixtable7[14, 2] = r(se)
end

program medallion_owners
    use ../output_local/taxi_8h30m.dta if cum_total_duration <= 8*60 + 50, clear
    append using ../output_local/taxi_8h.dta
    keep if cum_total_duration <= 8*60 + 50 & cum_total_duration >= 8*60 + 10

    egen tag_driver = tag(driver_id)
    gen owner_driver = car_numdrivers==1
    sum owner_driver if tag_driver

    areg final_trip cum_income cum_total_duration i.dis_ridebin* $all_controls_except_id if owner_driver, absorb(driver_id) vce(cluster driver_id)
    lincom _b[cum_income] * $baseincome8h30m / $base8h30m
    matrix appendixtable7[1, 3] = r(estimate)
    matrix appendixtable7[2, 3] = r(se)

    areg final_trip incomebin_1-incomebin_8 cum_income cum_total_duration i.dis_ridebin* $all_controls_except_id if owner_driver, absorb(driver_id) vce(cluster driver_id)
    forval j = 2(2)8 {
        lincom (_b[cum_income] + _b[incomebin_`j']) * $baseincome8h30m / $base8h30m
        matrix appendixtable7[3 + `j', 3] = r(estimate)
        matrix appendixtable7[4 + `j', 3] = r(se)
   }
end

* Execute
main
