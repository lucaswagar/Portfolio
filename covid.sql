-- Covid Data from January 22, 2020 - January 14, 2022
-- https://ourworldindata.org/covid-deaths


SELECT
	*
FROM
	portfolio.covid_data


-- standardize date and extract month/year into new columns

SELECT
	date,
	STR_TO_DATE(date, '%c/%e/%y') AS new_date,
	SUBSTRING_INDEX(STR_TO_DATE(date, '%c/%e/%y'), '-', 1) AS reported_year,
	SUBSTRING_INDEX(SUBSTRING_INDEX(STR_TO_DATE(date, '%c/%e/%y'), '-', - 2), '-', 1) AS reported_month,
FROM
	portfolio.covid_data;

ALTER TABLE covid_data
	ADD COLUMN new_date VARCHAR(255),
			ADD COLUMN reported_year VARCHAR(255),
					ADD COLUMN reported_month VARCHAR(255);

UPDATE
	covid_data
SET
	new_date = STR_TO_DATE(date, '%c/%e/%y'),
	reported_year = SUBSTRING_INDEX(STR_TO_DATE(date, '%c/%e/%y'), '-', 1),
	reported_month = SUBSTRING_INDEX(SUBSTRING_INDEX(STR_TO_DATE(date, '%c/%e/%y'), '-', - 2), '-', 1);


-- Vaccination rate vs Fatality rate by region

SELECT
	LOCATION,
	(MAX(people_fully_vaccinated) / MAX(population)) * 100 AS vaccination_rate,
	(MAX(total_deaths) / MAX(total_cases)) * 100 AS fatality_rate
FROM
	portfolio.covid_data
WHERE
	continent = ''
	AND LOCATION <> 'Upper middle income'
	AND LOCATION <> 'Lower middle income'
	AND LOCATION <> 'Low income'
	AND LOCATION <> 'High income'
	AND LOCATION <> 'International'
GROUP BY
	LOCATION;


-- top 10 countries with highest total case numbers and their percentage of world's cases

WITH top AS (
	SELECT
		LOCATION,
		MAX(total_cases) AS cases,
		RANK() OVER (ORDER BY MAX(total_cases)
			DESC) AS case_rank
	FROM
		portfolio.covid_data
	WHERE
		continent <> ''
	GROUP BY
		LOCATION ORDER BY
			cases DESC
)
SELECT
	LOCATION,
	cases,
	(cases / (
	   SELECT
		   MAX(total_cases)
	   FROM
		   portfolio.covid_data
	   WHERE
		   LOCATION = 'World')) * 100 AS percent_world_cases
FROM
	top
WHERE
	case_rank <= 10;


-- Reported cases per million compared to vaccination rate and fatality rate

SELECT
	LOCATION,
	MAX(total_cases_per_million) AS reported_cases_per_million,
	MAX(total_deaths_per_million) AS reported_deaths_per_million,
	(MAX(people_fully_vaccinated) / MAX(population)) * 100 AS vaccination_rate,
	(MAX(total_deaths) / MAX(total_cases)) * 100 AS fatality_rate
FROM
	portfolio.covid_data
WHERE
	continent <> ''
GROUP BY
	LOCATION
ORDER BY
	reported_cases_per_million DESC;


-- Rolling total of cases in United States

SELECT
	LOCATION,
	new_cases,
	sum(new_cases) OVER (ORDER BY new_date) AS rolling_total_cases
FROM
	portfolio.covid_data
WHERE
	LOCATION = 'United States';


-- View for Tableau

SELECT
	LOCATION,
	total_cases,
	new_cases,
	(people_fully_vaccinated / population) * 100 AS full_vaccination_rate,
	total_deaths,
	new_date
FROM
	portfolio.covid_data
WHERE
	continent <> '';
	
