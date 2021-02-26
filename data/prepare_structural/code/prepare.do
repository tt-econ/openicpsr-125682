version 16
preliminaries, matsize(11000)

program main
    local controls = "drf_hour drf_dayofweek " + ///
        "to_jfk to_lga drf_boro " + ///
        "near_temp_c near_rain"
    local variables = "final_trip driver_id shift_id trip_id " + ///
        "exp_income exp_duration cum_income cum_total_duration " + ///
        "r_income_driverdow_all r_hours_driverdow_all " + ///
        "shift_numtrips shift_total_hours " + ///
        "pred_total_income_trip_m1 pred_total_income_hour r_income_driver_all " + ///
        "`controls'"
    use `variables' using ///
        ../input/taxi_with_expectations.dta ///
        if (r_hours_driverdow_all > 7.5 & r_hours_driverdow_all < 9.5) & ///
        cum_total_duration > 3*60 & cum_total_duration <= 12*60, clear
    scaling
    save ../temp/temp_rhours25p75p_all.dta, replace

    use driver_id shift_id trip_id cum_income cum_total_duration ///
        exp_income exp_duration shift_total_hours r_hours_driverdow_all using ///
        ../input/taxi_with_expectations.dta ///
        if cum_total_duration <= 12*60, clear
    scaling

    sort driver_id shift_id trip_id

    sum trip_id
    local maxntrips = `r(max)'
    bysort driver_id shift_id (trip_id): gen income = cum_income - cum_income[_n-1]
    bysort driver_id shift_id (trip_id): gen duration = cum_total_duration - cum_total_duration[_n-1]
    bysort driver_id shift_id (trip_id): gen delta = income - exp_income[_n-1]*duration/exp_duration[_n-1]
    drop income duration
    forval i = 2 / `maxntrips' {
        gen temp = delta if trip_id == `i'
        bysort driver_id shift_id (trip_id): egen temp_shift = mean(temp)
        bysort driver_id shift_id (trip_id): gen delta_`i' = temp_shift if trip_id >= `i'
        drop if trip_id < `i' & ~(r_hours_driverdow_all > 7.5 & r_hours_driverdow_all < 9.5)
        drop temp temp_shift
    }
    drop delta

    keep if cum_total_duration > 3
    keep if (r_hours_driverdow_all > 7.5 & r_hours_driverdow_all < 9.5)

    mmerge driver_id shift_id trip_id using ../temp/temp_rhours25p75p_all.dta, type(1:1) unmatched(master)
    drop _merge

    egen drf_hr = group(drf_hour)
    egen drf_dow = group(drf_dayofweek)
    quietly tabulate drf_boro, generate(I_drf_boro)
    quietly tabulate near_temp_c, generate(I_near_temp_c)
    quietly tabulate near_rain, generate(I_near_rain)
    quietly tabulate drf_hr, generate(I_drf_hr)
    quietly tabulate drf_dow, generate(I_drf_dow)

    drop drf_hr drf_dow drf_hour drf_dayofweek drf_boro near_temp_c near_rain

    save_data ../output_local/taxi_rhours25p75p_all.dta, replace key(driver_id shift_id trip_id)
end

program scaling
    foreach v of varlist * {
        if strpos("`v'", "income") {
            replace `v' = `v' / 100
        }
        else if strpos("`v'", "duration") {
            replace `v' = `v' / 60
        }
    }
    drop if shift_total_hours == .
    drop shift_total_hours
end

main
