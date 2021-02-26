version 16
preliminaries, matsize(11000) maxvar(20000)

program main
    use ../output_local/taxi_rhours25p75p_all.dta if driver_id <= 500, clear
    save ../temp/taxi_rhours25p75p_500.dta, replace

    use driver_id shift_id trip_id cum_total_duration cum_income ///
        shift_total_income drf_hour drf_dayofweek shift_start ///
        drf_weekofyear holiday drf_nta near_temp_c near_rain near_wind_c ///
        final_trip break_time exp_income exp_duration shift_total_hours ///
        using ../input/taxi_with_expectations.dta ///
        if driver_id <= 500 & cum_total_duration < 9*60, clear
    mmerge driver_id shift_id trip_id using ///
        ../input/incomebins.dta, ///
        type(1:1) unmatched(master) ukeep(incomebin*)
    drop _merge
    scaling

    areg shift_total_income incomebin* cum_total_duration ///
        i.drf_hour#i.drf_dayofweek i.shift_start i.drf_weekofyear holiday ///
        i.drf_nta i.near_temp_c near_rain i.near_wind_c ///
        if !final_trip & !break_time, absorb(driver_id)
    estimates save ../temp/sti.ster, replace
    predict FE, d
    bysort driver_id (FE): replace FE = FE[1]

    sort driver_id shift_id trip_id

    forval j = 0 / 8 {
        preserve
        replace cum_income = cum_income + .01 if cum_total_duration > `j'.5
        sum trip_id
        local maxntrips = `r(max)'
        bysort driver_id shift_id (trip_id): gen income = cum_income - cum_income[_n-1]
        bysort driver_id shift_id (trip_id): gen duration = cum_total_duration - cum_total_duration[_n-1]
        bysort driver_id shift_id (trip_id): gen delta = income - exp_income[_n-1]*duration/exp_duration[_n-1]
        drop income duration
        forval i = 2 / `maxntrips' {
            bysort driver_id shift_id (trip_id): gen delta_`i' = delta[`i'] if trip_id >= `i'
        }
        drop delta

        mmerge driver_id shift_id trip_id using ../temp/taxi_rhours25p75p_500.dta, ///
            type(1:1) unmatched(master)
        drop _merge

        local k = `j' + 1
        replace incomebin_`k' = incomebin_`k' + .01 if cum_total_duration > `j'+.5
        estimates use ../temp/sti.ster
        predict pred, xb
        gen pred_total_income_trip = pred + FE
        drop pred
        drop FE
        bysort driver_id shift_id (trip_id): ///
            replace pred_total_income_trip_m1  = pred_total_income_trip[_n - 1]
        replace pred_total_income_trip_m1 = r_income_driverdow_all if pred_total_income_trip_m1 == .

        sum trip_id
        local rmax = r(max)
        gen lag_id = 0
        forval i = `rmax'(-1)1 {
            bysort driver_id shift_id: replace lag_id = `i' if ///
                cum_total_duration - 1 > cum_total_duration[_n - `i']
        }
        replace pred_total_income_hour = r_income_driverdow_all
        sum lag_id
        local rmax = r(max)
        forval i = 1/`rmax' {
            bysort driver_id shift_id: replace pred_total_income_hour ///
                    = pred_total_income_trip[_n - `i'] if lag_id == `i'
        }
        replace pred_total_income_hour = r_income_driverdow_all if pred_total_income_hour == .
        drop lag_id pred_total_income_trip

        keep if cum_total_duration >= 8

        gen sample_id = `j'
        forval i = 1 / 9 {
            gen I_psi_ctd`i' = (cum_total_duration >= `i'+2 & cum_total_duration < `i'+3)
        }

        drop incomebin*
        drop break_time drf_dayofweek drf_hour drf_nta drf_weekofyear holiday near_rain near_temp_c near_wind_c shift_start shift_total_income
        save_data ../output_local/taxi_sim_`j'.csv, replace export key(driver_id shift_id trip_id)
        restore
    }
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

* Execute
main

