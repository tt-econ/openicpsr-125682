program make_bins_phantom
    syntax [if], x(varname) h(varlist) [lastbin(string) binmin(string)]
    tokenize `h'
    local hour = "`1'"

    if "`lastbin'" == "" {
        local lastbin = 6
    }
    if "`binmin'" == "" {
        local binmin = 120
    }

    keep driver_id shift_id `hour' `x'
    gen phantom = 0
    gen bin = floor(`hour' / `binmin')
    replace bin = `lastbin' - 1 if bin>=`lastbin'
    save ../temp/data_`x'.dta, replace

    create_phantoms, hour(`hour') income(`x') lastbin(`lastbin') binmin(`binmin')
    create_bins, income(`x') lastbin(`lastbin')
    cleanup
end

program create_phantoms
    syntax , hour(varname) income(varname) lastbin(string) binmin(string)

    keep driver_id shift_id
    duplicates drop
    expandcl `lastbin', cluster(driver_id shift_id) generate(bin)
    drop bin
    by driver_id shift_id: gen bin = _n - 1
    gen `hour' = `binmin' * bin
    gen `income' = .
    gen phantom = 1

    append using ../temp/data_`income'.dta
    sort driver_id shift_id `hour'

    by driver_id shift_id: gen trip_id = _n
    egen driver_shift = group(driver_id shift_id)
    xtset driver_shift trip_id

    replace `income' = 0 if `hour'==0 & phantom==1

    gen beforeincome = L.`income'
    gen afterincome = F.`income'
    gen beforehour = L.`hour'
    gen afterhour = F.`hour'

    local min_between_shifts 360
    forval i = 2/`lastbin' {
        gen beforeincometemp = L`i'.`income' if beforeincome==.
        replace beforehour = L`i'.`hour' if beforeincome==.
        replace beforeincome = beforeincometemp if beforeincome==.
        drop beforeincometemp

        gen afterincometemp = F`i'.`income' if afterincome==.
        replace afterhour = F`i'.`hour' if afterincome==.
        replace afterincome = afterincometemp if afterincome==.
        drop afterincometemp
    }

    replace `income' = (afterincome - beforeincome) / (afterhour - beforehour) * ///
        (`hour' - beforehour) + beforeincome if phantom==1 & `income'==.
    drop before* after*
    replace `income' = 0 if bin==0 & phantom==1


    keep if phantom==1
    xtset driver_shift bin
    gen incomebin = `income' - L1.`income'
    replace incomebin = 0 if bin==0


    forval i = 1/`lastbin' {
        gen incomebin_`i' = 0
        replace incomebin_`i' = incomebin if bin==`i' & incomebin!=.
        by driver_shift: egen temp = max(incomebin_`i')
        replace incomebin_`i' = temp if bin>=`i'
        drop temp
    }
    drop incomebin phantom


    save ../temp/phantom_`income'.dta, replace
end

program create_bins
    syntax , income(varname) lastbin(string)

    use ../temp/data_`income'.dta, clear
    mmerge driver_id shift_id bin using ../temp/phantom_`income', type(n:1) ukeep(incomebin*) unmatched(master)

    egen sumrow = rowtotal(incomebin*)
    forval i = 1/`lastbin' {
        replace incomebin_`i' = `income' - sumrow if bin==`i'-1
    }

end

program cleanup
    drop bin
    drop sumrow
    drop phantom
    assert _merge==3
    drop _merge
    describe
end
