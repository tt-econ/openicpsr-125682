version 16
preliminaries, matsize(11000) maxvar(20000)

program main
    matrix appendixtable3 = J(20, 4, .)
    matrix appendixtable4 = J(18, 1, .)

    use final_trip cum_total_duration cum_work_duration cum_ride_duration ///
        cum_income driver_id shift_id trip_id non_nyc_shift ///
        if cum_total_duration < 780 & driver_id <= 1000 & !non_nyc_shift ///
        using ../input/taxi_with_expectations.dta, clear

    mmerge driver_id shift_id trip_id using ../input/incomebins.dta, ///
        type(1:1) unmatched(master) ukeep(incomebin*)

    generate_bins

    bysort driver_id shift_id (trip_id): gen shift_hours = cum_total_duration if _n == _N
    by driver_id: egen driver_avg_hours = mean(shift_hours)
    sum driver_avg_hours

    gen x = 0
    gen y = 0
    gen z = 0

    replace x = 1 if cum_total_duration > 9.5 * 60
    gen epsilon = runiform()
    replace x = 1 if epsilon < .05 & cum_total_duration < 9.5 * 60

    replace y = 1 if cum_total_duration >= driver_avg_hours - 60
    gen epsilon2 = runiform()
    replace y = 1 if epsilon2 < .05

    gen epsilon3 = runiform()
    replace z = 1 if cum_total_duration > 9.5 * 60
    replace z = 1 if epsilon < .05 * cum_income / 100 & cum_total_duration < 9.5 * 60

    bysort driver_id shift_id (trip_id): gen cum_x = sum(x)
    bysort driver_id shift_id (trip_id): gen cum_cum_x = sum(cum_x)
    gen complete_x = cum_cum_x <= 1

    bysort driver_id shift_id (trip_id): gen cum_y = sum(y)
    bysort driver_id shift_id (trip_id): gen cum_cum_y = sum(cum_y)
    gen complete_y = cum_cum_y <= 1

    bysort driver_id shift_id (trip_id): gen cum_z = sum(z)
    bysort driver_id shift_id (trip_id): gen cum_cum_z = sum(cum_z)
    gen complete_z = cum_cum_z <= 1

    run_regressions x "if complete_x" 1
    run_regressions y "if complete_y" 2
    run_timing_regressions z "if complete_z"

    matrix_to_txt, matrix(appendixtable3) saving(../output/appendixtable3.txt) title(<tab:appendixtable3>) replace
    matrix_to_txt, matrix(appendixtable4) saving(../output/appendixtable4.txt) title(<tab:appendixtable4>) replace
end

program run_timing_regressions
    args yvar str

    oo TT
    areg `yvar' i.duration_bin#c.cum_income i.duration_bin#c.incomebin* i.duration_bin#c.cum_total_duration `str', absorb(durationXdriver) vce(robust)
    forval i = 1 / 8 {
        lincom _b[51.duration_bin#c.cum_income] * 60 + _b[51.duration_bin#c.incomebin_`i'] * 60
        matrix appendixtable4[2*`i'-1, 1] = r(estimate)
        matrix appendixtable4[2*`i', 1] = r(se)
    }
    testparm i.duration_bin#c.cum_income
    matrix appendixtable4[17, 1] = r(p)
    testparm i.duration_bin#c.incomebin*
    matrix appendixtable4[18, 1] = r(p)
end

program run_regressions
    args yvar str sim

    oo TT
    areg `yvar' i.duration_bin#c.cum_income i.duration_bin#c.cum_total_duration `str', absorb(durationXdriver) vce(robust)
    lincom _b[51.duration_bin#c.cum_income] * 60
    matrix appendixtable3[1, 2*`sim'-1] = r(estimate)
    matrix appendixtable3[2, 2*`sim'-1] = r(se)
    testparm i.duration_bin#c.cum_income
    matrix appendixtable3[1, 2*`sim'] = r(p)

    oo F-1 LPM
    reg `yvar' cum_income cum_total_duration i.driver_id `str', vce(robust)
    lincom _b[cum_income] * 60
    matrix appendixtable3[3, 2*`sim'-1] = r(estimate)
    matrix appendixtable3[4, 2*`sim'-1] = r(se)
    testparm cum_income
    matrix appendixtable3[3, 2*`sim'] = r(p)

    oo F-1s LPM
    reg `yvar' cum_income i.duration_bin i.driver_id `str', vce(robust)
    lincom _b[cum_income] * 60
    matrix appendixtable3[5, 2*`sim'-1] = r(estimate)
    matrix appendixtable3[6, 2*`sim'-1] = r(se)
    testparm cum_income
    matrix appendixtable3[5, 2*`sim'] = r(p)

    oo F-2a LPM
    reg `yvar' i.inc_bin_2005 i.hr_bin_2005 i.driver_id `str', vce(robust)
    testparm i.inc_bin_2005
    matrix appendixtable3[7, 2*`sim'] = r(p)

    oo F-2b LPM
    reg `yvar' i.inc_bin_2015 i.hr_bin_2015 i.driver_id `str', vce(robust)
    lincom _b[9.inc_bin_2015] - _b[8.inc_bin_2015]
    matrix appendixtable3[9, 2*`sim'-1] = r(estimate)
    matrix appendixtable3[10, 2*`sim'-1] = r(se)
    testparm i.inc_bin_2015
    matrix appendixtable3[9, 2*`sim'] = r(p)

    oo F-3 LPM
    reg `yvar' i.hr_bin_2015 i.inc_bin_2015#i.hr_bin_2015 i.driver_id `str', vce(robust)
    lincom _b[9.inc_bin_2015#5.hr_bin_2015]-_b[8.inc_bin_2015#5.hr_bin_2015]
    matrix appendixtable3[11, 2*`sim'-1] = r(estimate)
    matrix appendixtable3[12, 2*`sim'-1] = r(se)
    testparm i.inc_bin_2015#i.hr_bin_2015
    matrix appendixtable3[11, 2*`sim'] = r(p)

    oo F-1 Probit
    probit `yvar' cum_income cum_total_duration i.driver_id `str', vce(robust)
    margins, dydx(cum_income) at(cum_total_duration=510 cum_income=300)
    lincom _b[cum_income]
    matrix appendixtable3[13, 2*`sim'-1] = r(estimate)
    matrix appendixtable3[14, 2*`sim'-1] = r(se)
    testparm cum_income
    matrix appendixtable3[13, 2*`sim'] = r(p)

    oo F-1s Probit
    probit `yvar' cum_income i.duration_bin i.driver_id `str', vce(robust)
    margins, dydx(cum_income) at(duration_bin=51 cum_income=300)
    lincom _b[cum_income]
    matrix appendixtable3[15, 2*`sim'-1] = r(estimate)
    matrix appendixtable3[16, 2*`sim'-1] = r(se)
    testparm cum_income
    matrix appendixtable3[15, 2*`sim'] = r(p)

    oo F-2a Probit
    probit `yvar' i.inc_bin_2005 i.hr_bin_2005 i.driver_id `str', vce(robust)
    testparm i.inc_bin_2005
    matrix appendixtable3[17, 2*`sim'] = r(p)

    oo F-2b Probit
    probit `yvar' i.inc_bin_2015 b8.inc_bin_2015 i.hr_bin_2015 i.driver_id `str', vce(robust)
    margins, dydx(9.inc_bin_2015) at(hr_bin_2015=5)
    lincom _b[9.inc_bin_2015]
    matrix appendixtable3[19, 2*`sim'-1] = r(estimate)
    matrix appendixtable3[20, 2*`sim'-1] = r(se)
    testparm i.inc_bin_2015
    matrix appendixtable3[19, 2*`sim'] = r(p)
end

program generate_bins
    gen exp_income = 12
    gen exp_duration = 20
    gen exp_cum_income = cum_income + exp_income
    gen exp_cum_duration = cum_total_duration + exp_duration

    sort driver_id shift_id trip_id

    gen duration_bin = 0
    gen hr_bin_2005 = 0
    gen inc_bin_2005 = 0
    gen hr_bin_2015 = 0
    gen inc_bin_2015 = 0
    gen durationXdriver = 0

    replace duration_bin = floor(cum_total_duration / 10)
    replace durationXdriver = duration_bin * 10000 + driver_id

    replace hr_bin_2005 = 1 if cum_total_duration <= 180
    replace hr_bin_2005 = 2 if cum_total_duration > 180 & cum_total_duration <= 360
    replace hr_bin_2005 = 3 if cum_total_duration > 360 & cum_total_duration <= 420
    replace hr_bin_2005 = 4 if cum_total_duration > 420 & cum_total_duration <= 480
    replace hr_bin_2005 = 5 if cum_total_duration > 480 & cum_total_duration <= 540
    replace hr_bin_2005 = 6 if cum_total_duration > 540 & cum_total_duration <= 600
    replace hr_bin_2005 = 7 if cum_total_duration > 600 & cum_total_duration <= 660
    replace hr_bin_2005 = 8 if cum_total_duration > 660 & cum_total_duration <= 720
    replace hr_bin_2005 = 9 if cum_total_duration > 720

    replace inc_bin_2005 = 1 if cum_income < 25
    replace inc_bin_2005 = 2 if cum_income >= 25 & cum_income < 50
    replace inc_bin_2005 = 3 if cum_income >= 50 & cum_income < 75
    replace inc_bin_2005 = 4 if cum_income >= 75 & cum_income < 100
    replace inc_bin_2005 = 5 if cum_income >= 100 & cum_income < 125
    replace inc_bin_2005 = 6 if cum_income >= 125 & cum_income < 150
    replace inc_bin_2005 = 7 if cum_income >= 150 & cum_income < 175
    replace inc_bin_2005 = 8 if cum_income >= 175 & cum_income < 200
    replace inc_bin_2005 = 9 if cum_income >= 200 & cum_income < 225
    replace inc_bin_2005 = 10 if cum_income >= 225

    replace hr_bin_2015 = 1 if cum_total_duration <= 180
    replace hr_bin_2015 = 2 if cum_total_duration > 180 & cum_total_duration <= 360
    replace hr_bin_2015 = 3 if cum_total_duration > 360 & cum_total_duration <= 420
    replace hr_bin_2015 = 4 if cum_total_duration > 420 & cum_total_duration <= 480
    replace hr_bin_2015 = 5 if cum_total_duration > 480 & cum_total_duration <= 540
    replace hr_bin_2015 = 6 if cum_total_duration > 540 & cum_total_duration <= 600
    replace hr_bin_2015 = 7 if cum_total_duration > 600 & cum_total_duration <= 660
    replace hr_bin_2015 = 8 if cum_total_duration > 660 & cum_total_duration <= 720
    replace hr_bin_2015 = 9 if cum_total_duration > 720 & cum_total_duration <= 780
    replace hr_bin_2015 = 10 if cum_total_duration > 780

    replace inc_bin_2015 = 1 if cum_income < 100
    replace inc_bin_2015 = 2 if cum_income >= 100 & cum_income < 150
    replace inc_bin_2015 = 3 if cum_income >= 150 & cum_income < 200
    replace inc_bin_2015 = 4 if cum_income >= 200 & cum_income < 225
    replace inc_bin_2015 = 5 if cum_income >= 225 & cum_income < 250
    replace inc_bin_2015 = 6 if cum_income >= 250 & cum_income < 275
    replace inc_bin_2015 = 7 if cum_income >= 275 & cum_income < 300
    replace inc_bin_2015 = 8 if cum_income >= 300 & cum_income < 350
    replace inc_bin_2015 = 9 if cum_income >= 350 & cum_income < 400
    replace inc_bin_2015 = 10 if cum_income >= 400
end

* Execute
main
