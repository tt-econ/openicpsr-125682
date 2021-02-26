version 16
preliminaries, matsize(11000) maxvar(20000)

program main
    sample_data
    get_variables
    save_data ../temp/twofifteenths.dta, ///
        replace key(driver_id shift_id trip_id)
end

program sample_data
    use final_trip cum_total_duration cum_work_duration cum_ride_duration ///
        driver_id shift_id trip_id cum_income non_nyc_shift ///
        drf_dayofweek drf_hour drf_weekofyear holiday ///
        near_rain near_temp_c near_wind_c drf_nta ///
        using ../input/taxi.dta, clear
    keep if !non_nyc_shift
    drop non_nyc_shift
    sample `=2/15*100'
end

program get_variables
    mmerge driver_id shift_id trip_id using ../input/incomebins.dta, ///
        type(1:1) unmatched(master) ukeep(incomebin*)

    mmerge driver_id shift_id using ../input/taxi_shift.dta, ///
        type(n:1) unmatched(master) ukeep(shift_start shift_date)

    foreach hr in total work ride {
        gen HF_`hr'_bin0 = (cum_`hr'_duration < 180)
        gen HF_`hr'_bin1 = (cum_`hr'_duration >= 180 & cum_`hr'_duration < 360)
        gen HF_`hr'_bin2 = (cum_`hr'_duration >= 360 & cum_`hr'_duration < 420)
        gen HF_`hr'_bin3 = (cum_`hr'_duration >= 420 & cum_`hr'_duration < 480)
        gen HF_`hr'_bin4 = (cum_`hr'_duration >= 480 & cum_`hr'_duration < 540)
        gen HF_`hr'_bin5 = (cum_`hr'_duration >= 540 & cum_`hr'_duration < 600)
        gen HF_`hr'_bin6 = (cum_`hr'_duration >= 600 & cum_`hr'_duration < 660)
        gen HF_`hr'_bin7 = (cum_`hr'_duration >= 660 & cum_`hr'_duration < 720)
        gen HF_`hr'_bin8 = (cum_`hr'_duration >= 720 & cum_`hr'_duration < 780)
        gen HF_`hr'_bin9 = (cum_`hr'_duration >= 780)
    }

    gen HF_income_bin0 = (cum_income < 100)
    gen HF_income_bin1 = (cum_income >= 100 & cum_income < 150)
    gen HF_income_bin2 = (cum_income >= 150 & cum_income < 200)
    gen HF_income_bin3 = (cum_income >= 200 & cum_income < 225)
    gen HF_income_bin4 = (cum_income >= 225 & cum_income < 250)
    gen HF_income_bin5 = (cum_income >= 250 & cum_income < 275)
    gen HF_income_bin6 = (cum_income >= 275 & cum_income < 300)
    gen HF_income_bin7 = (cum_income >= 300 & cum_income < 350)
    gen HF_income_bin8 = (cum_income >= 350 & cum_income < 400)
    gen HF_income_bin9 = (cum_income >= 400)

    sort driver_id shift_id trip_id
    save ../temp/twofifteenths.dta, replace

    bysort driver_id shift_id (trip_id): gen tag_driver_shift = (_n == 1)
    keep if tag_driver_shift == 1
    keep driver_id shift_id
    save ../temp/twofifteenths_drivershiftlist.dta

    use ../input/ridebins.dta
    keep driver_id shift_id trip_id ridebin*
    bysort driver_id shift_id (trip_id): gen tag_driver_shift = (_n == _N)
    keep if tag_driver_shift == 1
    mmerge driver_id shift_id using ../temp/twofifteenths_drivershiftlist.dta, ///
        type(1:1) unmatched(using)
    save ../temp/twofifteenths_drivershiftlist_withride.dta

    use ../temp/twofifteenths.dta, clear
    mmerge driver_id shift_id using ../temp/twofifteenths_drivershiftlist_withride.dta, ///
        type(n:1) unmatched(master)

    keep if ridebin_1 <= 55 & ridebin_2 >= 10
    sort driver_id shift_id trip_id
end

* Execute
main
