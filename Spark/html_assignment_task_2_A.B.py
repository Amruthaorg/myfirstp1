from pyspark.sql import SparkSession
from bs4 import BeautifulSoup
import re
import json


def extract_js_object(html_content):

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

    soup = BeautifulSoup(html_content, 'html.parser')
    title_tag = soup.find('title')
    return title_tag.text.strip() if title_tag else "No Title Found"


def process_html_file(file_name):

    spark = SparkSession.builder.appName("HTML Processor").getOrCreate()

    rdd = spark.sparkContext.textFile(file_name)
    html_content = "\n".join(rdd.collect())

    title = extract_title(html_content)

    track_data = extract_js_object(html_content)

    if track_data:
        keys = ["title"] + list(track_data.keys())
        values = [title] + list(track_data.values())

        header = ",".join(keys)
        data_row = ",".join(map(str, values))
        return [header, data_row]
    else:
        print("No JavaScript object found.")
        return None

if __name__ == "__main__":

    file_name = "/Ammu1/datafiles/pagesource/Visit_1.txt"
    output_path = "/Ammu1/datafiles/output_files/output1"

    result = process_html_file(file_name)

    if result:
        spark = SparkSession.builder.appName("HTML Processor").getOrCreate()

        spark.sparkContext.parallelize(result).coalesce(1).saveAsTextFile(output_path)
        print(f"Output saved to {output_path}")
    else:
        print("No data to save.")
