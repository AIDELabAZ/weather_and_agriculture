# Weather and Agriculture: Cleaning code for LSMS-ISA and remotely sensed weather data integration project

This repository acts as the mother ship for a number of other repositories that hold replication code for papers sprining from the main project. The main project site is on [OSF][1] and has the goal of exploring a variety of issues that arise when remotely sensed weather data is integrated with socioeconomic survey data. The dependency or subsidiary repos from this repo include replication packages for:

- Michler, J.D., Josephson, A., Kilic, T., and Murray, S. (2021). "[Estimating the Impact of Weather on Agriculture][4]." World Bank Policy Research Working Paper, No. 9867.
- Michler, J.D., Josephson, A., Kilic, T., and Murray, S. (2022). "[Privacy Protection, Measurement Error, and the Integration of Remote Sensing and Socioeconomic Survey Data][5]." *Journal of Development Economics 158*: 102927.
- Josephson, A., Michler, J.D., Kilic, T., and Murray, S. (2024). "[The Mismeasure of Weather: Using Remotely Sensed Weather in Economic Contexts][6]."
- Agme, C., Josephson, A., Michler, J.D., Kilic, T., and Murray, S. (2024). "[Variable Selection in Economic Applications of Remotely Sensed Weather Data: Evidence from the LSMS-ISA][7]."

<span style="color:blue">Because the weather data contains confidential information, it is not publically available. This means the weather code will not function, as that data is held by the World Bank. Contact Drs. Jeffrey D. Michler or Anna Josephson and they can share an intermediate - de-identified - version of the weather data for use in replicating the results.</span>

This README was last updated on 3 September 2024. 

 ## Index

 - [Project Team](#project-team)
 - [Data cleaning](#data-cleaning)
 - [Pre-requisites](#pre-requisites)
 - [Folder structure](#folder-structure)

## Project Team

Contributors:
* Jeffrey D. Michler [jdmichler@arizona.edu] (Conceptualizaiton, Supervision, Visualization, Writing)
* Anna Josephson [aljosephson@arizona.edu] (Conceptualizaiton, Supervision, Visualization, Writing)
* Talip Kilic (Conceptualization, Resources, Writing)
* Siobhan Murray (Conceptualization, Writing)
* Brian McGreal (Data curation)
* Alison Conley (Data curation)
* Emil Kee-Tui (Data curation)
* Reece Branham (Data curation)
* Rodrigo Guerra Su (Data curation)
* Jacob Taylor (Data curation)
* Kieran Douglas (Data curation)

## Data cleaning

The code in this repository is primarily for replicating the cleaning of the household LSMS-ISA data. This requires downloading this repo and the household data from the World Bank webiste. The `projectdo.do` should then replicate the data cleaning process.

### Pre-requisites

#### Stata req's

  * The data processing and analysis requires a number of user-written
    Stata programs:
    1. `weather_command`
    2. `blindschemes`
    3. `estout`
    4. `winsor2`
    5. `mdesc`
    6. `distinct`

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
  [4]: https://github.com/jdavidm/weather_project
  [5]: https://github.com/AIDELabAZ/privacy_protection
  [6]: https://github.com/AIDELabAZ/mismeasure_weather
  [7]: https://github.com/AIDELabAZ/weather_metrics
