# BHAM Source Registry

**Date:** March 9, 2026  
**Status:** Active working document  
**Purpose:** Concrete registry table implementing the source intake plan from `02_BHAM_SOURCE_REGISTRY_AND_REPLAY_INTAKE_PLAN.md`.

Machine-readable companion:

- `03_BHAM_SOURCE_REGISTRY_DATA.json` is the governed selector input for Wave 8 replay-year scoring.
- `06_BHAM_REPLAY_YEAR_SELECTION.md` records the current scored replay-year recommendation from that JSON registry.

## Source Intake Registry

### Tier 1: Core Physical, Demographic, Spatial & Economic Reality
*Ingest Priority 1: Do not proceed until these are successfully mapped and loaded.*

| Source Name | Category | Entity Coverage | Earliest | Most Recent | Richest Year | Access Method / Notes |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **BEA / U.S. Census Bureau (Economic)** | Economic | Personal income, consumer spending, median wages across Greater Bham | 1969 | 2025 | 2019 | API. Seeds the starting wallets, financial limits, and salary priors for simulated citizens. |
| **Bureau of Labor Statistics (BLS) / State DOL** | Economic | Occupational distribution, industry sectors | 1990 | 2026 | 2021 | API/Reports. Dictates agent job types (e.g., healthcare vs manufacturing), mapping them to specific work venues and shift hours. |
| **Municipal Budgets & Tax Revenue** | Economic | City-wide sales/property tax revenue, civic funding | 2005 | 2026 | 2023 | OpenData. Establishes the macro-financial health of the city governments and service limits. 2023 ACFR, FY23 operating budget, Jan-May local PDFs, and Jul-Dec revenue URLs are now logged. |
| **U.S. Census ACS** | Demographics | Population priors, age distributions, childrearing/family sizes | 2005 | 2024 | 2020 | API. Crucial for generating accurate family unit sizes, age-based routines, and child-care needs. |
| **National/Local Pet Ownership Models (AVMA)** | Demographics | Dog/Cat ownership rates by neighborhood | 2007 | 2025 | 2022 | Survey/Statistical. Modifies family structures to include pets, dictating entirely new routine vectors (dog walking, pet stores, dog parks). |
| **ADPH / CDC Vital Statistics** | Health | Birth rates, death rates, hospital admission rates, public health | 1990 | 2025 | 2021 | API/Reports. Dictates the natural life-cycle events of simulated agents (spawning newborns, agent deaths, medical emergencies). |
| **ADPH / County Probate Data** | Demographics | Marriage rates, divorce rates | 1980 | 2026 | 2019 | API/OpenData. Triggers massive household shifts—merging or splitting agent families and altering joint financial wallets. |
| **U.S. Census Migration Flows** | Demographics | County-to-county migration, out-of-state influx | 2005 | 2024 | 2020 | API. Tells us exactly where new residents are coming from and leaving for. |
| **USPS NCOA (Change of Address)** | Demographics | Real-time moving trends, neighborhood flight | 2010 | 2026 | 2021 | Commercial API. Tracks hyper-local relocation, gentrification, and state-line "brain drain". |
| **USCIS / Local Resettlement (e.g., Inspiritus)**| Demographics | International immigration, refugee placement | 2000 | 2025 | 2018 | OpenData/Local. Injects distinct international cultural routines/ideas to normalize to Birmingham. |
| **LEHD / OnTheMap** | Movement | Commuter flows, day/night location | 2002 | 2023 | 2019 | API. Vital for modeling commutes between suburbs (Hoover, Vestavia) and downtown. |
| **JeffCo, Shelby, St. Clair & Blount GIS / Tax Assessors** | Spatial | Tax parcels, building footprints, zoning | 1998 | 2026 | 2024 | ESRI/Shapefile. Crucial for realistic venue capacities across the Greater Birmingham area. |
| **City of Birmingham OpenGov**| Spatial | Civic boundaries, 99 neighborhood boundaries | 2015 | 2026 | 2023 | OpenData Portal. Strict polygons for Southside, Avondale, Woodlawn, etc. |
| **Municipal GIS (Hoover, Vestavia, Mtn Brook, Trussville, Irondale)** | Spatial | Suburban city limits, local zoning | 2010 | 2026 | 2023 | Local portals. Required for distinct locality agents and suburban routines. |
| **USGS National Map** | Spatial | Topography, elevation (Red Mountain, etc.)| 1985 | 2025 | 2020 | REST API/Shapefile. Dictates physical movement limits between valleys. |
| **Alabama Power / BWW (Water Works) Outages**| Infrastructure| Power grid failures, water main breaks, rolling blackouts | 2010 | 2026 | 2011 | API/Scrape. Crucial for multi-year friction. Disables entire neighborhood grids and forces sudden venue closures. |
| **NWS / NOAA Weather API** | Environment | Severe weather, tornadoes, flooding, heatwaves | 1950 | 2026 | 2011 | API. Introduces chaotic environmental friction. (2011 April Super Outbreak is the richest). |
| **FEMA / Local EMA Disasters** | Environment | Disaster declarations, relief zones, fire perimeters | 1980 | 2026 | 2011 | OpenData. Shifts entire locality logic to "survival/relief" mode, overriding normal agent chores. |
| **MAX Transit GTFS Feed** | Movement | Bus routes, stops, schedules | 2014 | 2026 | 2019 | Standard GTFS format. Public transit rhythm priors. |
| **ALDOT Traffic Data** | Movement | Highway traffic counts, major artery flows | 2000 | 2026 | 2019 | API. Helps model commute rush hours on I-65 and Hwy 280. |
| **ALDOT Long-Term Construction Projects** | Movement | Bridge replacements (I-20/59), lane expansions, permanent detours | 2005 | 2026 | 2019 | API/Reports. Essential for multi-year runs. Reshapes entire city-wide commute patterns for 12-18 month stretches. |
| **ALDOT Crash & Incident Reports** | Movement | Vehicle collisions, lane closures, severe wrecks | 2009 | 2026 | 2022 | API/OpenData. Injects chaotic, localized traffic friction and triggers emergency response/police routines. |
| **BHM Airport Flight Data & TSA Throughput** | Movement | Daily flights, business travel, holiday mass travel | 1990 | 2026 | 2019 | API/Scrape. Simulates regular daily migration patterns of travelers and massive holiday exodus/influx waves. |
| **ALDOT Commercial & Freight Routing** | Movement | Trucking lanes, shipping logistics, I-65 heavy freight | 2010 | 2026 | 2022 | API/OpenData. Essential for modeling truck rhythms and supply-chain logistics. |
| **CSX / Norfolk Southern Rail Timetables** | Movement | Freight rail delays, downtown train crossings | 2005 | 2026 | 2022 | Scrape/API. Dictates heavy industrial movement and intermittent street traffic blockages. |
| **Municipal Waste & Sanitation Routes** | Common | Garbage trucks, recycling pickups, street sweepers | 2012 | 2026 | 2023 | API/Schedules. The invisible morning rhythm. Blocks residential streets and dictates hyper-local morning friction. |

### Tier 2: Major Anchor Institutions & Education (The Gravity Wells)
*Ingest Priority 2: Ingest these to provide the massive gravitational "pull" that dictates large crowd movements.*

| Source Name | Category | Entity Coverage | Earliest | Most Recent | Richest Year | Access Method / Notes |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **UAB Academic, Clinical & Event Calendars** | Institution | World model for students, medical staff, professors | 2000 | 2026 | 2023 | Calendar Sync/Scrape/Campus Map. Highest density gravity well in the city. |
| **Samford University Calendars & Campus Map** | Institution | Homewood campus routines, student/faculty life | 2005 | 2026 | 2023 | Portal/Sync. Crucial for simulating the Homewood/Lakeshore rhythm. |
| **Religious Institutions & Congregration Sizes**| Institution | Churches, Mosques, Synagogues, service times | 1995 | 2026 | 2019 | API / Church directories. Massive gravity wells in the South; completely rewrites Sunday morning and Wednesday night movement priors. |
| **UAB/Samford Out-of-State & Int'l Enrollment**| Institution | Student origins, massive seasonal cultural influx | 1990 | 2025 | 2022 | Reports/Data. Pulls thousands of young agents from distinct origins, injecting new ideas. |
| **JeffCo, Shelby & Mtn Brook Boards of Education** | Education | School locations, calendars, teacher/student counts | 2000 | 2026 | 2022 | API/Scrape. Dictates morning/afternoon routines for parent and teacher agents. |
| **BJCC / Legacy Arena / Protective Stadium**| Venues | Concerts, large gatherings, traffic surges | 1995 | 2026 | 2022 | Web / Calendar. Primary generator of massive one-off evening anomalies. (World Games 2022 is richest). |
| **Birmingham Botanical Gardens** | Recreation | Weekend/seasonal plant sales, gardening classes, tourism | 2000 | 2026 | 2023 | Calendar/Scrape. Massive botanical gravity well modifying suburban families' weekend movements. |
| **SEC & College Football TV Schedules**| Events | Bama, Auburn, UAB game times | 1990 | 2026 | 2023 | Calendar/API. The ultimate Saturday macro-override. Entire agent populations halt routines to watch or travel. |
| **Oak Mountain State Park Data** | Recreation | Trails, park hours, massive event days | 2005 | 2026 | 2021 | State Park portal. The largest suburban recreation gravity well. |
| **Birmingham Barons & Legion FC** | Venues | Sports schedules, Regions Field events | 2013 | 2026 | 2022 | Calendar / ICS. Creates highly predictable weekend/evening rhythms. |
| **Major Venue Calendars and Historical Venue Calendars** | Venues | Saturn, Iron City, The Nick, Alabama Theatre, Lyric Theatre, Alys Stephens Center, Workplay, BJCC campus, Oak Mountain Amphitheatre, plus legacy venue calendars | 2013 | 2026 | 2023 | Official venue calendars / venue sites / historical venue memory. Use for nightlife and large-event gravity wells, and retain historical venues even when current operating status changes. |

### Tier 3: Commercial & Daily Routine POIs (The Micro-World)
*Ingest Priority 3: Granular destinations for individual simulated agent routines (chores, health, errands).*

| Source Name | Category | Entity Coverage | Earliest | Most Recent | Richest Year | Access Method / Notes |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **OpenStreetMap (OSM) POI Data** | Commerce | Grocery stores, dry cleaners, parks, services | 2008 | 2026 | 2024 | Overpass API. Excellent open-source baseline for daily routine destinations. |
| **Country Clubs & Private Social Clubs** | Social | Golf courses, The Club, private pools | 2010 | 2026 | 2022 | Scrape. Establishes elite-tier socializing, exclusive networking nodes, and distinct geographic recreation paths. |
| **Google Places API / Yelp Data** | Commerce | Operating hours, vets, doctors, flower shops, cobblers | 2011 | 2026 | 2023 | API. Provides the exact opening/closing times for highly specific agent tasks. |
| **Resy / OpenTable / Venue Reservation Exports** | Commerce | Reservations, booking windows, table scarcity, service-period demand | 2014 | 2026 | 2024 | API/Partner Export/Allowed Scrape. High-value occupancy and demand signal for restaurants. Must not be treated as sole proof of venue truth. |
| **Data Axle / InfoGroup Business Listings** | Business | Active businesses by NAICS code | 2006 | 2026 | 2023 | Commercial DB. Truth layer for obscure service categories (furniture stores, specialty repair). |
| **FDIC / Local Financial Chains** | Finance | Banks, credit unions, ATMs, payday lenders | 1995 | 2026 | 2020 | API/OSM. Drives agent financial errands, loan processing, and localized credit availability/debt cycles. |
| **IRS 990 / Non-profit Tax Records** | Finance | Charities, non-profit intake, civic donation trends | 2005 | 2025 | 2021 | OpenData/ProPublica. Tracks philanthropic cash flow, mapping how much agents donate annually and non-profit health. |
| **State Dept. of Insurance / Claim Models**| Finance | Auto collisions, property damage, weather payouts | 2000 | 2025 | 2011 | API/Reports. Represents the financial fallout of accidents and disasters; deductibles drain agent wallets unexpectedly. |
| **AL Secretary of State (SOS) Entities** | Business | Corporate ownership, holding companies, registered agents | 1985 | 2026 | 2023 | API/Scrape. Links seemingly separate retail/restaurants to parent groups (e.g., Pihakis, Fresh Hospitality). |
| **County Business Licenses & Tax Records**| Business | DBA (Doing Business As) names, exact tax linkages | 2005 | 2026 | 2022 | OpenData/FOIA. Exposes the invisible financial and ownership graph behind the local economy. |
| **STR Data (Airbnb/VRBO) & Hotel Occupancy** | Tourism | Vacations, temporary housing, holiday visitors | 2014 | 2026 | 2022 | Commercial/API. Controls the volume of temporary "tourist agents" entering the simulation for events, or extended family visiting for holidays. |
| **Real Estate & Rent Index (Zillow/MLS/HUD)** | Real Estate | Home prices, rent spikes, housing availability | 2000 | 2026 | 2023 | Public PDF/API mix. The engine of **multi-year gentrification**. Public Redfin monthly Birmingham housing data is now logged as the first approved housing signal lane. |
| **Gig Economy Swarms (Uber/Doordash/Instacart)**| Commerce | Ride-shares, food delivery, gig-worker routing | 2014 | 2026 | 2023 | API/Scrape. Introduces the roaming swarm of "gig-agents" constantly fulfilling the micro-demands of stationary agents. |
| **Delivery / Ordering Platform Aggregates** | Commerce | Meal delivery demand, cuisine preference timing, destination density | 2014 | 2026 | 2024 | Partner Export/API/Allowed Scrape. Useful for locality meal-demand rhythms and popularity shifts. Store governed aggregate patterns, not raw personal order histories. |
| **Retail & Seasonal Consumer Trends (NRF)** | Commerce | Holiday shopping rushes, back-to-school, summer lulls | 2005 | 2026 | 2021 | API/Scrape. Completely overrides baseline retail routines, triggering massive traffic to malls, big boxes, and local boutiques during specific months. |
| **Gasoline & EV Charging Networks** | Commerce | Gas stations, fuel stops, charging stations | 2012 | 2026 | 2024 | API/Map. **Crucial:** Defines natural anchor points for vehicle idle time and prolonged **AI-to-AI exchanges**. |
| **Commercial Supply Chain / Vendor Rhythms** | Commerce | Food distribution deliveries, shelf stocking periods | 2015 | 2026 | 2022 | Simulated / Scrape | Defines when businesses are actually populated by logistics/delivery agents versus normal customers. |

### Tier 4: Community Venues, Civic Data, Legal & Local Events
*Ingest Priority 4: Links to existing entities. Deduplication requires extreme care.*

| Source Name | Category | Entity Coverage | Earliest | Most Recent | Richest Year | Access Method / Notes |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **County/Municipal Courts & Police Dispatch** | Legal | Traffic tickets, minor incidents, dispatch noise | 2010 | 2026 | 2023 | API/Scrape. Injects random, realistic friction into agent routines (e.g., getting delayed by a traffic stop). Public Birmingham precinct CSVs and the FBI trend explorer are now logged as partial inputs, but the lane remains review-gated until fuller court/dispatch access exists. |
| **Federal, State & Corporate Holiday Calendars**| Events | Work/School cancellations, vacation days | 2000 | 2026 | 2024 | API/ICS. The ultimate macro override for standard weekday behaviors, triggering vacation and mass travel routines. |
| **Elections & Civic Voting Days (Probate)** | Events | Polling places, civic disruption, voting queues | 2000 | 2026 | 2020 | Scrape/Data. Transforms specific schools, churches, and libraries into massive localized gravity wells for a single Tuesday. |
| **Alacourt (Public Court Records)** | Legal | Evictions, civil disputes, bankruptcies | 1990 | 2026 | 2015 | API/Scrape. Adds a deep narrative layer of financial and legal history to specific entities and venues. |
| **BPD / JeffCo Crime & Vice Mapping**| Shadow | DUI hotspots, drug busts, illicit gambling rings | 2010 | 2026 | 2021 | Scrape/OpenData. The **illegal economy**. Seeds underground shadow agent routines and high-risk encounters. |
| **City Council & Zoning Boards** | Civic | Zoning changes, permit approvals, public grievances | 2000 | 2026 | 2022 | OpenData/Scrape. Simulates the bureaucratic friction and local politics shaping the city map. |
| **Neighborhood Association Calendars** | Events | Hyper-local meetings (Avondale, Southside, Woodlawn) | 2012 | 2026 | 2019 | Scrape. Empowers distinct neighborhood locality agents. Governed archival reconstruction is now operational for East Avondale, Glen Iris, and Wylam; direct 2023 calendar captures remain a richer follow-on lane. |
| **BPL (Birmingham Public Library) Network** | Events | Community classes, tutoring, public safe-spaces | 2005 | 2026 | 2023 | API/Scrape. Essential public gathering anchor for varied demographics. |
| **Municipal Parades & High School Events** | Events | High school football, marching bands, holiday parades | 2010 | 2026 | 2022 | ICS/Scrape. Disrupts local traffic flow drastically and draws large, family-centric core crowds. |
| **Youth & Amateur Sports Hubs** | Events | Little league, pee-wee, martial arts, dance studios, skateparks | 2015 | 2026 | 2023 | Parks & Rec APIs / Scrape. Dictates extreme localized parent/child movement across weeknights and Saturdays. |
| **Local Charities, Volunteer Hubs & Thrift Stores**| Social | Soup kitchens, charity work, donations, volunteer shifts | 2012 | 2026 | 2021 | Scrape/API. Core routine destinations for philanthropic agents and necessary sustenance nodes for low-income/shadow agents. |
| **Community Arts & Festivals** | Events | Magic City Art Connection, Art by the Tracks, Sidewalk Fest | 2008 | 2026 | 2022 | Calendar/Scrape. Completely transforms localized zones (e.g. Linn Park, Avondale) into intense weekend pedestrian hubs. |
| **Farmers Markets (Pepper Place, Valleydale)** | Events | Weekly markets, local vendors, community gathering | 2010 | 2026 | 2023 | Calendar/Scrape. Massive recurring Saturday morning gravity well that pulls diverse populations into localized mixed-use spaces. |
| **IN Birmingham (CVB Calendar)** | Events | Tourism events, major conventions | 2012 | 2026 | 2022 | API/Scrape. Broad coverage of "official" Birmingham. Runtime puller now catalogs the public tourism lane, but it is still structural until governed historical extraction is validated. |
| **Major Venue Calendars (Saturn, Iron City, The Nick)**| Venues | Nightlife, recurring cultural cycles | 2014 | 2026 | 2023 | ICS/Scrape. Granular engine of nighttime simulation. |
| **City of Birmingham Play Pages** | Events, Venues | Civic cultural anchors, museums, gardens, arts spaces, official city event pages | 2023 | 2026 | 2026 | Scrape/Manual. Structural citywide seed for Birmingham venues and public cultural places, plus direct dated city event pages when explicit 2023 history is available. |
| **Birmingham365.org** | Events | Citywide culture/community discovery network | 2023 | 2026 | 2026 | Scrape/Manual. Strong structural seed for community and venue discovery; must be deduplicated and should not stand alone as authoritative historical event truth until archival extraction is validated. |
| **Eventbrite / Meetup** | Events | Community, hobbyist, localized events | 2012 | 2026 | 2023 | API/Scrape. *Must be deduplicated against official venue calendars.* Runtime puller now catalogs the public discovery lane, but it is still structural until governed historical extraction is validated. |
| **COVID-19 / Pandemic Mobility Data (Apple/Google)**| Historic | Lockdowns, curfew zones, total retail collapse | 2020 | 2022 | 2020 | API/Dump. The ultimate "Black Swan" override. Completely destroys normal agent movement vectors for specific years. |
| **REV Birmingham Updates** | Narrative | Downtown/Woodlawn/Avondale biz openings | 2013 | 2026 | 2022 | Newsletter/Scrape. Highly trusted for retail/food turnover. |

### Tier 5: Narrative, Verification, & Prestige Enrichment
*Ingest Priority 5: Uses NLP to extract entities based ONLY on pre-existing mapped locations.*

| Source Name | Category | Entity Coverage | Earliest | Most Recent | Richest Year | Access Method / Notes |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Dating App Aggregates (Hinge/Bumble)**| Social | Dating spots, demographic mix, relationship churn | 2016 | 2026 | 2023 | API/Reports. Identifies popular date spots and models the relationship-seeking behavior of young adult agents. |
| **Bham Now / AL.com / BBJ** | Verification | Venue openings/closures, cross-verification | 2016 | 2026 | 2023 | RSS/Scrape. Used to detect business rhythm & unexpected closures. |
| **r/Birmingham (Reddit)** | Narrative | Crowdsourced news, rumors, civic complaints | 2010 | 2026 | 2023 | API/Scrape. Injects hyper-local internet culture, rumors, and real-time "What's that noise/smell?" sentiment. |
| **WBHM 90.3 Public Radio** | Narrative | Event sponsorships, civic updates | 2005 | 2026 | 2020 | RSS. Good for overarching civic mood and major news events. |
| **James Beard Foundation / G&G**| Prestige | Status, culinary awards (Highlands, etc.) | 2000 | 2026 | 2018 | API/Scrape. Ingest *only* after core venue entities exist. |
| **Bhamwiki.com** | Artifact | Extremely detailed civic history, entity mapping| 2006 | 2026 | 2024 | Dump/Scrape. *The absolute best source for mapping historical Birmingham entities and lore.* |
| **BPL Archives & Digital Collections**| Artifact | Long-lived memory, deep historical context | 1880 | 2026 | 1963 | API/Manual. Useful for legacy events and deep narrative grounding. |

## Ingestion Phasing Sequence

1. **Priority 1 (Physical & Economic Reality):** Establish the terrain, demographic baseline, and macro-financial/income brackets across all counties (Greater Birmingham Area). 
2. **Priority 2 (Institutions & Schools):** Establish the major gravity wells—UAB, Samford, public schools, stadiums, and massive parks (Oak Mountain).
3. **Priority 3 (Daily Life POIs):** Populate specific local shops, corporate networks, and services needed for granular agent chores and routines.
4. **Priority 4 (Venues, Civic & Legal):** Populate court friction, bureaucratic noise, neighborhood associations, and the night-to-night reality of local venues.
5. **Priority 5 (Narrative & Lore):** Layer on Bhamwiki historical ties, AL.com verification reports, and prestige mechanics.
