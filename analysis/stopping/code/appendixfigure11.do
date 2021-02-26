version 16
preliminaries, matsize(11000) loadglob(../temp/basefile.txt)

program main
    global path ../output_local

    local name gradient_8h30m
    local k 8
    local baseline = $base8h30m
    local baseincome = $baseincome8h30m

    import delim ../input/compare.csv, clear
    save ../temp/compare, replace

    est use $path/`name'
    forval j = 1/`k' {
        lincom (_b[cum_income] + _b[incomebin_`j']) * `baseincome' / 10 * 100 / `baseline'
        local bin`j' = r(estimate)
        local CIrad`j' = invttail(r(df),.025)*r(se)
    }
    parmest, saving(../temp/`name'_compare, replace)
    use ../temp/`name'_compare, clear
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

    mmerge parm using ../temp/compare, type(1:1) unmatched(master) ukeep(hour trip)
    assert _merge==3
    drop _merge

    eclplot estimate min95 max95 bin, ///
        addplot((scatter hour bin, msymbol(D) mcolor(black) msize(medlarge)) ///
          (scatter trip bin, msymbol(S) mcolor(gs8) msize(medlarge))) ///
        estopts(msize(small) mcolor(gs5)) ///
        legend(on) ///
        legend(order(4 3) label(3 "Lagged (hour) expectation") label(4 "Lagged (trip) expectation")) ///
        ylabel(-4(3)16) ///
        xlabel(1(1)8) ///
        ytitle("Percent change in stopping probability at hour 8.5") ///
        xtitle("Timing of income (hour in shift)") ciopts(lwidth(medthin) lcolor(black) ///
        yline(0, lcolor(gs10)))

    graph export ../output/appendixfigure11.pdf, replace
end

main

