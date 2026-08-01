version 18.0
set more off
set varabbrev off

/*
    Confirm that regenerated headline results agree with the paper.
    Coefficient tolerances allow only rounding differences.
*/

capture log close validation
log using "$LOGS/05_validate_outputs.log", replace text name(validation)

import delimited "$TABLES/table1_baseline.csv", clear varnames(1)

assert abs(coefficient - 51.879) < 0.01 if model == "OLS"
assert abs(coefficient - 43.942) < 0.01 if model == "ZIP FE"
assert abs(coefficient - 20.845) < 0.01 if model == "ZIP + year FE"
assert abs(coefficient - 2.954) < 0.01 if model == "ZIP trends"
assert abs(coefficient - 5.781) < 0.01 if model == "CSDID"

assert observations == 824710 if inlist(model, "OLS", "ZIP FE", "ZIP + year FE")
assert observations == 824033 if model == "ZIP trends"
assert observations == 518433 if model == "CSDID"

import delimited "$TABLES/table2_density.csv", clear varnames(1)

assert abs(did_b - 4.216) < 0.01 if model == "Base"
assert abs(did_b - 4.078) < 0.01 if model == "Linear density"
assert abs(did_b - 3.640) < 0.01 if model == "Quadratic density"
assert abs(did_b - 10.734) < 0.01 if model == "CSDID + density"
assert abs(linear_b - 0.379) < 0.01 if model == "Quadratic density"
assert abs(quadratic_b - (-0.005)) < 0.001 if model == "Quadratic density"

assert observations == 707161 if inlist(model, "Base", "Linear density", "Quadratic density")
assert observations == 454497 if model == "CSDID + density"

import delimited "$TABLES/tableA4_aggregation.csv", clear varnames(1)
assert abs(coefficient - 20.845) < 0.01 if geography == "ZIP"
assert abs(coefficient - 9.921) < 0.01 if geography == "County"
assert abs(coefficient - 11.264) < 0.01 if geography == "CBSA"

import delimited "$TABLES/tableA5_csdid_event.csv", clear varnames(1)
assert abs(estimate - 2.614) < 0.01 if term == "Pre_avg"
assert abs(estimate - 5.784) < 0.01 if term == "Post_avg"
assert abs(estimate - 1.831) < 0.01 if term == "Tm4"
assert abs(estimate - 8.511) < 0.01 if term == "Tp5"

import delimited "$TABLES/tableA6_csdid_density_event.csv", clear varnames(1)
assert abs(estimate - 3.200) < 0.01 if term == "Pre_avg"
assert abs(estimate - 10.731) < 0.01 if term == "Post_avg"
assert abs(estimate - 3.515) < 0.01 if term == "Tm4"
assert abs(estimate - 18.601) < 0.01 if term == "Tp5"

import delimited "$TABLES/tableA7_kernel_density.csv", clear varnames(1)
assert _N == 19
assert abs(effect - 0.506) < 0.02 if density_percentile == 5
assert abs(effect - 4.669) < 0.02 if density_percentile == 75
assert abs(effect - 5.517) < 0.02 if density_percentile == 80
assert abs(effect - 2.603) < 0.02 if density_percentile == 95

import delimited "$TABLES/tableA1_summary_statistics.csv", clear varnames(1)
assert observations == 824710 if variable == "Startup formation rate (SFR)"
assert observations == 31264 if variable == "ZCTA 2000 population"
assert observations == 31264 if variable == "ZCTA 2000 density"
assert observations == 22601 if variable == "Craigslist entry year"

foreach figure in figure1_rollout figure2_csdid_event ///
    figure3_csdid_density_event figure4_kernel_density ///
    figureA1_honestdid figureA2_honestdid_density ///
    figureA3_event_omit0 figureA4_event_include0 {
    confirm file "$FIGURES/`figure'.pdf"
    confirm file "$FIGURES/`figure'.png"
}

file open validation_note using "$OUTPUT/VALIDATION_PASSED.txt", write replace
file write validation_note "All headline coefficients and sample sizes match the paper within the documented rounding tolerances." _n
file close validation_note

display as result "Validation passed: regenerated outputs match the paper."
log close validation
