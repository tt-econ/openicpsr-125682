version 16
preliminaries, matsize(11000) maxvar(20000)
adopath + ../lib

program main
    use driver_id shift_id cum_total_duration cum_income ///
        if cum_total_duration < 780 using ../input/taxi.dta, clear
    make_bins_phantom, x(cum_income) h(cum_total_duration) ///
        lastbin(12) binmin(60)
    save_data ../temp/incomebins.dta, ///
        key(driver_id shift_id cum_total_duration) replace

    use driver_id shift_id trip_id cum_total_duration ///
        if cum_total_duration < 780 using ../input/taxi.dta, clear
    save ../temp/merging_income.dta, replace
    use ../temp/incomebins.dta, clear
    mmerge driver_id shift_id cum_total_duration ///
        using ../temp/merging_income.dta, ///
        type(1:1) unmatched(master) ukeep(trip_id)
    assert _merge==3
    drop _merge
    save_data ../output_local/incomebins.dta, ///
        key(driver_id shift_id trip_id) replace

end

* Execute
main
