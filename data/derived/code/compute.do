version 16
set more off
preliminaries

program main
    use "../temp/tripsheet_clean.dta", clear
    compute_working_hours
    compute_cumulative_variables
    minute_level
    save_data "../temp/tripsheet_noweather.dta", ///
        key(driver_id shift_id trip_id) replace
end

program compute_working_hours
    sort driver_id shift_id trip_id

    * Time elapsed between the end of this trip and
    * the beginning of the next trip of the shift
    * (except for the last trip of a shift)
    gen wait_duration = 0
    replace wait_duration = (pkp_time[_n+1] - drf_time)/60000 if !final_trip

    * Define break time (after the trip) a la Farber 2005:
    gen break_time = 0
    replace break_time = 1 if ///
        (wait_duration>30 & pkp_boro=="Manhattan" & drf_boro=="Manhattan") | ///
        (wait_duration>60 & (pkp_boro!="Manhattan" | drf_boro!="Manhattan") ///
            & !to_jfk & !to_lga & !to_ewr & drf_boro!="Non-NYC") | ///
        (wait_duration>90 & (to_jfk | to_lga | to_ewr | drf_boro=="Non-NYC"))

    * Define ALTERNATE break time (after the trip):
    gen break_time_m15 = 0
    replace break_time_m15 = 1 if ///
        (wait_duration>15 & pkp_boro=="Manhattan" & drf_boro=="Manhattan") | ///
        (wait_duration>45 & (pkp_boro!="Manhattan" | drf_boro!="Manhattan") ///
            & !to_jfk & !to_lga & !to_ewr & drf_boro!="Non-NYC") | ///
        (wait_duration>75 & (to_jfk | to_lga | to_ewr | drf_boro=="Non-NYC"))

    gen break_time_p15 = 0
    replace break_time_p15 = 1 if ///
        (wait_duration>45 & pkp_boro=="Manhattan" & drf_boro=="Manhattan") | ///
        (wait_duration>75 & (pkp_boro!="Manhattan" | drf_boro!="Manhattan") ///
            & !to_jfk & !to_lga & !to_ewr & drf_boro!="Non-NYC") | ///
        (wait_duration>105 & (to_jfk | to_lga | to_ewr | drf_boro=="Non-NYC"))


    * Total trip duration according to Crawford and Meng 2011: ride duration
    * + wait time prior to this trip (if it's not break time)
    * + break time after this trip (if it's indeed break time)
    gen total_duration_cm = 0
    replace total_duration_cm = ride_duration ///
        + (wait_duration[_n-1] * (1 - break_time[_n-1])) ///
        + (wait_duration * break_time) if trip_id!=1
    replace total_duration_cm = ride_duration if trip_id==1

    gen total_duration = ride_duration + wait_duration[_n-1] if _n!=1
    replace total_duration = ride_duration if _n==1

    gen work_duration = (drf_time - drf_time[_n-1]) / 1000 / 60
    replace work_duration = (drf_time - pkp_time) / 1000 / 60 ///
        if trip_id==1 | break_time[_n-1]

    gen work_duration_m15 = (drf_time - drf_time[_n-1]) / 1000 / 60
    replace work_duration_m15 = (drf_time - pkp_time) / 1000 / 60 ///
        if trip_id==1 | break_time_m15[_n-1]

    gen work_duration_p15 = (drf_time - drf_time[_n-1]) / 1000 / 60
    replace work_duration_p15 = (drf_time - pkp_time) / 1000 / 60 ///
        if trip_id==1 | break_time_p15[_n-1]

    gen holiday = pkp_date==mdy(1, 1, 2013) | pkp_date==mdy(5, 27, 2013) | ///
        pkp_date==mdy(7, 4, 2013) | pkp_date==mdy(9, 2, 2013) | ///
        pkp_date==mdy(11, 28, 2013) | pkp_date==mdy(12, 25, 2013)
end

program compute_cumulative_variables
    gen income = fare + surcharge
    gen income_tip = income + tip

    oo Computing cumulative income per shift
    by driver_id shift_id: gen cum_income = sum(income)
    by driver_id shift_id: gen cum_tip = sum(tip)
    gen cum_income_tip = cum_income + cum_tip

    oo Computing cumulative work/ride/total minutes per shift
    by driver_id shift_id: gen cum_work_duration = sum(work_duration)
    by driver_id shift_id: gen cum_ride_duration = sum(ride_duration)
    by driver_id shift_id: gen cum_total_duration_cm = sum(total_duration_cm)
    by driver_id shift_id: gen cum_total_duration = sum(total_duration)
end

program minute_level
    gen minute_miles = distance / ride_duration
    gen minute_wage = income / work_duration
end

* Execute
main
