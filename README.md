# Estimating the Impact of Weather on Agriculture
 This README describes the directory structure & should enable users to replicate all tables and figures from "Estimating the Impact of Weather on Agriculture" project. The main project site is on [OSF][1].

 ## Index

 - [Introduction](#introduction)
 - [Data cleaning](#data-cleaning)
  - [Pre-requisites](#pre-requisites)
  - [Folder structure](#folder-structure)

## Introduction

This is the repo for the weather project.<br>

Contributors:
* Jeffrey D. Michler
* Anna Josephson
* Talip Kilic
* Siobhan Murray
* Brian McGreal
* Alison Conley
* Emil Kee-Tui

As described in more detail below, scripts various
go through each step, from cleaning raw data to analysis.

## Data cleaning

The code in `projectdo.do` (to be done) replicates
    the data cleaning and analysis.

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
│────results_data        /* overall analysis */
     ├──tables
     ├──figures
     └──logs
```

  [1]: https://osf.io/8hnz5/
  [2]: https://www.worldbank.org/en/programs/lsms/initiatives/lsms-ISA
