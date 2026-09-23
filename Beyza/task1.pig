-- Regional Ranking by Country Medal Efficiency
REGISTER 'task1.py' USING jython AS myudfs;

-- Load and Filter --
countries_raw = LOAD '/countries.csv' USING PigStorage(',')
    AS (country_code:chararray, country_name:chararray, region:chararray);

-- filter on region before join
countries_filtered = FILTER countries_raw BY region == $REGION;

medals_raw = LOAD '/medal_table.csv' USING PigStorage(',')
    AS (year:int, country_code:chararray, gold:int, silver:int, bronze:int);

population_raw = LOAD '/population.csv' USING PigStorage(',')
    AS (year:int, country_code:chararray, population:int);

-- Join Filtered Small Countries into medal_table --
countries_medals = JOIN countries_filtered BY country_code, medals_raw BY country_code USING 'replicated';
-- replicated hints to Pig to load the small filtered countries bag into memory on each mapper, avoiding full shuffle

-- Bring in Population via Composite Key (year, country_code)
with_population = JOIN countries_medals BY (medals_raw::year, medals_raw::country_code), 
                    population_raw BY (year, country_code);

-- Compute Derived Fields and Keep Necessary Columns Only
enriched = FOREACH with_population GENERATE
    medals_raw::year AS year,
    countries_filtered::region AS region,
    countries_filtered::country_code AS country_code,
    countries_filtered::country_name AS country_name,
    medals_raw::gold AS gold,
    (medals_raw::gold + medals_raw::silver + medals_raw::bronze) AS total_medals,
    population_raw::population AS population,
    ((double)(medals_raw::gold + medals_raw::silver + medals_raw::bronze) / 
    population_raw::population) * 1000000 AS medals_per_million;

-- Group per (year, region) for Ranking
grouped = GROUP enriched BY (year, region);

ranked = FOREACH grouped GENERATE
    FLATTEN(myudfs.rank_countries(enriched))
    AS (year, region, rank_no, country_code, country_name, gold, total_medals, population, medals_per_million);

final_output = ORDER ranked BY year ASC, rank_no ASC;
STORE final_output INTO '/Output/task1' USING PigStorage(',');


