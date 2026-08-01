version 18.0
clear all
set more off
set varabbrev off
set seed 20260801

/*
    Master replication file
    Bazaar Effects in the Digital Marketplace

    Run this file from the replication-package root:

        cd "/path/to/Craigslist_Replication_Package"
        do master.do

    The code intentionally reproduces only results reported in the paper.
*/

global ROOT "`c(pwd)'"

capture confirm file "$ROOT/master.do"
if _rc {
    display as error "Run master.do from the Craigslist_Replication_Package directory."
    error 601
}

global SOURCE  "$ROOT/data/source"
global DERIVED "$ROOT/data/derived"
global OUTPUT  "$ROOT/output"
global FIGURES "$OUTPUT/figures"
global TABLES  "$OUTPUT/tables"
global LOGS    "$OUTPUT/logs"
global OUTDATA "$OUTPUT/data"

capture mkdir "$DERIVED"
capture mkdir "$OUTPUT"
capture mkdir "$FIGURES"
capture mkdir "$TABLES"
capture mkdir "$LOGS"
capture mkdir "$OUTDATA"

capture log close _all
log using "$LOGS/master.log", replace text

display as text "Stata environment"
about

* Required community-contributed commands. Installation instructions are in README.md.
which reghdfe
which csdid
which csdid_plot
which coefplot
which honestdid

* The manuscript figures were rendered with this scheme.
set scheme cleanplots

do "$ROOT/code/01_build_panel.do"
do "$ROOT/code/02_main_results.do"
do "$ROOT/code/03_appendix_results.do"
do "$ROOT/code/04_honestdid.do"
do "$ROOT/code/05_validate_outputs.do"

display as result "Replication completed successfully."
display as result "Figures: $FIGURES"
display as result "Tables:  $TABLES"

log close
