version 16
preliminaries

program main
    use non_nyc_shift shift_total_hours shift_start ///
        using "../input/taxi_shift.dta", clear
    drop if non_nyc_shift

    bys shift_start: gen shifts_fraction = _N
    bys shift_start: egen shift_total_hours_upper = pctile(shift_total_hours), p(75)
    bys shift_start: egen shift_total_hours_lower = pctile(shift_total_hours), p(25)
    replace shifts_fraction = shifts_fraction / _N

    collapse shifts_fraction shift_total_hours*, by(shift_start)

    twoway (bar shifts_fraction shift_start, yaxis(2) color(gs10)) ///
           (rcap shift_total_hours_upper shift_total_hours_lower shift_start, lcolor(black)) ///
           (scatter shift_total_hours shift_start, yaxis(1) mcolor(black) msymbol(O)), ///
           legend(order(1 2) label( 1 "Fraction of shifts") label(2 "Hours in shift (25% - 75%)")) ///
           ytitle("Fraction of shifts started", axis(2)) ///
           ytitle("Shift duration (hours)", axis(1)) ///
           xtitle("Clock hour of shift start") ///
           xtick(0(2)23) xlabel(0(2)23) ytick(0(2)15, axis(1)) ylabel(0(2)15, axis(1))

    graph export "../output/figure1.pdf", replace
end

* Exexute
main

