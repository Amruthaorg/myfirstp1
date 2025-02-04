import sys
from pyspark.sql import SparkSession
from pyspark.sql.functions import unix_timestamp

# Check if correct number of arguments are provided
if len(sys.argv) != 4:
    print("Usage: spark-submit script.py <members_file_path> <sales_file_path> <visits_file_path>")
    sys.exit(1)

# Fetch file paths from command-line arguments
file_path_members = sys.argv[1]
file_path_sales = sys.argv[2]
file_path_visits = sys.argv[3]

# Initialize Spark session
spark = SparkSession.builder.appName("Dynamic File Paths").getOrCreate()

# Read CSV files into DataFrames (assuming they have headers)
df_members = spark.read.csv(file_path_members, header=True, inferSchema=True)
df_sales = spark.read.csv(file_path_sales, header=True, inferSchema=True)
df_visits = spark.read.csv(file_path_visits, header=True, inferSchema=True)

# Create temporary views (tables) for SQL queries
df_members.createOrReplaceTempView("members")
df_sales.createOrReplaceTempView("sales")
df_visits.createOrReplaceTempView("visits")

# Show the first few rows of each DataFrame
df_members.show()
df_sales.show()
df_visits.show()

# List all available temporary views (tables) in the current Spark session
print("Listing all available temporary views:")
spark.sql("SHOW TABLES").show()

# Running SQL Query
query = """
WITH MEMBERS AS (
    SELECT name, state, membership_status, timestamp FROM members
),
MBR_2 AS (
    SELECT *, row_number() over (partition by name order by timestamp DESC) as rn FROM MEMBERS 
),
MBR_3 AS (
    SELECT name, state, membership_status, timestamp FROM MBR_2 WHERE rn = 1 AND UPPER(TRIM(membership_status)) = 'ACTIVE'
),
sales AS (
    SELECT *, row_number() over (partition by mem_name order by pur_timestamp DESC) as rn FROM sales 
),
sales2 AS (
    SELECT saleId, product, mem_name, price, pur_timestamp FROM sales WHERE rn = 1
),
mbr_sales AS (
    SELECT m.name, m.state, m.membership_status, m.timestamp, s.saleId, s.product, s.mem_name, s.price, s.pur_timestamp
    FROM MBR_3 m
    JOIN sales2 s ON UPPER(TRIM(m.name)) = UPPER(TRIM(s.mem_name))
),
visits AS (
    SELECT *, row_number() over (partition by name order by timestamp DESC) as rn FROM visits
),
visits2 AS (
    SELECT title, visitId, name, persistentCart, timestamp AS wv_timestamp FROM visits WHERE rn = 1
),
mbr_sales_visits AS (
    SELECT ms.*, v.title, v.visitId, v.persistentCart, v.wv_timestamp, 
           unix_timestamp(ms.pur_timestamp) - unix_timestamp(v.wv_timestamp) AS time_diff_seconds,
           CASE 
               WHEN (unix_timestamp(ms.pur_timestamp) - unix_timestamp(v.wv_timestamp)) < 300 THEN 1 
               WHEN (unix_timestamp(ms.pur_timestamp) - unix_timestamp(v.wv_timestamp)) BETWEEN 300 AND 1800 THEN 2
               WHEN (unix_timestamp(ms.pur_timestamp) - unix_timestamp(v.wv_timestamp)) BETWEEN 1800 AND 3600 THEN 3
               WHEN (unix_timestamp(ms.pur_timestamp) - unix_timestamp(v.wv_timestamp)) BETWEEN 3600 AND 14400 THEN 4
               WHEN (unix_timestamp(ms.pur_timestamp) - unix_timestamp(v.wv_timestamp)) BETWEEN 14400 AND 28800 THEN 5
               ELSE 6 
           END AS time_diff_category
    FROM mbr_sales ms
    LEFT JOIN visits2 v ON UPPER(TRIM(ms.name)) = UPPER(TRIM(v.name))
)
SELECT * FROM mbr_sales_visits
"""

# Execute the query and show the result
result = spark.sql(query)
result.show()
