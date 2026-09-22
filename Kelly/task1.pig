-- task1.pig - assignment 2 big data processing task1

-- Load
medal_table = LOAD '/medal_table.csv' USING PigStorage(',')
    AS (year:int, country_code:chararray, gold:int, silver:int, bronze:int);

populations = LOAD '/population.csv' USING PigStorage(',')
    AS (year:int, country_code:chararray, population:int);

countries = LOAD '/countries.csv' USING PigStorage(',')
    AS (country_code:chararray, country_name:chararray, region:chararray);

-- Join
medalandpop = JOIN populations BY (year, country_code), medal_table BY (year, country_code);

joined = JOIN medalandpop BY populations::country_code, countries BY country_code;

/* Dump joined bag
DUMP joined
*/

-- Filter by region
region_filtered = FILTER joined BY region == '$REGION';

-- Foreach generate computing for total_medals & medals_per_million
firststage = FOREACH region_filtered GENERATE
    populations::year, region, populations::country_code, country_name, gold, 
    (gold+silver+bronze) AS total_medals, 
    population;

completebag = FOREACH firststage GENERATE 
    year, region, country_code, country_name, gold, total_medals, population,
    ((double)total_medals/population)*1000000 AS medals_per_million;

/* Dump the bag after foreach generate stages
DUMP completebag
*/

-- Group By ()
grouped_year_region = GROUP completebag BY (year, region);

/* Dump some of grouped bag
limited = LIMIT grouped_year_region 3;
DUMP limited
*/

-- UDF usage
REGISTER 'task1.py' USING jython AS task1_udf;

ranked = FOREACH grouped_year_region GENERATE 
    FLATTEN(task1_udf.rank_group(completebag)) AS
    (year:int, region:chararray, rank_no:int, country_code:chararray, country_name:chararray, 
    gold:int, total_medals:int, population:int, medals_per_million:double);

-- Order and Store
final_sorted = ORDER ranked BY year ASC, rank_no ASC;

STORE final_sorted INTO '/Output/task1' USING PigStorage(',');