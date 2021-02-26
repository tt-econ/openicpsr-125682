version 16
preliminaries

program main
    get_daily_weather

    use woy dow hour minute avg_wage clock ///
        using "../input/clock_minute.dta", clear

    mmerge woy dow using "../temp/weather_daily.dta", type(n:1) ///
        ukeep(rain temphigh templow holiday) unmatched(master)

    bysort woy dow (hour minute): egen day_wage = sum(avg_wage)
    keep if hour==1 & minute==1
    drop minute hour
    tsset, delta(1 day)

    oooo Residualized after day of week, week of year
    corr_withinteraction
end

program get_daily_weather
    use "../input/minute_weather2013.dta", clear
    keep date hour minute rainNYC tempNYC
    gen dow = dow(date)
    gen woy = week(date)

    replace rainNYC = 0 if rainNYC==.

    bysort woy dow (hour minute): egen rain = max(rainNYC)
    bysort woy dow (hour minute): egen temp = mean(tempNYC)
    egen tag_day = tag(woy dow)
    keep if tag_day
    drop tag_day rainNYC tempNYC
    gen temphigh = temp > 80
    gen templow = temp < 30
    replace temphigh = . if temp==.
    replace templow = . if temp==.

    gen holiday = date==mdy(1, 1, 2013) | date==mdy(5, 27, 2013) | ///
        date==mdy(7, 4, 2013) | date==mdy(9, 2, 2013) | ///
        date==mdy(11, 28, 2013) | date==mdy(12, 25, 2013)

    save "../temp/weather_daily.dta", replace
end

program corr_withinteraction
    reg day_wage i.dow i.woy i.holiday i.rain i.temphigh i.templow
    predict res_day_wage, resid
    tsset, delta(1 day)
    corrgram res_day_wage
    ac res_day_wage, lags(10) note("") ///
        ytitle("Autocorrelation of residualized daily market wage")
    graph export "../output/appendixfigure8.pdf", replace

    forval i=1/10 {
        reg F`i'.res_day_wage res_day_wage
    }

    drop res_day_wage
end

main
