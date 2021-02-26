version 16
preliminaries

program main
    forvalues m=1/12 {
        create_template `m'
        split_minute `m'
        merge_weather
        save ../temp/clock_minute_`m'.dta, replace
    }

    use ../temp/clock_minute_1.dta, clear
    forvalues m=2/12 {
        append using ../temp/clock_minute_`m'.dta
    }

    foreach weather in rain wind temp {
        oo `weather' information by clock hour
        tab `weather'
        tab `weather' dow
        tab `weather' month
    }

   save ../output_local/clock_minute.dta, replace
end

program create_template
    args m

    clear
    set obs 2
    gen date = mdy(`m', 1, 2013)
    gen double clock = dhms(date, 0, 0, 0)
    format clock %tc
    if `m'==12 {
        replace date = mdy(12, 31, 2013) if _n==_N
    }
    else {
        replace date = mdy(`m' + 1, 1, 2013) - 1 if _n==_N
    }
    replace clock = dhms(date, 23, 59, 00) if _n==_N
    drop date
    tsset(clock), delta(1 min)
    tsfill
    save ../temp/minute_master.dta, replace
end

program split_minute
    args m

    use driver_id shift_id trip_id break_time final_trip pkp_boro drf_boro ///
        pkp_time drf_time minute_wage minute_miles distance ///
        non_nyc_trip income holiday drf_date pkp_date ///
        using ../input/taxi.dta, clear
    if `m'!= 12 {
        keep if drf_date >= mdy(`m', 1, 2013) & pkp_date < mdy(`m' + 1, 1, 2013)
    }
    else {
        keep if drf_date >= mdy(`m', 1, 2013) & pkp_date < mdy(1, 1, 2014)
    }
    sort driver_id shift_id trip_id
    sum driver_id

    save ../temp/trips.dta, replace

    gen double wage_start = drf_time[_n-1]
    gen double wage_end = drf_time

    oo In wage analysis, do not count first trip after a break period
    drop if trip_id==1 | break_time[_n-1]

    oo Drop non-Manhattan start and end trips
    drop if pkp_boro!="Manhattan":boro & drf_boro!="Manhattan":boro
    oo Drop if not-NYC trip
    drop if non_nyc_trip

    keep driver_id shift_id trip_id wage_start wage_end minute_wage income
    process_minute_wage

    use ../temp/trips.dta, clear
    oo Drop non-Manhattan start and end trips
    drop if pkp_boro!="Manhattan":boro & drf_boro!="Manhattan":boro
    oo Drop non-NYC trips
    drop if non_nyc_trip
    keep driver_id shift_id trip_id pkp_time drf_time minute_miles distance ///
        break_time final_trip
    process_minute_miles
end

    program process_minute_wage
        ooo Process minute wage and work-duration variables

        oo total minutes in a trip
        gen total_mins = (wage_end - wage_start) / 1000 / 60
        oo expand each trip by the number of minutes in that trip
        expand total_mins
        oo count the minutes in a trip
        bys driver_id shift_id trip_id: gen mincount = _n
        oo generate the current clock minute based on wage_start minute
        gen double clock_tmp = wage_start + (mincount - 1) * 1000 * 60
        format clock_tmp %tc
        gen double clock = dhms(dofc(clock_tmp), hh(clock_tmp), mm(clock_tmp), 0)
        format clock %tc
        drop clock_tmp wage_start wage_end shift_id trip_id

        sort clock driver_id

        oo average wage and average log wage
        gen lwage = log(minute_wage)
        by clock: egen avg_lwage = mean(lwage)
        by clock: egen avg_wage = mean(minute_wage)
        by clock: egen sd_lwage = sd(lwage)
        by clock: egen sd_wage = sd(minute_wage)

        oo number of drivers with a positive minute wage in this minute
        by clock: egen driver_work = total(minute_wage > 0)

        oo only consider trips starting this minute for work duration / income
        replace total_mins = . if mincount>1
        gen ltotal_mins = log(total_mins)
        by clock: egen avg_work_duration = mean(total_mins)
        by clock: egen avg_lwork_duration = mean(ltotal_mins)
        replace income = . if mincount>1
        gen lincome = log(income)
        by clock: egen avg_income = mean(income)
        by clock: egen avg_lincome = mean(lincome)

        oo collapse to minute-level data
        egen tagclock = tag(clock)
        keep if tagclock
        drop driver_id tagclock total_mins ltotal_mins mincount ///
            minute_wage lwage lincome

        foreach v in avg_wage driver_work {
                gen l`v' = log(`v')
        }

        mmerge clock using ../temp/minute_master.dta, type(1:1) unmatched(using)
        save ../temp/minute_master.dta, replace
    end

    program process_minute_miles
        ooo Process minute miles and ride-duration variables

        gen total_mins = (drf_time - pkp_time) / 1000 / 60
        expand total_mins
        bys driver_id shift_id trip_id: gen mincount = _n
        gen double minute = pkp_time + (mincount - 1) * 1000 * 60
        format minute %tc
        gen double clock = dhms(dofc(minute), hh(minute), mm(minute), 0)
        format clock %tc
        drop minute pkp_time drf_time shift_id

        oo average miles and average log miles
        sort clock driver_id
        gen lmiles = log(minute_miles)
        gen ldistance = log(distance)
        by clock: egen avg_lmiles = mean(lmiles)
        by clock: egen avg_miles = mean(minute_miles)

        oo number of drivers with a positive minute wage in this minute
        by clock: egen driver_ride = total(minute_miles > 0)

        oo drivers who start working beginning the minute this trip starts
        by clock: egen resume = total(break_time[_n-1] & mincount==1)
        by clock: egen startshift = total(trip_id==1 & mincount==1)

        oo drivers who stop working beginning the minute this trip ends
        by clock: egen takebreak = total(break_time[_n] & ///
                                         mincount==round(total_mins))
        by clock: egen endshift = total(final_trip & ///
                                        mincount==round(total_mins))

        gen get_rest = takebreak + endshift
        gen get_going = resume + startshift

        oo only consider ride durations of ride trip starting this minute
        replace total_mins = . if mincount>1
        gen ltotal_mins = log(total_mins)
        by clock: egen avg_ride_duration = mean(total_mins)
        by clock: egen avg_lride_duration = mean(ltotal_mins)

        oo only consider ride distance of ride trip starting this minute
        replace distance = . if mincount>1
        by clock: egen avg_ldistance = mean(ldistance)
        by clock: egen avg_distance = mean(distance)

        egen tagclock = tag(clock)
        keep if tagclock
        drop driver_id tagclock minute_miles lmiles ldistance distance ///
            total_mins ltotal_mins mincount trip_id final_trip break_time

        foreach v in avg_miles driver_ride resume startshift ///
            takebreak endshift get_rest get_going {
               gen l`v' = log(`v')
        }

        mmerge clock using ../temp/minute_master.dta, type(1:1) unmatched(using)
        save ../temp/minute_master.dta, replace
    end

program merge_weather
    use ../temp/minute_master.dta, clear
    mmerge clock using ../input/minute_weather2013.dta, ///
        type(n:1) unmatched(master) ukeep(rainNYC tempNYC windtwominNYC ///
                                         rainLGA tempLGA windtwominLGA)
    drop _merge

    gen date = dofc(clock)
    gen hour = hh(clock)
    gen minute = mm(clock)
    gen minute_of_day = hh(clock) * 60 + minute

    gen dow = dow(date)
    gen woy = week(date)

    gen month = month(date)

    rename tempNYC tempf
    rename windtwominNYC windspdmph
    rename rainNYC rain

    replace tempf = tempLGA if tempf == .
    replace windspdmph = windtwominLGA if windspdmph == .
    replace rain = rainLGA if rain == .

    gen wind = 0
    replace wind = 1 if windspdmph > 0 & windspdmph <= 3
    replace wind = 2 if windspdmph > 3 & windspdmph <= 7
    replace wind = 3 if windspdmph > 7 & windspdmph <= 12
    replace wind = 4 if windspdmph > 12 & windspdmph <= 17
    replace wind = 5 if windspdmph > 17 & windspdmph <= 24
    replace wind = 6 if windspdmph > 24

    gen temp = 0
    replace temp = 1 if tempf < 30
    replace temp = 2 if tempf > 80

    label define rain_label 0 "No rain" 1 "Rain"
    label values rain rain_label

    label define wind_label 0 "Beaufort 0" 1 "Beaufort 1" 2 "Beaufort 2" ///
        3 "Beaufort 3" 4 "Beaufort 4" 5 "Beaufort 5" 6 "Beaufort 6+"
    label values wind wind_label

    label define temp_label 0 "30F-80F" 1 "<30F" 2 ">80F"
    label values temp temp_label
end

* Execute
main

