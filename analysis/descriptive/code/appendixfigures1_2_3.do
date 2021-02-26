version 16
preliminaries

program main
    appendixfigure1
    appendixfigure2
    appendixfigure3
end

program appendixfigure1
    use "../input/clock_minute.dta", clear
    collapse driver_work driver_ride hour minute, by(minute_of_day)
    gen hour_of_day = minute_of_day / 60

    line driver_work hour_of_day, yaxis(1) ///
        lcolor(black) lpattern(solid) ///
        || line driver_ride hour_of_day, yaxis(1) ///
        lcolor(black) lpattern(dash) ///
        || , xlabel(0(2)24) xtitle("Hour of day") ///
        ytitle("Number of cabs", axis(1)) xline(5 17) ///
        legend(label (1 "Number of cabs on the street") ///
        label(2 "Number of occupied cabs on the street") cols(1))
    graph export "../output/appendixfigure1.pdf", replace
end

program appendixfigure2
    use "../input/clock_minute.dta", clear
    egen sd_wage_mod = sd(avg_wage), by(minute_of_day)
    collapse avg_wage sd_wage_mod hour minute, by(minute_of_day)
    gen wage_high = avg_wage + sd_wage_mod
    gen wage_low = avg_wage - sd_wage_mod
    gen hour_of_day = minute_of_day/60

    line avg_wage wage_high wage_low hour_of_day, xlabel(0(2)24) ///
        legend(off) lcolor(black gs12 gs12) lwidth(medium vthin vthin) ///
        xtitle("Hour of day") ytitle("dollars/minute") xline(5 17)
    graph export "../output/appendixfigure2.pdf", replace
end

program appendixfigure3
    save_weekend

    use "../input/clock_minute.dta", clear
    drop if ((dow == 5 | dow == 6) & minute_of_day > 17 * 60) | ///
        ((dow == 6 | dow == 0) & minute_of_day <= 17 * 60)
    egen sd_wage_mod = sd(avg_wage), by(minute_of_day)
    collapse avg_wage sd_wage_mod, by(minute_of_day)
    gen wage_high = avg_wage + sd_wage_mod
    gen wage_low = avg_wage - sd_wage_mod

    keep avg_wage wage_high wage_low minute_of_day
    rename avg_wage avg_wage_wday
    rename wage_high wage_high_wday
    rename wage_low wage_low_wday

    mmerge minute_of_day using "../temp/weekend_pattern.dta", type(1:1)
    assert _merge==3
    drop _merge

    gen hour_of_day = minute_of_day/60

    line avg_wage_wend avg_wage_wday hour_of_day, xlabel(0(2)24) ///
        lcolor(black black) lpattern(solid longdash) xtitle("Hour of day") ///
        ytitle("dollars/minute") xline(5 17) legend(label (1 "Weekend") ///
                                              label(2 "Weekday"))

    graph export "../output/appendixfigure3.pdf", replace
end

program save_weekend
    use "../input/clock_minute.dta", clear
    keep if ((dow == 5 | dow == 6) & minute_of_day > 17 * 60) | ///
        ((dow == 6 | dow == 0) & minute_of_day <= 17 * 60)
    egen sd_wage_mod = sd(avg_wage), by(minute_of_day)
    collapse avg_wage sd_wage_mod, by(minute_of_day)
    gen wage_high = avg_wage + sd_wage_mod
    gen wage_low = avg_wage - sd_wage_mod

    keep avg_wage wage_high wage_low minute_of_day
    rename avg_wage avg_wage_wend
    rename wage_high wage_high_wend
    rename wage_low wage_low_wend
    save "../temp/weekend_pattern.dta", replace
end

main
