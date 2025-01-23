from pyspark.sql import SparkSession
from bs4 import BeautifulSoup
import re
import json
import sys
import os


def extract_js_object(html_content):
    """
    Extract JavaScript object embedded in the HTML content.
    """
    pattern = r'var trackData = ({.*?});'
    match = re.search(pattern, html_content, re.DOTALL)
    if match:
        js_object = match.group(1)

        # Convert to valid JSON format
        js_object = re.sub(r'(\b[a-zA-Z_][a-zA-Z0-9_]*\b)(?=\s*:)', r'"\1"', js_object)
        js_object = js_object.replace('false', 'false').replace('true', 'true').replace('null', 'null')

        try:
            return json.loads(js_object)
        except json.JSONDecodeError as e:
            print(f"Error decoding JSON: {e}")
            return None
    return None


def extract_title(html_content):
    """
    Extract the title from HTML content using BeautifulSoup.
    """
    soup = BeautifulSoup(html_content, 'html.parser')
    title_tag = soup.find('title')
    return title_tag.text.strip() if title_tag else "No Title Found"


def process_html_file(spark, file_path):
    """
    Process a single HTML file to extract the title and JavaScript object.
    """
    rdd = spark.sparkContext.textFile(file_path)
    html_content = "\n".join(rdd.collect())

    title = extract_title(html_content)
    track_data = extract_js_object(html_content)

    if track_data:
        keys = ["title"] + list(track_data.keys())
        values = [title] + list(track_data.values())

        return keys, values
    else:
        print(f"No JavaScript object found in file: {file_path}")
        return None, None


def process_directory(input_dir, output_dir):
    """
    Process all files in the input directory and save the results to the output directory.
    """
    spark = SparkSession.builder.appName("HTML Processor").getOrCreate()
    header = None
    rows = []

    for file_name in os.listdir(input_dir):
        file_path = os.path.join(input_dir, file_name)
        if os.path.isfile(file_path):
            keys, values = process_html_file(spark, file_path)
            if keys and values:
                if not header:
                    header = ",".join(keys)
                rows.append(",".join(map(str, values)))

    if rows:
        # Combine header and rows
        final_output = [header] + rows

        # Save to output directory
        spark.sparkContext.parallelize(final_output).coalesce(1).saveAsTextFile(output_dir)
        print(f"Output saved to {output_dir}")
    else:
        print("No data to save.")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: spark-submit app.py <input_directory> <output_directory>")
        sys.exit(1)

    input_dir = sys.argv[1]
    output_dir = sys.argv[2]

    process_directory(input_dir, output_dir)

