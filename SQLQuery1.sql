SELECT * FROM proj1..CovidDeaths
SELECT location, date, population, total_cases, total_deaths
FROM proj1..CovidDeaths 
ORDER BY 1,2 

USE proj1
EXEC sp_help 'CovidDeaths'

ALTER TABLE CovidDeaths
	ALTER COLUMN total_cases FLOAT

ALTER TABLE CovidDeaths
	ALTER COLUMN total_deaths FLOAT

--Looking for total deaths vs total cases in India
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM proj1..CovidDeaths
WHERE location = 'India'
ORDER BY 1,2

--Looking at total cases vs population
SELECT location, date, total_cases, population, (total_cases/population)*100 AS PopCovid
FROM proj1..CovidDeaths
WHERE location = 'India'
ORDER BY 1,2

--Highest infection rates by countires
SELECT location, MAX(total_cases) as HighestInfectedCount, population, MAX((total_cases/population))*100 AS InfectedPopulation
FROM proj1..CovidDeaths
GROUP BY location, population
ORDER BY InfectedPopulation DESC

--Number of people died in each country
SELECT location, MAX(total_deaths) as DeathsByCovid 
FROM proj1..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY DeathsByCovid DESC

--Number of people died in each continent
SELECT continent, MAX(total_deaths) as DeathsByCovidPerContinent
FROM proj1..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY DeathsByCovidPerContinent DESC

--Global Numbers per day
SELECT date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, 
	SUM(new_deaths)/NULLIF(SUM(new_cases),0)*100 as death_percentage
FROM proj1..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

--Global numbers in total
SELECT SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, 
	SUM(new_deaths)/NULLIF(SUM(new_cases),0)*100 as death_percentage
FROM proj1..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

--Joining both tables
SELECT *
FROM proj1..CovidDeaths death 
	JOIN proj1..CovidVaccinations vacc
	ON death.location = vacc.location
	AND death.date = vacc.date

--Total population vs Vaccinations
SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations
FROM proj1..CovidDeaths death 
	JOIN proj1..CovidVaccinations vacc
	ON death.location = vacc.location
	AND death.date = vacc.date
WHERE death.continent IS NOT NULL 
ORDER BY 1,2,3

--Aggregating vaccinated people count by rolling over
SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations, 
	SUM(CONVERT(bigint, vacc.new_vaccinations)) 
	OVER (PARTITION BY death.location ORDER BY death.location, death.date) as rolling_count
FROM proj1..CovidDeaths death 
	JOIN proj1..CovidVaccinations vacc
	ON death.location = vacc.location
	AND death.date = vacc.date
WHERE death.continent IS NOT NULL 
ORDER BY 2,3

--Total population vs Vaccination using Common Table Expression
WITH Pop_CTE(continent, location, date, population, new_vaccinations, rolling_count)
AS(
	SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations, 
		SUM(CONVERT(bigint, vacc.new_vaccinations)) 
	OVER (PARTITION BY death.location ORDER BY death.location, death.date) as rolling_count
		FROM proj1..CovidDeaths death 
	JOIN proj1..CovidVaccinations vacc
		ON death.location = vacc.location AND death.date = vacc.date
	WHERE death.continent IS NOT NULL)

SELECT *, (rolling_count/population)*100 as vaccianted_pop_percentage
FROM Pop_CTE

--Creating a view
CREATE VIEW PopVaccinated AS 
	SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations, 
		SUM(CONVERT(bigint, vacc.new_vaccinations)) 
	OVER (PARTITION BY death.location ORDER BY death.location, death.date) as rolling_count
		FROM proj1..CovidDeaths death 
	JOIN proj1..CovidVaccinations vacc
		ON death.location = vacc.location AND death.date = vacc.date
	WHERE death.continent IS NOT NULL

SELECT * 
FROM PopVaccinated
