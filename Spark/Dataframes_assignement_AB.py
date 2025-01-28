from pyspark.sql import SparkSession
from pyspark.sql.functions import trim, col, to_date, to_timestamp, hour, count, unix_timestamp, min, max
import sys

# Initialize SparkSession
spark = SparkSession.builder \
    .appName("Dynamic Input and Output for Web Visits") \
    .getOrCreate()

# Parse command-line arguments
if len(sys.argv) != 3:
    print("Usage: spark-submit script_name.py <input_path> <output_path>")
    sys.exit(1)

hdfs_input_path = sys.argv[1]
hdfs_output_path = sys.argv[2]

# Read the text file into a DataFrame, using the first line as the header
df = spark.read.csv(hdfs_input_path, header=True, inferSchema=True)

# Remove leading and trailing spaces from all string columns
trimmed_df = df.select(
    *[trim(col(c)).alias(c) if df.schema[c].dataType.simpleString() == 'string' else col(c) for c in df.columns]
)

# Convert the timestamp column to a proper timestamp and add Sys_date if the column exists
if 'timestamp' in trimmed_df.columns:
    df_transformed = trimmed_df.withColumn(
        'timestamp',
        to_timestamp(col('timestamp'))
    ).withColumn(
        'Sys_date',
        to_date(col('timestamp'))
    )
else:
    df_transformed = trimmed_df  # No timestamp column to process

# Show the first 10 rows of the transformed DataFrame
df_transformed.show(10, truncate=False)

# Print the schema to verify changes
df_transformed.printSchema()

# Print the row count of the transformed DataFrame
print(f"Transformed DataFrame row count: {df_transformed.count()}")

# Write the DataFrame to the specified HDFS path in Parquet format
df_transformed.write.mode("overwrite").parquet(hdfs_output_path)

print(f"Transformed data has been written to {hdfs_output_path} in Parquet format.")

# Load data from the Parquet file into a new DataFrame
new_df = spark.read.parquet(hdfs_output_path)

# a: Find out the total number of visits per each title
visits_per_title = new_df.groupBy("title").agg(count("*").alias("total_visits"))
visits_per_title_filtered = visits_per_title.filter((col("title") != "title") | (col("total_visits") != 1))
print("Total number of visits per each title (filtered):")
visits_per_title_filtered.show(truncate=False)

# b: Find out the hour of the day with the most visits overall
if 'timestamp' in new_df.columns:
    hourly_visits = new_df.withColumn("hour", hour("timestamp")) \
        .groupBy("hour").agg(count("*").alias("total_visits")) \
        .orderBy(col("total_visits").desc()) \
        .limit(1)

    print("Hour of the day with the most visits:")
    hourly_visits.show(truncate=False)
else:
    print("The 'timestamp' column does not exist in the data.")

# c: Find out the user with the most visits overall
if 'name' in new_df.columns:
    user_visits = new_df.groupBy("name").agg(count("*").alias("total_visits")) \
        .orderBy(col("total_visits").desc()) \
        .limit(1)

    print("User with the most visits:")
    user_visits.show(truncate=False)
else:
    print("The 'name' column does not exist in the data.")

# d: Find out the user with the most visits for a specific title
if 'title' in new_df.columns and 'name' in new_df.columns:
    remote_support_visits = new_df.filter(col("title") == "Remote Support: Geek Squad - Best Buy") \
        .groupBy("name").agg(count("*").alias("total_visits")) \
        .orderBy(col("total_visits").desc()) \
        .limit(1)

    print("User with the most visits for 'Remote Support: Geek Squad - Best Buy':")
    remote_support_visits.show(truncate=False)
else:
    print("Required columns ('title' and/or 'name') do not exist in the data.")

# e: Find out the number of users who have visited both specific titles
if 'title' in new_df.columns and 'name' in new_df.columns:
    best_buy_visits = new_df.filter(col("title") == "Best Buy Support & Customer Service").select("name").distinct()
    remote_support_visits = new_df.filter(col("title") == "Remote Support: Geek Squad - Best Buy").select("name").distinct()
    common_users = best_buy_visits.intersect(remote_support_visits)
    print(f"Number of users who visited both 'Best Buy Support & Customer Service' and 'Remote Support: Geek Squad - Best Buy': {common_users.count()}")

  # f: Find out the number of users who have visited both specific titles
    schedule_service_visits = new_df.filter(col("title") == "Schedule a Service - Best Buy").select("name").distinct()
    common_users_schedule = best_buy_visits.intersect(schedule_service_visits)
    print(f"Number of users who visited both 'Best Buy Support & Customer Service' and 'Schedule a Service - Best Buy': {common_users_schedule.count()}")
else:
    print("Required columns ('title' and/or 'name') do not exist in the data.")

# g: Find the user with the longest time interval between visits
if 'timestamp' in new_df.columns and 'name' in new_df.columns:
    user_time_range = new_df.groupBy("name").agg(
        min("timestamp").alias("min_time"),
        max("timestamp").alias("max_time")
    ).withColumn(
        "time_interval",
        unix_timestamp(col("max_time")) - unix_timestamp(col("min_time"))
    )
    longest_time_interval_user = user_time_range.orderBy(col("time_interval").desc()).first()
    print(f"User with the longest time interval: {longest_time_interval_user['name']}")

# h: Find the user with the shortest time interval between visits
if 'timestamp' in new_df.columns and 'name' in new_df.columns:
    shortest_time_interval_user = user_time_range.filter(col("time_interval") > 0) \
        .orderBy(col("time_interval").asc()) \
        .first()
    print(f"User with the shortest time interval: {shortest_time_interval_user['name']}")

# Stop the Spark session
spark.stop()
