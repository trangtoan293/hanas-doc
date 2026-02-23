#!/usr/bin/env python3
import argparse
import json
import logging
import re
import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

ANSI_ESCAPE = re.compile(r"\x1B\[[0-?]*[ -/]*[@-~]")

def _parse_iso(ts: str) -> datetime:
    if ts.endswith("Z"):
        ts = ts[:-1] + "+00:00"
    dt = datetime.fromisoformat(ts)
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def _read_json_from_uri(spark, uri: str) -> Optional[Dict[str, Any]]:
    try:
        if uri.startswith("s3a://") or uri.startswith("hdfs://") or uri.startswith("file://"):
            df = spark.read.text(uri)
            text = "\n".join([r[0] for r in df.collect()])
            return json.loads(text) if text else None
        with open(uri, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:
        logger.error(f"Failed to read JSON from {uri}: {e}")
        return None


def _gather_sql_entries(run_results: Dict[str, Any], manifest: Optional[Dict[str, Any]]) -> List[Dict[str, Any]]:
    sql_entries: List[Dict[str, Any]] = []
    manifest_nodes = (manifest or {}).get("nodes", {})
    for result in run_results.get("results", []):
        uid = result.get("unique_id")
        if not uid:
            continue
        node = manifest_nodes.get(uid, {})
        rtype = node.get("resource_type")
        if rtype not in {"model", "seed", "snapshot"}:
            continue
        compiled_code = (
            result.get("compiled_code")
            or result.get("compiled_sql")
            or node.get("compiled_code")
            or node.get("compiled_sql")
        )
        timing = result.get("timing") or []
        started_at = completed_at = None
        if timing:
            started_at = _parse_iso(timing[0]["started_at"]) if timing[0].get("started_at") else None
            completed_at = _parse_iso(timing[-1]["completed_at"]) if timing[-1].get("completed_at") else None
        sql_entries.append(
            {
                "unique_id": uid,
                "model_name": node.get("name"),
                "resource_type": rtype,
                "status": result.get("status"),
                "started_at": started_at,
                "completed_at": completed_at,
                "execution_time": result.get("execution_time"),
                "rows_affected": (result.get("adapter_response") or {}).get("rows_affected"),
                "relation_name": result.get("relation_name") or node.get("relation_name"),
                "sql_text": compiled_code,
            }
        )
    return sql_entries


def _compute_job_times(sql_entries: List[Dict[str, Any]]) -> (Optional[datetime], Optional[datetime]):
    starts = [e["started_at"] for e in sql_entries if e.get("started_at")]
    ends = [e["completed_at"] for e in sql_entries if e.get("completed_at")]
    if not starts and not ends:
        return None, None
    start = min(starts) if starts else None
    end = max(ends) if ends else None
    return start, end


def main():
    p = argparse.ArgumentParser(description="Standalone LakeHouse logger for dbt artifacts")
    p.add_argument("--artifacts-bucket", required=False)
    p.add_argument("--artifacts-prefix", required=False)
    p.add_argument("--artifacts-uri", required=False)
    p.add_argument("--job-etl-table", required=True)
    p.add_argument("--sql-log-table", required=True)
    p.add_argument("--source-system", default="dbt")
    p.add_argument("--retention-days", type=int, default=7, help="Days to retain logs")
    p.add_argument("--derive-rows-from-tables", action="store_true")
    p.add_argument("--derive-sql-rows-from-tables", action="store_true")
    p.add_argument("--rows-catalog", default=None)
    args = p.parse_args()

    from pyspark.sql import SparkSession
    from pyspark.sql.types import (
        DoubleType,
        LongType,
        BooleanType,
        StringType,
        StructField,
        StructType,
        TimestampType,
    )

    spark = SparkSession.builder.getOrCreate()
    spark.sparkContext.setLogLevel("WARN")

    if args.artifacts_uri:
        base_uri = args.artifacts_uri.rstrip("/")
    else:
        if not args.artifacts_bucket or not args.artifacts_prefix:
            logger.error("Provide --artifacts-uri or both --artifacts-bucket and --artifacts-prefix")
            return
        base_uri = f"s3a://{args.artifacts_bucket}/{args.artifacts_prefix.strip('/')}"

    run_results = _read_json_from_uri(spark, f"{base_uri}/run_results.json") or {}
    manifest = _read_json_from_uri(spark, f"{base_uri}/manifest.json")

    invocation_id = ((run_results.get("metadata") or {}).get("invocation_id") or str(uuid.uuid4()))
    logger.info(f"dbt invocation id: {invocation_id}")

    sql_entries = _gather_sql_entries(run_results, manifest)
    dest_tables = [e.get("relation_name") for e in sql_entries if e.get("relation_name")]
    dest_tables = list(dict.fromkeys(dest_tables))

    table_counts: Dict[str, int] = {}

    rows_vals = [
        e.get("rows_affected")
        for e in sql_entries
        if isinstance(e.get("rows_affected"), (int, float)) and e.get("rows_affected") >= 0
    ]
    rows_processed = int(sum(rows_vals)) if rows_vals else None

    if dest_tables and (args.derive_rows_from_tables or args.derive_sql_rows_from_tables):
        for table_name in dest_tables:
            qualified = f"{args.rows_catalog}.{table_name}" if args.rows_catalog else table_name
            try:
                count_value = spark.table(qualified).count()
            except Exception as exc:
                logger.warning("Failed to count rows for table %s: %s", qualified, exc)
                continue
            table_counts[table_name] = int(count_value)

    if args.derive_rows_from_tables and rows_processed is None and table_counts:
        rows_processed = sum(table_counts.values())

    statuses = [e.get("status") for e in sql_entries if e.get("status")]
    if statuses:
        success = all(s.lower() in {"success", "ok", "passed"} for s in statuses)
    else:
        success = True
    job_status = "SUCCESS" if success else "FAILED"

    start_time, end_time = _compute_job_times(sql_entries)
    now = datetime.now(timezone.utc)
    start_time = (start_time or now).replace(tzinfo=None)
    end_time = (end_time or now).replace(tzinfo=None)

    project_name = None
    try:
        project_name = (manifest or {}).get("metadata", {}).get("project_name")
    except Exception:
        project_name = None
    target_name = None
    try:
        target_name = (run_results.get("args") or {}).get("target") or (run_results.get("metadata") or {}).get("target_name")
    except Exception:
        target_name = None
    dest_tables_str = ",".join(dest_tables) if dest_tables else None
    primary_dest = dest_tables[0] if dest_tables else None
    duration_seconds = (end_time - start_time).total_seconds() if (start_time and end_time) else None

    manifest_nodes = (manifest or {}).get("nodes", {})
    mats = []
    for e in sql_entries:
        node = manifest_nodes.get(e.get("unique_id"), {})
        cfg = (node.get("config") or {})
        m = cfg.get("materialized")
        if m:
            mats.append(m)
    unique_mats = sorted(set(mats))
    materialized = unique_mats[0] if len(unique_mats) == 1 else ("mixed" if unique_mats else None)

    args_map = (run_results.get("args") or {})
    fr = args_map.get("full_refresh")
    if fr is None:
        fr = (run_results.get("metadata") or {}).get("full_refresh")
    full_refresh = bool(fr) if fr is not None else False

    job_table_parts = [p for p in args.job_etl_table.split(".") if p]
    sql_table_parts = [p for p in args.sql_log_table.split(".") if p]

    qualified_job = ".".join(f"`{p}`" for p in job_table_parts)
    qualified_sql = ".".join(f"`{p}`" for p in sql_table_parts)

    spark.sql(f"""
        CREATE TABLE IF NOT EXISTS {qualified_job} (
          job_id STRING NOT NULL,
          source_system STRING,
          project STRING,
          target STRING,
          materialized STRING,
          full_refresh BOOLEAN,
          status STRING,
          start_time TIMESTAMP,
          end_time TIMESTAMP,
          duration_seconds DOUBLE,
          rows_processed BIGINT,
          primary_destination STRING,
          destination_tables STRING,
          error_message STRING,
          artifacts_uri STRING
        ) USING iceberg
        TBLPROPERTIES ('format-version'='2')
    """)

    spark.sql(f"""
        CREATE TABLE IF NOT EXISTS {qualified_sql} (
          job_id STRING NOT NULL,
          unique_id STRING,
          model_name STRING,
          resource_type STRING,
          status STRING,
          started_at TIMESTAMP,
          completed_at TIMESTAMP,
          execution_time DOUBLE,
          rows_affected BIGINT,
          relation_name STRING,
          sql_text STRING
        ) USING iceberg
        TBLPROPERTIES ('format-version'='2')
    """)


    job_schema = StructType([
        StructField("job_id", StringType(), False),
        StructField("source_system", StringType(), True),
        StructField("project", StringType(), True),
        StructField("target", StringType(), True),
        StructField("materialized", StringType(), True),
        StructField("full_refresh", BooleanType(), True),
        StructField("status", StringType(), True),
        StructField("start_time", TimestampType(), True),
        StructField("end_time", TimestampType(), True),
        StructField("duration_seconds", DoubleType(), True),
        StructField("rows_processed", LongType(), True),
        StructField("primary_destination", StringType(), True),
        StructField("destination_tables", StringType(), True),
        StructField("error_message", StringType(), True),
        StructField("artifacts_uri", StringType(), True),
    ])

    job_row = [(
        invocation_id,
        args.source_system,
        project_name,
        target_name,
        materialized,
        full_refresh,
        job_status,
        start_time,
        end_time,
        float(duration_seconds) if duration_seconds is not None else None,
        rows_processed,
        primary_dest,
        dest_tables_str,
        None,
        base_uri,
    )]

    job_df = spark.createDataFrame(job_row, schema=job_schema)
    job_df.createOrReplaceTempView("src_job")
    spark.sql(f"""
        MERGE INTO {qualified_job} AS tgt
        USING src_job AS src
        ON tgt.job_id = src.job_id
        WHEN MATCHED THEN UPDATE SET
          tgt.source_system = src.source_system,
          tgt.project = src.project,
          tgt.target = src.target,
          tgt.materialized = src.materialized,
          tgt.full_refresh = src.full_refresh,
          tgt.status = src.status,
          tgt.start_time = src.start_time,
          tgt.end_time = src.end_time,
          tgt.duration_seconds = src.duration_seconds,
          tgt.rows_processed = src.rows_processed,
          tgt.primary_destination = src.primary_destination,
          tgt.destination_tables = src.destination_tables,
          tgt.error_message = src.error_message,
          tgt.artifacts_uri = src.artifacts_uri
        WHEN NOT MATCHED THEN
          INSERT (job_id, source_system, project, target, materialized, full_refresh, status, start_time, end_time, duration_seconds, rows_processed, primary_destination, destination_tables, error_message, artifacts_uri)
          VALUES (src.job_id, src.source_system, src.project, src.target, src.materialized, src.full_refresh, src.status, src.start_time, src.end_time, src.duration_seconds, src.rows_processed, src.primary_destination, src.destination_tables, src.error_message, src.artifacts_uri)
    """)

    if sql_entries:
        sql_schema = StructType([
            StructField("job_id", StringType(), False),
            StructField("unique_id", StringType(), True),
            StructField("model_name", StringType(), True),
            StructField("resource_type", StringType(), True),
            StructField("status", StringType(), True),
            StructField("started_at", TimestampType(), True),
            StructField("completed_at", TimestampType(), True),
            StructField("execution_time", DoubleType(), True),
            StructField("rows_affected", LongType(), True),
            StructField("relation_name", StringType(), True),
            StructField("sql_text", StringType(), True),
        ])
        sql_rows = []
        for e in sql_entries:
            rows_affected_value = e.get("rows_affected")
            if not isinstance(rows_affected_value, (int, float)):
                rows_affected_value = None
            if rows_affected_value is None and args.derive_sql_rows_from_tables:
                rel_name = e.get("relation_name")
                if rel_name and rel_name in table_counts:
                    rows_affected_value = table_counts[rel_name]

            sql_rows.append(
                (
                    invocation_id,
                    e["unique_id"],
                    e["model_name"],
                    e["resource_type"],
                    e["status"],
                    e["started_at"].replace(tzinfo=None) if e.get("started_at") else None,
                    e["completed_at"].replace(tzinfo=None) if e.get("completed_at") else None,
                    e.get("execution_time"),
                    int(rows_affected_value) if isinstance(rows_affected_value, (int, float)) else None,
                    e.get("relation_name"),
                    e.get("sql_text"),
                )
            )
        sql_df = spark.createDataFrame(sql_rows, schema=sql_schema)
        sql_df.createOrReplaceTempView("src_sql")
        spark.sql(f"""
            MERGE INTO {qualified_sql} AS tgt
            USING src_sql AS src
            ON tgt.job_id = src.job_id AND tgt.unique_id = src.unique_id
            WHEN MATCHED THEN UPDATE SET
              tgt.model_name = src.model_name,
              tgt.resource_type = src.resource_type,
              tgt.status = src.status,
              tgt.started_at = src.started_at,
              tgt.completed_at = src.completed_at,
              tgt.execution_time = src.execution_time,
              tgt.rows_affected = src.rows_affected,
              tgt.relation_name = src.relation_name,
              tgt.sql_text = src.sql_text
            WHEN NOT MATCHED THEN
              INSERT (job_id, unique_id, model_name, resource_type, status, started_at, completed_at, execution_time, rows_affected, relation_name, sql_text)
              VALUES (src.job_id, src.unique_id, src.model_name, src.resource_type, src.status, src.started_at, src.completed_at, src.execution_time, src.rows_affected, src.relation_name, src.sql_text)
        """)

    logger.info(f"Logged dbt job {invocation_id} to {args.job_etl_table} and {args.sql_log_table}")

    # Clean up old logs
    if args.retention_days > 0:
        try:
            logger.info(f"Cleaning up logs older than {args.retention_days} days in {args.job_etl_table}")
            spark.sql(f"""
                DELETE FROM {qualified_job}
                WHERE start_time < date_sub(current_timestamp(), {args.retention_days})
            """)
            
            logger.info(f"Cleaning up logs older than {args.retention_days} days in {args.sql_log_table}")
            spark.sql(f"""
                DELETE FROM {qualified_sql}
                WHERE started_at < date_sub(current_timestamp(), {args.retention_days})
            """)
        except Exception as e:
            logger.error(f"Failed to clean up old logs: {e}")

if __name__ == "__main__":
    main()
