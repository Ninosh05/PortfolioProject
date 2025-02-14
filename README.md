COVID-19 Data Analysis with Tableau


This project aims to analyze global COVID-19 data and provide key insights into infection rates, death percentages, vaccination progress, and other essential metrics using SQL for data extraction and Tableau for visualization.
Project Overview
Main Objective:
The main objective of this project is to examine how different regions and populations around the world have been impacted by the COVID-19 pandemic. The focus is on key metrics like cases, deaths, death percentages, and infection rates at a location level across continents, countries, and regions.
Key Focus Areas:
Total COVID-19 Cases and Deaths:
This analysis calculates the total number of new COVID-19 cases and deaths globally, as well as the death percentage (new deaths/new cases * 100). This helps provide an overview of the pandemic's severity across all locations.
COVID-19 Death Count by Continent:
Here, we calculate the total death count for each continent, excluding certain locations such as 'World' and 'European Union'. The locations are then sorted by death count to help compare across continents.
Infection Rates by Location:
This analysis identifies the regions with the highest infection counts and calculates the percentage of the population infected by using the formula (total cases/population * 100). This highlights which regions have been most heavily affected relative to their population size.
Infection Rates Over Time by Location:
This analysis tracks the evolution of infection rates over time for each location, calculated by date. We calculate cumulative total cases for each location and show how infection rates have changed over time. The analysis is focused on the years 2020 and 2021.

Queries Overview:
Total Cases, Total Deaths, and Death Percentage:
This query calculates the total number of new cases and deaths globally and computes the death percentage (new deaths/new cases * 100).

SELECT SUM(new_cases) AS total_cases, 
       SUM(CAST(new_deaths AS SIGNED)) AS total_deaths, 
       (SUM(CAST(new_deaths AS SIGNED)) / SUM(new_cases)) * 100 AS DeathPercentage
FROM ProjectPortfolio.coviddeathfixed
WHERE continent IS NOT NULL
ORDER BY 1, 2;
Total Deaths by Continent (Excluding Specific Locations):
This query calculates the total number of deaths by continent and excludes certain locations like 'World' and 'European Union'.

SELECT continent, 
       SUM(CAST(new_deaths AS SIGNED)) AS TotalDeathCount
FROM ProjectPortfolio.coviddeathfixed
WHERE continent IS NOT NULL 
  AND continent NOT IN ('World', 'European Union', 'International')
GROUP BY continent
ORDER BY TotalDeathCount DESC;
Infection Rates by Location:
This query identifies regions with the highest infection counts and calculates the percentage of the population infected (total cases/population * 100).

SELECT location, 
       population, 
       MAX(total_cases) AS HighestInfectionCount, 
       MAX((total_cases / population)) * 100 AS PercentPopulationInfected
FROM ProjectPortfolio.coviddeathfixed
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;
Infection Rates Over Time by Location:
This query calculates the cumulative total cases over time for each location and computes the percentage of the population infected.

WITH TotalCases AS (
    SELECT location, 
           population, 
           date, 
           SUM(new_cases) AS new_cases,  
           (SUM(new_cases) / NULLIF(population, 0)) * 100 AS PercentPopulationInfected
    FROM ProjectPortfolio.coviddeathfixed
    WHERE population IS NOT NULL AND population > 0
      AND YEAR(date) IN (2020, 2021)
    GROUP BY location, date, population
),
CumulativeCases AS (
    SELECT location, 
           population, 
           date, 
           new_cases,  
           SUM(new_cases) OVER (PARTITION BY location ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS total_cases,  
           PercentPopulationInfected
    FROM TotalCases
)
SELECT location, 
       population, 
       date, 
       total_cases AS CalculatedTotalCases,  
       PercentPopulationInfected
FROM CumulativeCases
ORDER BY location, date;

Requirements:
You need a MySQL database to execute these queries.
The dataset should be imported into a MySQL table named coviddeathfixed and should include columns such as location, date, new_cases, new_deaths, and population.
Setup:
Import the coviddeathfixed dataset into MySQL.
Run the SQL queries using MySQL Workbench or another MySQL interface.
Once you have the results, you can visualize the data in Tableau or any other data visualization tool.
Visualizing the Data:
The results of these queries are designed to be visualized in Tableau, where you can create dashboards based on the following metrics:
Total Cases & Deaths: Display the overall impact of COVID-19 globally and by continent.
Death Percentage: Visualize the death rate across different locations.
Infection Rates: Show the highest infection counts and infection percentages by location.
Time Series Analysis: Track daily cumulative cases and infection rates for each location.
