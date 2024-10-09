libname covid "/home/u49225096/SQL";

/* run this macro only once to import and save it to a library*/
%macro a (filein, fileout);
proc import out = covid.&fileout 
datafile = "/home/u49225096/SQL/&filein..csv"
dbms = csv replace;
GETNAMES = YES;
run;
%mend a;
%a (CovidDeaths, Covid_Deaths);
%a (CovidVaccinations, Covid_Vaccinations);

*viewing the covid deaths dataset;
proc sql outobs=10; /*replaces limit 10*/
select *
from covid.covid_deaths
order by location, date;

/*viewing the covid vaccinations dataset*/
select *
from covid.covid_vaccinations
order by location, date;
quit;

*selecting columns of interest in covid deaths dataset,
converting character variables to numeric;
proc sql;
create table covid_deaths_a as
select location, date, population, new_cases, new_deaths, new_cases_per_million,
new_deaths_per_million, 
	input(total_cases, best12.) AS total_cases, /*MySQL version: cast(total_cases as decimal) as total_cases*/
	input(total_deaths, best12.) AS total_deaths,
    input(total_cases_per_million, best12.) AS total_cases_per_million,
    input(total_deaths_per_million, best12.) AS total_deaths_per_million
from covid.covid_deaths;
 
*selecting columns of interest in vaccinations datasets, 
converting character variables to numeric;

create table vaccinations as
select location, date, population_density, gdp_per_capita, 
input(total_tests, best12.) as total_tests, 
input(new_tests, best12.) as new_tests,
input(total_tests_per_thousand, best12.) as total_tests_per_thousand,
input(new_tests_per_thousand, best12.) as new_tests_per_thousand,
input(total_vaccinations, best12.) as total_vaccinations,
input(new_vaccinations, best12.) as new_vaccinations
from covid.covid_vaccinations;

/*Find top 5 countries with highest number of deaths per million*/

create table top_five_deaths as
select location, total_deaths, total_cases, total_cases_per_million,
total_deaths_per_million
from covid_deaths_a
group by location
order by total_deaths_per_million desc, total_cases_per_million desc;

/*Find top 5 countries with highest number of new deaths per million*/

create table new_top_five_deaths as
select location, new_deaths, new_cases, new_cases_per_million,
new_deaths_per_million
from covid_deaths_a
group by location
order by new_deaths_per_million desc, new_cases_per_million desc;

/*Find countries with the highest likelihood of total deaths
and deaths per million*/

create table deaths_percent as
select distinct location, date, total_cases, total_deaths,
total_cases_per_million, total_deaths_per_million, 
 ((total_deaths/total_cases)*100) as death_percentage,
 ((total_deaths_per_million/total_cases_per_million) * 100) as death_percent_per_million
from covid_deaths_a
where total_deaths is not null
and total_cases is not null 
and total_deaths_per_million is not null
and total_cases_per_million is not null
and total_deaths < total_cases
and total_deaths_per_million < total_cases_per_million
order by death_percentage desc, death_percent_per_million desc;

/*Find countries with the highest incidence of new
cases per million, new deaths per million, and new deaths*/

create table incidence_percent as
select distinct location, new_cases_per_million,
total_cases_per_million, new_deaths, total_deaths,
new_deaths_per_million, total_deaths_per_million,
((new_cases_per_million/total_cases_per_million) * 100) as incidence_cases_per_mill,
((new_deaths/total_deaths) * 100) as incidence_deaths,
((new_deaths_per_million/total_deaths_per_million) * 100) as incidence_deaths_per_mill
from covid_deaths_a
where new_cases_per_million is not null
and new_deaths is not null 
and new_deaths_per_million is not null
and new_cases_per_million < total_cases_per_million
and new_deaths < total_deaths
and new_deaths_per_million < total_deaths_per_million
order by incidence_deaths desc;

/* Countries with Highest Infection Rate compared to Population 
	Using MAX */

create table max_pop as
select location, population, total_cases, MAX(total_cases) as highest_cases, MAX((total_cases/population) * 100) 
as highest_covid_percent
from covid_deaths_a
group by location, population
order by highest_covid_percent;

/*joining the covid deaths and vaccinations tables*/

create table cov_vacc as
select cov.location, cov.total_deaths, cov.total_cases,
vac.total_tests, vac.total_vaccinations
from covid_deaths_a as cov
inner join vaccinations as vac
on cov.location = vac.location
;