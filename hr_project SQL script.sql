CREATE DATABASE hr_project;

USE hr_project;

-- Load .csv file table : hr

SELECT * FROM hr;
DESCRIBE hr;

ALTER TABLE hr
CHANGE COLUMN id emp_id VARCHAR(20) NULL;

-- Modify column 'birthdate', 'hire_date' and 'termdate' to appropriate datatype

-- for birthdate column

SET SQL_SAFE_UPDATES = 0;

UPDATE hr
SET birthdate = CASE
	WHEN birthdate LIKE '%/%/%' THEN DATE_FORMAT(STR_TO_DATE(birthdate, '%m/%d/%Y'), '%Y-%m-%d')
    WHEN birthdate LIKE '%-%-%' THEN DATE_FORMAT(STR_TO_DATE(birthdate, '%m-%d-%Y'), '%Y-%m-%d')
    ELSE NULL 
	END;

ALTER TABLE hr
MODIFY COLUMN birthdate DATE;


-- for hire_date column
UPDATE hr
SET hire_date = CASE
	WHEN hire_date LIKE '%/%/%' THEN DATE_FORMAT(STR_TO_DATE(hire_date, '%m/%d/%Y'), '%Y-%m-%d')
    WHEN hire_date LIKE '%-%-%' THEN DATE_FORMAT(STR_TO_DATE(hire_date, '%m-%d-%Y'), '%Y-%m-%d')
    ELSE NULL 
	END;

ALTER TABLE hr
MODIFY COLUMN hire_date DATE;

-- for termdate column
UPDATE hr
SET termdate = date(STR_TO_DATE(termdate, '%Y-%m-%d %H:%i:%s UTC'))
WHERE termdate IS NOT NULL AND termdate != ' ';

ALTER TABLE hr
MODIFY COLUMN termdate DATE;

-- ADD column for 'age' -- calculated from birthdate to current date

ALTER TABLE hr
ADD COLUMN age INT;

UPDATE hr
SET age = TIMESTAMPDIFF(YEAR, birthdate, CURDATE());

SELECT birthdate, age FROM hr;
DESCRIBE hr;

-- check min and max age
SELECT
	MIN(age) as youngest,
    MAX(age) as oldest
FROM hr;

-- You may use this dataset for Power BI visualization
SELECT *
FROM hr;

-- QUESTIONS: 
-- 01 What is the gender breakdown of employees in the company?
SELECT * FROM hr;
SELECT gender, COUNT(*) AS count_gender
FROM hr
WHERE age >= 18 AND termdate = '0000-00-00'
GROUP BY gender;

-- 02 What is the race/ethnicity breakdown of employees in the company?
SELECT * FROM hr;
SELECT race, COUNT(*) AS count_race
FROM hr
WHERE age >= 18 AND termdate = '0000-00-00'
GROUP BY race
ORDER by race DESC;

-- 03 What is the age distribution of employees in the company?
SELECT * FROM hr;
SELECT 
	CASE 
		WHEN age >= 18 AND age <= 24 THEN '18-24'
        WHEN age >= 25 AND age <= 34 THEN '25-34'
        WHEN age >= 35 AND age <= 44 THEN '35-44'
        WHEN age >= 45 AND age <= 54 THEN '45-54'
        WHEN age >= 55 AND age <= 64 THEN '55-64'
        ELSE '65+'
	END AS age_group,
    gender,
    COUNT(*) AS age_group_count
FROM hr
WHERE age >= 18 AND termdate = '0000-00-00'
GROUP BY age_group, gender
ORDER BY age_group, gender;

-- 04 How many employees work at headquarters versus remote locations?
SELECT * FROM hr;
SELECT 
	location, 
    COUNT(*) AS loc_count
FROM hr
WHERE age >= 18 AND termdate = '0000-00-00'
GROUP BY location;

-- 05 What is the average length of employment for employees who have been terminated?
SELECT * FROM hr;
SELECT
	AVG(TIMESTAMPDIFF(DAY, hire_date, termdate)) / 365 AS length_of_employment_avg
FROM hr
WHERE termdate <= CURDATE() AND termdate <> '0000-00-00' AND age >= 18;


-- 06 How does the gender distribution vary across departments and job titles?
SELECT * FROM hr;
SELECT 
	department,
    jobtitle,
    gender,
    COUNT(*)
FROM hr
WHERE age >= 18 AND termdate = '0000-00-00'
GROUP BY department, jobtitle, gender
ORDER BY department, jobtitle, gender;

-- 07 What is the distribution of job titles across the company?
SELECT 
	jobtitle,
    COUNT(*)
FROM hr
WHERE age >=18 AND termdate = '0000-00-00'
GROUP BY jobtitle
ORDER BY COUNT(*) DESC;


-- 08 Which department has the highest turnover rate?
SELECT * FROM hr;
WITH subquery AS (
    SELECT 
		department,
		COUNT(*) AS total_count,
        SUM(CASE WHEN termdate <> '0000-00-00' AND termdate <= CURDATE() THEN 1 ELSE 0 END) AS term_count
	FROM hr
    GROUP BY department
    )
SELECT
	department,
    total_count,
    term_count,
    ROUND(term_count / total_count * 100,2) AS termination_rate
FROM subquery
GROUP BY department
ORDER BY termination_rate DESC;

SELECT department, COUNT(*) AS count_term
FROM hr
WHERE age >= 18 and termdate <> '0000-00-00' AND termdate <= CURDATE()
GROUP BY department
ORDER BY count_term DESC
LIMIT 1;

-- 09 What is the distribution of employees across locations by state?
SELECT * FROM hr;
SELECT
    location_state,
    COUNT(*) AS count
FROM hr
WHERE age >= 18 AND termdate = '0000-00-00'
GROUP BY location_state
ORDER BY location, count DESC;


-- 10 How has the company's employee count changed over time based on hire and term dates?
SELECT * FROM hr;
WITH subquery AS (
	SELECT 
		EXTRACT(YEAR FROM hire_date) AS year,
		COUNT(*) AS hires,
		SUM(CASE
			WHEN termdate <> '0000-00-00' AND termdate <= CURDATE() THEN 1
			ELSE 0 END) AS terminations
	FROM hr
	GROUP BY year
    )
SELECT
	year,
    hires,
    terminations,
    hires-terminations AS net_change,
    ROUND(((terminations) / hires *100),2)
FROM subquery
GROUP BY year;

-- using running totals
WITH subquery AS (
	SELECT
		YEAR(hire_date) AS year,
		COUNT(*) AS hires,
		SUM(CASE WHEN termdate <> '0000-00-00' AND termdate <= CURDATE() THEN 1 ELSE 0 END) AS terminations
	FROM hr
	GROUP BY year
	ORDER BY year
    )

SELECT
	year,
	hires,
	terminations,
	hires - terminations AS net_change,
    ROUND((hires - terminations) / hires *100, 2) AS net_change_percent,
	SUM(hires - terminations) OVER(ORDER BY year ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_pop
FROM subquery
GROUP BY year;


-- 11 What is the tenure distribution for each department?
SELECT * FROM hr;
SELECT
	department,
    ROUND(AVG(TIMESTAMPDIFF(DAY, hire_date, termdate)/365),2) AS tenure_avg
FROM hr
WHERE termdate <> '0000-00-00' AND termdate <= CURDATE() AND age >= 18	
GROUP BY department
ORDER BY tenure_avg;
