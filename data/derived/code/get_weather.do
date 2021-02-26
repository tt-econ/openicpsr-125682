version 16
set more off
preliminaries

program main
    get_stations
    merge_weather_tripsheet
    adjust_erroneous_gps
    station_distance
    nearest_weather
    weather_categories
    save_data "../temp/taxi.dta", ///
        key(driver_id shift_id trip_id) replace
end

program get_stations
    import delimited "../external/stations.csv"
    save "../temp/stations.dta", replace
end

program merge_weather_tripsheet
    use "../temp/tripsheet_noweather.dta", clear
    sort driver_id shift_id trip_id

    local times "date hour minute"
    foreach t of local times {
        gen `t' = drf_`t'
    }

    mmerge date hour minute using "../input/minute_weather2013.dta", ///
        type(n:1) unmatched(master) ukeep(wind* rain* temp*)

    drop `times'
    capture assert _merge==3
    drop _merge
    save "../temp/taxi.dta", replace
end

program adjust_erroneous_gps
    local endpoints "pkp drf"

    foreach ep of local endpoints {
        gen `ep'_latFLIP=`ep'_long
        gen `ep'_longFLIP=`ep'_lat
        gen `ep'_lat_long_swap=(`ep'_lat<0 & 0<`ep'_long)
        tab `ep'_lat_long_swap, m

        replace `ep'_lat=`ep'_longFLIP if `ep'_lat_long_swap
        replace `ep'_long=`ep'_latFLIP if `ep'_lat_long_swap
        drop `ep'_latFLIP `ep'_longFLIP `ep'_lat_long_swap

        oo Flag latitude/longitude out of -90 to 90 range
        gen `ep'_lat_high = (`ep'_lat > 90)
        gen `ep'_lat_low = (`ep'_lat < -90)
        gen `ep'_long_high = (`ep'_long > 90)
        gen `ep'_long_low = (`ep'_long < -90)
        tab `ep'_lat_high
        tab `ep'_lat_low
        tab `ep'_long_high
        tab `ep'_long_low
    }

    gen flag_error = pkp_lat_high|pkp_lat_low| ///
        pkp_long_high|pkp_long_low| ///
        drf_lat_high|drf_lat_low| ///
        drf_long_high|drf_long_low
    bys driver_id shift_id: egen driver_shift_error = total(flag_error)
    oo Drop if latitude/longitude out of -90 to 90 range
    tab driver_shift_error
    drop if driver_shift_error > 0
    drop *_error *_lat_high *_lat_low *_long_high *_long_low
end

program station_distance
    gen long baseid = _n
    destring pkp_lat pkp_long, force replace
    geonear baseid pkp_lat pkp_long using "../temp/stations.dta", ///
        neighbors(station_id station_lat station_long) nearcount(2)

    geodist pkp_lat pkp_long drf_lat drf_long, generate(geodistance)

    drop_far_stations
end

    program drop_far_stations
        gen far_station_error = (km_to_nid1 > 50)
        bys driver_id shift_id: egen driver_shift_error = total(far_station_error)
        oo Drop if more than 50 km from weather station
        tab driver_shift_error
        drop if driver_shift_error > 0
        drop *_error
    end

program nearest_weather
    local newark "EWR"
    local central_park "NYC"
    local lga "LGA"
    local jfk "JFK"
    local long_island "FRG"
    local stations `newark' `central_park' `lga' `jfk' `long_island'
    gen near_rain = .
    gen near_wind = .
    gen near_temp = .

    gen nid = nid1
    gen km_to_nid = km_to_nid1
    foreach station of local stations {
        replace near_rain = rain`station' if nid1 == "`station'"
        replace near_wind = windtwomin`station' if nid1 == "`station'"
        replace near_temp = temp`station' if nid1 == "`station'"
    }

    replace nid = nid2 if near_rain == .
    replace km_to_nid = km_to_nid2 if near_rain == .
    foreach station of local stations {
        replace near_rain = rain`station' if nid2 == "`station'" ///
            & near_rain == .
        replace near_wind = windtwomin`station' if nid2 == "`station'" ///
            & near_wind == .
        replace near_temp = temp`station' if nid2 == "`station'" ///
            & near_temp == .
        replace near_temp = . if near_temp < -15 | near_temp > 110
    }
    drop rain* wind* temp* pkp_lat pkp_long drf_lat drf_long baseid
    drop nid1 nid2 km_to_nid1 km_to_nid2
    encode nid, generate(nid_c)
    drop nid
    rename nid_c nid
end

program weather_categories
    gen near_wind_c = 0
    replace near_wind_c = 1 if near_wind > 0 & near_wind <= 3
    replace near_wind_c = 2 if near_wind > 3 & near_wind <= 7
    replace near_wind_c = 3 if near_wind > 7 & near_wind <= 12
    replace near_wind_c = 4 if near_wind > 12 & near_wind <= 17
    replace near_wind_c = 5 if near_wind > 17 & near_wind <= 24
    replace near_wind_c = 6 if near_wind > 24

    gen near_temp_c = 0 if near_temp!=.
    replace near_temp_c = 1 if near_temp < 30 & near_temp !=.
    replace near_temp_c = 2 if near_temp > 80 & near_temp !=.

    label define rain_label 0 "No rain" 1 "Rain"
    label values near_rain rain_label

    label define wind_label 0 "Beaufort 0" 1 "Beaufort 1" 2 "Beaufort 2" ///
        3 "Beaufort 3" 4 "Beaufort 4" 5 "Beaufort 5" 6 "Beaufort 6+"
    label values near_wind_c wind_label

    label define temp_label 0 "30F-80F" 1 "<30F" 2 ">80F"
    label values near_temp_c temp_label
end

* Execute
main
