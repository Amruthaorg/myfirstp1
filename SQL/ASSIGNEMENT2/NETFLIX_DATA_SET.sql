show databases;
use bigdata2025;


create table Netflix_show_data (
show_id varchar(200),
Type varchar (200),
Title varchar (200),
Director_name varchar (1000),
Cast varchar (1000),
Country_name varchar (200),
date_added varchar (200),
release_year varchar (200),
rating varchar (200),
duration varchar (200),
listed_in varchar (200),
description varchar (1000)
);


-- select * from Netflix_data;
-- SET GLOBAL local_infile = 1;
-- load data infile 'C:\ProgramData\MySQL\MySQL Server 8.0\Uploads\netflix_titles.csv'
-- into table Netflix_movies_data  
-- fields terminated by ','
-- optionally enclosed by '"'
-- lines terminated by '\n'
-- ignore 1 rows;

SHOW VARIABLES LIKE 'secure_file_priv';

ALTER TABLE Netflix_data
MODIFY description VARCHAR(1000);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/netflix_titles.csv'
INTO TABLE Netflix_show_data
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

select count(*) from Netflix_show_data;
select * from Netflix_show_data
limit 20;


rename table Netflix_show_data to netflix_shows_raw_data;

CREATE TABLE Netflix_clean_data (
    show_id VARCHAR(200),
    type VARCHAR(200),
    title VARCHAR(255),
    director_name VARCHAR(255),
    cast varchar(1000),
    country_name VARCHAR(100),
    date_added DATE,
    release_year YEAR,
    rating VARCHAR(200),
    duration VARCHAR(200),
    listed_in varchar(1000),
    description TEXT
);

alter table Netflix_clean_data 
rename column director to director_name;

alter table Netflix_clean_data 
rename column country to country_name;

describe Netflix_clean_data;

drop table Netflix_clean_data;
select count(date_added) from Netflix_clean_data;

select * from  Netflix_clean_data
limit 100;
INSERT INTO Netflix_clean_data 
SELECT
    show_id,
    type,
    title,
    director_name,
    cast,
    country_name,
    CASE
    WHEN STR_TO_DATE(date_added, '%d-%b-%y') IS NOT NULL THEN STR_TO_DATE(date_added, '%d-%b-%y')
    WHEN STR_TO_DATE(date_added, '%M %d,%Y') IS NOT NULL THEN STR_TO_DATE(date_added, '%M %d,%Y')
    ELSE NULL
    END AS date_added,
    CAST(release_year AS UNSIGNED),
    rating,
    duration,
    listed_in,
    description
FROM netflix_shows_raw_data;


use bigdata2025;

select date_added from netflix_shows_raw_data
limit 1000;
select date_added from Netflix_clean_data 
limit 1000;
describe Netflix_clean_data;

--- 1. check for Missing Values 

SELECT 
  COUNT(*) AS total_rows,
  COUNT(CASE WHEN show_id IS NULL THEN 1 END) AS null_show_id,
  COUNT(CASE WHEN type IS NULL THEN 1 END) AS null_type,
  COUNT(CASE WHEN title IS NULL THEN 1 END) AS null_title,
  COUNT(CASE WHEN director_name IS NULL THEN 1 END) AS null_director_name,
  COUNT(CASE WHEN cast IS NULL THEN 1 END) AS null_cast,
  COUNT(CASE WHEN country_name IS NULL THEN 1 END) AS null_country_name,
  COUNT(CASE WHEN date_added IS NULL THEN 1 END) AS null_date_added,
  COUNT(CASE WHEN release_year IS NULL THEN 1 END) AS null_release_year,
  COUNT(CASE WHEN rating IS NULL THEN 1 END) AS null_rating,
  COUNT(CASE WHEN duration IS NULL THEN 1 END) AS null_duration,
  COUNT(CASE WHEN listed_in IS NULL THEN 1 END) AS null_listed_in,
  COUNT(CASE WHEN description IS NULL THEN 1 END) AS null_description
FROM Netflix_clean_data;

 --- 2. Checking for empty strings

SELECT 
  COUNT(*) AS total_rows,
  COUNT(CASE WHEN show_id = '' THEN 1 END) AS empty_show_id,
  COUNT(CASE WHEN type = '' THEN 1 END) AS empty_type,
  COUNT(CASE WHEN title = '' THEN 1 END) AS empty_title,
  COUNT(CASE WHEN director_name = '' THEN 1 END) AS empty_director,
  COUNT(CASE WHEN cast = '' THEN 1 END) AS empty_cast,
  COUNT(CASE WHEN country_name = '' THEN 1 END) AS empty_country,
  COUNT(CASE WHEN release_year = '' THEN 1 END) AS empty_release_year,
  COUNT(CASE WHEN rating = '' THEN 1 END) AS empty_rating,
  COUNT(CASE WHEN duration = '' THEN 1 END) AS empty_duration,
  COUNT(CASE WHEN listed_in = '' THEN 1 END) AS empty_listed_in,
  COUNT(CASE WHEN description = '' THEN 1 END) AS empty_description
FROM Netflix_clean_data;

--- 3.Replace Empty Strings with NULLs
UPDATE Netflix_clean_data
SET 
    Director_name = NULLIF(Director_name, ''),
    Cast = NULLIF(Cast, ''),
    Country_name = NULLIF(Country_name, ''),
    Rating = NULLIF(Rating, ''),
    Duration = NULLIF(Duration, '');
    
--- 4. Check for NULL values in those columns
SELECT *
FROM Netflix_clean_data
WHERE
    Director_name IS NULL OR
    Cast IS NULL OR
    Country_name IS NULL OR
    Rating IS NULL OR
    Duration IS NULL;

SELECT * 
FROM Netflix_clean_data
WHERE
    Title REGEXP '[^a-zA-Z0-9 .,:;!?()''"-]' OR
    Director_name REGEXP '[^a-zA-Z0-9 .,:;!?()''"-]' OR
    Cast REGEXP '[^a-zA-Z0-9 .,:;!?()''"-]' OR
    Country_name REGEXP '[^a-zA-Z0-9 .,:;!?()''"-]' OR
    date_added REGEXP '[^a-zA-Z0-9 ,-]' OR
    release_year REGEXP '[^0-9]' OR
    rating REGEXP '[^a-zA-Z0-9 .,:;!?()''"-]' OR
    duration REGEXP '[^a-zA-Z0-9 .,:;!?()''"-]' OR
    listed_in REGEXP '[^a-zA-Z0-9 .,:;!?()''"-]' OR
    description REGEXP '[^a-zA-Z0-9 .,:;!?()''"-]';

-- select * from netflix_shows_raw_data
-- limit 20;

select * from Netflix_clean_data
limit 20;

SELECT show_id, COUNT(*) as count
FROM netflix_clean_data;

--- 5. want find Top 5 countries with the most content?

select country_name, total_content
from (
 select country_name,count(*) as total_content,
rank() over (order by count(*) desc ) as rank_by_content
from netflix_clean_data
where country_name is not null 
group by country_name 
) a 
where rank_by_content <= 5;
 
 --- 6. want to find Average duration of movies?
 
 select * from netflix_clean_data
 limit 20;
 
 select round(avg(cast(substring_index(duration, ' ',1) as unsigned )),2) as avg_movie_duration
 from netflix_clean_data
 where type = 'Movie';
 
--- 7. find Top directors by number of titles?
select director_name, count(title) as total_titles
from netflix_clean_data
group by director_name
order by total_titles desc;

--- 8. find Movies with the longest durations? 

select title,duration from netflix_clean_data
where type = 'movie' and duration like '%min%' or duration LIKE '%Season%' -- no_difference
ORDER BY CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) DESC
LIMIT 5;

select title,duration from netflix_clean_data
where type = 'movie' and duration like '%min%' 
ORDER BY CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) DESC
LIMIT 5;

--- 9.Most Frequent Cast Members

SELECT `cast`, COUNT(*) AS appearances # 
FROM Netflix_clean_data
WHERE `cast` IS NOT NULL
GROUP BY `cast`
ORDER BY appearances DESC
LIMIT 5;

--- 10.find TV shows with the most Seasons 

SELECT title, duration from netflix_clean_data
where type = 'TV Show'and duration like '%Season%'
group by  title
ORDER BY CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) DESC
LIMIT 5;

--- 11.new Content Added Per  every Month?
SELECT 
  DATE_FORMAT(date_added, '%Y-%m') AS month_added,
  COUNT(*) AS new_titles
FROM Netflix_clean_data
WHERE date_added IS NOT NULL
GROUP BY month_added
ORDER BY month_added desc;

--- ROW_NUMBER

-- with cte as (
-- select *, row_number() over (partition by show_id order by date_added desc) as rn
-- from Netflix_clean_data
-- )
-- select * from cte where rn = 1;

-- with cte as (
-- select *, rank () over (partition by show_id order by date_added desc) as rn
-- from Netflix_clean_data
-- )
-- select * from cte where rn = 1;
