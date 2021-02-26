version 16
preliminaries, matsize(11000) loadglob(../temp/basefile.txt)

local filestub gradient
local fileend ""

local i 55
foreach hour in 5h45m 6h15m 6h45m 7h15m 7h45m 8h15m 8h45m 9h15m 9h45m 10h15m 10h45m {
    est use ../output_local/`filestub'_`hour'`fileend'
    parmest, saving(../temp/`filestub'_`i'`fileend', replace)
    use ../temp/`filestub'_`i'`fileend', clear
    keep parm estimate
    keep if parm=="cum_income" | substr(parm, 1, 9) =="incomebin"
    if "`hour'" == "5h45m" {
        replace estimate = estimate * $baseincome5h45m / 10
    }
    else if "`hour'" == "6h15m" {
        replace estimate = estimate * $baseincome6h15m / 10
    }
    else if "`hour'" == "6h45m" {
        replace estimate = estimate * $baseincome6h45m / 10
    }
    else if "`hour'" == "7h15m" {
        replace estimate = estimate * $baseincome7h15m / 10
    }
    else if "`hour'" == "7h45m" {
        replace estimate = estimate * $baseincome7h45m / 10
    }
    else if "`hour'" == "8h15m" {
        replace estimate = estimate * $baseincome8h15m / 10
    }
    else if "`hour'" == "8h45m" {
        replace estimate = estimate * $baseincome8h45m / 10
    }
    else if "`hour'" == "9h15m" {
        replace estimate = estimate * $baseincome9h15m / 10
    }
    else if "`hour'" == "9h45m" {
        replace estimate = estimate * $baseincome9h45m / 10
    }
    else if "`hour'" == "10h15m" {
        replace estimate = estimate * $baseincome10h15m / 10
    }
    else if "`hour'" == "10h45m" {
        replace estimate = estimate * $baseincome10h45m / 10
    }
    set obs `=_N+1'
    gen h = `i' / 10
    replace parm = "base" if parm==""
    if "`hour'" == "5h45m" {
        replace estimate = $base5h45m if estimate==.
    }
    else if "`hour'" == "6h15m" {
        replace estimate = $base6h15m if estimate==.
    }
    else if "`hour'" == "6h45m" {
        replace estimate = $base6h45m if estimate==.
    }
    else if "`hour'" == "7h15m" {
        replace estimate = $base7h15m if estimate==.
    }
    else if "`hour'" == "7h45m" {
        replace estimate = $base7h45m if estimate==.
    }
    else if "`hour'" == "8h15m" {
        replace estimate = $base8h15m if estimate==.
    }
    else if "`hour'" == "8h45m" {
        replace estimate = $base8h45m if estimate==.
    }
    else if "`hour'" == "9h15m" {
        replace estimate = $base9h15m if estimate==.
    }
    else if "`hour'" == "9h45m" {
        replace estimate = $base9h45m if estimate==.
    }
    else if "`hour'" == "10h15m" {
        replace estimate = $base10h15m if estimate==.
    }
    else if "`hour'" == "10h45m" {
        replace estimate = $base10h45m if estimate==.
    }
    save ../temp/`filestub'_`i'`fileend', replace
    local i = `i' + 5
}


use ../temp/`filestub'_55`fileend', clear
forval h=60(5)105 {
    append using ../temp/`filestub'_`h'`fileend'
}
gen type = .
replace type = 100 if parm=="cum_income"
replace type = 200 if parm=="base"
gen bin = substr(parm, 11, .)
destring bin, replace
replace type = bin if substr(parm, 1, 9) =="incomebin"
drop bin
drop parm
reshape wide estimate, i(h) j(type)
rename estimate100 dollar
rename estimate200 base
forval bin = 1/10 {
    rename estimate`bin' incomebin`bin'
    replace incomebin`bin' = (incomebin`bin' + dollar) / base * 100
}
drop dollar base
reshape long incomebin, i(h) j(bin)
drop if incomebin==.
rename incomebin estimate
save ../temp/incomebin`fileend', replace
export delim ../temp/incomebin`fileend'.csv, replace
