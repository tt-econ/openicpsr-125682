version 16
preliminaries

program main
    global time_controls "i.drf_hour#i.drf_dayofweek i.shift_date"
    global weather_controls "near_rain i.near_temp_c i.near_wind_c"
    global location_controls "i.drf_nta"
    global all_controls_except_id "$time_controls $weather_controls $location_controls"

    file open basefile using ../temp/basefile.txt, write replace

    forval i = 5 / 10 {
        use ../output_local/taxi_`i'h30m.dta, clear
        append using ../output_local/taxi_`i'h.dta
        gen cond30 = cum_total_duration >= `i'*60 + 25 & cum_total_duration <= `i'*60 + 35
        gen cond15 = cum_total_duration >= `i'*60 + 10 & cum_total_duration <= `i'*60 + 20
        gen cond45 = cum_total_duration >= `i'*60 + 40 & cum_total_duration <= `i'*60 + 50
        forval j = 15(15)45 {
            sum final_trip if cond`j'
            write_glob "base`i'h`j'm" `r(mean)'
            sum cum_income if cond`j'
            write_glob "baseincome`i'h`j'm" `r(mean)'
            sum final_trip if cond`j' & shift_start >= 4 & shift_start < 10
            write_glob "base`i'h`j'm_day" `r(mean)'
            sum cum_income if cond`j' & shift_start >= 4 & shift_start < 10
            write_glob "baseincome`i'h`j'm_day" `r(mean)'
            sum final_trip if cond`j' & (shift_dayofweek != 6 & shift_dayofweek != 0) & shift_start >= 4 & shift_start < 10
            write_glob "base`i'h`j'm_day_weekday" `r(mean)'
            sum cum_income if cond`j' & (shift_dayofweek != 6 & shift_dayofweek != 0) & shift_start >= 4 & shift_start < 10
            write_glob "baseincome`i'h`j'm_day_weekday" `r(mean)'
            sum final_trip if cond`j' & (shift_dayofweek == 6 | shift_dayofweek == 0) & shift_start >= 4 & shift_start < 10
            write_glob "base`i'h`j'm_day_weekend" `r(mean)'
            sum cum_income if cond`j' & (shift_dayofweek == 6 | shift_dayofweek == 0) & shift_start >= 4 & shift_start < 10
            write_glob "baseincome`i'h`j'm_day_weekend" `r(mean)'
            sum final_trip if cond`j' & shift_start >= 14 & shift_start < 20
            write_glob "base`i'h`j'm_night" `r(mean)'
            sum cum_income if cond`j' & shift_start >= 14 & shift_start < 20
            write_glob "baseincome`i'h`j'm_night" `r(mean)'
            sum final_trip if cond`j' & shift_dayofweek < 5 & shift_start >= 14 & shift_start < 20
            write_glob "base`i'h`j'm_night_weekday" `r(mean)'
            sum cum_income if cond`j' & shift_dayofweek < 5 & shift_start >= 14 & shift_start < 20
            write_glob "baseincome`i'h`j'm_night_weekday" `r(mean)'
            sum final_trip if cond`j' & shift_dayofweek >= 5 & shift_start >= 14 & shift_start < 20
            write_glob "base`i'h`j'm_night_weekend" `r(mean)'
            sum cum_income if cond`j' & shift_dayofweek >= 5 & shift_start >= 14 & shift_start < 20
            write_glob "baseincome`i'h`j'm_night_weekend" `r(mean)'
        }
    }

    forval i = 5 / 10 {
        local k = `i' - 1
        use ../output_local/taxi_`i'h.dta if cum_total_duration <= `i'*60 + 5, clear
        append using ../output_local/taxi_`k'h30m.dta
        gen cond0 = cum_total_duration >= `i'*60 - 5 & cum_total_duration <= `i'*60 + 5
        sum final_trip
        write_glob "base`i'h" `r(mean)'
        sum cum_income
        write_glob "baseincome`i'h" `r(mean)'
        sum final_trip if cond0 & shift_start >= 4 & shift_start < 10
        write_glob "base`i'h_day" `r(mean)'
        sum cum_income if cond0 & shift_start >= 4 & shift_start < 10
        write_glob "baseincome`i'h_day" `r(mean)'
        sum final_trip if cond0 & (shift_dayofweek != 6 & shift_dayofweek != 0) & shift_start >= 4 & shift_start < 10
        write_glob "base`i'h_day_weekday" `r(mean)'
        sum cum_income if cond0 & (shift_dayofweek != 6 & shift_dayofweek != 0) & shift_start >= 4 & shift_start < 10
        write_glob "baseincome`i'h_day_weekday" `r(mean)'
        sum final_trip if cond0 & (shift_dayofweek == 6 | shift_dayofweek == 0) & shift_start >= 4 & shift_start < 10
        write_glob "base`i'h_day_weekend" `r(mean)'
        sum cum_income if cond0 & (shift_dayofweek == 6 | shift_dayofweek == 0) & shift_start >= 4 & shift_start < 10
        write_glob "baseincome`i'h_day_weekend" `r(mean)'
        sum final_trip if cond0 & shift_start >= 14 & shift_start < 20
        write_glob "base`i'h_night" `r(mean)'
        sum cum_income if cond0 & shift_start >= 14 & shift_start < 20
        write_glob "baseincome`i'h_night" `r(mean)'
        sum final_trip if cond0 & shift_dayofweek < 5 & shift_start >= 14 & shift_start < 20
        write_glob "base`i'h_night_weekday" `r(mean)'
        sum cum_income if cond0 & shift_dayofweek < 5 & shift_start >= 14 & shift_start < 20
        write_glob "baseincome`i'h_night_weekday" `r(mean)'
        sum final_trip if cond0 & shift_dayofweek >= 5 & shift_start >= 14 & shift_start < 20
        write_glob "base`i'h_night_weekend" `r(mean)'
        sum cum_income if cond0 & shift_dayofweek >= 5 & shift_start >= 14 & shift_start < 20
        write_glob "baseincome`i'h_night_weekend" `r(mean)'
    }

    file close basefile

end

program write_glob
    args name number

    file write basefile "`name' `number'" _n
end

* Execute
main
