version 18.0
set more off
set varabbrev off

/*
    Reproduce Appendix Figures A1-A2 using Rambachan and Roth's HonestDiD
    relative-magnitude sensitivity analysis.
*/

capture log close honestresults
log using "$LOGS/04_honestdid.log", replace text name(honestresults)

use "$DERIVED/analysis_panel.dta", clear
keep if cl_entry_year_csdid == 0 | inrange(rel_year, -5, 5)

********************************************************************************
* Appendix Figure A1. Baseline HonestDiD sensitivity
********************************************************************************

csdid SFR, ///
    ivar(zip_id) time(year) gvar(cl_entry_year_csdid) ///
    method(dripw) vce(cluster zip_id)

csdid_estat event, window(-5 5) estore(honest_base_event)
estimates restore honest_base_event

* Average event-year 0 through +5 effects with equal weights.
matrix average_post = (1/6 \ 1/6 \ 1/6 \ 1/6 \ 1/6 \ 1/6)

honestdid, ///
    pre(3/6) post(7/12) l_vec(average_post) ///
    mvec(0(0.25)3) delta(rm) alpha(0.05) coefplot ///
    title("HonestDiD Sensitivity of the Post-Craigslist Effect", size(medsmall)) ///
    subtitle("Average CSDID effect from event year 0 through +5", size(small)) ///
    xtitle("Allowed violation relative to the largest pre-treatment violation") ///
    ytitle("Robust 95% confidence interval for the SFR effect") ///
    yline(0, lcolor(gs8) lwidth(thin)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    bgcolor(white) legend(off)

graph export "$FIGURES/figureA1_honestdid.pdf", replace
graph export "$FIGURES/figureA1_honestdid.png", replace width(2200)

********************************************************************************
* Appendix Figure A2. HonestDiD with density controls
********************************************************************************

csdid SFR density_1000_c density_1000_c_sq ///
    if !missing(density_1000_c, density_1000_c_sq), ///
    ivar(zip_id) time(year) gvar(cl_entry_year_csdid) ///
    method(dripw) vce(cluster zip_id)

csdid_estat event, window(-5 5) estore(honest_density_event)
estimates restore honest_density_event

honestdid, ///
    pre(3/6) post(7/12) l_vec(average_post) ///
    mvec(0(0.05)1) delta(rm) alpha(0.05) coefplot ///
    title("HonestDiD Sensitivity with Density Controls", size(medsmall)) ///
    subtitle("Average CSDID effect from event year 0 through +5", size(small)) ///
    xtitle("Allowed violation relative to the largest pre-treatment violation") ///
    ytitle("Robust 95% confidence interval for the SFR effect") ///
    yline(0, lcolor(gs8) lwidth(thin)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    bgcolor(white) legend(off)

graph export "$FIGURES/figureA2_honestdid_density.pdf", replace
graph export "$FIGURES/figureA2_honestdid_density.png", replace width(2200)

log close honestresults

