/*

COVID19 Data Exploration Project

SKILLS USED:
- Joins,
- CTE's,
- Temp Tables,
- Windows Functions,
- Aggregate Functions,
- Creating Views,
- Converting Views,
- Converting Data Types

*/

-- Selecting the data to begin querying

SELECT *
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY 3, 4

--SELECT *
--FROM PortfolioProject..CovidVaccinations$
--ORDER BY 3, 4

SELECT continent, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY 1, 2

-- Total Cases v/s Total Deaths
-- Shows the likelihood of dying if a person contracts Covid19 in Canada

SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS decimal)/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths$
WHERE location LIKE '%Canada%'
AND continent IS NOT NULL
ORDER BY 1, 2

-- Creating View to store data for later visualizations

GO
CREATE VIEW TotCasesvsTotDeaths AS
SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS decimal)/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths$
WHERE location LIKE '%Canada%'
AND continent IS NOT NULL
--ORDER BY 1, 2
GO

-- Total Cases v/s Population
-- Shows what percentage of population got infected by Covid19

SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths$
--WHERE location LIKE '%Canada%'
ORDER BY 1, 2

-- Creating View to store data for later visualizations

GO
CREATE VIEW TotCasesvsPop AS
SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths$
--WHERE location LIKE '%Canada%'
--ORDER BY 1, 2
GO

-- Countries with the Highest Infection Rate compared to the Population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, (MAX(total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths$
--WHERE location LIKE '%Canada%'
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

-- Creating View to store data for later visualizations

GO
CREATE VIEW CountryHighInfRatecompPop AS
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, (MAX(total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths$
--WHERE location LIKE '%Canada%'
GROUP BY location, population
--ORDER BY PercentPopulationInfected DESC
GO


-- Countries with the Highest Death Count per Population

SELECT location, MAX(CAST(total_deaths AS decimal)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths$
--WHERE location LIKE '%Canada%'
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Creating View to store data for later visualizations

GO
CREATE VIEW CountryHighDeathCountperPop AS
SELECT location, MAX(CAST(total_deaths AS decimal)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths$
--WHERE location LIKE '%Canada%'
WHERE continent IS NOT NULL
GROUP BY location
--ORDER BY TotalDeathCount DESC
GO

-- BREAKING THINGS DOWN BY CONTINENT

-- Displaying the Continents with the highest death count per population

SELECT continent, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths$
--WHERE location LIKE '%Canada%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Creating View to store data for later visualizations

GO
CREATE VIEW ContHighDeathCountperPop AS
SELECT continent, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths$
--WHERE location LIKE '%Canada%'
WHERE continent IS NOT NULL
GROUP BY continent
--ORDER BY TotalDeathCount DESC
GO

-- GLOBAL NUMBERS

SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(NULLIF(new_cases, 0))*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths$
--WHERE location LIKE '%Canada%'
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1, 2

-- Total Population v/s Vaccination
-- Shows Percentage of Population that has received at least one Covid19 vaccine

SELECT dat.continent, dat.location, dat.date, dat.population, vac.new_vaccinations, SUM(CONVERT(decimal, vac.new_vaccinations)) OVER (PARTITION BY dat.location ORDER BY dat.location, dat.date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinalted/population)*100
FROM PortfolioProject..CovidDeaths$ dat
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dat.location = vac.location
	AND dat.date = vac.date
WHERE dat.continent IS NOT NULL
ORDER by 2, 3

-- Creating View to store data for later visualizations

GO
CREATE VIEW TotalpopvsVacc AS
SELECT dat.continent, dat.location, dat.date, dat.population, vac.new_vaccinations, SUM(CONVERT(decimal, vac.new_vaccinations)) OVER (PARTITION BY dat.location ORDER BY dat.location, dat.date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinalted/population)*100
FROM PortfolioProject..CovidDeaths$ dat
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dat.location = vac.location
	AND dat.date = vac.date
WHERE dat.continent IS NOT NULL
--ORDER by 2, 3
GO

-- Using CTE to perform Calculations on PARTITION BY in previous query

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinalted)
AS (
SELECT dat.continent, dat.location, dat.date, dat.population, vac.new_vaccinations, SUM(CONVERT(decimal, vac.new_vaccinations)) OVER (PARTITION BY dat.location ORDER BY dat.location, dat.date) AS RollingPeopleVaccinated 
--, (RollingPeopleVaccinalted/population)*100
FROM PortfolioProject..CovidDeaths$ dat
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dat.location = vac.location
	AND dat.date = vac.date
WHERE dat.continent IS NOT NULL
--ORDER by 2, 3
)
SELECT *, (RollingPeopleVaccinalted/population)*100
FROM PopvsVac

-- Using Temp Table to perform Calculation on PARTITION BY in previous query

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(	Continent nvarchar(255), Location nvarchar(255), Date datetime, Population numeric, New_Vaccinations numeric, RollingPeopleVaccinated numeric)

INSERT INTO #PercentPopulationVaccinated
SELECT dat.continent, dat.location, dat.date, dat.population, vac.new_vaccinations, SUM(CONVERT(decimal, vac.new_vaccinations)) OVER (PARTITION BY dat.location ORDER BY dat.location, dat.date) AS RollingPeopleVaccinated 
--, (RollingPeopleVaccinalted/population)*100
FROM PortfolioProject..CovidDeaths$ dat
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dat.location = vac.location
	AND dat.date = vac.date
--WHERE dat.continent IS NOT NULL
--ORDER by 2, 3

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

GO
CREATE VIEW PercentPopulationVaccinated AS
SELECT dat.continent, dat.location, dat.date, dat.population, vac.new_vaccinations, SUM(CONVERT(decimal, vac.new_vaccinations)) OVER (PARTITION BY dat.location ORDER BY dat.location, dat.date) AS RollingPeopleVaccinated 
--, (RollingPeopleVaccinalted/population)*100
FROM PortfolioProject..CovidDeaths$ dat
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dat.location = vac.location
	AND dat.date = vac.date
WHERE dat.continent IS NOT NULL
--ORDER by 2, 3
GO

SELECT *
FROM PercentPopulationVaccinated
