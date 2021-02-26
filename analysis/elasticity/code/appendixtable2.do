version 16
preliminaries, matsize(11000) maxvar(20000)

program main
    create_iv

    matrix appendixtable2 = J(8, 2, .)

    use driver_id shift_id shift_date shift_total_hours shift_total_wage ///
        shift_type_hf shift_dayofweek shift_weekofyear holiday ///
        using ../input/taxi_shift.dta if driver_id > 2500, clear

    rename shift_date pkp_date

    mmerge pkp_date using ../temp/iv.dta, type(n:1) ukeep(shift_others_wage) unmatched(master)

    global time_controls "i.shift_dayofweek i.shift_weekofyear holiday"

    xtset driver_id shift_id

    gen lshift_total_hours = log(shift_total_hours)
    gen lshift_total_wage = log(shift_total_wage)

    gen lshift_others_wage = log(shift_others_wage)
    gen weekend_day = (shift_dayofweek == 6 | shift_dayofweek == 0)
    gen weekend_night = (shift_dayofweek >= 5)

    bysort driver_id: egen group_weekend_day = total(weekend_day & shift_type_hf == 1)
    bysort driver_id: egen group_weekday_day = total(~weekend_day & shift_type_hf == 1)
    bysort driver_id: egen group_weekend_night = total(weekend_night & shift_type_hf == 2)
    bysort driver_id: egen group_weekday_night = total(~weekend_night & shift_type_hf == 2)

    ols_night_week
    ols_day_week
    iv_night_week
    iv_day_week

    matrix_to_txt, matrix(appendixtable2) saving(../output/appendixtable2.txt) title(<tab:appendixtable2>) replace
end

program iv_night_week
    oo IV: night, weekday
    xtivreg lshift_total_hours (lshift_total_wage = lshift_others_wage) $time_controls ///
        if shift_type_hf == "Night Shift":shift_type_label ///
        & ~weekend_night & group_weekend_night & group_weekday_night, ///
        fe vce(cluster driver_id)
    lincom _b[lshift_total_wage]
    matrix appendixtable2[5, 2] = r(estimate)
    matrix appendixtable2[6, 2] = r(se)

    oo IV: night, weekend
    xtivreg lshift_total_hours (lshift_total_wage = lshift_others_wage) $time_controls ///
        if shift_type_hf == "Night Shift":shift_type_label ///
        & weekend_night & group_weekend_night & group_weekday_night, ///
        fe vce(cluster driver_id)
    lincom _b[lshift_total_wage]
    matrix appendixtable2[7, 2] = r(estimate)
    matrix appendixtable2[8, 2] = r(se)
end

program iv_day_week
    oo IV: day, weekday
    xtivreg lshift_total_hours (lshift_total_wage = lshift_others_wage) $time_controls ///
        if shift_type_hf == "Day Shift":shift_type_label ///
        & ~weekend_day & group_weekend_day & group_weekday_day, ///
        fe vce(cluster driver_id)
    lincom _b[lshift_total_wage]
    matrix appendixtable2[1, 2] = r(estimate)
    matrix appendixtable2[2, 2] = r(se)

    oo IV: day, weekend
    xtivreg lshift_total_hours (lshift_total_wage = lshift_others_wage) $time_controls ///
        if shift_type_hf == "Day Shift":shift_type_label ///
        & weekend_day & group_weekend_day & group_weekday_day, ///
        fe vce(cluster driver_id)
    lincom _b[lshift_total_wage]
    matrix appendixtable2[3, 2] = r(estimate)
    matrix appendixtable2[4, 2] = r(se)
end

program ols_night_week
    oo OLS: night, weekday
    areg lshift_total_hours lshift_total_wage $time_controls ///
        if shift_type_hf == "Night Shift":shift_type_label ///
        & ~weekend_night & group_weekend_night & group_weekday_night, ///
        absorb(driver_id) vce(cluster driver_id)
    lincom _b[lshift_total_wage]
    matrix appendixtable2[5, 1] = r(estimate)
    matrix appendixtable2[6, 1] = r(se)

    oo OLS: night, weekend
    areg lshift_total_hours lshift_total_wage $time_controls ///
        if shift_type_hf == "Night Shift":shift_type_label ///
        & weekend_night & group_weekend_night & group_weekday_night, ///
        absorb(driver_id) vce(cluster driver_id)
    lincom _b[lshift_total_wage]
    matrix appendixtable2[7, 1] = r(estimate)
    matrix appendixtable2[8, 1] = r(se)
end

program ols_day_week
    oo OLS: day, weekday
    areg lshift_total_hours lshift_total_wage $time_controls ///
        if shift_type_hf == "Day Shift":shift_type_label ///
        & ~weekend_day & group_weekend_day & group_weekday_day, ///
        absorb(driver_id) vce(cluster driver_id)
    lincom _b[lshift_total_wage]
    matrix appendixtable2[1, 1] = r(estimate)
    matrix appendixtable2[2, 1] = r(se)

    oo OLS: day, weekend
    areg lshift_total_hours lshift_total_wage $time_controls ///
        if shift_type_hf == "Day Shift":shift_type_label ///
        & weekend_day & group_weekend_day & group_weekday_day, ///
        absorb(driver_id) vce(cluster driver_id)
    lincom _b[lshift_total_wage]
    matrix appendixtable2[3, 1] = r(estimate)
    matrix appendixtable2[4, 1] = r(se)
end

program create_iv
    use driver_id shift_id trip_id break_time shift_total_mins pkp_date income ///
         using ../input/taxi.dta if driver_id <= 2500, clear
    sort driver_id shift_id trip_id

    by driver_id shift_id: egen shift_total_income = total(income)
    gen shift_total_hours = shift_total_mins / 60
    gen shift_others_wage = shift_total_income / shift_total_hours

    egen tag_shift = tag(driver_id shift_id)
    keep if tag_shift

    collapse shift_others_wage, by(pkp_date)

    keep shift_others_wage pkp_date
    save ../temp/iv.dta, replace
end

* Execute
main
