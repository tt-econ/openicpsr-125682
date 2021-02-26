version 16
set more off
preliminaries

program main
    global year 2013

    global newark "EWR"
    global central_park "NYC"
    global lga "LGA"
    global jfk "JFK"
    global long_island "FRG"
    global stations $newark $central_park $lga $jfk $long_island

    merge_wind_rain
    append_stations
    process_clock
    impute_weather
    process_weather

    * In 2013 we do not have NYC station data from June to December
    foreach w in rain temp windtwomin windfivesec {
        replace `w'NYC = . if month > 5
    }

    save_data "../output_local/minute_weather$year.dta", ///
        key(year month day hour minute) replace
end

program merge_wind_rain
    foreach station of global stations {

        if "`station'"=="NYC" & $year==2013 {
            infix str stationid 11-13 str year 14-17 str month 18-19 ///
                str day 20-21 str hour 22-23 str minute 24-25 ///
                str weather_rain 33-34 str weather_temp 95-98 ///
                using "../temp/`station'_rain_$year.dat", clear
            duplicates drop year month day hour minute, force
            save "../temp/windrain_`station'.dta", replace

            infix str stationid 11-13 str year 14-17 str month 18-19 ///
                str day 20-21 str hour 22-23 str minute 24-25 ///
                str weather_windtwomin 78-79 str weather_windfivesec 88-89 ///
                using "../temp/`station'_wind_$year.dat", clear
            duplicates drop year month day hour minute, force
        }
        else {
            infix str stationid 11-13 str year 14-17 str month 18-19 ///
                str day 20-21 str hour 22-23 str minute 24-25 ///
                str weather_rain 32-33 str weather_temp 95-98 ///
                using "../temp/`station'_rain_$year.dat", clear
            duplicates drop year month day hour minute, force
            save "../temp/windrain_`station'.dta", replace

            infix str stationid 11-13 str year 14-17 str month 18-19 ///
                str day 20-21 str hour 22-23 str minute 24-25 ///
                str weather_windtwomin 76-77 str weather_windfivesec 87-88 ///
                using "../temp/`station'_wind_$year.dat", clear
            duplicates drop year month day hour minute, force
        }

        merge 1:1 year month day hour minute using ///
            "../temp/windrain_`station'.dta", keep(matched master)
        drop _merge
        save "../temp/windrain_`station'.dta", replace
    }
end

program append_stations
    local first_sheet 1
    foreach station of global stations {
        use "../temp/windrain_`station'.dta"
        if !`first_sheet' append using "../temp/minute_weather$year.dta", force
        save "../temp/minute_weather$year.dta", replace
        local first_sheet 0
    }
    duplicates drop year month day hour minute stationid, force
    reshape wide weather*, i(year month day hour minute) j(stationid) string
    save "../temp/minute_weather$year.dta", replace
end

program process_clock
    destring month day year hour minute, replace
    capture gen date = mdy(month,day,year)
    capture replace date = dofc(clock)
    format date %td
    capture gen double clock = dhms(date, hour, minute, 0)
    capture replace double clock = dhms(date, hour, minute, 0)
    format clock %tc
    tsset clock, delta(1 min)
    replace year = year(date)
    replace month = month(date)
    replace day = day(date)
    replace hour = hh(clock)
    replace minute = mm(clock)
    save "../temp/minute_weather$year.dta", replace
end

program impute_weather
    fill
    merge 1:1 clock using "../temp/minute_weather$year.dta", ///
        keep(matched master)
    process_clock
    gen needs_imputation = (_merge==1)
    oo number of missing observations
    bys month: tab needs_imputation
    drop _merge needs_imputation
    imputation
end

    program fill
        clear
        set obs 2
        gen date = mdy(1,1,$year)
        gen double clock = dhms(date, 0, 0, 0)
        format clock %tc
        replace date = mdy(12,31,$year) if _n==_N
        replace clock = dhms(date, 23, 59, 00) if _n==_N
        drop date
        tsset(clock), delta(1 min)
        tsfill
    end

    program imputation
        gsort clock
        foreach w of varlist weather* {
            capture replace `w' = `w'[_n-1] if `w' == ""
            capture replace `w' = `w'[_n-1] if `w' == .
        }
    end

program process_weather
    pre_process_rain
    destring weather*, replace force
    post_process_rain
    imputation
    convert_knots

    rename_vars
    save "../temp/minute_weather$year.dta", replace
end

    program pre_process_rain
        foreach station of global stations {
            gen rainy_weather_rain`station' = ///
                (weather_rain`station'!="NP" & weather_rain`station'!=" M")
            gen norain_weather_rain`station' = (weather_rain`station'=="NP")
        }
    end

    program post_process_rain
        foreach station of global stations {
            replace weather_rain`station' = 1 if rainy_weather_rain`station'
            replace weather_rain`station' = 0 if norain_weather_rain`station'
        }
        drop *_weather_rain*
    end

    program convert_knots
        foreach w of varlist weather_wind* {
            replace `w' = 1.151 * `w'
        }
    end

    program rename_vars
        renpfix weather_
    end


* Execute
main

