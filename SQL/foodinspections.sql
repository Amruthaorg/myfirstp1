show databases;
drop database w3schools;
use bigdata;
CREATE TABLE Foodinspections (
    Name VARCHAR(200),
    Program_Identifier VARCHAR(200),
    Inspection_Date VARCHAR(200),
    Description VARCHAR(200),
    Address VARCHAR(200),
    City VARCHAR(100),
    Zip_Code VARCHAR(20),
    Phone VARCHAR(20),
    Longitude VARCHAR(200),
    Latitude VARCHAR(200),
    Inspection_Business_Name VARCHAR(200),
    Inspection_Type VARCHAR(200),
    Inspection_Score VARCHAR(200),
    Inspection_Result VARCHAR(200),
    Inspection_Closed_Business VARCHAR(200),
    Violation_Type VARCHAR(200),
    Violation_Description VARCHAR(200),
    Violation_Points VARCHAR(200),
    Business_ID VARCHAR(200),
    Inspection_Serial_Num VARCHAR(200),
    Violation_Record_ID VARCHAR(200),
    Grade VARCHAR(200)
);
alter table inspections
modify Inspection_Date varchar(20);

select * from foodinspections;
DESCRIBE inspections;
SET GLOBAL local_infile = 1;


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Food_Establishment_Inspection_Data_20250520.csv'
INTO TABLE foodinspections
FIELDS TERMINATED BY ',' 
optionally ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SHOW VARIABLES LIKE 'secure_file_priv';

select count(*) from foodinspections;

CREATE TABLE inspections_cleaned_data (
    Name VARCHAR(200),
    Program_Identifier VARCHAR(200),
    Inspection_Date date,
    Description VARCHAR(200),
    Address VARCHAR(200),
    City VARCHAR(100),
    Zip_Code VARCHAR(20),
    Phone VARCHAR(20),
    Longitude double,
    Latitude double,
    Inspection_Business_Name VARCHAR(200),
    Inspection_Type VARCHAR(200),
    Inspection_Score int,
    Inspection_Result VARCHAR(200),
    Inspection_Closed_Business boolean,
    Violation_Type VARCHAR(200),
    Violation_Description VARCHAR(200),
    Violation_Points int,
    Business_ID VARCHAR(200),
    Inspection_Serial_Num VARCHAR(200),
    Violation_Record_ID VARCHAR(200),
    Grade int
);


describe inspections_cleaned_data;

-- INSERT INTO inspections_cleaned_data (
--     Name, Program_Identifier, Inspection_Date, Description, Address,
--     City, Zip_Code, Phone, Longitude, Latitude,
--     Inspection_Business_Name, Inspection_Type, Inspection_Score, Inspection_Result,
--     Inspection_Closed_Business, Violation_Type, Violation_Description,
--     Violation_Points, Business_ID, Inspection_Serial_Num, Violation_Record_ID, Grade
-- )
-- SELECT
--     Name,
--     Program_Identifier,
--     CASE
--         WHEN Inspection_Date REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$'
--             THEN STR_TO_DATE(Inspection_Date, '%m/%d/%Y')
--         WHEN Inspection_Date REGEXP '^[a-zA-Z]{3,9}-[0-9]{1,2}-[0-9]{4}$'
--             THEN STR_TO_DATE(Inspection_Date, '%b-%d-%Y')  -- Or %M-%d-%Y if full month
--         WHEN Inspection_Date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$'
--             THEN STR_TO_DATE(Inspection_Date, '%d-%m-%Y')
--         ELSE NULL
--     END,
--     Description,
--     Address,
--     City,
--     Zip_Code,
--     Phone,
--     CAST(Longitude AS DOUBLE),
--     CAST(Latitude AS DOUBLE),
--     Inspection_Business_Name,
--     Inspection_Type,
--     CAST(Inspection_Score AS SIGNED),
--     Inspection_Result,
--     CASE 
--         WHEN Inspection_Closed_Business IN ('Y', 'Yes', 'TRUE', '1') THEN TRUE
--         ELSE FALSE
--     END,
--     Violation_Type,
--     Violation_Description,
--     CAST(Violation_Points AS SIGNED),
--     Business_ID,
--     Inspection_Serial_Num,
--     Violation_Record_ID,
--     CAST(Grade AS SIGNED)
-- FROM Foodinspections;

INSERT INTO inspections_cleaned_data (
    Name,
    Program_Identifier,
    Inspection_Date,
    Description,
    Address,
    City,
    Zip_Code,
    Phone,
    Longitude,
    Latitude,
    Inspection_Business_Name,
    Inspection_Type,
    Inspection_Score,
    Inspection_Result,
    Inspection_Closed_Business,
    Violation_Type,
    Violation_Description,
    Violation_Points,
    Business_ID,
    Inspection_Serial_Num,
    Violation_Record_ID,
    Grade
)
SELECT
    Name,
    Program_Identifier,
    CASE
        WHEN Inspection_Date REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$'
            THEN STR_TO_DATE(Inspection_Date, '%m/%d/%Y')
        WHEN Inspection_Date REGEXP '^[a-zA-Z]{3,9}-[0-9]{1,2}-[0-9]{4}$'
            THEN STR_TO_DATE(Inspection_Date, '%b-%d-%Y')  -- Try %M-%d-%Y if full month name
        WHEN Inspection_Date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$'
            THEN STR_TO_DATE(Inspection_Date, '%d-%m-%Y')
        ELSE NULL
    END,
    Description,
    Address,
    City,
    Zip_Code,
    Phone,
    CAST(NULLIF(Longitude, '') AS DOUBLE),
    CAST(NULLIF(Latitude, '') AS DOUBLE),
    Inspection_Business_Name,
    Inspection_Type,
    CAST(NULLIF(Inspection_Score, '') AS SIGNED),
    Inspection_Result,
    CASE 
        WHEN Inspection_Closed_Business IN ('Y', 'Yes', 'TRUE', '1') THEN TRUE
        ELSE FALSE
    END,
    Violation_Type,
    Violation_Description,
    CAST(NULLIF(Violation_Points, '') AS SIGNED),
    Business_ID,
    Inspection_Serial_Num,
    Violation_Record_ID,
    CAST(NULLIF(Grade, '') AS SIGNED)
FROM Foodinspections;

select system_user();
-- select * from inspections_cleaned_data
-- limit 20;

-- select count(*) from inspections_cleaned_data;
-- select count(*) from Foodinspections;
-- RENAME TABLE inspections_cleaned_data TO food_inspections_cleaned;
-- select count(*) from food_inspections_cleaned;

-- select * from food_inspections_cleaned
-- limit 20;

-- describe food_inspections_cleaned;

-- select count(*) from food_inspections_cleaned;

--- 1. Number of rows in the table.
select count(*) from food_inspections_cleaned;

--- 2.Number of unique rows in the table.
select count(*) as unique_records from (select distinct * from food_inspections_cleaned) as unique_rows;

-- 3. Number of records with Inspection date in 2025
select * from food_inspections_cleaned
limit 20;

select count(*) from food_inspections_cleaned
where year (Inspection_date) = 2025;

select count(*) from food_inspections_cleaned
where year (inspection_date) = 2024;

select year(inspection_date) as year_wise, count(*) as records_count from food_inspections_cleaned
where year (inspection_date) = 2024 or year(inspection_date) = 2025
group by year(inspection_date);

-- 4. Number of records per each City 
select * from food_inspections_cleaned
limit 100;

select city, count(*) as records_count from food_inspections_cleaned
group by city;

--- 5. Number of businesses that have an Inspection Result of Unsatisfactory in each year.

select * from food_inspections_cleaned
limit 100;

select count(inspection_result) as number_of_business, year(inspection_date) as year_wise from food_inspections_cleaned
where lower(inspection_result) = 'unsatisfactory'
group by year(inspection_date);

--- Average inspection score per city
select * from food_inspections_cleaned
limit 20;

select lower(city) ,avg(inspection_score) as avg_score from food_inspections_cleaned
group by city
order by city;

--- Highest inspection score and business name
select max(inspection_score) as highest_score, inspection_business_name
from food_inspections_cleaned 
group by inspection_business_name
order by highest_score desc
limit 1;

--- Count of inspections that resulted in failure

select * from food_inspections_cleaned
limit 20;

select count(Inspection_Result) as result_fail from food_inspections_cleaned
where Inspection_Result = 'completed'
group by Inspection_Result;


explain select * from food_inspections_cleaned where year (inspection_date) = 2024;

SELECT 
  REGEXP_REPLACE(Name, '[+#()\\-]', '') AS Cleaned_Name
FROM food_inspections_cleaned;

select * from food_inspections_cleaned;
-- 1.  Remove any special characters such as +, #, (, ),  from all Values. 
SET SQL_SAFE_UPDATES = 0;
UPDATE food_inspections_cleaned
SET
  Name = REGEXP_REPLACE(Name, '[+#()\\-]', ''),
  Program_Identifier = REGEXP_REPLACE(Program_Identifier, '[+#()\\-]', ''),
  City = REGEXP_REPLACE(City, '[+#()\\-]', ''),
  Zip_Code = REGEXP_REPLACE(Zip_Code, '[+#()\\-]', ''),
  Phone = REGEXP_REPLACE(Phone, '[^0-9]', ''),
  Inspection_Business_Name = REGEXP_REPLACE(Inspection_Business_Name, '[+#()\\-]', ''),
  Inspection_Type = REGEXP_REPLACE(Inspection_Type, '[+#()\\-]', ''),
  Inspection_Result = REGEXP_REPLACE(Inspection_Result, '[+#()\\-]', ''),
  Violation_Type = REGEXP_REPLACE(Violation_Type, '[+#()\\-]', ''),
  Violation_Description = REGEXP_REPLACE(Violation_Description, '[+#()\\-]', ''),
  Business_ID = REGEXP_REPLACE(Business_ID, '[+#()\\-]', ''),
  Inspection_Serial_Num = REGEXP_REPLACE(Inspection_Serial_Num, '[+#()\\-]', ''),
  Violation_Record_ID = REGEXP_REPLACE(Violation_Record_ID, '[+#()\\-]', '');

select count(*) from food_inspections_cleaned;
select * from food_inspections_cleaned
limit 100;

-- Split the value of column Inspection_Type into multiple parts using the separator /.
ALTER TABLE food_inspections_cleaned
ADD COLUMN Inspection_Type_Main VARCHAR(200),
ADD COLUMN Inspection_Type_Sub VARCHAR(200);

-- Step 2: Populate the new columns by splitting using '/'
UPDATE food_inspections_cleaned
SET 
    Inspection_Type_Main = TRIM(SUBSTRING_INDEX(Inspection_Type, '/', 1)),
    Inspection_Type_Sub = TRIM(SUBSTRING_INDEX(Inspection_Type, '/', -1));
    
    select * from food_inspections_cleaned
limit 100;

SELECT 
  CONCAT_WS(', ', Address, City, Zip_Code, Longitude, Latitude) AS Full_Address
FROM food_inspections_cleaned;

   select * from food_inspections_cleaned
limit 100;

-- Step 1: Add a new column to store the full address
ALTER TABLE food_inspections_cleaned
ADD COLUMN Full_Address VARCHAR(500);

-- Step 2: Populate the Full_Address column using CONCAT_WS
UPDATE food_inspections_cleaned
SET Full_Address = CONCAT_WS(', ', Address, City, Zip_Code, Longitude, Latitude);

select count(*) from food_inspections_cleaned;
select * from food_inspections_cleaned
limit 100;

SELECT CURRENT_USER;
SELECT VERSION();

create view Inspections_V1 as
select 
Inspection_Business_Name,
Inspection_Type,
Inspection_Score,
Inspection_Date,
Inspection_Result,
Inspection_Closed_Business,
Inspection_Serial_Num,
row_number() over() as RN
from food_inspections_cleaned;
select * from food_inspections_cleaned;

create view Violations as
select 
Violation_Type,
Violation_Description,
Violation_Points,
Violation_Record_ID,
row_number() over() as VRN
from food_inspections_cleaned;
select * from Violations;

create view Persons_details as
select 
Name,
Phone,
Business_ID,
Full_Address
from food_inspections_cleaned;
select * from Inspections_V1 limit 20;
select * from Violations limit 20;
select * from Persons_details limit 20;


SELECT *
FROM Inspections_V1 i
JOIN Violations v ON i.RN = v.VRN
JOIN Persons_details p ON i.RN = p.PRN
limit 20;

create view Inspections_Vw1 as
select 
Inspection_Business_Name,
Inspection_Type,
Inspection_Score,
Inspection_Date,
Inspection_Result,
Inspection_Closed_Business,
Inspection_Serial_Num
from Foodinspections;

create view Violations_vw1 as
select 
Inspection_Business_Name,
Violation_Type,
Violation_Description,
Violation_Points,
Violation_Record_ID
from Foodinspections;

create view person_details_vw as
select 
Name,
Phone,
Inspection_Business_Name,
Business_ID,
Address, 
City,
Zip_Code 
from Foodinspections;

select * from Inspections_Vw1 limit 20;
select * from Violations_vw1 limit 20;
select * from person_details_vw limit 20;

select i.inspection_score, i.inspection_type, v.violation_type,v.violation_points,
p.name,p.phone from inspections_vw1 i  
join violations_vw1 v 
on i.inspection_business_name = V.inspection_business_name
join person_details_vw p 
on v.inspection_business_name = p.inspection_business_name 
limit 20;
CREATE FUNCTION ExtractSeatingAndRisk(description TEXT)
RETURNS VARCHAR(100)
DETERMINISTIC
BEGIN
    DECLARE seating_range VARCHAR(50);
    DECLARE risk_category VARCHAR(50);
    DECLARE combined_output VARCHAR(100);

    -- Extract seating range: between 'Seating ' and ' -'
    SET seating_range = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(description, ' -', 1), 'Seating ', -1));

    -- Extract risk category: everything after 'Risk Category'
    SET risk_category = TRIM(SUBSTRING_INDEX(description, 'Risk Category', -1));

    -- Combine
    SET combined_output = CONCAT('Seating: ', seating_range, ' | Risk: ', risk_category);

    RETURN combined_output;
END //

DELIMITER ;

SELECT Description,
ExtractSeatingAndRisk(Description) AS Parsed_Info FROM food_inspections_cleaned;