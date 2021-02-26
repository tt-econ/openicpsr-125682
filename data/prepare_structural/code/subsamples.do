version 16
preliminaries, matsize(11000)

program main
    local samplesize = 150000
    local numsamples = 230

    use ../output_local/taxi_rhours25p75p_all.dta if cum_total_duration < 12, clear

    gen psi_ctd = floor(cum_total_duration)
    tabulate psi_ctd, generate(I_psi_ctd)
    drop psi_ctd

    sample `=`samplesize'*`numsamples'', count

    set seed 123456
    gen u = uniform()
    sort u
    drop u

    gen sample_id = 1 + floor((_n - 1) / `samplesize')
    quietly sum sample_id, d
    forval i = 1 / `r(max)' {
        export delimited ../output_local/taxi_rhours25p75p_`i'.csv if sample_id == `i', replace
    }
    summarize
end

main
