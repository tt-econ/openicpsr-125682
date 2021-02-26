version 16
preliminaries

program main
    use medallion hack_license using ///
        ../input/taxi.dta, clear
    egen car_driver = tag(medallion hack_license)
    keep if car_driver
    drop car_driver

    egen car_driver = tag(medallion hack_license)
    keep if car_driver
    drop car_driver

    get_car_driver_counts
end

program get_car_driver_counts
    egen car_driver = tag(medallion hack_license)
    bys medallion: egen car_numdrivers = total(car_driver)
    bys hack_license: egen driver_numcars = total(car_driver)
    drop car_driver
    save_data ../output_local/car_driver.dta, replace key(medallion hack_license)
end

* Execute
main
