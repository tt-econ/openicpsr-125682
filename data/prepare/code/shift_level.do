version 16
preliminaries

program main
    use car_id driver_id shift_id trip_id break_time pkp_date shift* payment_type ///
        ride_duration wait_duration work_duration fare surcharge income tip ///
        near* minute_wage non_nyc_shift driver_* holiday ///
        hack_license pkp_minute ///
        using ../input/taxi.dta, clear
    sort driver_id shift_id trip_id

    define_tip_vars
    define_income_hour_vars
    define_temperature

    drop if trip_id==1 | break_time[_n-1]
    individual_slope

    egen tag_shift = tag(driver_id shift_id)
    keep if tag_shift
    drop tag_shift trip_id pkp_date break_time ride_duration wait_duration ///
        fare surcharge payment_type tip income near* minute_wage pkp_minute
    define_shift_type
    define_driver_type

    label_vars
    save_data ../output_local/taxi_shift.dta, replace key(driver_id shift_id)
end

program define_tip_vars
    by driver_id shift_id: egen shift_credit_income = ///
        total(income * (payment_type=="credit":payment))
    by driver_id shift_id: egen shift_tip_income = ///
        total(tip * (payment_type=="credit":payment))
    by driver_id shift_id: egen num_credit_trips ///
        = total(payment_type=="credit":payment)
end

program define_income_hour_vars
    oo Compute shift start-time variables
    by driver_id shift_id: egen shift_date = min(pkp_date)
    by driver_id shift_id: egen shift_last_date = max(pkp_date)
    gen shift_year = year(shift_date)
    gen shift_month = month(shift_date)
    gen shift_day = day(shift_date)
    gen shift_dayofweek = dow(shift_date)
    gen shift_weekofyear = week(shift_date)
    by driver_id shift_id: gen shift_min = pkp_minute[1]

    oo Computing riding hours per shift
    gen shift_total_hours = shift_total_mins / 60
    by driver_id shift_id: egen shift_ride_hours = total(ride_duration / 60)

    oo Computing break hours per shift
    by driver_id shift_id: ///
        egen shift_break_hours = total(wait_duration * break_time / 60)

    oo Computing work hours per shift
    gen shift_work_hours = shift_total_hours - shift_break_hours

    oo Computing income per shift
    by driver_id shift_id: egen shift_total_income = total(income)

    oo Computing hour wage per shift
    by driver_id shift_id: gen shift_total_wage = ///
        shift_total_income / shift_total_hours

    gen shift_work_wage = shift_total_income / shift_work_hours

    gen shift_wait_hours = shift_work_hours - shift_ride_hours
    gen shift_ride_ratio = shift_ride_hours / shift_work_hours
    gen shift_work_ratio = shift_work_hours / shift_total_hours
end

program define_shift_type
    oo Hank's definition of shift type
    gen shift_type_hf = 0
    replace shift_type_hf = 1 if shift_start>=4 & shift_start<10
    replace shift_type_hf = 2 if shift_start>=14 & shift_start<20

    oo weekend night
    gen weekend_night_start = (shift_start >= 16 & shift_dayofweek >= 5) ///
        | (shift_start < 4 & shift_end <= 4 & ///
        (shift_dayofweek == 6 | shift_dayofweek == 0))
    gen weekend_night_end = (shift_end >= 16 & shift_dayofweek >= 5) ///
        | (shift_end <= 4 & (shift_dayofweek == 6 | shift_dayofweek == 0))
    gen weekend_night = weekend_night_start & weekend_night_end
    drop weekend_night_start weekend_night_end

    oo weekend day
    gen weekend_day_start = (shift_start >= 4 & shift_start < 16) ///
        & (shift_dayofweek == 6 | shift_dayofweek == 0) ///
        & shift_date == shift_last_date
    gen weekend_day_end = (shift_end >= 4 & shift_end <= 16) ///
        & (shift_dayofweek == 6 | shift_dayofweek == 0) ///
        & shift_date == shift_last_date
    gen weekend_day = weekend_day_start & weekend_day_end
    drop weekend_day_start weekend_day_end

    oo weekday night
    gen weekday_night_start = (shift_start >= 16 & shift_dayofweek <= 5) ///
        | (shift_start < 4 & (shift_dayofweek ~= 6 & shift_dayofweek ~= 0))
    gen weekday_night_end = (shift_end >= 16 & shift_dayofweek <= 5) ///
        | (shift_end <= 4 & (shift_dayofweek ~= 6 & shift_dayofweek ~= 0))
    gen weekday_night = weekday_night_start & weekday_night_end
    drop weekday_night_start weekday_night_end

    oo weekday day
    gen weekday_day_start = (shift_start >= 4 & shift_start < 16) ///
        & (shift_dayofweek ~= 6 & shift_dayofweek ~= 0) ///
        & shift_date == shift_last_date
    gen weekday_day_end = (shift_end >= 4 & shift_end <= 16) ///
        & (shift_dayofweek ~= 6 & shift_dayofweek ~= 0) ///
        & shift_date == shift_last_date
    gen weekday_day = weekday_day_start & weekday_day_end
    drop weekday_day_start weekday_day_end

    oo night shift
    gen night_shift = .
    replace night_shift = 1 if weekday_night | weekend_night
    replace night_shift = 0 if weekday_day | weekend_day
end

program define_driver_type
    oo medallion owner driver
    gen owner_driver = driver_numcars==1 ///
        & driver_numshifts>210*.75

    oo driver under shift constraints
    by driver_id: egen driver_numothershifts = total(night_shift==.)
end

program define_temperature
    egen rain = max(near_rain), by(driver_id shift_id)
    egen avg_wind = mean(near_wind), by(driver_id shift_id)

    egen min_temp = min(near_temp), by(driver_id shift_id)
    egen max_temp = max(near_temp), by(driver_id shift_id)

    gen wind = 0
    replace wind = 1 if avg_wind>=4 & avg_wind<13
    replace wind = 2 if avg_wind>=13

    gen temp = 0
    replace temp = 1 if min_temp < 30
    replace temp = 2 if max_temp > 80
end

program individual_slope
    by driver_id shift_id: egen tripcount = count(trip_id)

    gen enough_trips = tripcount >= 3

    by driver_id shift_id: egen meanx = mean(minute_wage)
    by driver_id shift_id: egen meany = mean(trip_id)

    gen xy = (trip_id - meany) * (minute_wage - meanx)
    gen xx = (trip_id - meany)^2

    by driver_id shift_id: egen sumxy = total(xy)
    by driver_id shift_id: egen sumxx = total(xx)

    gen beta = sumxy / sumxx

    drop xy xx meanx meany tripcount sumxx sumxy
end

program label_vars
    label var shift_total_hours "Total hours in a shift including wait time"
    label var shift_ride_hours  "Hours in a shift spent riding in a trip"
    label var shift_work_hours  "Hours in a shift spent searching and riding in a trip"
    label var shift_break_hours "Hours in a shift being on a break (as defined by Farber 2005)"
    label var shift_dayofweek   "Day of the week of trip pick-up time (0 = Sunday, 6 = Saturday)"
    label define dow_label 0 "SUN" 1 "MON" 2 "TUE" 3 "WED" 4 "THU" 5 "FRI" 6 "SAT"
    label values shift_dayofweek dow_label
    label var shift_total_income "Total fare and surcharge earned in a shift"
    label var shift_total_wage    "Average wage per hour during the whole shift including minutes spent waiting"
    label var shift_work_wage    "Average wage per hour during working hours"
    label var shift_wait_hours "Hours in a shift spent looking for the next ride"
    label var shift_ride_ratio "Ratio of riding time over working time"
    label var shift_work_ratio "Ratio of working time over total shift time"

    label define shift_type_label 0 "Other shift" 1 "Day Shift" 2 "Night Shift"
    label values shift_type_hf shift_type_label

    label define owner_type_label 0 "Not owning a medallion" 1 "Owning a medallion"
    label values owner_driver owner_type_label

    label values rain rain_label

    label define wind_label_coarse 0 "Scale 0-1" 1 "Scale 2-3" 2 "Scale 4+"
    label values wind wind_label_coarse

    label values temp temp_label
end

* Execute
main
