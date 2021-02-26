version 16
preliminaries, matsize(11000) maxvar(20000)
adopath + ../lib

program main
    use driver_id shift_id cum_total_duration cum_ride_duration ///
        if cum_total_duration < 780 using ../input/taxi.dta, clear
    make_bins_phantom, x(cum_ride_duration) h(cum_total_duration) ///
        lastbin(12) binmin(60)
    rename incomebin* ridebin*
    save_data ../temp/ridebins.dta, ///
        key(driver_id shift_id cum_total_duration) replace

    use driver_id shift_id trip_id cum_total_duration ///
        if cum_total_duration < 780 using ../input/taxi.dta, clear
    save ../temp/merging_ride.dta, replace
    use ../temp/ridebins.dta, clear
    mmerge driver_id shift_id cum_total_duration ///
        using ../temp/merging_ride.dta, ///
        type(1:1) unmatched(master) ukeep(trip_id)
    assert _merge==3
    drop _merge
    save_data ../output_local/ridebins.dta, ///
        key(driver_id shift_id trip_id) replace
end

* Execute
main
