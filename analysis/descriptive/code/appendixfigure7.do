version 16
preliminaries

program main
    get_hourly_weather

    use woy dow hour minute avg_wage clock ///
        using "../input/clock_minute.dta", clear

    mmerge woy dow hour using "../temp/weather_hourly.dta", type(n:1) ///
        ukeep(rain temphigh templow holiday) unmatched(master)

    bysort woy dow hour (minute): egen hour_wage = sum(avg_wage)
    keep if minute==1
    drop minute
    tsset, delta(1 hour)

    oooo Residualized after hour of day x day of week, week of year
    corr_withinteraction
end

program get_hourly_weather
    use "../input/minute_weather2013.dta", clear
    keep date hour minute rainNYC tempNYC
    gen dow = dow(date)
    gen woy = week(date)

    replace rainNYC = 0 if rainNYC==.

    bysort woy dow hour (minute): egen rain = max(rainNYC)
    bysort woy dow hour (minute): egen temp = mean(tempNYC)
    egen tag_hour = tag(woy dow hour)
    keep if tag_hour
    drop tag_hour rainNYC tempNYC
    gen temphigh = temp > 80
    gen templow = temp < 30
    replace temphigh = . if temp==.
    replace templow = . if temp==.

    gen holiday = date==mdy(1, 1, 2013) | date==mdy(5, 27, 2013) | ///
        date==mdy(7, 4, 2013) | date==mdy(9, 2, 2013) | ///
        date==mdy(11, 28, 2013) | date==mdy(12, 25, 2013)

    save "../temp/weather_hourly.dta", replace
end

program corr_withinteraction
    reg hour_wage i.hour#i.dow i.woy i.holiday i.rain i.temphigh i.templow
    predict res_hour_wage, resid
    tsset, delta(1 hour)
    corrgram res_hour_wage
    ac res_hour_wage, lags(10) note("") ///
        ytitle("Autocorrelation of residualized hourly market wage")
    graph export "../output/appendixfigure7.pdf", replace

    forval i=1/10 {
        reg F`i'.res_hour_wage res_hour_wage
    }

    drop res_hour_wage
end

main
