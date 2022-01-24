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

The general repo structure looks as follows:<br>

```stata
weather_project
├────README.md
├────projectdo.do
│    
├────country             /* one dir for each country */
│    ├──household_code
│    │  └──wave          /* one dir for each wave */
│    ├──weather_code
│    │  └──wave          /* one dir for each wave */
│    ├──regression_code
│    └──output
│       ├──tables
│       └──figures
│
│────Analysis            /* overall analysis */
│    ├──code
│    └──output
│       ├──tables
│       └──figures
│   
└────config
```

  [1]: https://osf.io/8hnz5/
