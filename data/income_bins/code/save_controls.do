version 16
preliminaries, matsize(11000) maxvar(20000)

program main
    use final_trip cum* driver_id shift_id trip_id hack_license drf* ///
        near* holiday non* car* tag* break* total* work* ///
        wait* *boro tip distance if cum_total_duration < 780 ///
        using ../input/taxi.dta, clear
    mmerge driver_id shift_id cum_total_duration ///
        using ../output_local/incomebins.dta, ///
        type(1:1) unmatched(master) ukeep(incomebin*)
    assert _merge==3
    drop _merge

    sum incomebin* cum_*_duration if final_trip==1
    save_data ../output_local/taxi_last12_min60.dta, ///
        key(driver_id shift_id trip_id) replace
end

* Execute
main
