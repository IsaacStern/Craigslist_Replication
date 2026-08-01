version 18.0
set more off
set varabbrev off

/*
    Reproduce the paper's main exhibits:
      Figure 1: Craigslist rollout
      Table 1: baseline specification ladder
      Figure 2: baseline CSDID event study
      Table 2: density specifications
      Figure 3: density-adjusted CSDID event study
      Figure 4: kernel-weighted density profile
*/

capture log close mainresults
log using "$LOGS/02_main_results.log", replace text name(mainresults)

use "$DERIVED/zip_year_panel.dta", clear

egen long zip_id = group(zipcode)
xtset zip_id year

gen byte CL_yes = !missing(CL_entry_year_)
gen byte did = year >= CL_entry_year_ if CL_yes
replace did = 0 if missing(did)
quietly count if did == 1
assert r(N) == 223011

gen int cl_entry_year_csdid = CL_entry_year_
replace cl_entry_year_csdid = 0 if missing(cl_entry_year_csdid)
gen int rel_year = year - CL_entry_year_ if CL_yes

gen double density_1000 = zcta_pop_density_2000 / 1000
quietly summarize density_1000, detail
scalar density_median = r(p50)
gen double density_1000_c = density_1000 - density_median
gen double density_1000_c_sq = density_1000_c^2

gen double did_density_1000_c = did * density_1000_c
gen double did_density_1000_c_sq = did * density_1000_c_sq

gen byte csdid_window = cl_entry_year_csdid == 0 | inrange(rel_year, -5, 5)

label variable did "Post Craigslist"
label variable density_1000 "ZCTA density, thousands per square mile"
label variable density_1000_c "ZCTA density centered at sample median"

save "$DERIVED/analysis_panel.dta", replace

local graph_size xsize(7.2) ysize(4.8)

********************************************************************************
* Figure 1. Craigslist rollout
********************************************************************************

preserve
    keep zipcode CL_entry_year_
    duplicates drop zipcode, force
    drop if missing(CL_entry_year_)

    histogram CL_entry_year_, discrete frequency ///
        fcolor(navy%70) lcolor(navy) ///
        title("Craigslist Entry Timing Across Treated ZIP Codes", ///
            size(medsmall) color(black) position(12)) ///
        xtitle("Craigslist entry year", size(medsmall) margin(medium)) ///
        ytitle("Number of treated ZIP codes", size(medsmall) margin(medium)) ///
        xlabel(1995(2)2015, labsize(small) nogrid) ///
        ylabel(, angle(horizontal) labsize(small) nogrid format(%9.1f)) ///
        xscale(lcolor(gs8) lwidth(thin)) ///
        yscale(lcolor(gs8) lwidth(thin)) ///
        graphregion(color(white) lcolor(white%0)) ///
        plotregion(color(white) lcolor(white%0)) ///
        bgcolor(white) `graph_size' scheme(s1color)

    graph export "$FIGURES/figure1_rollout.pdf", replace
    graph export "$FIGURES/figure1_rollout.png", replace width(2200)
restore

********************************************************************************
* Table 1. Baseline specification ladder
********************************************************************************

tempfile table1
postfile table1out str24 model double coefficient se p_value observations r_squared ///
    using `table1', replace

reg SFR did, vce(cluster zip_id)
post table1out ("OLS") (_b[did]) (_se[did]) ///
    (2 * ttail(e(df_r), abs(_b[did] / _se[did]))) (e(N)) (e(r2))

xtreg SFR did, fe vce(cluster zip_id)
post table1out ("ZIP FE") (_b[did]) (_se[did]) ///
    (2 * ttail(e(df_r), abs(_b[did] / _se[did]))) (e(N)) (e(r2_w))

xtreg SFR did i.year, fe vce(cluster zip_id)
post table1out ("ZIP + year FE") (_b[did]) (_se[did]) ///
    (2 * ttail(e(df_r), abs(_b[did] / _se[did]))) (e(N)) (e(r2_w))

reghdfe SFR did, absorb(zip_id year zip_id#c.year) vce(cluster zip_id)
post table1out ("ZIP trends") (_b[did]) (_se[did]) ///
    (2 * ttail(e(df_r), abs(_b[did] / _se[did]))) (e(N)) (e(r2))

csdid SFR if csdid_window, ///
    ivar(zip_id) time(year) gvar(cl_entry_year_csdid) ///
    method(dripw) vce(cluster zip_id)

csdid_estat simple
matrix csdid_simple = r(table)
scalar csdid_att = csdid_simple[1,1]
scalar csdid_se = csdid_simple[2,1]
scalar csdid_p = csdid_simple[4,1]
quietly count if csdid_window & !missing(SFR)
scalar csdid_n = r(N)

post table1out ("CSDID") (csdid_att) (csdid_se) (csdid_p) (csdid_n) (.)
postclose table1out

preserve
    use `table1', clear
    format coefficient se p_value r_squared %9.4f
    format observations %12.0fc
    export delimited using "$TABLES/table1_baseline.csv", replace
restore

********************************************************************************
* Figure 2 and Appendix Table A5. Baseline CSDID event study
********************************************************************************

csdid_estat event, window(-5 5)
csdid_plot, ///
    title("CSDID Event Study", size(medsmall) color(black) position(12)) ///
    subtitle("Craigslist entry and ZIP-level startup formation", size(small) color(gs6)) ///
    ytitle("ATT on startup formation rate", size(medsmall) margin(medium)) ///
    xtitle("Years relative to Craigslist entry", size(medsmall) margin(medium)) ///
    xlabel(-4(1)5, labsize(small) nogrid) ///
    ylabel(0(1)10, angle(horizontal) labsize(small) nogrid format(%9.1f)) ///
    yscale(range(0 10) lcolor(gs8) lwidth(thin)) ///
    xscale(noextend lcolor(gs8) lwidth(thin)) ///
    yline(0, lcolor(none)) legend(off) ///
    graphregion(color(white) lcolor(white%0) margin(medium)) ///
    plotregion(color(white) lcolor(white%0) margin(medium)) ///
    bgcolor(white) `graph_size'

graph export "$FIGURES/figure2_csdid_event.pdf", replace
graph export "$FIGURES/figure2_csdid_event.png", replace width(2200)

csdid_estat event, window(-5 5) estore(csdid_base_event)
estimates restore csdid_base_event
matrix event_b = e(b)
matrix event_V = e(V)

tempfile csdid_base_coefficients
postfile csbase str12 term double event_time estimate se using `csdid_base_coefficients', replace
post csbase ("Pre_avg") (.) (event_b[1,"Pre_avg"]) (sqrt(event_V["Pre_avg","Pre_avg"]))
post csbase ("Post_avg") (.) (event_b[1,"Post_avg"]) (sqrt(event_V["Post_avg","Post_avg"]))
foreach k in 4 3 2 1 {
    post csbase ("Tm`k'") (-`k') (event_b[1,"Tm`k'"]) (sqrt(event_V["Tm`k'","Tm`k'"]))
}
foreach k in 0 1 2 3 4 5 {
    post csbase ("Tp`k'") (`k') (event_b[1,"Tp`k'"]) (sqrt(event_V["Tp`k'","Tp`k'"]))
}
postclose csbase

preserve
    use `csdid_base_coefficients', clear
    gen ci_low = estimate - 1.96 * se
    gen ci_high = estimate + 1.96 * se
    export delimited using "$TABLES/tableA5_csdid_event.csv", replace
restore

********************************************************************************
* Table 2. Craigslist and density interactions
********************************************************************************

tempfile table2
postfile table2out str28 model double did_b did_se linear_b linear_se ///
    quadratic_b quadratic_se observations r_squared using `table2', replace

reghdfe SFR did if !missing(density_1000_c), ///
    absorb(zip_id year zip_id#c.year) vce(cluster zip_id)
post table2out ("Base") (_b[did]) (_se[did]) (.) (.) (.) (.) (e(N)) (e(r2))

reghdfe SFR did did_density_1000_c if !missing(density_1000_c), ///
    absorb(zip_id year zip_id#c.year) vce(cluster zip_id)
post table2out ("Linear density") (_b[did]) (_se[did]) ///
    (_b[did_density_1000_c]) (_se[did_density_1000_c]) (.) (.) (e(N)) (e(r2))

reghdfe SFR did did_density_1000_c did_density_1000_c_sq, ///
    absorb(zip_id year zip_id#c.year) vce(cluster zip_id)
post table2out ("Quadratic density") (_b[did]) (_se[did]) ///
    (_b[did_density_1000_c]) (_se[did_density_1000_c]) ///
    (_b[did_density_1000_c_sq]) (_se[did_density_1000_c_sq]) (e(N)) (e(r2))

csdid SFR density_1000_c density_1000_c_sq ///
    if csdid_window & !missing(density_1000_c, density_1000_c_sq), ///
    ivar(zip_id) time(year) gvar(cl_entry_year_csdid) ///
    method(dripw) vce(cluster zip_id)

csdid_estat simple
matrix csdid_density_simple = r(table)
scalar csdid_density_att = csdid_density_simple[1,1]
scalar csdid_density_se = csdid_density_simple[2,1]
quietly count if csdid_window & !missing(SFR, density_1000_c, density_1000_c_sq)
scalar csdid_density_n = r(N)

post table2out ("CSDID + density") (csdid_density_att) (csdid_density_se) ///
    (.) (.) (.) (.) (csdid_density_n) (.)
postclose table2out

preserve
    use `table2', clear
    format did_b did_se linear_b linear_se quadratic_b quadratic_se r_squared %9.4f
    format observations %12.0fc
    export delimited using "$TABLES/table2_density.csv", replace
restore

********************************************************************************
* Figure 3 and Appendix Table A6. Density-adjusted CSDID event study
********************************************************************************

csdid_estat event, window(-5 5)
csdid_plot, ///
    title("CSDID Event Study with Density Controls", size(medsmall) color(black) position(12)) ///
    subtitle("Controlling for Census 2000 ZIP density and density squared", size(small) color(gs6)) ///
    ytitle("ATT on startup formation rate", size(medsmall) margin(medium)) ///
    xtitle("Years relative to Craigslist entry", size(medsmall) margin(medium)) ///
    xlabel(-4(1)5, labsize(small) nogrid) ///
    ylabel(0(5)30, angle(horizontal) labsize(small) nogrid format(%9.1f)) ///
    yscale(range(0 30) lcolor(gs8) lwidth(thin)) ///
    xscale(noextend lcolor(gs8) lwidth(thin)) ///
    yline(0, lcolor(none)) legend(off) ///
    graphregion(color(white) lcolor(white%0) margin(medium)) ///
    plotregion(color(white) lcolor(white%0) margin(medium)) ///
    bgcolor(white) `graph_size'

graph export "$FIGURES/figure3_csdid_density_event.pdf", replace
graph export "$FIGURES/figure3_csdid_density_event.png", replace width(2200)

csdid_estat event, window(-5 5) estore(csdid_density_event)
estimates restore csdid_density_event
matrix density_event_b = e(b)
matrix density_event_V = e(V)

tempfile csdid_density_coefficients
postfile csdensity str12 term double event_time estimate se using `csdid_density_coefficients', replace
post csdensity ("Pre_avg") (.) (density_event_b[1,"Pre_avg"]) (sqrt(density_event_V["Pre_avg","Pre_avg"]))
post csdensity ("Post_avg") (.) (density_event_b[1,"Post_avg"]) (sqrt(density_event_V["Post_avg","Post_avg"]))
foreach k in 4 3 2 1 {
    post csdensity ("Tm`k'") (-`k') (density_event_b[1,"Tm`k'"]) (sqrt(density_event_V["Tm`k'","Tm`k'"]))
}
foreach k in 0 1 2 3 4 5 {
    post csdensity ("Tp`k'") (`k') (density_event_b[1,"Tp`k'"]) (sqrt(density_event_V["Tp`k'","Tp`k'"]))
}
postclose csdensity

preserve
    use `csdid_density_coefficients', clear
    gen ci_low = estimate - 1.96 * se
    gen ci_high = estimate + 1.96 * se
    export delimited using "$TABLES/tableA6_csdid_density_event.csv", replace
restore

********************************************************************************
* Figure 4 and Appendix Table A7. Kernel-weighted density profile
********************************************************************************

use "$DERIVED/analysis_panel.dta", clear

quietly _pctile density_1000 if !missing(density_1000), p(10 90)
local density_p10 = r(r1)
local density_p90 = r(r2)
local bandwidth = (`density_p90' - `density_p10') / 2

tempfile kernel_results
postfile kernelout int density_percentile double density_1000 effect se ///
    ci_low ci_high observations using `kernel_results', replace

foreach percentile in 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 {
    quietly _pctile density_1000 if !missing(density_1000), p(`percentile')
    local target_density = r(r1)

    capture drop density_distance kernel_weight did_density_distance

    * Double precision is essential after absorbing ZIP-specific trends.
    gen double density_distance = density_1000 - `target_density'
    gen double kernel_weight = 1 - abs(density_distance / `bandwidth')
    replace kernel_weight = 0 if kernel_weight < 0 | missing(kernel_weight)
    gen double did_density_distance = did * density_distance

    quietly count if kernel_weight > 0 & !missing(SFR, did, did_density_distance)
    local local_n = r(N)

    quietly reghdfe SFR did did_density_distance [aw=kernel_weight] ///
        if kernel_weight > 0, ///
        absorb(zip_id year zip_id#c.year) vce(cluster zip_id)

    post kernelout (`percentile') (`target_density') (_b[did]) (_se[did]) ///
        (_b[did] - 1.96 * _se[did]) (_b[did] + 1.96 * _se[did]) (`local_n')
}
postclose kernelout

use `kernel_results', clear
export delimited using "$TABLES/tableA7_kernel_density.csv", replace
save "$OUTDATA/kernel_density_estimates.dta", replace

quietly summarize ci_low
local y_min = floor(r(min))
quietly summarize ci_high
local y_max = ceil(r(max))

twoway ///
    (rarea ci_high ci_low density_percentile, sort ///
        color(ltblue%35) lcolor(ltblue%55) lwidth(vthin)) ///
    (line effect density_percentile, sort lcolor(navy) lwidth(medthick)), ///
    yline(0, lcolor(gs10) lwidth(thin)) ///
    xlabel(5 "5th" 25 "25th" 50 "50th" 75 "75th" 95 "95th", labsize(small) nogrid) ///
    ylabel(`y_min'(1)`y_max', angle(horizontal) labsize(small) nogrid format(%9.1f)) ///
    xtitle("ZIP density percentile", size(medsmall) margin(medium)) ///
    ytitle("Estimated effect on SFR", size(medsmall) margin(medium)) ///
    title("Craigslist Effects Rise with ZIP Density", size(medsmall) color(black)) ///
    subtitle("Local-linear estimates with 95 percent confidence band", size(small) color(gs6)) ///
    legend(order(2 "Local-linear estimate" 1 "95% CI") rows(1) position(6) ///
        size(small) region(lcolor(none) fcolor(none))) ///
    graphregion(color(white) margin(medium)) ///
    plotregion(color(white) margin(small)) bgcolor(white) ///
    xscale(range(5 95) lcolor(gs8) lwidth(thin)) ///
    yscale(range(`y_min' `y_max') lcolor(gs8) lwidth(thin)) `graph_size'

graph export "$FIGURES/figure4_kernel_density.pdf", replace
graph export "$FIGURES/figure4_kernel_density.png", replace width(2200)

log close mainresults
