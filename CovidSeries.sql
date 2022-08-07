select * from PortfolioProject..CovidDeaths$ 
where continent is not null order by 3,4

--select * from PortfolioProject..CovidVaccines$ order by 3,4
--selecting data we're going to use

select location,date,total_cases,new_cases,total_deaths,population 
from PortfolioProject..CovidDeaths$ 
where continent is not null order by 1,2

--Percentage of daths (by cases)
--what percentage of people deied due to covid

select location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 as Percentage_of_deaths 
from PortfolioProject..CovidDeaths$
where continent is not null
--where location='India'
order by 1,2

--Total cases vs population
--what percentage of people got covid

select location,date,population,total_cases,(total_cases/population)*100 as Percentage_of_cases 
from PortfolioProject..CovidDeaths$
where continent is not null
--where location='India'
order by 1,2

--countries with highest infection rate compared to population
select location,population,max(total_cases) as max_cases,max((total_cases/population))*100 as Percentage_of_infection 
from PortfolioProject..CovidDeaths$
where continent is not null
group by location,population
order by Percentage_of_infection desc

--countries with highest deaths(because the datatype of total_deaths is varchar we need to type cast it into int)
select location,max(cast(total_deaths as int)) as max_deaths 
from PortfolioProject..CovidDeaths$
where continent is not null
group by location
order by max_deaths desc

--BREAK THINGS DOWN BY CONTINENT
select continent,max(cast(total_deaths as int)) as max_deaths 
from PortfolioProject..CovidDeaths$
where continent is not null
group by continent
order by max_deaths desc 

select continent,sum(cast(new_deaths as int)) as TotaldeathsCounts 
from PortfolioProject..CovidDeaths$
where continent is not null
group by continent
order by TotaldeathsCounts desc 

select location,population,date,max(new_cases) as MaximumCase,max((new_cases/population))*100 as InfectedPopulationPercentage
from PortfolioProject..CovidDeaths$
group by location,population,date
order by InfectedPopulationPercentage desc

--GLOBAL NUMBERS

--Total death percentage date wise
select date,sum(new_cases)as total_cases,sum(cast(new_deaths as int)) as total_deaths, 
sum(cast(new_deaths as int))/sum(new_cases)*100 as death_percentage
from PortfolioProject..CovidDeaths$ 
where continent is not null
group by date
order by 1,2

--Total death percentage in whole world
select sum(new_cases)total_cases,sum(cast(new_deaths as int)) as total_deaths, 
sum(cast(new_deaths as int))/sum(new_cases)*100 as death_percentage
from PortfolioProject..CovidDeaths$ 
where continent is not null
order by 1,2 

--JOINING TABLES
select * from PortfolioProject..CovidDeaths$ dea
join PortfolioProject..CovidVaccines$ vac
on dea.location=vac.location
and dea.date=vac.date
where dea.continent is not null

--Total population vs total vaccination
select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations
from PortfolioProject..CovidDeaths$ dea
join PortfolioProject..CovidVaccines$ vac
on dea.location=vac.location
and dea.date=vac.date
where dea.continent is not null 
order by 2,3

--sum of new vaccination with previous ones (for example if on 1st jan 2021 the vaccination starts and the count is 30 and 
--then the next day the count is 20 the total added like 50(30 from previous and 20 for current and the count goes till last one)
select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
sum(convert(bigint,vac.new_vaccinations)) over (partition by dea.location order by dea.location,dea.date) as RollingSum
from PortfolioProject..CovidDeaths$ dea
join PortfolioProject..CovidVaccines$ vac
on dea.location=vac.location
and dea.date=vac.date
where dea.continent is not null 
order by 2,3 

-- USE CTE
--just because we created rollingsum column we can not use it in another calculation so now I want to find the percentage
-- of people who vaccinated by using the rollingsum numbers because it has the total number of vaccination count
-- and we can not use order by inside CTE individually
-- we have to always run CTE query with its definition we can not execute individual query like we can not execute 
--select statement directly we have to execute the whole thing from "with" to the select statement

with popvsVac(continent,location,date,population,new_vaccinations,RollingSum)
as
(
select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
sum(convert(bigint,vac.new_vaccinations)) over (partition by dea.location order by dea.location,dea.date) as RollingSum
from PortfolioProject..CovidDeaths$ dea
join PortfolioProject..CovidVaccines$ vac
on dea.location=vac.location
and dea.date=vac.date
where dea.continent is not null 
)
select *,(RollingSum/population)*100 as RollingPercentage
from popvsVac

--TEMP TABLE
drop table if exists #TempRollingTable
create table #TempRollingTable
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingSum numeric
)
insert into #TempRollingTable 
select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
sum(convert(bigint,vac.new_vaccinations)) over (partition by dea.location order by dea.location,dea.date) as RollingSum
from PortfolioProject..CovidDeaths$ dea
join PortfolioProject..CovidVaccines$ vac
on dea.location=vac.location
and dea.date=vac.date
where dea.continent is not null 

select *,(RollingSum/population)*100 as RollingPercentage
from #TempRollingTable order by 2,3

--CREATE VIEW
create view DeathPercentage as 
select sum(new_cases)total_cases,sum(cast(new_deaths as int)) as total_deaths, 
sum(cast(new_deaths as int))/sum(new_cases)*100 as death_percentage
from PortfolioProject..CovidDeaths$ 
where continent is not null

create view DeathSumRolling as
select continent,location,date,population,new_deaths,
sum(convert(bigint,new_deaths)) over (partition by location order by location,date) as RollingSum
from PortfolioProject..CovidDeaths$ 
where continent is not null 


/*create view DeathPercentageRolling as
select continent,location,date,population,new_deaths,
sum(convert(bigint,new_deaths)) over (partition by location order by location,date) as RollingSum,
sum(convert(bigint,new_deaths)) over (partition by location order by location,date)/population*100 as RollingPercentage
from PortfolioProject..CovidDeaths$ 
where continent is not null */

select * from DeathPercentage 
select * from DeathSumRolling
--select *,RollingSum/population*100 from DeathSumRolling
