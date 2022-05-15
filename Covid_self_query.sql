/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

select *
from covid.dbo.Covid_deaths
where continent is not null
order by 3,4;

-- Select Data that we are going to be starting with
select location,date,new_cases,total_cases,total_deaths,population
from covid.dbo.Covid_deaths
where continent is not null
order by 1,2;

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

select location , date, total_cases,total_deaths,(total_deaths  /total_cases)*100 as DeathPercentage
from covid.dbo.Covid_deaths
--where location like'%India%'
where continent is not null
order by 1,2;

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

select location, date, total_cases,population,(total_cases/population)*100 as PopulationInfected
from covid.dbo.Covid_deaths
where continent is not null
order by 1,2;

-- Countries with Highest Infection Rate compared to Population

select location,population,MAX(total_cases) as HighestInfectionCount , MAX((total_cases/population))*100 as PopulationInfectedPercentage
from covid.dbo.Covid_deaths
--where location like'%India%'
group by location,population
order by PopulationInfectedPercentage desc;

-- Countries with Highest Death Count per Population
select location,MAX(cast(total_deaths as int)) as HighestDeathCount
from covid.dbo.Covid_deaths
--where location like'%India%
where continent is not null
group by location
order by HighestDeathCount desc;

-- BREAKING THINGS DOWN BY CONTINENT

-- Showing continents with the highest death count per population

select continent,MAX(cast(total_deaths as int)) as HighestDeathCount
from covid.dbo.Covid_deaths
--where location like '%India%'
where continent is not null
group by continent
order by HighestDeathCount desc;

-- GLOBAL NUMBERS

select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths,SUM(cast(new_deaths as int))/SUM(new_cases)*100  as DeathPercentage
from covid.dbo.Covid_deaths
where continent is not null
--group by date
order by 1,2


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
-- showing rolling count of vaccinations

select dea.continent , dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(convert(int,vac.new_vaccinations)) OVER (partition by dea.location order by dea.location,dea.date) as RollingCountOfVaccination
-- ,(RollingCountOfVaccination/population)*100 as RollingPercentage 
-- actually u cant create column mentione above , for that we have to create CTE or temp tables
from covid.dbo.Covid_deaths as dea join covid.dbo.CovidVaccinations as vac
on
dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
order by 2,3;

-- Using CTE to perform Calculation on Partition By in previous query

with PopvsVac (Continent,location,date, population,new_vaccinations,RollingCountOfVaccination)
as
(
select dea.continent , dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(convert(int,vac.new_vaccinations)) OVER (partition by dea.location order by dea.location,dea.date) as RollingCountOfVaccination
-- ,(RollingCountOfVaccination/population)*100 as RollingPercentage 
-- actually u cant create column mentione above , for that we have to create CTE or temp tables
from covid.dbo.Covid_deaths as dea join covid.dbo.CovidVaccinations as vac
on
dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
select *,(RollingCountOfVaccination/population)*100 as VaccinationPercentage
from PopvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query


Drop table if exists #VaccinationPercentage
create Table #VaccinationPercentage
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingCountOfVaccination numeric
)

Insert into #VaccinationPercentage
select dea.continent , dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(convert(int,vac.new_vaccinations)) OVER (partition by dea.location order by dea.location,dea.date) as RollingCountOfVaccination
-- ,(RollingCountOfVaccination/population)*100 as RollingPercentage 
from covid.dbo.Covid_deaths as dea join covid.dbo.CovidVaccinations as vac
on
dea.location = vac.location and dea.date = vac.date
--where dea.continent is not null
--order by 2,3

select *,(RollingCountOfVaccination/population)*100 as VaccinationPercentage
from #VaccinationPercentage



-- Creating View to store data for later visualizations


create View VaccinationPercentage as

select dea.continent , dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(convert(int,vac.new_vaccinations)) OVER (partition by dea.location order by dea.location,dea.date) as RollingCountOfVaccination
-- ,(RollingCountOfVaccination/population)*100 as RollingPercentage 
from covid.dbo.Covid_deaths as dea join covid.dbo.CovidVaccinations as vac
on
dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
--order by 2,3

select *  from VaccinationPercentage