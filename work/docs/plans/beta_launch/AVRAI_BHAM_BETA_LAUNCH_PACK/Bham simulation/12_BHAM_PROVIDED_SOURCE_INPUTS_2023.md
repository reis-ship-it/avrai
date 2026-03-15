# BHAM Provided Source Inputs 2023

**Date logged:** March 11, 2026  
**Purpose:** explicit record of user-provided source links, local files, and access grants added during Wave 8 replay intake work

## Access Provisioned

- `BEA / U.S. Census Bureau Economic Series`
  - access state: `provisioned locally`
  - note: API key was provided out-of-band on March 11, 2026 and intentionally is **not** stored in the repository
  - validation result: Jefferson County (`01073`) 2023 `CAINC1` line 3 query succeeded
  - docs:
    - https://apps.bea.gov/api/_pdf/bea_web_service_api_user_guide.pdf
    - https://apps.bea.gov/API/_pdf/bea_api_tos.pdf
    - https://apps.bea.gov/developers/r-index.htm
    - https://github.com/us-bea/
    - https://github.com/us-bea/bea_geo_aggregator

## UAB Inputs Provided

- campus calendar 2023:
  - https://calendar.uab.edu/calendar/day/2023/1/1?card_size=small&order=date&days=366&experience=
- academic calendar 2022-2023:
  - https://www.uab.edu/students/academics/academic-calendar/2022-2023
- academic calendar 2023-2024:
  - https://www.uab.edu/students/academics/academic-calendar/2023-2024
- current intake state:
  - academic term windows are available for replay timing
  - event-level campus normalization is still pending
  - clinical-schedule extraction is still pending

## Birmingham OpenGov Inputs Provided

- portal:
  - https://data.birminghamal.gov/dataset/
- ACFR 2023:
  - https://s3.amazonaws.com/og-production-open-data-birminghamal-892364687672/resources/e8caddb7-6cdc-42a5-8927-8e7d7e9eed3e/acfr-print-file-01222024.pdf
- FY23 operating budget:
  - https://s3.amazonaws.com/og-production-open-data-birminghamal-892364687672/resources/9113d270-945f-4d8b-bf9a-1fc116445763/fy23-official-operating-budget-final.pdf
- planning commission archive:
  - https://data.birminghamal.gov/dataset/birmingham-planning-commission-archive-2023-2019
- Magic City Classic agreement:
  - https://data.birminghamal.gov/dataset/magic-city-classic-contract-2023-2026/resource/0383f73c-486d-45a8-a593-9ecf184a1602
- precinct crime CSVs:
  - east: https://s3.amazonaws.com/og-production-open-data-birminghamal-892364687672/resources/83954d55-51a3-4a57-8181-bcd00d961ead/open-data-east-dec-2023.csv
  - north: https://s3.amazonaws.com/og-production-open-data-birminghamal-892364687672/resources/21397b4a-e99a-42f5-993f-713c87742653/open-data-north-dec-2023.csv
  - south: https://s3.amazonaws.com/og-production-open-data-birminghamal-892364687672/resources/fb772dd6-8b92-4735-978c-790bd4c21e10/open-data-south-dec-2023.csv
  - west: https://s3.amazonaws.com/og-production-open-data-birminghamal-892364687672/resources/4b3640fe-ccea-4135-acce-dd5ee1b28c16/open-data-west-dec-2023.csv
- current intake state:
  - OpenGov locality/civic lane is materially improved
  - planning commission archive is useful for later locality/zoning/permitting context
  - public crime CSVs are partial safety inputs, not a replacement for full court/dispatch access

## Municipal Finance Inputs Provided

- local files:
  - /Users/reisgordon/Downloads/2023.2.3.open-data.finance.advertising-invoice-and-payment-reports.bhamtimes.pdf
  - /Users/reisgordon/Downloads/budget-by-revenue-type-january-2023.pdf
  - /Users/reisgordon/Downloads/budget-by-revenue-type-february-2023.pdf
  - /Users/reisgordon/Downloads/budget-by-revenue-type-march-2023.pdf
  - /Users/reisgordon/Downloads/budget-by-revenue-type-april-2023.pdf
  - /Users/reisgordon/Downloads/budget-by-revenue-type-may-2023.pdf
- remote files:
  - July: https://s3.amazonaws.com/og-production-open-data-birminghamal-892364687672/resources/5fc81463-230b-403c-a889-784c7a26a1e3/budget-by-revenue-type-july-2023.pdf
  - August: https://s3.amazonaws.com/og-production-open-data-birminghamal-892364687672/resources/65462364-d758-4d08-91b2-231426d7ba87/budget-by-revenue-type-august-2023.pdf
  - September: https://s3.amazonaws.com/og-production-open-data-birminghamal-892364687672/resources/684bc3f1-2510-49e6-a77a-638a880f701c/budget-by-revenue-type-september-2023.pdf
  - October: https://s3.amazonaws.com/og-production-open-data-birminghamal-892364687672/resources/6ba74459-dd9f-4dc2-94ff-4a4b5e91f841/budget-by-revenue-type-october-2023.pdf
  - November: https://s3.amazonaws.com/og-production-open-data-birminghamal-892364687672/resources/9afa850e-1062-4bff-95d6-8f7582cee4dc/budget-by-revenue-type-november-2023.pdf
  - December: https://s3.amazonaws.com/og-production-open-data-birminghamal-892364687672/resources/8be4284c-24af-49f1-b49a-92da05fc8587/budget-by-revenue-type-december-2023.pdf
- current intake state:
  - January-May PDFs were inspected locally
  - July-December URLs are logged
  - June 2023 revenue remains missing
  - Birmingham Times advertising invoice report is logged as a civic/publicity-finance enrichment source, not a core budget substitute

## Housing Inputs Provided

- local file:
  - /Users/reisgordon/Downloads/Redfin Monthly Housing Market Data-2.pdf
- current intake state:
  - enough to approve a first-pass public housing signal lane
  - still not a replacement for richer MLS or proprietary rent feeds

## Safety / Crime Inputs Provided

- FBI trend explorer:
  - https://cde.ucr.cjis.gov/LATEST/webapp/#/pages/explorer/crime/crime-trend
- Birmingham precinct CSVs:
  - east / north / south / west links listed above
- current intake state:
  - partial public safety lane is available
  - full municipal court / records access is still unavailable
  - this lane remains review-gated in the main registry

## Culture / Event Inputs Provided

- Birmingham365:
  - https://birmingham365.org
- City festivals:
  - https://www.birminghamal.gov/play/city-birmingham-festivals
- Arts and museums:
  - https://www.birminghamal.gov/play/arts-museums
- current intake state:
  - useful for later event/culture enrichment
  - not yet elevated into the authoritative replay registry because historical 2023 extraction and normalization are still pending

## Explicit Defers / Unavailable Sources

- `Data Axle / InfoGroup Business Listings`
  - deferred because paid access is not wanted right now
- `Resy / OpenTable`
  - inaccessible without restaurant-partner access
- `DoorDash / Uber Eats merchant analytics`
  - inaccessible without merchant/customer export access
- `Municipal court / records`
  - not obtained
