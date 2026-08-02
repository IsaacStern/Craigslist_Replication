# Data sources and availability

## 1. Startup Cartography Project

**File:** `data/source/scp/Entrepreneurship_by_ZIP_Code_academic.dta`

**Contents:** ZIP-year measures for 1988-2016, including Startup Formation Rate (`SFR`), Entrepreneurial Quality Index (`EQI`), and Regional Entrepreneurship Cohort Potential Index (`RECPI`).

**Role:** Supplies the paper's outcome and panel structure.

**Documented source page:** https://www.startupcartography.com/data

## 2. Craigslist entry timing

**File:** `data/source/craigslist/CL_entry.dta`

**Contents:** County FIPS, official and broad Craigslist entry months, site URLs, and broad-coverage URLs.

**Role:** Supplies staggered treatment timing. The build script assigns each ZIP the earliest entry among counties to which it maps.

**Origin:** Included with the Craigslist expansion replication materials used by Djourelova and coauthors. This package begins with their coded county-entry file rather than independently reconstructing launch dates from archived webpages.

## 3. ZIP-to-county crosswalk

**File:** `data/source/crosswalks/ZIP_to_FIPS.csv`

**Contents:** ZIP codes, county FIPS codes, state abbreviations, and county names. ZIPs may map to multiple counties.

**Role:** Links county-level Craigslist entry timing to SCP ZIP codes.

**Outstanding provenance issue:** The file schema and filename correspond to Domo's `zip_to_fips.csv` Dimensions product, but the project retained neither the original download note nor a permanent URL for this particular March 2024 extract. Exact reproduction is possible from the included file, but a public archive should describe this attribution as inferred or replace the file with a documented crosswalk and report whether results change.

**Documentation:** https://www.domo.com/docs/s/article/360042931454

## 4. Census 2000 ZCTA Gazetteer

**File:** `data/source/census/zcta5.txt`

**Contents:** Census 2000 ZCTA population, housing units, land and water area, and internal coordinates.

**Role:** Constructs population density as ZCTA population divided by ZCTA land area in square miles.

**Origin:** U.S. Census Bureau Census 2000 Gazetteer file for five-digit ZIP Code Tabulation Areas.

**Census archive:** https://www2.census.gov/geo/docs/maps-data/data/gazetteer/zcta5.zip

## 5. NBER county-to-CBSA crosswalk

**File:** `data/source/crosswalks/cbsa2fipsxw_2020.csv`

**Contents:** County FIPS to 2020 Core-Based Statistical Area assignments.

**Role:** Assigns ZIP observations to CBSAs for the appendix aggregation comparison.

**Origin:** NBER Census CBSA-to-FIPS county crosswalk, March 2020 version.

**NBER source page:** https://www.nber.org/research/data/census-core-based-statistical-area-cbsa-federal-information-processing-series-fips-county-crosswalk
