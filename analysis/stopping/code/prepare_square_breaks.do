version 16
preliminaries, matsize(11000) loadglob(../temp/basefile.txt)

local filestub breaks_8h30m

forval hourgroup = 1/4 {
    est use ../output_local/`filestub'_`hourgroup'
    parmest, saving(../temp/`filestub'_`hourgroup', replace)
    use ../temp/`filestub'_`hourgroup', clear
    keep parm estimate
    keep if parm=="cum_income" | substr(parm, 1, 9) =="incomebin"
    if "`hourgroup'" == "1" {
        replace estimate = estimate * $baseincome8h30m / 10
    }
    else if "`hourgroup'" == "2" {
        replace estimate = estimate * $baseincome8h30m / 10
    }
    else if "`hourgroup'" == "3" {
        replace estimate = estimate * $baseincome8h30m / 10
    }
    else if "`hourgroup'" == "4" {
        replace estimate = estimate * $baseincome8h30m / 10
    }
    set obs `=_N+1'
    gen h = `hourgroup'
    replace parm = "base" if parm==""
    * if "`hourgroup'" == "0" {
    *     replace estimate = $base8h30m6_0 if estimate==.
    * }
    if "`hourgroup'" == "1" {
        replace estimate = $base8h30m if estimate==.
    }
    else if "`hourgroup'" == "2" {
        replace estimate = $base8h30m if estimate==.
    }
    else if "`hourgroup'" == "3" {
        replace estimate = $base8h30m if estimate==.
    }
    else if "`hourgroup'" == "4" {
        replace estimate = $base8h30m if estimate==.
    }
    * else if "`hourgroup'" == "5" {
    *     replace estimate = $base8h30m6_5 if estimate==.
    * }
    save ../temp/`filestub'_`hourgroup', replace
}


use ../temp/`filestub'_1, clear
forval hourgroup = 2/4 {
    append using ../temp/`filestub'_`hourgroup'
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
forval bin = 1/8 {
    rename estimate`bin' incomebin`bin'
    replace incomebin`bin' = (incomebin`bin' + dollar) / base * 100
}
drop dollar base
reshape long incomebin, i(h) j(bin)
drop if incomebin==.
rename incomebin estimate
save ../temp/breaks, replace
export delim ../temp/breaks.csv, replace
