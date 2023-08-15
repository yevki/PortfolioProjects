/*
���������� ����� ��� Covid 19 

���������� �������: Joins, CTE's, Temp Tables, Windows Functions, Procedures, Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Select *
From PortfolioProject..CovidDeaths
Where continent is not null 
order by location, date


-- �������� ���, � ���� �� ������ ��������

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Where continent is not null 
order by location,population


-- ��������� ���������, ��� �������� �������� ������� ������� ��������� ����� �������� ������� ������� �� ����

create procedure CountryDeathPercentage (
	@Country varchar(20)
)
as
begin
	select location, date, total_cases, total_deaths, population, round((total_deaths/total_cases)*100,2) as DeathPercentage 
	from CovidDeaths
	where location = @Country
	and continent is not null
	order by location, date 
end

EXEC CountryDeathPercentage @Country = 'France';


-- �������� ������� ������� ����� ������� ���������
-- ������, ���� ������� ��������� ����������� Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
order by location, date


-- ����� � �������� ����� ����������� �������� � ����������

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Group by Location, Population
order by PercentPopulationInfected desc


-- ����� � �������� ������� ������� �� ���� ���������

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null 
Group by Location
order by TotalDeathCount desc



-- ������� �� ������������

-- ³������������ ���������� � ��������� ������� ������� �� ���� ���������

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null 
Group by continent
order by TotalDeathCount desc



-- �������� ���������

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null 



-- �������� ������� ��������� ��������� � ��������� �������
-- ������ ������� ���������, ��� �������� �������� ���� ������� ����� Covid

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by location,date


-- ������������ CTE ��� ��������� ���������� ��� Partition By � ������������ �����

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac


-- ������������ ��������� ������� ��� ��������� ���������� � Partition By � ������������ �����

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated




-- ��������� View ��� ��������� ����� ��� ��������� ����������

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

select*
from PercentPopulationVaccinated

-- -- ��������� �������, ��� �������� �������� ������� ������� ��������� ����� �������� ������� ������� �� ����

CREATE FUNCTION dbo.CountryDeathInfo (@Location nvarchar(255))
RETURNS TABLE
AS
RETURN
(
    SELECT location, date, total_cases, population, round((total_deaths/population)*100,2) as DeathPercentage 
    FROM CovidDeaths
    WHERE location = @Location 
	and continent is not null
);

GO

SELECT *
FROM dbo.CountryDeathInfo('Ukraine')
ORDER BY location, date;
