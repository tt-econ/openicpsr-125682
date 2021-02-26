version 16
preliminaries, matsize(11000)

program main
    add_shift_vars
    shift_level_expectation_proxy
    sophisticated_predictions
    save_data ../output_local/taxi_with_expectations.dta, replace ///
        key(driver_id shift_id trip_id)
end

program add_shift_vars
    use ../input/taxi.dta, clear
    drop if non_nyc_shift

    mmerge driver_id shift_id using ../output_local/taxi_shift.dta, type(n:1) ///
        ukeep(shift*) unmatched(master)
    drop _merge

    save ../temp/taxi.dta, replace
end

program shift_level_expectation_proxy
    use ../temp/taxi.dta, clear
    keep if tag_shift
    keep shift_* driver_id

    shift_expectation_driverdow
    shift_expectation_driver

    * recover trip level data
    expandcl shift_numtrips, cl(driver_id shift_id) gen(group)
    drop group
    bys driver_id shift_id: gen trip_id = _n

    mmerge driver_id shift_id trip_id using ../temp/taxi.dta, ///
        type(1:1) unmatched(both)
    assert _merge == 3
    drop _merge
    save ../temp/taxi.dta, replace
end

    program shift_expectation_driver
        sort driver_id
        by driver_id: gen bin_count = _N
        by driver_id: egen bin_income = total(shift_total_income)
        by driver_id: egen bin_hours = total(shift_total_hours)
        gen r_income_driver_all = (bin_income - shift_total_income) / ///
            (bin_count - 1)
        gen r_hours_driver_all = (bin_hours - shift_total_hours) / ///
            (bin_count - 1)
        drop bin_income bin_hours bin_count
    end

    program shift_expectation_driverdow
        sort driver_id shift_dayofweek shift_id
        by driver_id shift_dayofweek: gen bin_count = _N
        by driver_id shift_dayofweek: egen bin_income = total(shift_total_income)
        by driver_id shift_dayofweek: egen bin_hours = total(shift_total_hours)
        by driver_id shift_dayofweek: egen bin_wage = total(shift_total_wage)
        gen r_income_driverdow_all = (bin_income - shift_total_income) / ///
            (bin_count - 1)
        gen r_hours_driverdow_all = (bin_hours - shift_total_hours) / ///
            (bin_count - 1)
        drop bin_income bin_hours bin_wage bin_count
    end

program sophisticated_predictions
    use ../temp/taxi.dta, clear
    sort driver_id shift_id trip_id
    gen next_total_duration = total_duration[_n + 1]
    gen next_income = income[_n + 1]
    gen next_wage = minute_wage[_n + 1]
    by driver_id: egen mean_next_total_duration = mean(next_total_duration)
    by driver_id: egen mean_next_income = mean(next_income)
    by driver_id: egen mean_next_wage = mean(next_wage)
    gen next_total_duration_demean = next_total_duration - mean_next_total_duration
    gen next_income_demean = next_income - mean_next_income
    gen next_wage_demean = next_wage - mean_next_wage

    areg next_total_duration_demean i.drf_hour#i.drf_dayofweek i.drf_weekofyear ///
        holiday i.drf_nta i.near_temp_c near_rain i.near_wind_c ///
        if !final_trip & !break_time, absorb(driver_id)
    predict exp_duration, xb
    drop if exp_duration == .
    drop next_total_duration_demean
    replace exp_duration = exp_duration + mean_next_total_duration

    areg next_income_demean i.drf_hour#i.drf_dayofweek i.drf_weekofyear ///
        holiday i.drf_nta i.near_temp_c near_rain i.near_wind_c ///
        if !final_trip & !break_time, absorb(driver_id)
    predict exp_income, xb
    drop next_income_demean
    replace exp_income = exp_income + mean_next_income

    gen exp_cum_duration = cum_total_duration + exp_duration
    gen exp_cum_income = cum_income + exp_income

    areg next_wage_demean i.drf_hour#i.drf_dayofweek i.drf_weekofyear ///
        holiday i.drf_nta i.near_temp_c near_rain i.near_wind_c ///
        if !final_trip & !break_time, absorb(driver_id)
    predict exp_wage, xb
    drop next_wage_demean
    replace exp_wage = exp_wage + mean_next_wage


    mmerge driver_id shift_id trip_id using ///
        ../input/incomebins.dta, ///
        type(1:1) unmatched(master) ukeep(incomebin*)

    gen pred_total_income_trip = r_income_driverdow_all
    areg shift_total_income incomebin* cum_total_duration ///
        i.drf_hour#i.drf_dayofweek i.shift_start i.drf_weekofyear holiday ///
        i.drf_nta i.near_temp_c near_rain i.near_wind_c ///
        if !final_trip & !break_time, absorb(driver_id)
    predict FE, d
    bysort driver_id (FE): replace FE = FE[1]
    predict pred, xb
    replace pred_total_income_trip = pred + FE
    drop pred
    drop FE
    bysort driver_id shift_id (trip_id): gen pred_total_income_trip_m1 = pred_total_income_trip[_n - 1]
    replace pred_total_income_trip_m1 = r_income_driverdow_all if pred_total_income_trip_m1 == .

    sum trip_id
    local rmax = r(max)
    gen lag_id = 0
    forval i = `rmax'(-1)1 {
        bysort driver_id shift_id (trip_id): replace lag_id = `i' if cum_total_duration - 60 > cum_total_duration[_n - `i']
    }

    gen pred_total_income_hour = r_income_driverdow_all
    sum lag_id
    local rmax = r(max)
    forval i = 1/`rmax' {
        bysort driver_id shift_id (trip_id): replace pred_total_income_hour = pred_total_income_trip[_n - `i'] if lag_id == `i'
    }
    replace pred_total_income_hour = r_income_driverdow_all if pred_total_income_hour == .
end

* Execute
main
