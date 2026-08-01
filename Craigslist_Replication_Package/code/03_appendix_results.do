version 18.0
set more off
set varabbrev off

/*
    Reproduce appendix tables and event-study figures that are not generated.
*/

capture log close appendixresults
log using "$LOGS/03_appendix_results.log", replace text name(appendixresults)

use "$DERIVED/analysis_panel.dta", clear
local graph_size xsize(7.2) ysize(4.8)

********************************************************************************
* Appendix Table A1. Summary statistics
********************************************************************************

tempfile summary_table
postfile summaryout str50 variable str18 level double observations mean sd p25 p50 p75 ///
    using `summary_table', replace

quietly summarize SFR, detail
post summaryout ("Startup formation rate (SFR)") ("ZIP-year") ///
    (r(N)) (r(mean)) (r(sd)) (r(p25)) (r(p50)) (r(p75))

quietly summarize did, detail
post summaryout ("Post-Craigslist indicator") ("ZIP-year") ///
    (r(N)) (r(mean)) (r(sd)) (r(p25)) (r(p50)) (r(p75))

quietly summarize CL_yes, detail
post summaryout ("Ever Craigslist indicator") ("ZIP-year") ///
    (r(N)) (r(mean)) (r(sd)) (r(p25)) (r(p50)) (r(p75))

preserve
    keep zipcode zcta_pop2000 zcta_pop_density_2000 CL_entry_year_
    duplicates drop zipcode, force

    quietly summarize zcta_pop2000, detail
    post summaryout ("ZCTA 2000 population") ("ZIP") ///
        (r(N)) (r(mean)) (r(sd)) (r(p25)) (r(p50)) (r(p75))

    quietly summarize zcta_pop_density_2000, detail
    post summaryout ("ZCTA 2000 density") ("ZIP") ///
        (r(N)) (r(mean)) (r(sd)) (r(p25)) (r(p50)) (r(p75))

    quietly summarize CL_entry_year_, detail
    post summaryout ("Craigslist entry year") ("Treated ZIP") ///
        (r(N)) (r(mean)) (r(sd)) (r(p25)) (r(p50)) (r(p75))
restore

postclose summaryout

preserve
    use `summary_table', clear
    format observations %12.0fc
    format mean sd p25 p50 p75 %12.3f
    export delimited using "$TABLES/tableA1_summary_statistics.csv", replace
restore

********************************************************************************
* Appendix Tables A2-A3 and Figures A3-A4. ZIP-trend event studies
********************************************************************************

gen byte event_m5 = rel_year == -5
gen byte event_m4 = rel_year == -4
gen byte event_m3 = rel_year == -3
gen byte event_m2 = rel_year == -2
gen byte event_m1 = rel_year == -1
gen byte event_0  = rel_year == 0
gen byte event_p1 = rel_year == 1
gen byte event_p2 = rel_year == 2
gen byte event_p3 = rel_year == 3
gen byte event_p4 = rel_year == 4
gen byte event_p5 = rel_year == 5

reghdfe SFR event_m5 event_m4 event_m3 event_m2 event_m1 ///
    event_p1 event_p2 event_p3 event_p4 event_p5, ///
    absorb(zip_id year zip_id#c.year) vce(cluster zip_id)
estimates store event_omit0

test event_m5 event_m4 event_m3 event_m2 event_m1
scalar pretrend_F = r(F)
scalar pretrend_p = r(p)

tempfile event_omit0_results
postfile omit0 int event_time double estimate se using `event_omit0_results', replace
foreach k in 5 4 3 2 1 {
    post omit0 (-`k') (_b[event_m`k']) (_se[event_m`k'])
}
foreach k in 1 2 3 4 5 {
    post omit0 (`k') (_b[event_p`k']) (_se[event_p`k'])
}
postclose omit0

preserve
    use `event_omit0_results', clear
    gen ci_low = estimate - 1.96 * se
    gen ci_high = estimate + 1.96 * se
    gen pretrend_F = scalar(pretrend_F)
    gen pretrend_p = scalar(pretrend_p)
    export delimited using "$TABLES/tableA2_event_omit0.csv", replace
restore

coefplot event_omit0, ///
    keep(event_m5 event_m4 event_m3 event_m2 event_m1 ///
        event_p1 event_p2 event_p3 event_p4 event_p5) ///
    vertical ///
    coeflabels(event_m5="-5" event_m4="-4" event_m3="-3" event_m2="-2" ///
        event_m1="-1" event_p1="1" event_p2="2" event_p3="3" event_p4="4" event_p5="5") ///
    yline(0, lcolor(gs10) lwidth(thin)) ///
    xline(5.5, lpattern(solid) lcolor(gs12) lwidth(thin)) ///
    connect(l) lcolor(navy) lwidth(medthin) ///
    mcolor(navy) msymbol(Oh) msize(medsmall) ///
    ciopts(recast(rcap) lcolor(navy%70) lwidth(thin)) ///
    title("Event Study: Craigslist Entry and ZIP-Level Startup Formation", ///
        size(medsmall) color(black) position(12)) ///
    ytitle("Effect on startup formation rate", size(medsmall) margin(medium)) ///
    xtitle("Years relative to Craigslist entry", size(medsmall) margin(medium)) ///
    xlabel(, labsize(small) nogrid) ///
    ylabel(, angle(horizontal) labsize(small) nogrid format(%9.1f)) ///
    xscale(lcolor(gs8) lwidth(thin)) yscale(lcolor(gs8) lwidth(thin)) ///
    graphregion(color(white) margin(medium)) ///
    plotregion(color(white) margin(small)) bgcolor(white) `graph_size'

graph export "$FIGURES/figureA3_event_omit0.pdf", replace
graph export "$FIGURES/figureA3_event_omit0.png", replace width(2200)

reghdfe SFR event_m5 event_m4 event_m3 event_m2 event_m1 event_0 ///
    event_p1 event_p2 event_p3 event_p4 event_p5, ///
    absorb(zip_id year zip_id#c.year) vce(cluster zip_id)
estimates store event_include0

tempfile event_include0_results
postfile include0 int event_time double estimate se using `event_include0_results', replace
foreach k in 5 4 3 2 1 {
    post include0 (-`k') (_b[event_m`k']) (_se[event_m`k'])
}
post include0 (0) (_b[event_0]) (_se[event_0])
foreach k in 1 2 3 4 5 {
    post include0 (`k') (_b[event_p`k']) (_se[event_p`k'])
}
postclose include0

preserve
    use `event_include0_results', clear
    gen ci_low = estimate - 1.96 * se
    gen ci_high = estimate + 1.96 * se
    export delimited using "$TABLES/tableA3_event_include0.csv", replace
restore

coefplot event_include0, ///
    keep(event_m5 event_m4 event_m3 event_m2 event_m1 event_0 ///
        event_p1 event_p2 event_p3 event_p4 event_p5) ///
    vertical ///
    coeflabels(event_m5="-5" event_m4="-4" event_m3="-3" event_m2="-2" ///
        event_m1="-1" event_0="0" event_p1="1" event_p2="2" event_p3="3" ///
        event_p4="4" event_p5="5") ///
    yline(0, lcolor(gs10) lwidth(thin)) ///
    connect(l) lcolor(navy) lwidth(medthin) ///
    mcolor(navy) msymbol(Oh) msize(medsmall) ///
    ciopts(recast(rcap) lcolor(navy%70) lwidth(thin)) ///
    title("Event Study with Event Year 0 Estimated", ///
        size(medsmall) color(black) position(12)) ///
    ytitle("Effect on startup formation rate", size(medsmall) margin(medium)) ///
    xtitle("Years relative to Craigslist entry", size(medsmall) margin(medium)) ///
    xlabel(, labsize(small) nogrid) ///
    ylabel(, angle(horizontal) labsize(small) nogrid format(%9.1f)) ///
    xscale(lcolor(gs8) lwidth(thin)) yscale(lcolor(gs8) lwidth(thin)) ///
    graphregion(color(white) margin(medium)) ///
    plotregion(color(white) margin(small)) bgcolor(white) `graph_size'

graph export "$FIGURES/figureA4_event_include0.pdf", replace
graph export "$FIGURES/figureA4_event_include0.png", replace width(2200)

********************************************************************************
* Appendix Table A4. ZIP, county, and CBSA aggregation comparison
********************************************************************************

use "$DERIVED/analysis_panel.dta", clear
tempfile aggregation_table zip_panel
postfile aggout str12 geography double coefficient se p_value observations r_squared units ///
    using `aggregation_table', replace

reghdfe SFR did, absorb(zip_id year) vce(cluster zip_id)
egen byte tag_zip = tag(zip_id) if e(sample)
quietly count if tag_zip
local n_zip_units = r(N)
drop tag_zip
post aggout ("ZIP") (_b[did]) (_se[did]) ///
    (2 * ttail(e(df_r), abs(_b[did] / _se[did]))) (e(N)) (e(r2)) (`n_zip_units')
save `zip_panel'

drop if missing(fips)
collapse (mean) SFR did, by(fips year)
egen long county_id = group(fips)
xtset county_id year
xtreg SFR did i.year, fe vce(cluster county_id)
egen byte tag_county = tag(county_id) if e(sample)
quietly count if tag_county
local n_county_units = r(N)
drop tag_county
post aggout ("County") (_b[did]) (_se[did]) ///
    (2 * ttail(e(df_r), abs(_b[did] / _se[did]))) (e(N)) (e(r2_w)) (`n_county_units')

use `zip_panel', clear
drop if missing(CBSA)
collapse (mean) SFR did, by(CBSA year)
egen long cbsa_id = group(CBSA)
xtset cbsa_id year
xtreg SFR did i.year, fe vce(cluster cbsa_id)
egen byte tag_cbsa = tag(cbsa_id) if e(sample)
quietly count if tag_cbsa
local n_cbsa_units = r(N)
drop tag_cbsa
post aggout ("CBSA") (_b[did]) (_se[did]) ///
    (2 * ttail(e(df_r), abs(_b[did] / _se[did]))) (e(N)) (e(r2_w)) (`n_cbsa_units')

postclose aggout

use `aggregation_table', clear
format coefficient se p_value r_squared %9.4f
format observations units %12.0fc
export delimited using "$TABLES/tableA4_aggregation.csv", replace

log close appendixresults
