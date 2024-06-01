-- Exploratory Data Analysis

-- Taking a look at the data to find trends, patterns or anything interesting like outliers

#Take a look at the data
SELECT *
FROM layoffs_staging2;

#Looking at the timeframe of the dataset
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;
# Data was collected between March, 2020 and March, 2023


-- Agregates (totals)

# Highest number of people laid off according to the data
SELECT MAX(total_laid_off)
FROM layoffs_staging2;

# Percentage laid off
SELECT MAX(percentage_laid_off), MIN(percentage_laid_off)
FROM layoffs_staging2;

# Highest number of people laid off against highest percentage of people laid off
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;

# Companies with the biggest single Layoff
SELECT company, total_laid_off
FROM layoffs_staging2
ORDER BY 2 DESC
LIMIT 5;
# In a day Google fired 12000, Meta 11000, Amazon 10000, Microsoft 10000 and ericsson 8500, Wow!

# Companies with the most Total Layoffs
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;
# Amazon leads with a little over 18000 followed by Google with 1200 (which was in a day). Meta follows closely with 11000 (also in a day) not far behind are Salesforce, Microsoft and Philips who follow with about 10000 each

#Total Layoffs by industry
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

#Total Layoffs by location
SELECT location, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY location
ORDER BY 2 DESC;

#Total Layoffs by country
SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

#Total Layoffs by the stage of growth of the company
SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;

# Which companies had 1 which is basically 100 percent of they company laid off or the company closed down
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;

#Total number of companies that went under and the total number of layoffs by the stage of growth of the company
SELECT stage, SUM(total_laid_off) AS num_laid_off, COUNT(stage) AS total_stage, ROUND((COUNT(stage) / SUM(COUNT(stage)) OVER ()), 2) AS perc_stage
FROM layoffs_staging2
WHERE percentage_laid_off = 1 
AND stage != 'Unknown'
GROUP BY stage
ORDER BY total_stage DESC;
# It looks like it was mostly startups(Seed, Series A, B, C, D, E) (80%) that went out of business during this time

# Ordering by funds_raised_millions to see how big some of these companies were
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;
# With Britishvolt being the highest raising 2.4 billion, companies like Quibi, Deliveroo Australia, Katerra and BlockFi all raised over a billion only to go under



-- Time Series Analysis

# Looking at the total number of layoffs by year
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 2 DESC;
# Even though the highest number of layoffs was in 2022, as at March 2023, there had already been 125,677 layoffs

# Looking at the total number of layoffs month on month
SELECT SUBSTRING(`date`,1,7) AS `MONTH`, SUM(total_laid_off)
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC;

WITH Rolling_Total AS
(
SELECT SUBSTRING(`date`,1,7) AS `MONTH`, SUM(total_laid_off) AS total_sacked
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC
)
SELECT `MONTH`, total_sacked,
SUM(total_sacked) OVER(ORDER BY `MONTH`) AS rolling_total
FROM Rolling_Total;

# Looking at the top 5 companies for the highest number of layoffs per year
WITH Compay_Year (company, years, total_laid) AS
(
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
),
Company_Year_Rank AS
(
SELECT *, DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid DESC) AS Ranking
FROM Compay_Year
WHERE years IS NOT NULL
)
SELECT * 
FROM Company_Year_Rank
WHERE Ranking <= 5;

#Looking at the top 5 industries for the highest number of layoffs per year
WITH Industry_Year (industry, years, total_laid) AS
(
SELECT industry, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry, YEAR(`date`)
),
Industry_Year_Rank AS
(
SELECT *, DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid DESC) AS Ranking
FROM Industry_Year
WHERE years IS NOT NULL
)
SELECT * 
FROM Industry_Year_Rank
WHERE Ranking <= 5;

#Looking at the top 5 company stages with the highest number of layoffs per year
WITH Stage_Year (stage, years, total_laid) AS
(
SELECT 
CASE 
	WHEN stage LIKE 'Series%' OR stage = 'Seed' 
	THEN 'Start-Up'
	ELSE stage
END AS stage_label, 
YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage_label, YEAR(`date`)
),
Stage_Year_Rank AS
(
SELECT *, DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid DESC) AS Ranking
FROM Stage_Year
WHERE years IS NOT NULL
)
SELECT * 
FROM Stage_Year_Rank
WHERE Ranking <= 5;

#Looking at the top 5 countries for the highest number of layoffs per year
WITH Country_Year (country, years, total_laid) AS
(
SELECT country, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country, YEAR(`date`)
),
Country_Year_Rank AS
(
SELECT *, DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid DESC) AS Ranking
FROM Country_Year
WHERE years IS NOT NULL
)
SELECT * 
FROM Country_Year_Rank
WHERE Ranking <= 5;

#Looking at the top 5 Locations for the highest number of layoffs per year
WITH Location_Year (industry, years, total_laid) AS
(
SELECT location, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY location, YEAR(`date`)
),
Location_Year_Rank AS
(
SELECT *, DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid DESC) AS Ranking
FROM Location_Year
WHERE years IS NOT NULL
)
SELECT * 
FROM Location_Year_Rank
WHERE Ranking <= 5;
