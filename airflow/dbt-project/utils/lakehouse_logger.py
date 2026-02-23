from __future__ import annotations

import json
import logging
import uuid
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional


logger = logging.getLogger(__name__)


class LakehouseLogger:
    @staticmethod
    def log_from_artifacts(
        target_dir: str,
        job_log_table: str,
        sql_log_table: str,
        source_system: str,
        source_table: str,
        iceberg_table: Optional[str],
        start_time: datetime,
        end_time: datetime,
        success: bool,
        logs_dir: Optional[str] = None,
    ) -> None:
        try:
            from pyspark.sql.types import (
                DoubleType,
                LongType,
                StringType,
                StructField,
                StructType,
                TimestampType,
            )
        except ImportError:
            logger.warning("PySpark not available, skipping LakeHouse logging")
            return

        target_path = Path(target_dir)
        run_results = LakehouseLogger._read_json(target_path / "run_results.json") or {}
        manifest = LakehouseLogger._read_json(target_path / "manifest.json")

        invocation_id = (
            (run_results.get("metadata") or {}).get("invocation_id")
            or str(uuid.uuid4())
        )
        logger.info("dbt invocation id: %s", invocation_id)

        rows_processed: Optional[int] = None
        if run_results:
            row_values = [
                entry
                for entry in (
                    (res.get("adapter_response") or {}).get("rows_affected")
                    for res in run_results.get("results", [])
                )
                if isinstance(entry, (int, float)) and entry >= 0
            ]
            if row_values:
                rows_processed = int(sum(row_values))

        job_status = "SUCCESS" if success else "FAILED"
        error_message = None
        cli_summary = None
        if logs_dir:
            try:
                cli_summary = LakehouseLogger._summarize_cli_log(
                    Path(logs_dir) / "dbt.log"
                )
            except Exception:
                cli_summary = None

        if not success:
            error_lines: List[str] = []
            if cli_summary and cli_summary.get("errors"):
                error_lines = cli_summary["errors"]
            elif run_results:
                error_lines = [
                    msg
                    for msg in (
                        res.get("message")
                        for res in run_results.get("results", [])
                    )
                    if msg
                ]
            if error_lines:
                error_message = "\n".join(error_lines[-10:])[:1000]

        sql_entries = LakehouseLogger._gather_sql_entries(run_results, manifest)
        job_source_table_value = source_table
        job_iceberg_table_value = iceberg_table
        try:
            dest_tables = [
                e.get("relation_name") for e in sql_entries if e.get("relation_name")
            ]
            dest_tables = list(dict.fromkeys(dest_tables))
            if len(dest_tables) == 1:
                job_source_table_value = dest_tables[0]
                job_iceberg_table_value = dest_tables[0]
            elif len(dest_tables) > 1:
                job_source_table_value = None
                job_iceberg_table_value = None
        except Exception:
            pass

        spark = LakehouseLogger._get_spark_session()
        if spark is None:
            logger.error("Unable to acquire SparkSession; skipping LakeHouse logging")
            return
        spark.sparkContext.setLogLevel("WARN")

        try:
            job_table_parts = [p for p in job_log_table.split(".") if p]
            sql_table_parts = [p for p in sql_log_table.split(".") if p]

            qualified_job = ".".join(f"`{p}`" for p in job_table_parts)
            qualified_sql = ".".join(f"`{p}`" for p in sql_table_parts)

            spark.sql(
                f"""
                CREATE TABLE IF NOT EXISTS {qualified_job} (
                  job_id STRING NOT NULL,
                  source_system STRING,
                  source_table STRING,
                  iceberg_table STRING,
                  status STRING,
                  rows_processed BIGINT,
                  max_scn BIGINT,
                  start_time TIMESTAMP,
                  end_time TIMESTAMP,
                  error_message STRING
                ) USING iceberg
                TBLPROPERTIES ('format-version'='2')
                """
            )

            spark.sql(
                f"""
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
                """
            )

            job_schema = StructType(
                [
                    StructField("job_id", StringType(), False),
                    StructField("source_system", StringType(), True),
                    StructField("source_table", StringType(), True),
                    StructField("iceberg_table", StringType(), True),
                    StructField("status", StringType(), True),
                    StructField("rows_processed", LongType(), True),
                    StructField("max_scn", LongType(), True),
                    StructField("start_time", TimestampType(), True),
                    StructField("end_time", TimestampType(), True),
                    StructField("error_message", StringType(), True),
                ]
            )

            job_row = [
                (
                    invocation_id,
                    source_system,
                    job_source_table_value,
                    job_iceberg_table_value,
                    job_status,
                    rows_processed,
                    None,
                    start_time.replace(tzinfo=None),
                    end_time.replace(tzinfo=None),
                    error_message,
                )
            ]

            job_df = spark.createDataFrame(job_row, schema=job_schema)
            job_df.write.format("iceberg").mode("append").saveAsTable(
                ".".join(job_table_parts)
            )
            logger.info(
                "✅ Logged job metadata to %s for invocation %s",
                job_log_table,
                invocation_id,
            )

            if sql_entries:
                sql_schema = StructType(
                    [
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
                    ]
                )

                sql_rows = [
                    (
                        invocation_id,
                        entry["unique_id"],
                        entry["model_name"],
                        entry["resource_type"],
                        entry["status"],
                        entry["started_at"].replace(tzinfo=None)
                        if entry["started_at"]
                        else None,
                        entry["completed_at"].replace(tzinfo=None)
                        if entry["completed_at"]
                        else None,
                        entry["execution_time"],
                        int(entry["rows_affected"])
                        if isinstance(entry.get("rows_affected"), (int, float))
                        else None,
                        entry["relation_name"],
                        entry["sql_text"],
                    )
                    for entry in sql_entries
                ]

                sql_df = spark.createDataFrame(sql_rows, schema=sql_schema)
                sql_df.write.format("iceberg").mode("append").saveAsTable(
                    ".".join(sql_table_parts)
                )
                logger.info(
                    "✅ Logged %d SQL statements to %s for job %s",
                    len(sql_rows),
                    sql_log_table,
                    invocation_id,
                )
            else:
                logger.warning(
                    "⚠️  No SQL statements captured for job %s", invocation_id
                )

        except Exception as exc:
            logger.error("❌ Error logging to LakeHouse: %s", exc)
        finally:
            pass

    @staticmethod
    def _summarize_cli_log(log_path: Path) -> Dict[str, Any]:
        summary: Dict[str, Any] = {
            "pass": 0,
            "warn": 0,
            "error": 0,
            "skip": 0,
            "total": 0,
            "errors": [],
        }
        if not log_path.exists():
            return summary

        with log_path.open("r", encoding="utf-8") as handle:
            for raw_line in handle:
                line = LakehouseLogger._strip_ansi(raw_line.rstrip())
                match = LakehouseLogger._summary_re().search(line)
                if match:
                    summary.update(
                        {
                            "pass": int(match.group(1)),
                            "warn": int(match.group(2)),
                            "error": int(match.group(3)),
                            "skip": int(match.group(4)),
                            "total": int(match.group(5)),
                        }
                    )
                if LakehouseLogger._error_line_re().search(line):
                    summary["errors"].append(line)
        return summary

    @staticmethod
    def _gather_sql_entries(
        run_results: Dict[str, Any], manifest: Optional[Dict[str, Any]]
    ) -> List[Dict[str, Any]]:
        sql_entries: List[Dict[str, Any]] = []
        manifest_nodes = (manifest or {}).get("nodes", {})

        for result in run_results.get("results", []):
            unique_id = result.get("unique_id")
            if not unique_id:
                continue

            node = manifest_nodes.get(unique_id, {})
            resource_type = node.get("resource_type")

            if resource_type not in {"model", "seed", "snapshot"}:
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
                started_at = LakehouseLogger._parse_iso(timing[0]["started_at"])
                completed_at = LakehouseLogger._parse_iso(timing[-1]["completed_at"])

            sql_entries.append(
                {
                    "unique_id": unique_id,
                    "model_name": node.get("name"),
                    "resource_type": resource_type,
                    "status": result.get("status"),
                    "started_at": started_at,
                    "completed_at": completed_at,
                    "execution_time": result.get("execution_time"),
                    "rows_affected": (
                        result.get("adapter_response") or {}
                    ).get("rows_affected"),
                    "relation_name": result.get("relation_name")
                    or node.get("relation_name"),
                    "sql_text": compiled_code,
                }
            )
        return sql_entries

    @staticmethod
    def _read_json(path: Path) -> Optional[Dict[str, Any]]:
        if not path.exists():
            return None
        with path.open("r", encoding="utf-8") as handle:
            return json.load(handle)

    @staticmethod
    def _parse_iso(ts: str) -> datetime:
        if ts.endswith("Z"):
            ts = ts[:-1] + "+00:00"
        dt = datetime.fromisoformat(ts)
        if dt.tzinfo is None:
            return dt.replace(tzinfo=None)
        return dt

    @staticmethod
    def _strip_ansi(text: str) -> str:
        return LakehouseLogger._ansi_escape().sub("", text)

    @staticmethod
    def _ansi_escape():
        import re

        return re.compile(r"\x1B\[[0-?]*[ -/]*[@-~]")

    @staticmethod
    def _summary_re():
        import re

        return re.compile(
            r"Done\.\s+PASS=(\d+)\s+WARN=(\d+)\s+ERROR=(\d+)\s+SKIP=(\d+)\s+TOTAL=(\d+)",
            re.IGNORECASE,
        )

    @staticmethod
    def _error_line_re():
        import re

        return re.compile(r"(ERROR|FAIL|FATAL)", re.IGNORECASE)

    @staticmethod
    def _get_spark_session():
        try:
            spark = None
            try:
                from pyspark.sql import SparkSession

                active = SparkSession.getActiveSession()
            except Exception:
                active = None
            if active is not None:
                return active
            try:
                from pyspark import SparkContext

                sc = SparkContext._active_spark_context or SparkContext.getOrCreate()
                try:
                    from pyspark.sql import SQLContext

                    sqlctx = SQLContext.getOrCreate(sc)
                    return sqlctx.sparkSession
                except Exception:
                    from pyspark.sql import SparkSession as _SS

                    return _SS.builder.config(conf=sc.getConf()).getOrCreate()
            except Exception:
                pass
            return None
        except Exception as exc:
            logger.error("Failed to acquire SparkSession: %s", exc)
            return None
