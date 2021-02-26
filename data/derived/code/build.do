version 16
set more off
preliminaries

program main
    use ../input/taxi.dta, clear

    compress_cab_id
    rename_variables
    drop_duplicates
    process_datetime
    fix_time_errors
    create_shifts
    get_boro_nta
    save_data "../temp/tripsheet_preclean.dta", ///
        key(driver_id shift_id trip_id) replace
end

program compress_cab_id
    egen car_id = group(medallion)
    sort car_id
    egen driver_id = group(hack_license)
end

program rename_variables
    rename trip_distance distance
    rename pickup_datetime pkp_time_tmp
    rename pickup_longitude pkp_long
    rename pickup_latitude pkp_lat
    rename dropoff_datetime drf_time_tmp
    rename dropoff_longitude drf_long
    rename dropoff_latitude drf_lat
    rename fare_amount fare
    rename tip_amount tip
    rename total_amount total_amt
    rename tolls_amount tolls_amt
    rename tract_gid_start pkp_fips
    rename tract_gid_end drf_fips
    rename vendor_id vendor
    rename trip_time_in_secs trip_time

    replace payment_type = itrim(lower(payment_type))
    replace payment_type = "credit" if payment_type=="crd"
    replace payment_type = "cash" if payment_type=="csh"
    replace payment_type = "dispute" if payment_type=="dis"
    replace payment_type = "no charge" if payment_type=="noc"
    replace payment_type = "unknown" if payment_type=="unk"

    * Convert trip_time from seconds to minutes in the new set of data
    replace trip_time = trip_time / 60
end

program drop_duplicates
    duplicates drop car_id driver_id distance pkp_long pkp_lat ///
        drf_long drf_lat fare surcharge tip total_amt payment_type ///
        pkp_time_tmp drf_time_tmp vendor passenger_count trip_time, force
end

program process_datetime
    * Put pick-up and drop-off date-times in Stata clock format
    local endpoints "pkp drf"

    foreach ep of local endpoints {

        gen double `ep'_time = clock(`ep'_time_tmp, "YMD hms", 2000)
        format `ep'_time %tc
        gen double `ep'_date = dofc(`ep'_time)
        format `ep'_date %td

        gen `ep'_year = year(`ep'_date)
        gen `ep'_month = month(`ep'_date)
        gen `ep'_day = day(`ep'_date)
        gen `ep'_dayofweek = dow(`ep'_date)
        gen `ep'_weekofyear = week(`ep'_date)

        gen `ep'_hour = hh(`ep'_time)
        gen `ep'_minute = mm(`ep'_time)
        gen `ep'_second = ss(`ep'_time)
    }

    drop *_time_tmp
end

program fix_time_errors
    /* Sometimes drf_time comes before pkp_time, so we invert these values
    to correct the issue */
    gen pkp_timeFLIP=drf_time
    gen drf_timeFLIP=pkp_time
    gen start_end_swap=pkp_time>drf_time
    tab start_end_swap, m
    replace pkp_time=pkp_timeFLIP if start_end_swap
    replace drf_time=drf_timeFLIP if start_end_swap
    drop pkp_timeFLIP drf_timeFLIP

    /* There are also sequencing problems:
    Sometimes the current pick-up time comes before the previous
    drop off time.  We will set the drf time equal to the subsequent pkp time
    in these cases */
    oo driver trip sequencing problem
    sort driver_id pkp_time
    gen sequencing_problem=(drf_time[_n]-pkp_time[_n+1])>0 & driver_id[_n]==driver_id[_n+1]
    tab sequencing_problem, m
    replace drf_time=pkp_time[_n+1] if sequencing_problem

    oo car trip sequencing problem
    sort car_id pkp_time
    replace sequencing_problem=1 if (drf_time[_n]-pkp_time[_n+1])>0 & car_id[_n]==car_id[_n+1]
    replace sequencing_problem=1 if (drf_time[_n-1]-pkp_time[_n])>0 & car_id[_n-1]==car_id[_n]
    tab sequencing_problem, m
    replace drf_time=pkp_time[_n+1] if sequencing_problem

    ** Generate precise measure of ride_duration, since trip_time is a rounded estimate of minutes
    * Unit: minutes
    gen ride_duration=(drf_time-pkp_time)/60000
end

program create_shifts
    sort driver_id pkp_time

    * Generate difference between current pick up time and
    * last drop off time (in minutes)
    by driver_id: gen diff_pkp_time=(pkp_time[_n]-drf_time[_n-1])/60000

    * Generate an indicator for whether this difference is more
    * than 6 hours (360 minutes)
    gen diff_ind=(diff_pkp_time>300 & diff_pkp_time!=.)

    * Generate the shift
    by driver_id: gen shift_id=1+sum(diff_ind)
    drop diff_pkp_time diff_ind

    * Generate total minutes per shift
    bys driver_id shift_id (pkp_time): ///
        gen shift_total_mins=(drf_time[_N]-pkp_time[1])/60000

    * Generate trip number per shift
    bys driver_id shift_id (pkp_time): gen trip_id=_n

    * Generate final trip of shift indicator
    bys driver_id shift_id: egen shift_numtrips=max(trip_id)
    gen final_trip=trip_id==shift_numtrips
end

program get_boro_nta
    oo No GPS info
    count if pkp_lat == 0 | pkp_long == 0
    local no_gps = r(N)
    di _N
    di (1 - `no_gps' / _N) * 100

    local endpoints "pkp drf"

    foreach ep of local endpoints {
        gen FIPS = string(`ep'_fips , "%14.0g")
        drop `ep'_fips
        mmerge FIPS using "../external/nyc-d.dta", type(n:1) unmatched(master) ///
            ukeep(BoroName NTAName) missing(nomatch)
        gen `ep'_fips = FIPS
        drop FIPS
        rename BoroName `ep'_boro
        rename NTAName `ep'_nta
        replace `ep'_boro = "Non-NYC" if (`ep'_lat!=.) & (`ep'_long!=.) & (`ep'_boro == "")
        replace `ep'_nta = "Non-NYC" if `ep'_boro=="Non-NYC"

        drop _merge
    }

    tab pkp_boro drf_boro

    to_from_airport
end

    program to_from_airport
        gen from_jfk = pkp_fips=="36081071600"
        gen to_jfk = drf_fips=="36081071600"
        gen from_lga = pkp_fips=="36081033100"
        gen to_lga = drf_fips=="36081033100"
        gen from_ewr = pkp_fips=="34013980200"
        gen to_ewr = drf_fips=="34013980200"
    end

* Execute
main
