-- Data Cleaning

SELECT *
FROM layoffs;

-- Cleaning Process
-- 1. Stage the Data
-- 2. Remove Duplicates
-- 3. Standardize the Data
-- 4. Null Values or Blank Values
-- 5. Remove Any Columns or Rows


-- Create staging table
# This is done because we are about to change the original data alot so we do not want the situation where we lose data and cannot get it back

DROP TABLE IF EXISTS `layoffs_staging`;

CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT *
FROM layoffs_staging;

INSERT layoffs_staging
SELECT *
FROM layoffs;


-- Remove Duplicates
# We start by identifying the duplicates

# 1. Use row number and over and partition by unique columns
# 2. Check to see if any of the entries of the row_num column is 2 or more
# We do this using CTE
WITH duplicates_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicates_cte
WHERE row_num > 1;

SELECT *
FROM layoffs_staging
WHERE company = 'Casper';

# 3. Deleting Duplicates
# We start by creating a second staging table
DROP TABLE IF EXISTS `layoffs_staging2`;
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

SELECT *
FROM layoffs_staging2;

# Delete Th duplicates now
DELETE
FROM layoffs_staging2
WHERE row_num > 1;
#  Check if duplicates still exist
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

SELECT DISTINCT row_num
FROM layoffs_staging2; # another way to check


-- Standardizing the Data
# We are going to do this column by column

#company
# there were a lot of spaces infront and behind some of the company names which has to be dealt with
SELECT company, TRIM(company)
FROM layoffs_staging2; 

# Update the company name to the trim so all spaces will be removed
UPDATE layoffs_staging2
SET company = TRIM(company); 

#industry
# there were some null values and blank spases but also there were 3 different type of entries for crypto currecy
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

# Found out majority of the crypto currency entries were labelled as Crypto so we will change the rest to match
SELECT industry
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%'; 

# Update the names to just Crypto
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

#country
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

# update United States to the correct format
UPDATE layoffs_staging2
SET country = 'United States'
WHERE country LIKE 'United States%';

#date
SELECT `date`
FROM layoffs_staging2;

# Update date to the correct format
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

# Change the data type of the date column to date-time
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;


-- Dealing with Null Values or Blank Values

#industry
# Set all blank entries in the industry column to null
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

# Check If the companies with blank or null industry type has done layoffs multiple times
SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
ON t1.company = t2.company
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

# Fill Blank indusatries with the existing industry from the table if the company has done layoffs multiple times
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

# Verify if there are still null values in the industry column
SELECT company, industry
FROM layoffs_staging2
WHERE industry IS NULL;

# Research on the industry type for the nulls and fill them 
UPDATE layoffs_staging2
SET industry = 'Gaming'
WHERE company = 'Bally\'s Interactive';


-- Remove Any Columns or Rows

# total_laid_off and percentage_laid_off
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

# Delete rows wnere total_laid_off and percentage_laid_off columns are null
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

# Drop the row_num column
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

SELECT *
FROM layoffs_staging2;


-- Recap of Cleaning Process
-- 1. Stage the Data
-- 2. Remove Duplicates
-- 3. Standardize the Data
-- 4. Null Values or Blank Values
-- 5. Remove Any Columns or Rows

-- END