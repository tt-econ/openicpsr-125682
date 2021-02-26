version 16
preliminaries

program main
    use tip fare payment_type using "../input/taxi.dta", clear
    keep if tip > 0

    sample 7
    export delim ../temp/tip_sample.csv, replace delimiter(",")
end

* Execute
main
