version 16
preliminaries, matsize(11000) loadglob(../temp/basefile.txt)

program main
    global path ../output_local

    income_gradient appendixfigure6a 8 $base8h30m_day $baseincome8h30m_day
    income_gradient appendixfigure6b 8 $base8h30m_night $baseincome8h30m_night
end

program income_gradient
    args name k baseline baseincome

    est use $path/`name'
    forval j = 1/`k' {
        lincom (_b[cum_income] + _b[incomebin_`j']) * `baseincome' / 10 * 100 / `baseline'
        local bin`j' = r(estimate)
        local CIrad`j' = invttail(r(df),.025)*r(se)
    }
    parmest, saving(../temp/`name', replace)
    use ../temp/`name', clear
    keep parm estimate min95 max95
    keep if substr(parm, 1, 9) == "incomebin"
    forval j = 1/`k' {
        replace estimate = `bin`j'' if parm == "incomebin_`j'"
        replace min95 = `bin`j'' - `CIrad`j'' if parm == "incomebin_`j'"
        replace max95 = `bin`j'' + `CIrad`j'' if parm == "incomebin_`j'"
    }

    gen bin = substr(parm, -1, 1)
    destring bin, replace
    label values bin bin

    eclplot estimate min95 max95 bin, ///
        ylabel(-4(4)16) ///
        xlabel(1(1)8) ///
        ytitle("Percent change in stopping probability at hour 8.5") ///
        xtitle("Timing of income (hour in shift)") ciopts(lwidth(medthin) lcolor(black) ///
        yline(0, lcolor(gs10)))

    graph export ../output/`name'.pdf, replace
end

main

