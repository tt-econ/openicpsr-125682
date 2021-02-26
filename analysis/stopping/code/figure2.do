version 16
preliminaries, matsize(11000) loadglob(../temp/basefile.txt)

local filestub overall
local fileend ""
local incomevar "cum_income"

local i 500
foreach hour in 5h 5h15m 5h30m 5h45m 6h 6h15m 6h30m 6h45m 7h 7h15m 7h30m 7h45m 8h 8h15m 8h30m 8h45m 9h 9h15m 9h30m 9h45m 10h 10h15m 10h30m 10h45m {
    est use ../output_local/`filestub'_`hour'`fileend'
    if "`hour'" == "5h" {
        lincom _b[`incomevar'] * $baseincome5h / 10 * 100
    }
    else if "`hour'" == "5h15m" {
        lincom _b[`incomevar'] * $baseincome5h15m / 10 * 100
    }
    else if "`hour'" == "5h30m" {
        lincom _b[`incomevar'] * $baseincome5h30m / 10 * 100
    }
    else if "`hour'" == "5h45m" {
        lincom _b[`incomevar'] * $baseincome5h45m / 10 * 100
    }
    else if "`hour'" == "6h" {
        lincom _b[`incomevar'] * $baseincome6h / 10 * 100
    }
    else if "`hour'" == "6h15m" {
        lincom _b[`incomevar'] * $baseincome6h15m / 10 * 100
    }
    else if "`hour'" == "6h30m" {
        lincom _b[`incomevar'] * $baseincome6h30m / 10 * 100
    }
    else if "`hour'" == "6h45m" {
        lincom _b[`incomevar'] * $baseincome6h45m / 10 * 100
    }
    else if "`hour'" == "7h" {
        lincom _b[`incomevar'] * $baseincome7h / 10 * 100
    }
    else if "`hour'" == "7h15m" {
        lincom _b[`incomevar'] * $baseincome7h15m / 10 * 100
    }
    else if "`hour'" == "7h30m" {
        lincom _b[`incomevar'] * $baseincome7h30m / 10 * 100
    }
    else if "`hour'" == "7h45m" {
        lincom _b[`incomevar'] * $baseincome7h45m / 10 * 100
    }
    else if "`hour'" == "8h" {
        lincom _b[`incomevar'] * $baseincome8h / 10 * 100
    }
    else if "`hour'" == "8h15m" {
        lincom _b[`incomevar'] * $baseincome8h15m / 10 * 100
    }
    else if "`hour'" == "8h30m" {
        lincom _b[`incomevar'] * $baseincome8h30m / 10 * 100
    }
    else if "`hour'" == "8h45m" {
        lincom _b[`incomevar'] * $baseincome8h45m / 10 * 100
    }
    else if "`hour'" == "9h" {
        lincom _b[`incomevar'] * $baseincome9h / 10 * 100
    }
    else if "`hour'" == "9h15m" {
        lincom _b[`incomevar'] * $baseincome9h15m / 10 * 100
    }
    else if "`hour'" == "9h30m" {
        lincom _b[`incomevar'] * $baseincome9h30m / 10 * 100
    }
    else if "`hour'" == "9h45m" {
        lincom _b[`incomevar'] * $baseincome9h45m / 10 * 100
    }
    else if "`hour'" == "10h" {
        lincom _b[`incomevar'] * $baseincome10h / 10 * 100
    }
    else if "`hour'" == "10h15m" {
        lincom _b[`incomevar'] * $baseincome10h15m / 10 * 100
    }
    else if "`hour'" == "10h30m" {
        lincom _b[`incomevar'] * $baseincome10h30m / 10 * 100
    }
    else if "`hour'" == "10h45m" {
        lincom _b[`incomevar'] * $baseincome10h45m / 10 * 100
    }
    local incomeCIradius = invttail(r(df),.025)*r(se)
    parmest, saving(../temp/`filestub'_`i'`fileend', replace)
    use ../temp/`filestub'_`i'`fileend', clear
    keep parm estimate
    keep if parm=="`incomevar'"
    if "`hour'" == "5h" {
        replace estimate = estimate * $baseincome5h / 10 * 100 if parm=="`incomevar'"
    }
    else if "`hour'" == "5h15m" {
        replace estimate = estimate * $baseincome5h15m / 10 * 100 if parm=="`incomevar'"
    }
    else if "`hour'" == "5h30m" {
        replace estimate = estimate * $baseincome5h30m / 10 * 100 if parm=="`incomevar'"
    }
    else if "`hour'" == "5h45m" {
        replace estimate = estimate * $baseincome5h45m / 10 * 100 if parm=="`incomevar'"
    }
    else if "`hour'" == "6h" {
        replace estimate = estimate * $baseincome6h / 10 * 100 if parm=="`incomevar'"
    }
    else if "`hour'" == "6h15m" {
        replace estimate = estimate * $baseincome6h15m / 10 * 100 if parm=="`incomevar'"
    }
    else if "`hour'" == "6h30m" {
        replace estimate = estimate * $baseincome6h30m / 10 * 100 if parm=="`incomevar'"
    }
    else if "`hour'" == "6h45m" {
        replace estimate = estimate * $baseincome6h45m / 10 * 100 if parm=="`incomevar'"
    }
    else if "`hour'" == "7h" {
        replace estimate = estimate * $baseincome7h / 10 * 100 if parm=="`incomevar'"
    }
    else if "`hour'" == "7h15m" {
        replace estimate = estimate * $baseincome7h15m / 10 * 100 if parm=="`incomevar'"
    }
    else if "`hour'" == "7h30m" {
        replace estimate = estimate * $baseincome7h30m / 10 * 100 if parm=="`incomevar'"
    }
    else if "`hour'" == "7h45m" {
        replace estimate = estimate * $baseincome7h45m / 10 * 100 if parm=="`incomevar'"
    }
    else if "`hour'" == "8h" {
        replace estimate = estimate * $baseincome8h / 10 * 100 if parm=="`incomevar'"
    }
    else if "`hour'" == "8h15m" {
        replace estimate = estimate * $baseincome8h15m / 10 * 100 if parm=="`incomevar'"
    }
    else if "`hour'" == "8h30m" {
        replace estimate = estimate * $baseincome8h30m / 10 * 100 if parm=="`incomevar'"
    }
    else if "`hour'" == "8h45m" {
        replace estimate = estimate * $baseincome8h45m / 10 * 100 if parm=="`incomevar'"
    }
    else if "`hour'" == "9h" {
        replace estimate = estimate * $baseincome9h / 10 * 100 if parm=="`incomevar'"
    }
    else if "`hour'" == "9h15m" {
        replace estimate = estimate * $baseincome9h15m / 10 * 100 if parm=="`incomevar'"
    }
    else if "`hour'" == "9h30m" {
        replace estimate = estimate * $baseincome9h30m / 10 * 100 if parm=="`incomevar'"
    }
    else if "`hour'" == "9h45m" {
        replace estimate = estimate * $baseincome9h45m / 10 * 100 if parm=="`incomevar'"
    }
    else if "`hour'" == "10h" {
        replace estimate = estimate * $baseincome10h / 10 * 100 if parm=="`incomevar'"
    }
    else if "`hour'" == "10h15m" {
        replace estimate = estimate * $baseincome10h15m / 10 * 100 if parm=="`incomevar'"
    }
    else if "`hour'" == "10h30m" {
        replace estimate = estimate * $baseincome10h30m / 10 * 100 if parm=="`incomevar'"
    }
    else if "`hour'" == "10h45m" {
        replace estimate = estimate * $baseincome10h45m / 10 * 100 if parm=="`incomevar'"
    }
    gen incomeCIradius = `incomeCIradius' if parm=="`incomevar'"
    set obs `=_N+1'
    gen h = `i' / 100
    replace parm = "base" if parm==""
    replace parm = "dollar" if parm=="`incomevar'"
    if "`hour'" == "5h" {
        replace estimate = 100 * $base5h if estimate==.
    }
    else if "`hour'" == "5h15m" {
        replace estimate = 100 * $base5h15m if estimate==.
    }
    else if "`hour'" == "5h30m" {
        replace estimate = 100 * $base5h30m if estimate==.
    }
    else if "`hour'" == "5h45m" {
        replace estimate = 100 * $base5h45m if estimate==.
    }
    else if "`hour'" == "6h" {
        replace estimate = 100 * $base6h if estimate==.
    }
    else if "`hour'" == "6h15m" {
        replace estimate = 100 * $base6h15m if estimate==.
    }
    else if "`hour'" == "6h30m" {
        replace estimate = 100 * $base6h30m if estimate==.
    }
    else if "`hour'" == "6h45m" {
        replace estimate = 100 * $base6h45m if estimate==.
    }
    else if "`hour'" == "7h" {
        replace estimate = 100 * $base7h if estimate==.
    }
    else if "`hour'" == "7h15m" {
        replace estimate = 100 * $base7h15m if estimate==.
    }
    else if "`hour'" == "7h30m" {
        replace estimate = 100 * $base7h30m if estimate==.
    }
    else if "`hour'" == "7h45m" {
        replace estimate = 100 * $base7h45m if estimate==.
    }
    else if "`hour'" == "8h" {
        replace estimate = 100 * $base8h if estimate==.
    }
    else if "`hour'" == "8h15m" {
        replace estimate = 100 * $base8h15m if estimate==.
    }
    else if "`hour'" == "8h30m" {
        replace estimate = 100 * $base8h30m if estimate==.
    }
    else if "`hour'" == "8h45m" {
        replace estimate = 100 * $base8h45m if estimate==.
    }
    else if "`hour'" == "9h" {
        replace estimate = 100 * $base9h if estimate==.
    }
    else if "`hour'" == "9h15m" {
        replace estimate = 100 * $base9h15m if estimate==.
    }
    else if "`hour'" == "9h30m" {
        replace estimate = 100 * $base9h30m if estimate==.
    }
    else if "`hour'" == "9h45m" {
        replace estimate = 100 * $base9h45m if estimate==.
    }
    else if "`hour'" == "10h" {
        replace estimate = 100 * $base10h if estimate==.
    }
    else if "`hour'" == "10h15m" {
        replace estimate = 100 * $base10h15m if estimate==.
    }
    else if "`hour'" == "10h30m" {
        replace estimate = 100 * $base10h30m if estimate==.
    }
    else if "`hour'" == "10h45m" {
        replace estimate = 100 * $base10h45m if estimate==.
    }
    save ../temp/`filestub'_`i'`fileend', replace
    local i = `i' + 25
}













use ../temp/`filestub'_500`fileend', clear
forval h=525(25)1075 {
    append using ../temp/`filestub'_`h'`fileend'
}

gen min95 = estimate - incomeCIradius
gen max95 = estimate + incomeCIradius
drop incomeCIradius

gen type = .
replace type = 1 if parm=="dollar"
replace type = 2 if parm=="base"
drop parm
reshape wide estimate min95 max95, i(h) j(type)
rename estimate1 dollar
rename estimate2 base
rename min951 min95
rename max951 max95
drop min952 max952
save ../temp/`filestub'`fileend', replace
export delim ../temp/`filestub'`fileend'.csv, replace

twoway (bar base h if h >= 5 & h <= 10.75, yaxis(1) color(gs12) barw(.15)) ///
    (line dollar h if h >= 5 & h <= 10.75, yaxis(2) lcolor(gs2) lpattern(solid)) ///
    (line min95 h if h >= 5 & h <= 10.75, yaxis(2) lcolor(gs2) lpattern(dash)) ///
    (line max95 h if h >= 5 & h <= 10.75, yaxis(2) lcolor(gs2) lpattern(dash)), ///
    legend(order(1 - "" 2) label(1 "Baseline stopping probability") label(2 "10% increase in earnings")) ///
    xtitle("Hour of shift") ///
    xlabel(5(.5)10.5) ///
    ylabel(0(5)30, axis(1)) ///
    ylabel(0(.15).90, axis(2)) ///
    ytitle("Percentage point change in stopping probability", axis(2)) ///
    ytitle("Stopping probability (%)", axis(1))
graph export ../output/figure2.pdf, replace

