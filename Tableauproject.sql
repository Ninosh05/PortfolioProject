SET SQL_SAFE_UPDATES = 0;

UPDATE ProjectPortfolio.coviddeathfixed
SET continent = 'Africa'
WHERE location = 'Africa'
  AND continent IS NULL;

-- For coviddeathfixed: Remove unnecessary characters (like '0') and extra spaces in the location names
UPDATE ProjectPortfolio.coviddeathfixed
SET continent = REPLACE(continent, '0', ' '),
    location = REPLACE(location, '0', ' ')
WHERE continent LIKE '%0%' OR location LIKE '%0%';


-- For covidvaccinationscleaned: Remove unnecessary characters (like '0') and extra spaces in the location names
UPDATE ProjectPortfolio.covidvaccinationscleaned
SET continent = REPLACE(continent, '0', ' '),
    location = REPLACE(location, '0', ' ')
WHERE continent LIKE '%0%' OR location LIKE '%0%';

-- For coviddeathfixed: Assign location to continent where continent is NULL
UPDATE ProjectPortfolio.coviddeathfixed
SET continent = location
WHERE continent IS NULL;

-- For covidvaccinationscleaned: Assign location to continent where continent is NULL
UPDATE ProjectPortfolio.covidvaccinationscleaned
SET continent = location
WHERE continent IS NULL;

-- For coviddeathfixed: Clean up locations that have extra spaces or unwanted formatting
UPDATE ProjectPortfolio.coviddeathfixed
SET location = TRIM(location)
WHERE location IS NOT NULL;

-- For covidvaccinationscleaned: Clean up locations that have extra spaces or unwanted formatting
UPDATE ProjectPortfolio.covidvaccinationscleaned
SET location = TRIM(location)
WHERE location IS NOT NULL;

-- The TotalCases column will have the cumulative sum of new_cases for each location and population.

ALTER TABLE ProjectPortfolio.coviddeathfixed
ADD COLUMN Total_Cases DOUBLE;

UPDATE ProjectPortfolio.coviddeathfixed AS df
JOIN (
    SELECT location, 
           population, 
           SUM(new_cases) AS total_cases
    FROM ProjectPortfolio.coviddeathfixed
    GROUP BY location, population
) AS total_data
ON df.location = total_data.location AND df.population = total_data.population
SET df.total_cases = total_data.total_cases;

/* Queries used for Tableau Project */

/* 1. Total Cases, Total Deaths, and Death Percentage */
SELECT SUM(new_cases) AS total_cases, 
       SUM(CAST(new_deaths AS SIGNED)) AS total_deaths, 
       (SUM(CAST(new_deaths AS SIGNED)) / SUM(new_cases)) * 100 AS DeathPercentage
FROM ProjectPortfolio.coviddeathfixed
WHERE continent IS NOT NULL
ORDER BY 1, 2;

/* 2. Total Deaths by continent (excluding specific locations) */


SELECT continent, 
       SUM(CAST(new_deaths AS SIGNED)) AS TotalDeathCount
FROM ProjectPortfolio.coviddeathfixed
WHERE continent IS NOT NULL 
  AND continent NOT IN ('World', 'European Union', 'International')
GROUP BY continent
ORDER BY TotalDeathCount DESC;



/* 3. Highest Infection Count and Percent of Population Infected*/
SELECT location, 
       population, 
       MAX(total_cases) AS HighestInfectionCount, 
       MAX((total_cases / population)) * 100 AS PercentPopulationInfected
FROM ProjectPortfolio.coviddeathfixed
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;



/* 4. Highest Infection Count and Percent of Population Infected by Date */

WITH TotalCases AS (
    SELECT location, 
           population, 
           date, 
           SUM(new_cases) AS new_cases,  -- Sum new cases for each location per date
           (SUM(new_cases) / NULLIF(population, 0)) * 100 AS PercentPopulationInfected
    FROM ProjectPortfolio.coviddeathfixed
    WHERE population IS NOT NULL AND population > 0
      AND YEAR(date) IN (2020, 2021)  -- Filter for 2020 and 2021 only
    GROUP BY location, date, population  -- Group by location, date, and population to sum new_cases
),
CumulativeCases AS (
    SELECT location, 
           population, 
           date, 
           new_cases,  -- From the previous step
           SUM(new_cases) OVER (PARTITION BY location ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS total_cases,  -- Calculate cumulative total_cases over time
           PercentPopulationInfected
    FROM TotalCases
)
SELECT location, 
       population, 
       date, 
       total_cases AS CalculatedTotalCases,  -- New calculated total_cases
       PercentPopulationInfected
FROM CumulativeCases
ORDER BY location, date;





















/* 5. Total Cases and Deaths with Population */
SELECT location, 
       date, 
       population, 
       total_cases, 
       total_deaths
FROM ProjectPortfolio.coviddeathfixed
WHERE continent IS NOT NULL
ORDER BY 1, 2;

-- 6. Rolling Vaccinated People per Location
WITH PopvsVac AS (
    SELECT dea.continent, 
           dea.location, 
           dea.date, 
           dea.population, 
           vac.new_vaccinations, 
           SUM(CAST(vac.new_vaccinations AS SIGNED)) 
               OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
    FROM ProjectPortfolio.coviddeathfixed dea
    JOIN ProjectPortfolio.covidvaccinationscleaned vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT *, 
       (RollingPeopleVaccinated / population) * 100 AS PercentPeopleVaccinated
FROM PopvsVac;

-- 7. New Cases and Deaths Comparison by Location and Date
SELECT location, 
       population, 
       date, 
       SUM(new_cases) AS TotalNewCases, 
       SUM(new_deaths) AS TotalNewDeaths,
       (SUM(new_deaths) / SUM(new_cases)) * 100 AS DeathPercentage
FROM ProjectPortfolio.coviddeathfixed
GROUP BY location, population, date
ORDER BY TotalNewCases DESC;











