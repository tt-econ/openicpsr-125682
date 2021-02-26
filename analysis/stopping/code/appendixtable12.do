version 16
preliminaries, matsize(11000) maxvar(20000)

program main
    global time_controls "i.drf_hour#i.drf_dayofweek i.shift_date"
    global weather_controls "near_rain i.near_temp_c i.near_wind_c"
    global location_controls "i.drf_nta"
    global all_controls_except_id "$time_controls $weather_controls $location_controls"

    matrix appendixtable12 = J(10, 4, .)

    sumdelta 4
    sumdelta 8

    use ../output_local/taxi_8h30m.dta if cum_total_duration <= 8*60+40, clear
    append using ../output_local/taxi_8h.dta
    keep if cum_total_duration <= 8*60 + 40 & cum_total_duration >= 8*60 + 20

    mmerge driver_id shift_id trip_id using ../input/taxi_with_expectations.dta, type(1:1) unmatched(master) ukeep(r_income_driverdow_all r_hours_driverdow_all)
    mmerge driver_id shift_id using ../temp/sumdelta_4.dta, type(n:1) unmatched(master) ukeep(sumdelta_4)
    mmerge driver_id shift_id using ../temp/sumdelta_8.dta, type(n:1) unmatched(master) ukeep(sumdelta_8)
    sum cum_income r_income_driverdow_all r_hours_driverdow_all sumdelta_4 sumdelta_8
    capture noisily drop _merge
    keep if cum_total_duration >= 8*60 + 25 & cum_total_duration <= 8*60 + 35

    gen above_RP_hours = cum_total_duration > r_hours_driverdow_all*60

    foreach i in 0 25 50 75 100 {
        foreach j in 0 25 50 75 100 {
            gen RP_`i'_`j' = r_income_driverdow_all + `i'/100 * sumdelta_4 + `j'/100 * (sumdelta_8-sumdelta_4)
            gen above_RP_`i'_`j' = cum_income > RP_`i'_`j'
        }
    }

    areg final_trip cum_total_duration cum_income i.dis_ridebin* $all_controls_except_id above* if sumdelta_4!=., absorb(driver_id) vce(cluster driver_id)
    lincom above_RP_hours
    matrix appendixtable12[1, 1] = r(estimate)
    matrix appendixtable12[2, 1] = r(se)
    lincom above_RP_0_0
    matrix appendixtable12[3, 1] = r(estimate)
    matrix appendixtable12[4, 1] = r(se)
    lincom above_RP_25_0 + above_RP_50_0 + above_RP_50_25 + above_RP_75_0 + above_RP_75_25 + above_RP_75_50 + above_RP_100_0 + above_RP_100_25 + above_RP_100_50 + above_RP_100_75
    matrix appendixtable12[5, 1] = r(estimate)
    matrix appendixtable12[6, 1] = r(se)
    lincom above_RP_0_25 + above_RP_0_50 + above_RP_0_75 + above_RP_0_100 + above_RP_25_50 + above_RP_25_75 + above_RP_25_100 + above_RP_50_75 + above_RP_50_100 + above_RP_75_100
    matrix appendixtable12[7, 1] = r(estimate)
    matrix appendixtable12[8, 1] = r(se)
    lincom 100 * cum_income
    matrix appendixtable12[9, 1] = r(estimate)
    matrix appendixtable12[10, 1] = r(se)
    test above_RP_25_0 + above_RP_50_0 + above_RP_50_25 + above_RP_75_0 + above_RP_75_25 + above_RP_75_50 + above_RP_100_0 + above_RP_100_25 + above_RP_100_50 + above_RP_100_75 = above_RP_0_0
    test above_RP_25_0 + above_RP_50_0 + above_RP_50_25 + above_RP_75_0 + above_RP_75_25 + above_RP_75_50 + above_RP_100_0 + above_RP_100_25 + above_RP_100_50 + above_RP_100_75 = above_RP_0_25 + above_RP_0_50 + above_RP_0_75 + above_RP_0_100 + above_RP_25_50 + above_RP_25_75 + above_RP_25_100 + above_RP_50_75 + above_RP_50_100 + above_RP_75_100
    test above_RP_25_0 + above_RP_50_0 + above_RP_50_25 + above_RP_75_0 + above_RP_75_25 + above_RP_75_50 + above_RP_100_0 + above_RP_100_25 + above_RP_100_50 + above_RP_100_75 = above_RP_0_25 + above_RP_0_50 + above_RP_0_75 + above_RP_0_100 + above_RP_25_50 + above_RP_25_75 + above_RP_25_100 + above_RP_50_75 + above_RP_50_100 + above_RP_75_100 + above_RP_0_0

    drop RP_* above*
    gen above_RP_hours = cum_total_duration > r_hours_driverdow_all*60
    foreach i in 0 50 100 {
        foreach j in 0 50 100 {
            gen RP_`i'_`j' = r_income_driverdow_all + `i'/100 * sumdelta_4 + `j'/100 * (sumdelta_8-sumdelta_4)
            gen above_RP_`i'_`j' = cum_income > RP_`i'_`j'
        }
    }
    areg final_trip cum_total_duration cum_income i.dis_ridebin* $all_controls_except_id above* if sumdelta_4!=., absorb(driver_id) vce(cluster driver_id)
    lincom above_RP_hours
    matrix appendixtable12[1, 2] = r(estimate)
    matrix appendixtable12[2, 2] = r(se)
    lincom above_RP_0_0
    matrix appendixtable12[3, 2] = r(estimate)
    matrix appendixtable12[4, 2] = r(se)
    lincom above_RP_50_0 + above_RP_100_0 + above_RP_100_50
    matrix appendixtable12[5, 2] = r(estimate)
    matrix appendixtable12[6, 2] = r(se)
    lincom above_RP_0_50 + above_RP_0_100 + above_RP_50_100
    matrix appendixtable12[7, 2] = r(estimate)
    matrix appendixtable12[8, 2] = r(se)
    lincom 100 * cum_income
    matrix appendixtable12[9, 2] = r(estimate)
    matrix appendixtable12[10, 2] = r(se)
    test above_RP_50_0 + above_RP_100_0 + above_RP_100_50 = above_RP_0_0
    test above_RP_50_0 + above_RP_100_0 + above_RP_100_50 = above_RP_0_50 + above_RP_0_100 + above_RP_50_100
    test above_RP_50_0 + above_RP_100_0 + above_RP_100_50 = above_RP_0_50 + above_RP_0_100 + above_RP_50_100 + above_RP_0_0

    drop RP_* above*
    gen above_RP_hours = cum_total_duration > r_hours_driverdow_all*60
    foreach i in 0 10 25 50 75 90 100 {
        foreach j in 0 10 25 50 75 90 100 {
            gen RP_`i'_`j' = r_income_driverdow_all + `i'/100 * sumdelta_4 + `j'/100 * (sumdelta_8-sumdelta_4)
            gen above_RP_`i'_`j' = cum_income > RP_`i'_`j'
        }
    }
    areg final_trip cum_total_duration cum_income i.dis_ridebin* $all_controls_except_id above* if sumdelta_4!=., absorb(driver_id) vce(cluster driver_id)
    lincom above_RP_hours
    matrix appendixtable12[1, 3] = r(estimate)
    matrix appendixtable12[2, 3] = r(se)
    lincom above_RP_0_0
    matrix appendixtable12[3, 3] = r(estimate)
    matrix appendixtable12[4, 3] = r(se)
    lincom above_RP_10_0 + above_RP_25_0 + above_RP_50_0 + above_RP_50_10 + above_RP_50_25 + above_RP_75_0 + above_RP_90_0 + above_RP_75_10 + above_RP_75_25 + above_RP_90_10 + above_RP_90_25 + above_RP_75_50 + above_RP_90_50 + above_RP_100_0 + above_RP_100_10 + above_RP_100_25 + above_RP_100_50 + above_RP_100_75 + above_RP_100_90
    matrix appendixtable12[5, 3] = r(estimate)
    matrix appendixtable12[6, 3] = r(se)
    lincom above_RP_0_10 + above_RP_0_25 + above_RP_0_50 + above_RP_0_75 + above_RP_0_90 + above_RP_0_100 + above_RP_10_50 + above_RP_25_50 + above_RP_10_75 + above_RP_10_90 + above_RP_25_75 + above_RP_25_90 + above_RP_10_100 + above_RP_25_100 + above_RP_50_75 + above_RP_50_90 + above_RP_50_100 + above_RP_75_100 + above_RP_90_100
    matrix appendixtable12[7, 3] = r(estimate)
    matrix appendixtable12[8, 3] = r(se)
    lincom 100 * cum_income
    matrix appendixtable12[9, 3] = r(estimate)
    matrix appendixtable12[10, 3] = r(se)
    test above_RP_10_0 + above_RP_25_0 + above_RP_50_0 + above_RP_50_10 + above_RP_50_25 + above_RP_75_0 + above_RP_90_0 + above_RP_75_10 + above_RP_75_25 + above_RP_90_10 + above_RP_90_25 + above_RP_75_50 + above_RP_90_50 + above_RP_100_0 + above_RP_100_10 + above_RP_100_25 + above_RP_100_50 + above_RP_100_75 + above_RP_100_90 = above_RP_0_0
    test above_RP_10_0 + above_RP_25_0 + above_RP_50_0 + above_RP_50_10 + above_RP_50_25 + above_RP_75_0 + above_RP_90_0 + above_RP_75_10 + above_RP_75_25 + above_RP_90_10 + above_RP_90_25 + above_RP_75_50 + above_RP_90_50 + above_RP_100_0 + above_RP_100_10 + above_RP_100_25 + above_RP_100_50 + above_RP_100_75 + above_RP_100_90 = above_RP_0_10 + above_RP_0_25 + above_RP_0_50 + above_RP_0_75 + above_RP_0_90 + above_RP_0_100 + above_RP_10_50 + above_RP_25_50 + above_RP_10_75 + above_RP_10_90 + above_RP_25_75 + above_RP_25_90 + above_RP_10_100 + above_RP_25_100 + above_RP_50_75 + above_RP_50_90 + above_RP_50_100 + above_RP_75_100 + above_RP_90_100
    test above_RP_10_0 + above_RP_25_0 + above_RP_50_0 + above_RP_50_10 + above_RP_50_25 + above_RP_75_0 + above_RP_90_0 + above_RP_75_10 + above_RP_75_25 + above_RP_90_10 + above_RP_90_25 + above_RP_75_50 + above_RP_90_50 + above_RP_100_0 + above_RP_100_10 + above_RP_100_25 + above_RP_100_50 + above_RP_100_75 + above_RP_100_90 = above_RP_0_10 + above_RP_0_25 + above_RP_0_50 + above_RP_0_75 + above_RP_0_90 + above_RP_0_100 + above_RP_10_50 + above_RP_25_50 + above_RP_10_75 + above_RP_10_90 + above_RP_25_75 + above_RP_25_90 + above_RP_10_100 + above_RP_25_100 + above_RP_50_75 + above_RP_50_90 + above_RP_50_100 + above_RP_75_100 + above_RP_90_100 + above_RP_0_0

    drop RP_* above*
    gen above_RP_hours = cum_total_duration > r_hours_driverdow_all*60
    foreach i in 0 33 66 100 {
        foreach j in 0 33 66 100 {
            gen RP_`i'_`j' = r_income_driverdow_all + `i'/100 * sumdelta_4 + `j'/100 * (sumdelta_8-sumdelta_4)
            gen above_RP_`i'_`j' = cum_income > RP_`i'_`j'
        }
    }
    areg final_trip cum_total_duration cum_income i.dis_ridebin* $all_controls_except_id above* if sumdelta_4!=., absorb(driver_id) vce(cluster driver_id)
    lincom above_RP_hours
    matrix appendixtable12[1, 4] = r(estimate)
    matrix appendixtable12[2, 4] = r(se)
    lincom above_RP_0_0
    matrix appendixtable12[3, 4] = r(estimate)
    matrix appendixtable12[4, 4] = r(se)
    lincom above_RP_33_0 + above_RP_66_0 + above_RP_66_33 + above_RP_100_0 + above_RP_100_33 + above_RP_100_66
    matrix appendixtable12[5, 4] = r(estimate)
    matrix appendixtable12[6, 4] = r(se)
    lincom above_RP_0_33 + above_RP_0_66 + above_RP_0_100 + above_RP_33_66 + above_RP_33_100 + above_RP_66_100
    matrix appendixtable12[7, 4] = r(estimate)
    matrix appendixtable12[8, 4] = r(se)
    lincom 100 * cum_income
    matrix appendixtable12[9, 4] = r(estimate)
    matrix appendixtable12[10, 4] = r(se)
    test above_RP_33_0 + above_RP_66_0 + above_RP_66_33 + above_RP_100_0 + above_RP_100_33 + above_RP_100_66 = above_RP_0_0
    test above_RP_33_0 + above_RP_66_0 + above_RP_66_33 + above_RP_100_0 + above_RP_100_33 + above_RP_100_66 = above_RP_0_33 + above_RP_0_66 + above_RP_0_100 + above_RP_33_66 + above_RP_33_100 + above_RP_66_100
    test above_RP_33_0 + above_RP_66_0 + above_RP_66_33 + above_RP_100_0 + above_RP_100_33 + above_RP_100_66 = above_RP_0_33 + above_RP_0_66 + above_RP_0_100 + above_RP_33_66 + above_RP_33_100 + above_RP_66_100 + above_RP_0_0

    matrix_to_txt, matrix(appendixtable12) saving(../output/appendixtable12.txt) title(<tab:appendixtable12>) replace
end

program sumdelta
    args hr

    use driver_id shift_id trip_id cum_total_duration delta* using ///
        ../input/taxi_rhours25p75p_all.dta ///
        if cum_total_duration > `hr', clear
    bysort driver_id shift_id (trip_id): gen tag_shift = (_n == 1)
    keep if tag_shift
    drop tag_shift
    gen sumdelta_`hr' = 0
    sum trip_id
    local rmax = r(max)
    forval i = 2 / `rmax' {
        replace sumdelta_`hr' = sumdelta_`hr' + delta_`i' if trip_id >= `i'
    }
    keep driver_id shift_id sumdelta_`hr'
    replace sumdelta_`hr' = sumdelta_`hr' * 100
    save ../temp/sumdelta_`hr'.dta, replace
end

* Execute
main
