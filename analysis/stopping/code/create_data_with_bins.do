version 16
preliminaries, matsize(11000) maxvar(20000)

program main
    forval i = 4 / 10 {
        use ../input/ridebins.dta if cum_total_duration >= `i'*60+30 & cum_total_duration < `i'*60+60, clear
        rename cum_total_duration cum_total_duration0
        mmerge driver_id shift_id trip_id using ../input/taxi_last12_min60.dta, type(1:1) unmatched(master)
        drop cum_total_duration incomebin*
        rename cum_total_duration0 cum_total_duration
        mmerge driver_id shift_id trip_id using ../input/incomebins.dta, type(1:1) unmatched(master) ukeep(incomebin*)
        merge_shift
        save ../output_local/taxi_`i'h30m.dta, replace
    }

    forval i = 5 / 10 {
        use ../input/ridebins.dta if cum_total_duration >= `i'*60 & cum_total_duration < `i'*60+30, clear
        rename cum_total_duration cum_total_duration0
        mmerge driver_id shift_id trip_id using ../input/taxi_last12_min60.dta, type(1:1) unmatched(master)
        drop cum_total_duration incomebin*
        rename cum_total_duration0 cum_total_duration
        mmerge driver_id shift_id trip_id using ../input/incomebins.dta, type(1:1) unmatched(master) ukeep(incomebin*)
        merge_shift
        save ../output_local/taxi_`i'h.dta, replace
    }

end

program merge_shift
    mmerge driver_id shift_id using ../input/taxi_shift.dta, ///
        type(n:1) unmatched(master) ukeep(shift_date shift_start shift_dayofweek)
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
    drop if non_nyc_shift
    keep if ridebin_1 <= 55 & ridebin_2 >= 10
end

* Execute
main
