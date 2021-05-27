
								--Covid 19 Data Exploration  OF Canada

--- Maximum New Cases in A Single Day
SELECT  location As Country,date,new_cases Maximum_NewCasesInDay from CovidDeaths where location = 'Canada' and continent is not null and 
new_cases = (
select max(new_cases) from CovidDeaths
where location = 'Canada' and continent is not null)

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT
location AS Country,DATENAME(YEAR,date) IsYear,SUM(ISNULL(new_cases,0))total_cases,SUM(ISNULL(CAST(new_deaths as int),0))total_deaths,
SUM(ISNULL(CAST(new_deaths as int),0))/SUM(ISNULL(new_cases,0))*100 AS DeathPercentage 
FROM CovidDeaths WHERE continent IS NOT NULL AND location = 'Canada'
GROUP BY location,DATENAME(YEAR,date)
ORDER BY location
--- Max Deaths In A Single Day_2020
SELECT max(CAST(new_deaths as int)) MaxDeathsInSingleDay_2020 FROM CovidDeaths
WHERE location = 'Canada' and continent is not null and DATENAME(year,date) = 2020 order by MaxDeathsInSingleDay_2020 desc
--- Max Deaths In A Single Day_2021
SELECT max(CAST(new_deaths as int)) MaxDeathsInSingleDay_2021 FROM CovidDeaths 
WHERE location = 'Canada' and continent is not null and DATENAME(year,date) = 2021 order by MaxDeathsInSingleDay_2021 desc


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid
SELECT location As Coutry,date,total_cases,population TotalPopulation,CONVERT(DECIMAL(14,8), (total_cases/population)*100 ) as PercentPopulationInfected
FROM CovidDeaths
WHERE continent IS NOT NULL AND location = 'CANADA'
ORDER BY location,date

-- Countries with Highest NumberofCases
SELECT location As Coutry,MAX(total_cases) total_cases FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_cases DESC

-- Countries with Highest Infection Rate compared to Population
SELECT 
location As Country,population TotalPopulation,MAX(total_cases) AS HighestInfectionCount,MAX(CONVERT(DECIMAL(14,8), 
(total_cases/population)*100)) as PercentPopulationInfected
FROM CovidDeaths
GROUP BY location,population
ORDER BY PercentPopulationInfected DESC

-- Countries with Highest Death Count per Population
SELECT location AS Countries,population,max(total_deaths) As total_deaths
from CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location,population
ORDER BY total_deaths DESC

---Countries With Maximum Deaths
Select Location As Country, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null 
Group by Location
order by TotalDeathCount desc


						-- BREAKING THINGS DOWN BY CONTINENT


-- Showing contintents with the highest death count 
SELECT location Continent,MAX(cast(total_cases as int))total_cases,MAX(cast(Total_deaths as int)) AS Total_Deaths FROM CovidDeaths 
WHERE continent IS  NULL
GROUP BY location
ORDER BY Total_Deaths DESC


-- Showing contintents with the highest death count per population

SELECT location Continent,MAX(population) total_population,MAX(cast(Total_deaths as int)) AS Total_Deaths,
MAX(cast(Total_deaths as int)) / MAX(population)*100 As DeathPercentage
FROM CovidDeaths 
WHERE continent IS  NULL
GROUP BY location
ORDER BY DeathPercentage DESC



					--- GLOBAL NUMBERS

--- Total Cases/Deaths In the World PerDay
SELECT 
date,SUM( new_cases  )total_cases,SUM(CAST( new_deaths AS INT)) total_deaths,
SUM(CAST( new_deaths AS INT))/SUM(new_cases) * 100 As GlobalDeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
group by date
order by 1,2
--- Total Cases/Deaths In the World 
SELECT 
SUM( new_cases  )total_cases,SUM(CAST( new_deaths AS INT)) total_deaths,
SUM(CAST( new_deaths AS INT))/SUM(new_cases) * 100 As GlobalDeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
order by 1,2


--- Total Population vs Total Vaccination

-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3


---  Using CTE to perform Calculation on Partition By in previous query

with PopVsVacc (continent,location,date,population,new_vaccinations,RollingTotalForVaccination)
As
(
select CDeaths.continent,CDeaths.location,CDeaths.date,CDeaths.population,CVacc.new_vaccinations ,
SUM(CAST(CVacc.new_vaccinations AS int)) OVER (PARTITION BY CDeaths.location order by CDeaths.location,CDeaths.date) As RollingTotalForVaccination
from 
CovidDeaths CDeaths
JOIN CovidVaccinations CVacc
ON CDeaths.location = CVacc.location AND CDeaths.date = CVacc.date
WHERE CDeaths.continent IS NOT NULL 

)
select *,RollingTotalForVaccination/population*100 As PerPopulationVaccinated from PopVsVacc
order by 1,2,3


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP  TABLE IF  EXISTS #PerPopulationVaccinated
CREATE TABLE #PerPopulationVaccinated
(
Continent nvarchar(255),
Location  nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingTotalForVaccination numeric
)

insert into #PerPopulationVaccinated
select CDeaths.continent,CDeaths.location,CDeaths.date,CDeaths.population,CVacc.new_vaccinations ,
SUM(CAST(CVacc.new_vaccinations AS int)) OVER (PARTITION BY CDeaths.location order by CDeaths.location,CDeaths.date) As RollingTotalForVaccination
from 
CovidDeaths CDeaths
JOIN CovidVaccinations CVacc
ON CDeaths.location = CVacc.location AND CDeaths.date = CVacc.date
WHERE CDeaths.continent IS NOT NULL 

select *,RollingTotalForVaccination/population*100 As PerPopulationVaccinated from #PerPopulationVaccinated
order by 1,2,3

---- Create View to Store Data for Later Visualizations
CREATE VIEW PerPopulationVaccinated
AS
select CDeaths.continent,CDeaths.location,CDeaths.date,CDeaths.population,CVacc.new_vaccinations ,
SUM(CAST(CVacc.new_vaccinations AS int)) OVER (PARTITION BY CDeaths.location order by CDeaths.location,CDeaths.date) As RollingTotalForVaccination
from 
CovidDeaths CDeaths
JOIN CovidVaccinations CVacc
ON CDeaths.location = CVacc.location AND CDeaths.date = CVacc.date
WHERE CDeaths.continent IS NOT NULL 

