# Estimating the Impact of Weather on Agriculture
 This README describes the directory structure & should enable users to replicate all cleaning code used in the populated pre-analysis plan "[Estimating the Impact of Weather on Agriculture][3]." The main project site is on [OSF][1]. Unfortunately, because the weather data contains confidential information, it is not publically available. This means the weather code will not function since that data is held by the World Bank. Without the weather data, the results cannot be replicated from raw data to final analysis. Contact Drs. Jeffrey D. Michler or Anna Josephson and they can share an intermediate - de-identified - version of the weather data for use in replicating the results.

 ## Index

 - [Project Team](#project-team)
 - [Data cleaning](#data-cleaning)
  - [Pre-requisites](#pre-requisites)
  - [Folder structure](#folder-structure)

## Project Team

Contributors:
* Jeffrey D. Michler (Conceptualizaiton, Supervision, Visualization, Writing)
* Anna Josephson (Conceptualizaiton, Supervision, Visualization, Writing)
* Talip Kilic (Conceptualization, Resources, Writing)
* Siobhan Murray (Conceptualization, Writing)
* Brian McGreal (Data curation)
* Alison Conley (Data curation)
* Emil Kee-Tui (Data curation)

## Data cleaning

The code in this repository is primarily for replicating the cleaning of the household LSMS-ISA data. This requires downloading this repo and the household data from the World Bank webiste. The `projectdo.do` should then replicate the data cleaning process.

### Pre-requisites

#### Stata req's

  * The data processing and analysis requires a number of user-written
    Stata programs:
    1. `weather_command`
    2. `blindschemes`
    3. `estout`
    4. `customsave`
    5. `winsor2`
    6. `mdesc`
    7. `distinct`

#### Folder structure

The [OSF project page][1] provides more details on the data cleaning.

For the household cleaning code to run, the public use microdata must be downloaded from the [World Bank Microdata Library][2]. Furthermore, the data needs to be placed in the following folder structure:<br>

```stata
weather_and_agriculture
├────household_data      
│    └──country          /* one dir for each country */
│       ├──wave          /* one dir for each wave */
│       └──logs
├──weather_data
│    └──country          /* one dir for each country */
│       ├──wave          /* one dir for each wave */
│       └──logs
├──merged_data
│    └──country          /* one dir for each country */
│       ├──wave          /* one dir for each wave */
│       └──logs
├──regression_data
│    ├──country          /* one dir for each country */
│    └──logs
└────results_data        /* overall analysis */
     ├──tables
     ├──figures
     └──logs
```

  [1]: https://osf.io/8hnz5/
  [2]: https://www.worldbank.org/en/programs/lsms/initiatives/lsms-ISA
  [3]: https://openknowledge.worldbank.org/handle/10986/36643
