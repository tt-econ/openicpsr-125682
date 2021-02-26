version 16
preliminaries

use "../temp/taxi.dta", clear

local endpoints "pkp drf"

foreach ep of local endpoints {
    encode `ep'_boro, generate(`ep'_boro_c) label(boro)
    encode `ep'_nta, generate(`ep'_nta_c) label(nta)
    drop `ep'_boro `ep'_nta
    rename `ep'_boro_c `ep'_boro
    rename `ep'_nta_c `ep'_nta
}

label var passenger_count  "Number of passengers (original)"
label var trip_time        "(Rounded) Ride Duration Variable (original)"
label var distance         "Ride Distance (Miles)"
label var payment_type     "Customer payment type (original)"
label var fare             "Fare"
label var surcharge        "Surcharge"
label var mta_tax          "MTA Tax"
label var tip              "Tip Amount"
label var total_amt        "Total Amount"
label var car_id           "Car (random) identifier"
label var car_numdrivers   "Number of drivers by each car"
label var driver_id        "Driver (random) identifier"
label var driver_numcars   "Number of cars by each driver"
label var driver_numshifts "Number of shifts by each driver"
label var from_jfk         "Ride originated at JFK Airport"
label var to_jfk           "Ride ended at JFK Airport"
label var from_lga         "Ride originated at Laguadia Airport"
label var to_lga           "Ride ended at Laguadia Airport"
label var from_ewr         "Ride originated at EWR Airport"
label var to_ewr           "Ride ended at EWR Airport"
label var shift_id         "Shift # for driver in 2009 (new shift: diff in pick-up times >300 min)"
label var trip_id          "Trip # for each driver-shift in 2009"
label var shift_numtrips   "Number of trips for each driver-shift in 2009"
label var final_trip       "If the trip is the final one of a shift"

label var geodistance      "Direct distance between pkp and drf using geodist in km"

label var pkp_date        "Day of trip pick-up time"
label var pkp_day         "Day of the month of trip pick-up time"
label var pkp_month       "Month of the year of trip pick-up time"
label var pkp_year        "Year of trip pick-up time"
label var pkp_dayofweek   "Day of the week of trip pick-up time (0 = Sunday, 6 = Saturday)"
label var pkp_weekofyear  "Week of year of trip pick-up time (1-52)"
label var drf_date        "Day of trip drop-off time"
label var drf_day         "Day of the month of trip drop-off time"
label var drf_month       "Month of the year of trip drop-off time"
label var drf_year        "Year of trip drop-off time"
label var drf_dayofweek   "Day of the week of trip drop-off time (0 = Sunday, 6 = Saturday)"
label var drf_weekofyear  "Week of year of trip drop-off time (1-52)"

label define dow_label 0 "SUN" 1 "MON" 2 "TUE" 3 "WED" 4 "THU" 5 "FRI" 6 "SAT"
label values pkp_dayofweek dow_label
label values drf_dayofweek dow_label

* label var pkp_fips         "Census tract of pick-up location (constructed)"
label var pkp_time         "Pick-up time/date"
label var pkp_boro         "Borough of pick-up location if in NYC"
label var pkp_nta          "Neighborhood tabulation area of pick-up location if in NYC"
label var pkp_hour         "Hour of pick-up"
label var pkp_minute       "Minute of pick-up"
label var pkp_second       "Second of pick-up"

* label var drf_fips         "Census tract of drop-off location (constructed)"
label var drf_time         "Drop-off time/date"
label var drf_boro         "Borough of drop-off location if in NYC"
label var drf_nta          "Neighborhood tabulation area of drop-off location if in NYC"
label var drf_hour         "Hour of drop-off"
label var drf_minute       "Minute of drop-off"
label var drf_second       "Second of drop-off"

label var non_nyc_trip     "Indicator whether the trip starts or ends outside of NYC"
label var non_nyc_shift    "Total number of trips in the shift that starts or ends outside of NYC"

label var holiday           "Major holiday indicator"

label var ride_duration     "Ride Duration (Minutes; Dropoff - Pickup)"
label var wait_duration     "Wait Duration after trip in shift (Minutes; Pickup - Prior Dropoff)"
label var work_duration     "Work Duration (Minutes; Dropoff|Pickup if after break - Prior Dropoff)"
label var total_duration    "Total duration (minutes) with prior wait time"
label var total_duration_cm "Total duration (minutes) with prior wait time and/or post break time (CM 2011)"
label var shift_total_mins  "Total minutes in a shift including wait time"
label var shift_start       "The start hour of a shift"
label var shift_end         "The end hour of a shift"
label var break_time        "1/0 waittime >30m in Manhattan, >60m not to airport, >90m to airport, after trip"
label var cum_income        "Cumulative income (fare + surcharge) up to and including this trip in this shift"
label var cum_tip           "Cumulative (credit card) tip up to and including this trip in this shift"
label var cum_income_tip    "Cumulative fare+surcharge+(CC) tip up to and including this trip in this shift"
label var cum_work_duration "Cumulative work duration (minutes) up to and including this trip in this shift"
label var cum_ride_duration "Cumulative ride duration (minutes) up to and including this trip in this shift"
label var cum_total_duration_cm "Cumulative total_duration_cm (minutes) Crawford-Meng up to & including this trip"
label var cum_total_duration "Cumulative total_duration (minutes) up to & including this trip"

label var minute_miles      "Miles driven per ride minute in this trip"
label var minute_wage       "Wage (fare + surcharge) earned per work minute in this trip"

label var income            "fare and surcharge earned this trip"
label var income_tip        "fare and surcharge and tip earned this trip"

label var tag_shift         "Indicator for first trip in shift"

label var nid               "Nearest weather station (EWR, JFK, LGA, NYC, FRG)"
label var km_to_nid         "Distance (in km) to nearest weather station"
label var near_temp         "Temperature (F) at nearest weather station"
label var near_rain         "Indicator for precipitation/snow during pickup minute at nearest station"
label var near_wind         "Wind speed (miles/hour) during pickup minute at nearest station"

save_data "../output_local/taxi.dta", key(driver_id shift_id trip_id) replace
