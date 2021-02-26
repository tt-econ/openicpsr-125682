version 16
preliminaries, matsize(11000) maxvar(20000)

program main
    global time_controls "i.drf_hour#i.drf_dayofweek i.shift_date"
    global weather_controls "near_rain i.near_temp_c i.near_wind_c"
    global location_controls "i.drf_nta"
    global all_controls_except_id "$time_controls $weather_controls $location_controls"

    matrix appendixtable10 = J(10, 2, .)
    matrix appendixtable11 = J(20, 3, .)

    use driver_id shift_id shift_month driver_numshifts using ///
        ../input/taxi_shift.dta, clear
    bysort driver_id (shift_id): egen first_month = min(shift_month)
    bysort driver_id (shift_id): egen last_month = max(shift_month)
    by driver_id: gen num_shifts = _N

    gen new_driver_work_regularly = 0 if first_month >= 4
    replace new_driver_work_regularly = 1 if first_month >= 4 & num_shifts >= 50

    keep driver_id shift_id shift_month first_month ///
        new_driver_work_regularly* driver_numshifts
    save_data ../temp/experience.dta, key(driver_id shift_id) replace

    use ../output_local/taxi_8h30m.dta, clear
    append using ../output_local/taxi_8h.dta
    keep if cum_total_duration >= 8*60 + 10 & cum_total_duration <= 8*60 + 50
    mmerge driver_id shift_id using ../temp/experience.dta, ///
        type(n:1) unmatched(master)
    keep if shift_month >= 4

    across_driver_experience 1 "if new_driver_work_regularly == 1"
    across_driver_experience 2 "if new_driver_work_regularly == ."

    ooo within-driver
    gen within_experience1 = (shift_month - first_month)
    gen within_experience2 = shift_id
    gen within_experience3 = (shift_id > driver_numshifts / 2)
    forval j = 1 / 3 {
        within_driver_experience `j'
    }

    matrix_to_txt, matrix(appendixtable10) saving(../output/appendixtable10.txt) title(<tab:appendixtable10>) replace
    matrix_to_txt, matrix(appendixtable11) saving(../output/appendixtable11.txt) title(<tab:appendixtable11>) replace
end

program across_driver_experience
    args column cond

    sum final_trip `cond' & cum_total_duration >= 8*60 + 25 & cum_total_duration <= 8*60 + 35
    local base = r(mean)
    sum cum_income `cond' & cum_total_duration >= 8*60 + 25 & cum_total_duration <= 8*60 + 35
    local inc = r(mean)

    areg final_trip cum_income cum_total_duration i.dis_ridebin* $all_controls_except_id `cond', absorb(driver_id) vce(cluster driver_id)
    lincom _b[cum_income] * `inc' / `base'
    matrix appendixtable10[1, `column'] = r(estimate)
    matrix appendixtable10[2, `column'] = r(se)

    areg final_trip incomebin_1-incomebin_8 cum_income cum_total_duration i.dis_ridebin* $time_controls $location_controls $weather_controls `cond', absorb(driver_id) vce(cluster driver_id)
    lincom (_b[incomebin_2] + _b[cum_income]) * `inc' / `base'
    matrix appendixtable10[3, `column'] = r(estimate)
    matrix appendixtable10[4, `column'] = r(se)
    lincom (_b[incomebin_4] + _b[cum_income]) * `inc' / `base'
    matrix appendixtable10[5, `column'] = r(estimate)
    matrix appendixtable10[6, `column'] = r(se)
    lincom (_b[incomebin_6] + _b[cum_income]) * `inc' / `base'
    matrix appendixtable10[7, `column'] = r(estimate)
    matrix appendixtable10[8, `column'] = r(se)
    lincom (_b[incomebin_8] + _b[cum_income]) * `inc' / `base'
    matrix appendixtable10[9, `column'] = r(estimate)
    matrix appendixtable10[10, `column'] = r(se)
end

program within_driver_experience
    args j

    sum final_trip if cum_total_duration >= 8*60 + 25 & cum_total_duration <= 8*60 + 35
    local base = r(mean)
    sum cum_income if cum_total_duration >= 8*60 + 25 & cum_total_duration <= 8*60 + 35
    local inc = r(mean)

    areg final_trip c.cum_income c.within_experience`j'#c.cum_income ///
        cum_total_duration i.dis_ridebin* $all_controls_except_id ///
        if new_driver_work_regularly == 1, absorb(driver_id) vce(cluster driver_id)
    lincom _b[cum_income] * `inc' / `base'
    matrix appendixtable11[1, `j'] = r(estimate)
    matrix appendixtable11[2, `j'] = r(se)
    lincom (_b[within_experience`j'#cum_income]) * `inc' / `base'
    matrix appendixtable11[3, `j'] = r(estimate)
    matrix appendixtable11[4, `j'] = r(se)

    areg final_trip incomebin_1-incomebin_8 cum_income ///
        c.within_experience`j'#c.(incomebin_1-incomebin_8 cum_income) ///
        cum_total_duration i.dis_ridebin* $all_controls_except_id ///
        if new_driver_work_regularly == 1, absorb(driver_id) vce(cluster driver_id)
    lincom (_b[incomebin_2] + _b[cum_income]) * `inc' / `base'
    matrix appendixtable11[5, `j'] = r(estimate)
    matrix appendixtable11[6, `j'] = r(se)
    lincom (_b[within_experience`j'#incomebin_2] + _b[within_experience`j'#cum_income]) * `inc' / `base'
    matrix appendixtable11[7, `j'] = r(estimate)
    matrix appendixtable11[8, `j'] = r(se)
    lincom (_b[incomebin_4] + _b[cum_income]) * `inc' / `base'
    matrix appendixtable11[9, `j'] = r(estimate)
    matrix appendixtable11[10, `j'] = r(se)
    lincom (_b[within_experience`j'#incomebin_4] + _b[within_experience`j'#cum_income]) * `inc' / `base'
    matrix appendixtable11[11, `j'] = r(estimate)
    matrix appendixtable11[12, `j'] = r(se)
    lincom (_b[incomebin_6] + _b[cum_income]) * `inc' / `base'
    matrix appendixtable11[13, `j'] = r(estimate)
    matrix appendixtable11[14, `j'] = r(se)
    lincom (_b[within_experience`j'#incomebin_6] + _b[within_experience`j'#cum_income]) * `inc' / `base'
    matrix appendixtable11[15, `j'] = r(estimate)
    matrix appendixtable11[16, `j'] = r(se)
    lincom (_b[incomebin_8] + _b[cum_income]) * `inc' / `base'
    matrix appendixtable11[17, `j'] = r(estimate)
    matrix appendixtable11[18, `j'] = r(se)
    lincom (_b[within_experience`j'#incomebin_8] + _b[within_experience`j'#cum_income]) * `inc' / `base'
    matrix appendixtable11[19, `j'] = r(estimate)
    matrix appendixtable11[20, `j'] = r(se)
end

* Execute
main
