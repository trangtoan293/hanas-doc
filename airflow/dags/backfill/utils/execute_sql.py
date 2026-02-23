"""
Execute SQL script with parameter substitution for Spark jobs.
"""

import argparse
from pyspark.sql import SparkSession


def main():
    parser = argparse.ArgumentParser(description="Execute SQL with Jinja2 parameters")
    parser.add_argument("--sql-file", required=True, help="Path to SQL file")
    parser.add_argument("--start-date", required=True, help="Start date for backdate")
    parser.add_argument("--end-date", required=True, help="End date for backdate")
    args = parser.parse_args()
    
    # Create Spark session
    spark = SparkSession.builder.appName("Backdate Table Creation").getOrCreate()
    
    # Read SQL file
    with open(args.sql_file, 'r') as f:
        sql_template = f.read()
    
    # Replace parameters (simple string replacement for SQL dates)
    sql = sql_template.replace("{{ params.start_date }}", args.start_date)
    sql = sql.replace("{{ params.end_date }}", args.end_date)
    
    print(f"Executing SQL:\n{sql}")
    
    # Execute SQL
    spark.sql(sql)
    
    print("SQL executed successfully")
    spark.stop()


if __name__ == "__main__":
    main()
