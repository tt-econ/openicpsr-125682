version 15
preliminaries, matsize(11000) maxvar(20000)

program main
    local n_sim = 500
    matrix appendixfigure5_input = J(`n_sim', 2, .)

    use driver_id shift_id trip_id cum_total_duration cum_income *exp* r_* non_nyc_shift if driver_id <= 500 & !non_nyc_shift & cum_total_duration < 780 using ../input/taxi_with_expectations.dta, clear

    sort driver_id shift_id trip_id

    gen x = 0
    gen y = 0
    gen duration_bin = 0
    gen durationXdriver = 0
    gen epsilon = 0
    gen epsilon2 = 0
    gen cum_x = 0
    gen cum_cum_x = 0
    gen cum_y = 0
    gen cum_cum_y = 0
    gen complete_x = 0
    gen complete_y = 0

    replace duration_bin = floor(cum_total_duration / 10)
    replace durationXdriver = duration_bin * 10000 + driver_id

    bysort driver_id shift_id (trip_id): gen shift_hours = cum_total_duration if _n == _N
    by driver_id: egen driver_avg_hours = mean(shift_hours)
    sum driver_avg_hours

    sort driver_id shift_id trip_id
    forval i = 1 / `n_sim' {

        replace x = 0
        replace x = 1 if cum_total_duration > 9.5 * 60
        replace epsilon = runiform()
        replace x = 1 if epsilon < .05

        by driver_id shift_id: replace cum_x = sum(x)
        by driver_id shift_id: replace cum_cum_x = sum(cum_x)
        replace complete_x = cum_cum_x <= 1

        run_regressions x "if complete_x" `i' 1

    }

    sort driver_id shift_id trip_id
    forval i = 1 / `n_sim' {

        replace y = 0
        replace y = 1 if cum_total_duration >= driver_avg_hours - 60
        replace epsilon2 = runiform()
        replace y = 1 if epsilon2 < .05

        by driver_id shift_id: replace cum_y = sum(y)
        by driver_id shift_id: replace cum_cum_y = sum(cum_y)
        replace complete_y = cum_cum_y <= 1

        run_regressions y "if complete_y" `i' 2

    }

    matrix_to_txt, matrix(appendixfigure5_input) saving(../temp/appendixfigure5_input.txt) title(Input for Appendix Figure 5:) replace
end

program run_regressions
    args yvar str i j

    oo TT
    areg `yvar' i.duration_bin#c.cum_income i.duration_bin#c.cum_total_duration `str', absorb(durationXdriver) vce(robust)
    testparm i.duration_bin#c.cum_income
    matrix appendixfigure5_input[`i', `j'] = r(p)
end

* Execute
main
