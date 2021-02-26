version 16
preliminaries

program main
    use "../input/taxi.dta", clear
    broad_summary

    file open appendixtable1 using "../output/appendixtable1.txt", write replace
    file write appendixtable1 "<tab:appendixtable1>" _n
    file close appendixtable1
    summary_trip_level, outputfile("../output/appendixtable1.txt") mode(append)

    use "../input/taxi_shift.dta", clear
    summary_shift_level, outputfile("../output/appendixtable1.txt") mode(append)
end

program broad_summary
    ooo BROAD SUMMARY STATISTICS

    oo Number of drivers
    quiet sum driver_id
    display r(max)

    oo Number of cabs
    quiet sum car_id
    display r(max)

    oo Number of shifts
    quiet sum tag_shift
    display r(sum)

    oo Number of trips
    disp _N

    oo Total fare amount
    quiet sum fare
    display r(sum)

    oo Pick-up and drop-off areas
    tab pkp_boro drf_boro, cell
end

program summary_trip_level
    syntax, outputfile(string) mode(string)

    ooo SUMMARY STATISTICS AT THE TRIP LEVEL
    file open appendixtable1 using `outputfile', write `mode'

    oo Ride duration in minutes
    sum ride_duration, detail
    file write appendixtable1 (r(mean)) _tab (r(p25)) _tab (r(p50)) _tab (r(p75)) _n

    oo Wait duration in minutes
    sum wait_duration, detail
    file write appendixtable1 (r(mean)) _tab (r(p25)) _tab (r(p50)) _tab (r(p75)) _n

    oo Fare in dollars
    sum fare, detail
    file write appendixtable1 (r(mean)) _tab (r(p25)) _tab (r(p50)) _tab (r(p75)) _n

    oo Percent tip
    gen percent_tip = tip / fare * 100
    sum percent_tip if payment_type=="credit":payment, detail
    file write appendixtable1 (r(mean)) _tab (r(p25)) _tab (r(p50)) _tab (r(p75)) _n

    file close appendixtable1
end

program summary_shift_level
    syntax, outputfile(string) mode(string)

    ooo SUMMARY STATISTICS AT THE SHIFT LEVEL
    file open appendixtable1 using `outputfile', write `mode'
    egen tag_driver = tag(driver_id)

    oo Number of shifts per driver
    sum driver_numshifts if tag_driver, detail
    file write appendixtable1 (r(mean)) _tab (r(p25)) _tab (r(p50)) _tab (r(p75)) _n

    oo Number of trips in a shift
    sum shift_numtrips, detail
    file write appendixtable1 (r(mean)) _tab (r(p25)) _tab (r(p50)) _tab (r(p75)) _n

    oo Shift total hours
    sum shift_total_hours, detail
    file write appendixtable1 (r(mean)) _tab (r(p25)) _tab (r(p50)) _tab (r(p75)) _n

    oo Shift ride hours
    sum shift_ride_hours, detail
    file write appendixtable1 (r(mean)) _tab (r(p25)) _tab (r(p50)) _tab (r(p75)) _n

    oo Fraction break time
    gen fraction_break = shift_break_hours / shift_total_hours
    sum fraction_break, detail
    file write appendixtable1 (r(mean)) _tab (r(p25)) _tab (r(p50)) _tab (r(p75)) _n

    oo Shfit income in dollars
    sum shift_total_income, detail
    file write appendixtable1 (r(mean)) _tab (r(p25)) _tab (r(p50)) _tab (r(p75)) _n

    oo Shift income (day shift)
    sum shift_total_income if night_shift==0, detail
    file write appendixtable1 (r(mean)) _tab (r(p25)) _tab (r(p50)) _tab (r(p75)) _n

    oo Shift income (night shift)
    sum shift_total_income if night_shift==1, detail
    file write appendixtable1 (r(mean)) _tab (r(p25)) _tab (r(p50)) _tab (r(p75)) _n

    oo Hourly wage in dollars
    sum shift_total_wage, detail
    file write appendixtable1 (r(mean)) _tab (r(p25)) _tab (r(p50)) _tab (r(p75)) _n

    oo Hourly wage (day shift)
    sum shift_total_wage if night_shift==0, detail
    file write appendixtable1 (r(mean)) _tab (r(p25)) _tab (r(p50)) _tab (r(p75)) _n

    oo Hourly wage (night shift)
    sum shift_total_wage if night_shift==1, detail
    file write appendixtable1 (r(mean)) _tab (r(p25)) _tab (r(p50)) _tab (r(p75)) _n

    file close appendixtable1
end

* Execute
main

