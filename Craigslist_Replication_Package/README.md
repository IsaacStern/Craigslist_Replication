# Bazaar Effects in the Digital Marketplace

**Author:** Isaac Stern, Wesleyan University

This repository reproduces the tables and figures reported in *Bazaar Effects in the Digital Marketplace*. The pipeline begins with the earliest source-level files available for this project, constructs the ZIP-year analysis panel, estimates the reported models, exports publication figures and tidy tables, and verifies the headline results against the manuscript.

## Reproduction status

The package is self-contained at the **published source-data level**, but not at the underlying micro-record level. The Startup Cartography Project input is a ZIP-year data product created by its authors from business-registration microdata; those underlying registrations and the SCP prediction pipeline are not present. Likewise, the Craigslist entry file comes from the authors' replication materials rather than from a new scrape of historical Craigslist pages.

One source-provenance issue remains before public release: `ZIP_to_FIPS.csv` is present and fully reproducible as an input, but the workspace does not identify its original publisher or download URL. Its checksum is recorded, and its role is documented in `DATA_SOURCES.md`.

## Repository structure

```text
master.do                         Runs the complete pipeline
code/01_build_panel.do            Constructs the ZIP-year panel
code/02_main_results.do           Reproduces all main tables and figures
code/03_appendix_results.do       Reproduces appendix statistics and comparisons
code/04_honestdid.do              Reproduces HonestDiD sensitivity figures
code/05_validate_outputs.do       Checks results against manuscript values
data/source/                      Source-level input files
data/derived/                     Generated analysis datasets
output/figures/                   Generated PDF and PNG figures
output/tables/                    Generated tidy CSV tables
output/logs/                      Stata logs
output/data/                      Generated coefficient datasets
```

## Software

The code is written for Stata 18. Install the required community-contributed packages once:

```stata
ssc install ftools, replace
ssc install reghdfe, replace
ssc install drdid, replace
ssc install csdid, replace
ssc install coefplot, replace
net install cleanplots, from("https://tdmize.github.io/data") replace
net install honestdid, from("https://raw.githubusercontent.com/mcaceresb/stata-honestdid/main") replace
honestdid _plugin_check
```

Package updates can produce small numerical differences. `code/05_validate_outputs.do` allows only the rounding tolerance used in the paper and stops if headline estimates drift materially.

## Running the replication

Open Stata, change the working directory to this repository, and run:

```stata
cd "/path/to/Craigslist_Replication_Package"
do master.do
```

The CSDID and 19 kernel-weighted high-dimensional fixed-effect regressions are computationally intensive. The master file writes separate logs for each stage so a failed run can be diagnosed without rerunning earlier stages manually.

Successful completion creates `output/VALIDATION_PASSED.txt`.

## Paper-output map

| Paper exhibit | Generated file |
|---|---|
| Figure 1: rollout | `output/figures/figure1_rollout.pdf` |
| Table 1: baseline ladder | `output/tables/table1_baseline.csv` |
| Figure 2: baseline CSDID event study | `output/figures/figure2_csdid_event.pdf` |
| Table 2: density specifications | `output/tables/table2_density.csv` |
| Figure 3: density-adjusted CSDID | `output/figures/figure3_csdid_density_event.pdf` |
| Figure 4: kernel density profile | `output/figures/figure4_kernel_density.pdf` |
| Appendix Table A1 | `output/tables/tableA1_summary_statistics.csv` |
| Appendix Table A2 | `output/tables/tableA2_event_omit0.csv` |
| Appendix Table A3 | `output/tables/tableA3_event_include0.csv` |
| Appendix Table A4 | `output/tables/tableA4_aggregation.csv` |
| Appendix Table A5 | `output/tables/tableA5_csdid_event.csv` |
| Appendix Table A6 | `output/tables/tableA6_csdid_density_event.csv` |
| Appendix Table A7 | `output/tables/tableA7_kernel_density.csv` |
| Appendix Figure A1 | `output/figures/figureA1_honestdid.pdf` |
| Appendix Figure A2 | `output/figures/figureA2_honestdid_density.pdf` |
| Appendix Figure A3 | `output/figures/figureA3_event_omit0.pdf` |
| Appendix Figure A4 | `output/figures/figureA4_event_include0.pdf` |

## Construction decisions

- ZIPs that map to multiple counties receive the earliest Craigslist entry date among their mapped counties.
- ZIPs without a matched entry date remain never treated.
- The SCP source contains 60 surplus rows that are exact duplicates; they are removed using the ZIP-year key.
- Density equals Census 2000 ZCTA population divided by ZCTA land area in square miles.
- Density is measured in thousands of residents per square mile and centered at the panel median for interaction models.
- CBSA identifiers are assigned by merging the selected treatment county to the NBER 2020 county-CBSA crosswalk. This reproduces the manuscript's existing panel exactly.
- CSDID uses never-treated ZIPs as controls and retains treated observations from event time -5 through +5 while retaining never-treated observations in all years.
- The kernel figure estimates 19 local-linear treatment coefficients from the 5th through 95th density percentiles using triangular weights.
- Kernel distance and weight variables are stored in double precision. Single-precision intermediates are numerically unstable in this model after ZIP-specific trends are absorbed and do not reproduce the paper.

The manuscript values checked by the pipeline are collected in `EXPECTED_RESULTS.md`. This provides a compact audit target without treating previously generated estimates as inputs.
