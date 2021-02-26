version 16
set more off
preliminaries

program main
    use "../temp/tripsheet_preclean.dta", clear
    mmerge medallion hack_license using ../input/car_driver.dta, ///
        type(n:1) unmatched(master) ukeep(car_numdrivers driver_numcars)
    drop _merge
    test_distance_duration
    flag_fare_tax_surcharge
    flag_shifts
    flag_missing_locations
    flag_airport_problems
    flag_speed_distance
    drop_errors
    drop_truncated_shifts
    drop_drivers
    drop vendor
    encode payment_type, generate(payment)
    drop payment_type
    rename payment payment_type
    update_ids
    save_data "../temp/tripsheet_clean.dta", ///
        key(driver_id shift_id trip_id) replace
end

program test_distance_duration
    gen distance_error=distance==0
    gen ride_duration_error=ride_duration==0

    oo Tabulate Errors -- Vendor/Competitor
    tab vendor
    tab vendor distance_error
    tab vendor ride_duration_error

    oo Check independence of errors and vendor
    tab2 distance_error vendor ///
        if (vendor=="VTS" | vendor=="CMT") & fare>=15, chi2 ce
    tab2 ride_duration_error vendor ///
        if (vendor=="VTS" | vendor=="CMT") & fare>=15, chi2 ce

    drop distance_error ride_duration_error
end

program flag_fare_tax_surcharge
    oo Fill in zero values for missing mta_tax values (mostly values before this MTA Tax existed)
    replace mta_tax=0 if mta_tax==.

    oo Max mta_tax is $0.50
    gen mta_tax_error = mta_tax>0.5
    tab mta_tax_error

    oo Surcharge should be a multiple of 0.5
    gen surcharge_error = mod(surcharge, 0.5)!=0
    tab surcharge_error

    oo Flag observations that are below the minimum fare ($2.5 entry fee)
    gen below_minfare = fare<float(2.5)
    tab below_minfare

    oo Flag when payment_type is No Charge or Dispute or Unknown
    gen payment_error = payment_type=="no charge" | payment_type=="dispute" ///
        | payment_type=="unknown"
    tab payment_error

    oo Flag when fare is too high compared to distance and time and locations
    gen fare_error = (fare > 5 + 5 * (distance+1) + (ride_duration+1)) & ///
        ( pkp_boro!="Non-NYC" | drf_boro!="Non-NYC" ) & !to_jfk & !from_jfk
    tab fare_error

    oo Flag when fare is too low compared to distance and time and locations
    replace fare_error = 1 if fare < 0.5*(ride_duration-5*distance-1) & ///
        fare < 2.5 * distance & ///
        ( pkp_boro!="Non-NYC" | drf_boro!="Non-NYC" ) & !to_jfk & !from_jfk
    tab fare_error
end

program flag_shifts
    sort driver_id pkp_time

    oo Trip time and ride duration do not match
    gen trip_time_error = abs(trip_time - ride_duration)>2.5
    tab trip_time_error

    oo Outliers with durations/distances longer than 3 hours / 100 miles
    oo (and non-positive values)
    gen duration_outlier=(ride_duration>180 | ride_duration<=0)
    gen distance_outlier=(distance>100 | distance<=0)
    tab distance_outlier

    oo Identify shifts with over one car per driver
    egen tag_shift=tag(driver_id shift_id)
    egen tag_drivershiftcar=tag(driver_id shift_id car_id)
    bys driver_id shift_id: egen shift_numcars=total(tag_drivershiftcar)
    tab shift_numcars if tag_shift

    gen multiple_cars_per_shift=shift_numcars>1
    drop shift_numcars tag_drivershiftcar

    oo Trips with no passenger
    gen zero_passenger = passenger_count==0
    tab zero_passenger

    oo Flag shifts that are longer 18 hours straight
    oo (in some cases, drivers appear to be on the road for several days)
    gen long_shifts_outlier=shift_total_mins>1080
    tab long_shifts_outlier if tag_shift

    oo Flag shifts that are shorter than 120 minutes
    gen short_shifts_outlier=shift_total_mins<120
    tab short_shifts_outlier if tag_shift

    oo Flag drivers with under 100 rides on record (may be electronic tests sent by TLC/vendors)
    bysort driver_id: gen driver_ridecount=_N
    gen driver_under100rides=driver_ridecount<100
    tab driver_under100rides if tag_shift
    drop driver_ridecount

    oo Frag shifts with fewer than 3 trips
    gen few_trips = shift_numtrips < 3
    tab few_trips if tag_shift
end

program flag_missing_locations
    oo Flag missing GPS info
    gen no_locations = (pkp_boro=="") | (drf_boro=="")
    tab no_locations

    oo Add Non NYC trip indicator and adding up at the shift level
    gen non_nyc_trip = pkp_boro=="Non-NYC" | drf_boro=="Non-NYC"
    egen non_nyc_shift = total(non_nyc_trip), by(driver_id shift_id)
end

program flag_airport_problems
    oo Flag when airport ride costs at least $45 but takes less than 5 minutes
    gen short_airport_trip = (fare>=45 & (from_jfk | to_jfk) & ///
        ride_duration <= 5)
    tab short_airport_trip

    oo Flag when a ride between Manhattan and JFK is under 10 miles
    gen airport_distance_error = (distance < 10) & (from_jfk | to_jfk) & ///
        (pkp_boro=="Manhattan" | drf_boro=="Manhattan")
    tab airport_distance_error
end

program flag_speed_distance
    oo Flag when a ride is under 10 sec, or under 1 min and costs over $10
    gen ride_too_short = ((ride_duration<=1) & fare>10) | ride_duration<.17
    tab ride_too_short

    oo Flag when average speed exceeds 80 mph
    gen speed = distance/ride_duration*60
    gen ride_too_fast = (speed > 80)
    tab ride_too_fast
    drop speed
end

program drop_errors
    /* List issues/outliers

    duration_outlier (if ride is longer than 3 hours or equal to zero minutes)
    distance_outlier (if ride is more than 100 miles or equal to zero miles)
    surcharge_error (surcharge greater than $1)
    mta_tax_error (mta_tax is greater than $0.5)
    below_minfare (total fare is less than flat entry fee $2.5)
    driver_under100rides (less than 100 rides associated with driver)
    multiple_cars_per_shift (more than one car for a driver in a given shift)
    payment_error (no charge or dispute)
    long_shifts_outlier (if driver shift is longer than 20 hours)
    short_shifts_outlier (if driver shift is shorter than 30 minutes)
    no_locations (if there is missing GPS data for either pickup or dropoff)
    start_end_swap (if start and end times are not in order for a trip)
    sequencing_problem (if current pick-up time comes before the previous
                        drop off time)
    fare_error (if fare is too high or low compared to distance + duration + loc)
    zero_passenger (if no passenger in a trip during a shift)
    trip_time_error (trip_time and ride_duration do not match)
    short_airport_trip (if airport ride costs at least $45 but takes less than
                        5 minutes)
    airport_distance_error (if Manhattan-JFK ride is under 10 miles)
    ride_too_short (if ride is under 10 sec, or under 1 min and costs over $10)
    ride_too_fast (if average speed exceeds 80 mph)
    few_trips (fewer than 3 trips in the shift)
    */

    oo Drop driver-shift with issues/outliers
    gen flag_error = ///
        duration_outlier|distance_outlier|surcharge_error|mta_tax_error| ///
        below_minfare|driver_under100rides|multiple_cars_per_shift| ///
        payment_error|long_shifts_outlier|short_shifts_outlier| ///
        no_locations|start_end_swap|sequencing_problem|fare_error| ///
        zero_passenger|trip_time_error|short_airport_trip| ///
        airport_distance_error|ride_too_short|ride_too_fast|few_trips

    bys driver_id shift_id: egen driver_shift_error = total(flag_error)
    tab driver_shift_error

    drop if driver_shift_error > 0

    drop driver_shift_error flag_error duration_outlier distance_outlier ///
        surcharge_error mta_tax_error below_minfare driver_under100rides ///
        multiple_cars_per_shift payment_error long_shifts_outlier ///
        short_shifts_outlier no_locations start_end_swap sequencing_problem ///
        fare_error zero_passenger trip_time_error short_airport_trip ///
        airport_distance_error ride_too_short ride_too_fast few_trips
    disp _N
end

program drop_truncated_shifts
    ooo Drop shifts that get cut off during new-year days
    sort driver_id shift_id

    oo Computing first shift hour
    by driver_id shift_id: egen double shift_start = min(pkp_time)
    replace shift_start = hh(shift_start)

    oo Computing last shift hour
    by driver_id shift_id: egen double shift_end = max(drf_time)
    replace shift_end = hh(shift_end)


    egen shift_date = min(pkp_date), by(driver_id shift_id)

    oo Drop if shift date is year-end and shift spans 2 days
    drop if month(shift_date)==12 & day(shift_date)==31 & shift_start > shift_end

    oo Drop if shift date is new-year and shifts are early
    drop if month(shift_date)==1 & day(shift_date)==1 & shift_start < 5

    drop shift_date
end

program drop_drivers
    oo Drop drivers with under 10 shifts
    bysort driver_id: egen driver_numshifts=total(tag_shift)
    gen driver_under10shifts=driver_numshifts<10
    tab driver_under10shifts
    drop if driver_under10shifts
    drop driver_under10shifts
end

program update_ids
    oo Updating driver and shift id due to data cleaning
    rename driver_id driver
    egen driver_id = group(driver)
    drop driver
    egen driver_shift_id = group(driver_id shift_id)
    drop shift_id
    bys driver_id (driver_shift_id trip_id): gen shift_id = sum(tag_shift)
    drop driver_shift_id
    encode medallion, generate(medallion_temp)
    encode hack_license, generate(hack_license_temp)
    drop hack_license medallion
    rename hack_license_temp hack_license
    rename medallion_temp medallion
end


* Execute
main
