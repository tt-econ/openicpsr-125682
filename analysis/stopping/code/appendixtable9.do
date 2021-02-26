version 16
preliminaries, matsize(11000) maxvar(20000) loadglob(../temp/basefile.txt)

program main
    matrix appendixtable9 = J(8, 2, .)

    use driver_id shift_id trip_id pkp_date pkp_hour pkp_minute pkp_nta drf_nta ride_duration cum_total_duration using ../input/taxi.dta if cum_total_duration <= 8*60 + 40
    save ../temp/pickupvars_before8h40m.dta, replace
    use ../input/ridebins.dta if cum_total_duration <= 8*60+40, clear
    rename cum_total_duration cum_total_duration0
    mmerge driver_id shift_id trip_id using ../input/taxi_last12_min60.dta, type(1:1) unmatched(master)
    drop cum_total_duration incomebin*
    rename cum_total_duration0 cum_total_duration
    mmerge driver_id shift_id trip_id using ../input/incomebins.dta, type(1:1) unmatched(master) ukeep(incomebin*)
    save ../temp/taxi_before8h40m.dta, replace

    use ../temp/taxi_before8h40m.dta, clear
    mmerge driver_id shift_id trip_id using ../temp/pickupvars_before8h40m.dta, type(1:1) unmatched(master)
    gen hour_in_shift = ceil((cum_total_duration - total_duration) / 60)

    gen pkp_minute_coarse = floor(pkp_minute/10)

    bysort pkp_date pkp_hour pkp_minute_coarse pkp_nta drf_boro: egen sum_others_dist = total(distance)
    replace sum_others_dist = sum_others_dist - distance
    bysort driver_id shift_id hour_in_shift: egen sum_others_dist_hour = total(sum_others_dist)

    bysort pkp_date pkp_hour pkp_minute_coarse pkp_nta drf_boro: egen sum_others_time = total(ride_duration)
    replace sum_others_time = sum_others_time - ride_duration
    bysort driver_id shift_id hour_in_shift: egen sum_others_time_hour = total(sum_others_time)

    forval i = 1 / 9 {
        gen temp_`i' = sum_others_dist_hour / sum_others_time_hour if hour_in_shift == `i'
    }

    forval i = 1 / 9 {
        bysort driver_id shift_id: egen othersspeed_`i' = mean(temp_`i')
    }

    keep if cum_total_duration >= 8*60 + 15 & cum_total_duration <= 8*60 + 45
    save ../temp/IVothers15b_before8h40m.dta, replace

    use final_trip driver_id shift_id trip_id cum_income incomebin_1-incomebin_12 othersspeed_1-othersspeed_9 cum_total_duration ridebin_1-ridebin_12 drf_hour drf_dayofweek drf_nta pkp_boro drf_boro non_nyc_shift using ../temp/IVothers15b_before8h40m.dta if cum_total_duration >= 8*60+25 & cum_total_duration <= 8*60+35, clear

    keep if pkp_boro=="Manhattan":boro & drf_boro=="Manhattan":boro
    steps

    areg final_trip incomebin_1-incomebin_9 cum_total_duration i.dis_ridebin* $time_controls $location_controls, absorb(driver_id)
    forval j = 2(2)8 {
        lincom incomebin_`j' * $baseincome8h30m / $base8h30m
        matrix appendixtable9[`j' - 1, 1] = r(estimate)
        matrix appendixtable9[`j', 1] = r(se)
    }

    xtivreg final_trip (incomebin_1-incomebin_9 = othersspeed_1-othersspeed_9) cum_total_duration i.dis_ridebin* $time_controls $location_controls, fe
    forval j = 2(2)8 {
        lincom incomebin_`j' * $baseincome8h30m / $base8h30m
        matrix appendixtable9[`j' - 1, 2] = r(estimate)
        matrix appendixtable9[`j', 2] = r(se)
    }

    matrix_to_txt, matrix(appendixtable9) saving(../output/appendixtable9.txt) title(<tab:appendixtable9>) replace
end

program manhattan
    keep if pkp_boro=="Manhattan":boro & drf_boro=="Manhattan":boro
end

program steps
    merge_shift
    globs
    dis_hours
end

program dis_hours
    forval i = 1 / 12 {
        replace ridebin_`i' = 0 if ridebin_`i' < 0
    }
    forval i = 1 / 12 {
    replace incomebin_`i' = 0 if incomebin_`i' < 0
    }
    forval i = 1/12 {
        gen dis_ridebin0_`i' = floor(ridebin_`i' / 30)
        replace dis_ridebin0_`i' = 8 if ridebin_`i' == 0
        replace dis_ridebin0_`i' = 9 if ridebin_`i' == 60
    }
    sum ridebin_1, d
    keep if ridebin_1 < `r(p90)'
    sum ridebin_2, d
    keep if ridebin_2 > `r(p5)'
end

program merge_shift
    mmerge driver_id shift_id using ../input/taxi_shift.dta, ///
        type(n:1) unmatched(master) ukeep(shift_date shift_start)
end

program globs
    drop if non_nyc_shift

    global time_controls "i.drf_hour#i.drf_dayofweek i.shift_date"
    global weather_controls "near_rain i.near_temp_c i.near_wind_c"
    global location_controls "i.drf_nta"

    replace cum_income = incomebin_1 + incomebin_2 + incomebin_3 + incomebin_4 + incomebin_5 + incomebin_6 + incomebin_7 + incomebin_8 + incomebin_9 + incomebin_10 + incomebin_11 + incomebin_12

    egen driver_shift_id = group(driver_id shift_id)
    egen shift_trip_id = group(shift_id trip_id)
    xtset driver_id shift_trip_id
end

* Execute
main
