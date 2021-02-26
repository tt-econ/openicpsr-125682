clear all
set more off

program main
    import delim ../external/taxi_2013_1.csv, clear
    save ../output_local/taxi_combined.dta, replace
    forval m = 2/12 {
        ooo Month `m'
        import delim ../external/taxi_2013_`m'.csv, clear
        append using ../output_local/taxi_combined.dta
        save ../output_local/taxi_combined.dta, replace
    }
end

main

