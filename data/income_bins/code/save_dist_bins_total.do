version 16
preliminaries, matsize(11000) maxvar(20000)
adopath + ../lib

program main
    use driver_id shift_id cum_total_duration distance ///
        if cum_total_duration < 780 using ../input/taxi.dta, clear
    bysort driver_id shift_id (cum_total_duration): ///
        gen cum_dist = sum(distance)
    drop distance
    make_bins_phantom, x(cum_dist) h(cum_total_duration) lastbin(12) binmin(60)
    rename incomebin* distbin*
    save ../output_local/distbins.dta, replace
end

* Execute
main
