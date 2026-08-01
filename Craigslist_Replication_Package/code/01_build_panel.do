version 18.0
set more off
set varabbrev off

/*
    Build the ZIP-year analysis panel from source-level files.

    Source inputs:
      - Craigslist county entry dates
      - ZIP-to-county crosswalk
      - Startup Cartography Project ZIP-year data
      - Census 2000 ZCTA Gazetteer geography
      - NBER 2020 county-to-CBSA crosswalk
*/

capture log close build
log using "$LOGS/01_build_panel.log", replace text name(build)

********************************************************************************
* 1. County-level Craigslist entry timing
********************************************************************************

use "$SOURCE/craigslist/CL_entry.dta", clear

isid fips
rename entry_ym CL_entry_ym_
rename entry_ym_broad CL_entry_ym_broad

format CL_entry_ym_ %tm
format CL_entry_ym_broad %tm

gen int CL_entry_year_ = yofd(dofm(CL_entry_ym_)) if !missing(CL_entry_ym_)
gen int CL_entry_year_broad = yofd(dofm(CL_entry_ym_broad)) if !missing(CL_entry_ym_broad)

label variable CL_entry_year_ "Official Craigslist entry year"
label variable CL_entry_year_broad "Broad Craigslist availability year"

tempfile craigslist_county
save `craigslist_county'

********************************************************************************
* 2. ZIP-to-county crosswalk and ZIP-level treatment timing
********************************************************************************

import delimited "$SOURCE/crosswalks/ZIP_to_FIPS.csv", ///
    clear varnames(1) stringcols(_all)
rename *, lower

drop if zip == "0" | fips == "0"
drop if missing(zip_string_leading_zero) | missing(fips)

gen str5 zipcode = strtrim(zip_string_leading_zero)
replace zipcode = "00000" + zipcode if length(zipcode) < 5
replace zipcode = substr(zipcode, length(zipcode) - 4, 5) if length(zipcode) > 5
destring fips, replace force
drop if missing(fips)

keep zipcode fips state cnty_name
duplicates drop zipcode fips, force
sort zipcode fips

* Retain one deterministic county for untreated ZIPs and geographic controls.
preserve
    by zipcode: keep if _n == 1
    rename fips fips_zip_crosswalk
    rename state zip_state
    rename cnty_name zip_county_name
    tempfile zip_county_one
    save `zip_county_one'
restore

merge m:1 fips using `craigslist_county'
quietly count if _merge == 2
assert r(N) == 1
display as text "Dropping one Craigslist county (FIPS 46113) absent from the ZIP crosswalk."
drop if _merge == 2
assert inlist(_merge, 1, 3)
drop _merge

* For multi-county ZIPs, treatment begins at the earliest mapped county entry.
preserve
    keep zipcode fips CL_entry_ym_ CL_entry_year_ url
    drop if missing(CL_entry_ym_)
    sort zipcode CL_entry_ym_ fips
    by zipcode: keep if _n == 1
    rename fips fips_narrow
    rename url url_narrow_source
    tempfile zip_treatment_narrow
    save `zip_treatment_narrow'
restore

preserve
    keep zipcode fips CL_entry_ym_broad CL_entry_year_broad url_broad
    drop if missing(CL_entry_ym_broad)
    sort zipcode CL_entry_ym_broad fips
    by zipcode: keep if _n == 1
    rename fips fips_broad
    rename url_broad url_broad_source
    tempfile zip_treatment_broad
    save `zip_treatment_broad'
restore

use `zip_county_one', clear
merge 1:1 zipcode using `zip_treatment_narrow', nogen
merge 1:1 zipcode using `zip_treatment_broad', nogen

gen long fips = fips_narrow
replace fips = fips_broad if missing(fips)
replace fips = fips_zip_crosswalk if missing(fips)

isid zipcode
tempfile zip_treatment
save `zip_treatment'

********************************************************************************
* 3. Census 2000 ZCTA population, area, and density
********************************************************************************

infix ///
    str2   zcta_state              1-2   ///
    str64  zcta_name               3-66  ///
    long   zcta_pop2000            67-75 ///
    long   zcta_housing2000        76-84 ///
    double zcta_land_sqm_2000      85-98 ///
    double zcta_water_sqm_2000     99-112 ///
    double zcta_land_sqmi_2000     113-124 ///
    double zcta_water_sqmi_2000    125-136 ///
    double zcta_lat_2000           137-146 ///
    double zcta_lon_2000           147-157 ///
    using "$SOURCE/census/zcta5.txt", clear

gen str5 zipcode = substr(strtrim(zcta_name), 1, 5)
drop if missing(zipcode)

gen double zcta_pop_density_2000 = zcta_pop2000 / zcta_land_sqmi_2000 ///
    if zcta_land_sqmi_2000 > 0 & !missing(zcta_pop2000)

label variable zcta_pop2000 "Census 2000 ZCTA population"
label variable zcta_land_sqmi_2000 "Census 2000 ZCTA land area, square miles"
label variable zcta_pop_density_2000 "Census 2000 ZCTA residents per square mile"

duplicates drop zipcode, force
isid zipcode
tempfile zcta_geography
save `zcta_geography'

********************************************************************************
* 4. NBER county-to-CBSA crosswalk
********************************************************************************

import delimited "$SOURCE/crosswalks/cbsa2fipsxw_2020.csv", ///
    clear varnames(1) stringcols(_all)
rename *, lower

replace fipsstatecode = "0" + strtrim(fipsstatecode) if length(strtrim(fipsstatecode)) == 1
replace fipscountycode = "0" + strtrim(fipscountycode) if length(strtrim(fipscountycode)) == 2
replace fipscountycode = "00" + strtrim(fipscountycode) if length(strtrim(fipscountycode)) == 1

gen long fips = real(fipsstatecode + fipscountycode)
gen long CBSA = real(cbsacode)
drop if missing(fips) | missing(CBSA)

sort fips CBSA
by fips: keep if _n == 1
keep fips CBSA cbsatitle metropolitanmicropolitanstatis
isid fips

tempfile county_cbsa
save `county_cbsa'

********************************************************************************
* 5. Assemble the SCP ZIP-year panel
********************************************************************************

use "$SOURCE/scp/Entrepreneurship_by_ZIP_Code_academic.dta", clear

capture confirm numeric variable zipcode
if !_rc tostring zipcode, replace format(%05.0f)
replace zipcode = strtrim(zipcode)
replace zipcode = "00000" + zipcode if length(zipcode) < 5
replace zipcode = substr(zipcode, length(zipcode) - 4, 5) if length(zipcode) > 5

* The source contains 60 surplus rows that are exact duplicates.
duplicates drop zipcode year, force
isid zipcode year

merge m:1 zipcode using `zip_treatment'
quietly count if _merge == 2
assert r(N) == 3936
display as text "Dropping 3,936 crosswalk ZIPs absent from the SCP panel."
drop if _merge == 2
assert inlist(_merge, 1, 3)
rename _merge merge_treatment

merge m:1 zipcode using `zcta_geography'
drop if _merge == 2
rename _merge merge_zcta

* This key reproduces the CBSA assignment in the analysis used by the paper.
merge m:1 fips using `county_cbsa'
drop if _merge == 2
rename _merge merge_cbsa

sort zipcode year
isid zipcode year

assert _N == 824710
quietly summarize year
assert r(min) == 1988
assert r(max) == 2016

egen byte tag_zip = tag(zipcode)
quietly count if tag_zip
assert r(N) == 38264
quietly count if tag_zip & !missing(CL_entry_year_)
assert r(N) == 22601
quietly count if tag_zip & missing(CL_entry_year_)
assert r(N) == 15663
quietly count if tag_zip & !missing(zcta_pop_density_2000)
assert r(N) == 31264
drop tag_zip

quietly count if !missing(CL_entry_year_)
assert r(N) == 506939
quietly count if !missing(zcta_pop_density_2000)
assert r(N) == 707459

compress
save "$DERIVED/zip_year_panel.dta", replace

log close build
