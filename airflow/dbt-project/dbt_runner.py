#!/usr/bin/env python3
"""
dbt Runner for External Git Repository Integration
Wrapper script để run dbt từ external git repository với Spark environment
"""

import sys
import os
from pathlib import Path
import subprocess
import logging
import argparse
import json
import re
import uuid
import time
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Regex patterns for parsing dbt output
ANSI_ESCAPE = re.compile(r"\x1B\[[0-?]*[ -/]*[@-~]")
SUMMARY_RE = re.compile(
    r"Done\.\s+PASS=(\d+)\s+WARN=(\d+)\s+ERROR=(\d+)\s+SKIP=(\d+)\s+TOTAL=(\d+)",
    re.IGNORECASE,
)
ERROR_LINE_RE = re.compile(r"(ERROR|FAIL|FATAL)", re.IGNORECASE)

def install_dbt_dependencies(use_subprocess=False, dbt_command="dbt"):
    """Install dbt project dependencies if packages.yml exists
    
    Args:
        use_subprocess: If True, use subprocess to run dbt deps command
        dbt_command: Command to use (default: 'dbt', can be 'ktl_dbt')
    """
    
    packages_file = Path("packages.yml")
    if not packages_file.exists():
        logger.info("📦 No packages.yml found, skipping dependency installation")
        return True
    
    logger.info("📦 Found packages.yml, installing dbt dependencies...")
    
    try:
        if use_subprocess:
            # Run deps in a separate process to avoid importing adapters in-runner
            logger.info("🔄 Running dbt deps via subprocess")
            return run_dbt_subprocess(dbt_command, ['deps'])
        else:
            # Use dbtRunner (in-process)
            from dbt.cli.main import dbtRunner
            dbt = dbtRunner()

            logger.info("🔄 Running dbt deps (in-process)")
            result = dbt.invoke(['deps'])

            if result.success:
                logger.info("✅ dbt dependencies installed successfully")
                return True
            else:
                logger.error("❌ dbt deps command failed")
                if result.exception:
                    logger.error(f"Exception: {result.exception}")
                return False
            
    except Exception as e:
        logger.error(f"❌ Error installing dbt dependencies: {str(e)}")
        return False

def run_dbt_subprocess(dbt_command, dbt_args):
    """Run dbt command using subprocess
    
    Args:
        dbt_command: Command to use ('dbt' or 'ktl_dbt')
        dbt_args: List of arguments to pass to dbt command
    
    Returns:
        bool: True if command succeeded, False otherwise
    """
    try:
        cmd = [dbt_command] + dbt_args
        logger.info(f"🚀 Running command via subprocess: {' '.join(cmd)}")

        env = os.environ.copy()


        # Run command with real-time output
        process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
            universal_newlines=True,
            env=env,
        )
        
        # Print output in real-time
        for line in process.stdout:
            print(line, end='')
        
        # Wait for process to complete
        return_code = process.wait()
        
        if return_code == 0:
            logger.info("✅ dbt command completed successfully")
            return True
        else:
            logger.error(f"❌ dbt command failed with return code: {return_code}")
            return False
            
    except FileNotFoundError:
        logger.error(f"❌ Command not found: {dbt_command}")
        logger.error(f"Make sure {dbt_command} is installed and available in PATH")
        return False
    except Exception as e:
        logger.error(f"❌ Error running dbt command: {str(e)}")
        return False

def _strip_ansi(text: str) -> str:
    """Remove ANSI escape sequences from a log line."""
    return ANSI_ESCAPE.sub("", text)


def _parse_iso(ts: str) -> datetime:
    """Convert dbt ISO timestamp strings into timezone-aware datetimes."""
    if ts.endswith("Z"):
        ts = ts[:-1] + "+00:00"
    dt = datetime.fromisoformat(ts)
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def _read_json(path: Path) -> Optional[Dict[str, Any]]:
    """Safely load a JSON artifact if it exists on disk."""
    if not path.exists():
        return None
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def _summarize_cli_log(log_path: Path) -> Dict[str, Any]:
    """Aggregate pass/fail counts and capture error lines from dbt stdout/log file."""
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
            line = _strip_ansi(raw_line.rstrip())
            match = SUMMARY_RE.search(line)
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
            if ERROR_LINE_RE.search(line):
                summary["errors"].append(line)
    return summary


def _gather_sql_entries(
    run_results: Dict[str, Any], manifest: Optional[Dict[str, Any]]
) -> List[Dict[str, Any]]:
    """Build a list of model execution metadata and compiled SQL statements."""
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
            started_at = _parse_iso(timing[0]["started_at"])
            completed_at = _parse_iso(timing[-1]["completed_at"])

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
                    result.get("adapter_response", {}) or {}
                ).get("rows_affected"),
                "relation_name": result.get("relation_name") or node.get("relation_name"),
                "sql_text": compiled_code,
            }
        )
    return sql_entries


_GLOBAL_SPARK: Optional["SparkSession"] = None


def _ensure_global_spark_session() -> Optional["SparkSession"]:
    global _GLOBAL_SPARK
    if _GLOBAL_SPARK is not None:
        return _GLOBAL_SPARK
    try:
        from pyspark.sql import SparkSession
        # Attach to the existing session/context without creating a new SparkContext
        _GLOBAL_SPARK = SparkSession.builder.getOrCreate()
        return _GLOBAL_SPARK
    except Exception as exc:  # pragma: no cover
        logger.error(f"Failed to initialise SparkSession: {exc}")
        _GLOBAL_SPARK = None
        return None


def _get_spark_session() -> Optional["SparkSession"]:
    try:
        spark = _GLOBAL_SPARK
        if spark is not None:
            return spark
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
        return _ensure_global_spark_session()
    except Exception as exc:  # pragma: no cover
        logger.error(f"Failed to acquire SparkSession: {exc}")
        return None


def build_catalog_from_spark(manifest_path: str, output_path: str) -> int:
    try:
        manifest = _read_json(Path(manifest_path)) or {}
    except Exception as exc:
        logger.warning(f"Could not read manifest at {manifest_path}: {exc}")
        return 0

    nodes = manifest.get("nodes", {}) or {}
    if not nodes:
        logger.warning("Manifest contains no nodes; skipping Spark catalog fallback")
        return 0

    spark = _get_spark_session()
    if spark is None:
        logger.warning("SparkSession unavailable; skipping Spark catalog fallback")
        return 0

    def _q(parts: List[str]) -> str:
        return ".".join(f"`{p}`" for p in parts if p)

    out: Dict[str, Any] = {"nodes": {}, "sources": {}, "metadata": {}}
    added = 0
    for unique_id, node in nodes.items():
        rt = (node.get("resource_type") or "").lower()
        if rt not in {"model", "seed", "snapshot"}:
            continue
        db = (node.get("database") or "").strip()
        schema = (node.get("schema") or "").strip()
        name = (node.get("alias") or node.get("name") or "").strip()
        if not name or not schema:
            continue
        parts = [schema, name] if not db else [db, schema, name]
        ident = _q(parts)
        try:
            df = spark.sql(f"DESCRIBE TABLE {ident}")
        except Exception as exc:
            logger.warning(f"DESCRIBE failed for {ident}: {exc}")
            continue
        cols: Dict[str, Any] = {}
        try:
            rows = df.collect()
        except Exception as exc:
            logger.warning(f"Collect failed for {ident}: {exc}")
            continue
        for row in rows:
            try:
                col_name = row["col_name"]
                data_type = row["data_type"]
                comment = row.get("comment") if isinstance(row, dict) else None
            except Exception:
                col_name = row[0] if len(row) > 0 else None
                data_type = row[1] if len(row) > 1 else None
                comment = row[2] if len(row) > 2 else None
            if not col_name or str(col_name).startswith("#") or str(col_name).strip() == "":
                continue
            cols[str(col_name)] = {
                "name": str(col_name),
                "type": str(data_type) if data_type is not None else "",
                **({"description": str(comment)} if comment else {}),
                "index": len(cols) + 1,
            }
        if not cols:
            continue
        out["nodes"][unique_id] = {
            "metadata": {
                "database": db,
                "schema": schema,
                "name": name,
                "alias": name,
                "type": "table",
            },
            "database": db,
            "schema": schema,
            "name": name,
            "alias": name,
            "columns": cols,
        }
        added += 1

    if added > 0:
        try:
            p = Path(output_path)
            p.parent.mkdir(parents=True, exist_ok=True)
            with p.open("w", encoding="utf-8") as fh:
                json.dump(out, fh, ensure_ascii=False)
            logger.info(f"✅ Built fallback catalog.json with {added} nodes at {output_path}")
        except Exception as exc:
            logger.warning(f"Failed writing fallback catalog to {output_path}: {exc}")
            return 0
    else:
        logger.warning("Spark catalog fallback produced 0 nodes")
    return added

def build_catalog_from_manifest_sql(
    manifest_path: str, run_results_path: str, output_path: str
) -> int:
    from utils.dbt_catalog import DbtCatalogBuilder

    return DbtCatalogBuilder.build_from_manifest_sql(
        manifest_path=manifest_path,
        run_results_path=run_results_path,
        output_path=output_path,
    )

def log_to_lakehouse(
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
    from utils.lakehouse_logger import LakehouseLogger

    LakehouseLogger.log_from_artifacts(
        target_dir=target_dir,
        job_log_table=job_log_table,
        sql_log_table=sql_log_table,
        source_system=source_system,
        source_table=source_table,
        iceberg_table=iceberg_table,
        start_time=start_time,
        end_time=end_time,
        success=success,
        logs_dir=logs_dir,
    )


def main():
    """Main entry point for external dbt runner"""
    
    # Parse arguments
    parser = argparse.ArgumentParser(description='dbt Runner with subprocess support and optional Spark SQL execution')
    parser.add_argument('--use-subprocess', action='store_true', 
                        help='Use subprocess to run dbt command instead of dbtRunner')
    parser.add_argument('--dbt-command', default='dbt', 
                        help='dbt command to use (default: dbt, can use ktl_dbt)')
    # Optional: upload artifacts to S3 after successful run
    parser.add_argument('--upload-artifacts', action='store_true',
                        help='Upload dbt artifacts (manifest, run_results, catalog, dbt.log) to S3 after a successful run')
    parser.add_argument('--s3-bucket',
                        help='Target S3 bucket for artifacts (required when --upload-artifacts)')
    parser.add_argument('--s3-prefix', default='',
                        help='Optional S3 key prefix for uploaded artifacts, e.g. "dbt/artifacts/2025-10-10"')
    parser.add_argument('--artifacts-target-dir', default='target',
                        help='Relative target dir containing dbt artifacts (default: target)')
    parser.add_argument('--artifacts-logs-dir', default='logs',
                        help='Relative logs dir containing dbt.log (default: logs)')
    # MinIO/S3 options
    parser.add_argument('--s3-endpoint-url', default=None,
                        help='Custom S3/MinIO endpoint URL (e.g., http://minio:9000)')
    parser.add_argument('--s3-region', default=None,
                        help='AWS region name (default inferred or env AWS_DEFAULT_REGION)')
    parser.add_argument('--s3-access-key-id', default=None,
                        help='Explicit S3 access key ID (MinIO/AWS)')
    parser.add_argument('--s3-secret-access-key', default=None,
                        help='Explicit S3 secret access key (MinIO/AWS)')
    parser.add_argument('--s3-session-token', default=None,
                        help='Optional AWS session token')
    parser.add_argument('--s3-no-verify-ssl', action='store_true',
                        help='Disable SSL verification for S3/MinIO (useful for self-signed)')
    # LakeHouse logging options
    parser.add_argument('--log-to-lakehouse', action='store_true',
                        help='Log dbt execution metadata to LakeHouse.etladmin tables')
    parser.add_argument('--job-log-table', default='LakeHouse.etladmin.job_run_logs',
                        help='Fully-qualified table for job metadata (default: LakeHouse.etladmin.job_run_logs)')
    parser.add_argument('--sql-log-table', default='LakeHouse.etladmin.job_sql_logs',
                        help='Fully-qualified table for compiled SQL statements (default: LakeHouse.etladmin.job_sql_logs)')
    parser.add_argument('--source-system', default='dbt',
                        help='Value stored in job_run_logs.source_system (default: dbt)')
    parser.add_argument('--source-table', default='integration.raw_vault',
                        help='Value stored in job_run_logs.source_table (default: integration.raw_vault)')
    parser.add_argument('--iceberg-table', default=None,
                        help='Value stored in job_run_logs.iceberg_table (optional)')
    
    # Parse known args to separate our flags from dbt args
    args, remaining_args = parser.parse_known_args()
    
    # Set up paths
    dbt_project_dir = str(Path(__file__).resolve().parent)
    
    # Validate dbt project directory exists
    if not Path(dbt_project_dir).exists():
        logger.error(f"dbt project directory not found: {dbt_project_dir}")
        logger.error("Make sure git-sync init container has pulled the dbt project")
        sys.exit(1)
    
    # Change to dbt project directory
    os.chdir(dbt_project_dir)
    logger.info(f"Changed working directory to: {dbt_project_dir}")
    
    # Set environment variables
    os.environ['DBT_PROFILES_DIR'] = dbt_project_dir
    os.environ['DBT_PROJECT_DIR'] = dbt_project_dir
    
    # Import uploader only when needed and after switching into the project dir
    if 'args' in locals() and args.upload_artifacts:
        try:
            if dbt_project_dir not in sys.path:
                sys.path.insert(0, dbt_project_dir)
            from utils.dbt_artifacts_uploader import upload_dbt_artifacts
        except ModuleNotFoundError:
            logger.error("No module named 'utils.dbt_artifacts_uploader'. Ensure the project contains 'utils/' with __init__.py and the uploader module, and that we run from the project root.")
            sys.exit(1)

    # Create writable directories in temp space
    os.makedirs("/tmp/dbt_target", exist_ok=True)
    os.makedirs("/tmp/dbt_logs", exist_ok=True)
    logger.info("Created writable temp directories for dbt target and logs")
    if not os.environ.get('DBT_TARGET_PATH'):
        os.environ['DBT_TARGET_PATH'] = "/tmp/dbt_target"
    if not os.environ.get('DBT_LOG_PATH'):
        os.environ['DBT_LOG_PATH'] = "/tmp/dbt_logs"
    logger.info(f"Using DBT_TARGET_PATH={os.environ.get('DBT_TARGET_PATH')}, DBT_LOG_PATH={os.environ.get('DBT_LOG_PATH')}")

    # Compute initial effective artifact directories for uploader (can be overridden by CLI)
    effective_target_dir = args.artifacts_target_dir
    effective_logs_dir = args.artifacts_logs_dir
    if effective_target_dir == 'target' and os.environ.get('DBT_TARGET_PATH'):
        effective_target_dir = os.environ['DBT_TARGET_PATH']
    if effective_logs_dir == 'logs' and os.environ.get('DBT_LOG_PATH'):
        effective_logs_dir = os.environ['DBT_LOG_PATH']
    logger.info(f"Initial artifact dirs: target_dir={effective_target_dir}, logs_dir={effective_logs_dir}")
    
    # Build list of dbt command segments (support '--' separator)
    raw_args = []
    skip_next = False

    for arg in remaining_args:
        if skip_next:
            skip_next = False
            continue

        if arg in ['driver', '--properties-file', '--class']:
            skip_next = True
            continue
        if arg.startswith('org.apache.spark') or arg.startswith('local://'):
            continue

        raw_args.append(arg)

    command_segments = []
    current_segment = []

    for arg in raw_args:
        if arg == '--':
            if current_segment:
                command_segments.append(current_segment)
                current_segment = []
            continue
        current_segment.append(arg)

    if current_segment:
        command_segments.append(current_segment)

    if not command_segments:
        command_segments = [['run', '--target', 'dev']]

    # Normalise segments (remove redundant dbt command tokens)
    normalised_segments = []
    for segment in command_segments:
        seg = segment[:]
        if seg and seg[0] == args.dbt_command:
            seg = seg[1:]
        if not seg:
            continue
        normalised_segments.append(seg)

    if not normalised_segments:
        normalised_segments = [['run', '--target', 'dev']]

    multi_command = len(normalised_segments) > 1

    if multi_command and not args.use_subprocess:
        logger.error("Multiple dbt commands detected but --use-subprocess was not provided")
        sys.exit(1)

    logger.info(f"📋 Execution mode: {'subprocess' if args.use_subprocess else 'dbtRunner'}")
    logger.info(f"📋 Using command: {args.dbt_command}")

    # Detect explicit CLI overrides for paths and align env/effective dirs
    dbt_args_flat = []
    for seg in normalised_segments:
        dbt_args_flat.extend(seg)
    cli_target_path = None
    cli_log_path = None
    selected_target = "dev"
    i = 0
    while i < len(dbt_args_flat):
        tok = dbt_args_flat[i]
        if tok == '--target' and i + 1 < len(dbt_args_flat):
            selected_target = dbt_args_flat[i + 1]
            i += 2
            continue
        if tok == '--target-path' and i + 1 < len(dbt_args_flat):
            cli_target_path = dbt_args_flat[i + 1]
            i += 2
            continue
        if tok.startswith('--target-path='):
            cli_target_path = tok.split('=', 1)[1]
            i += 1
            continue
        if tok == '--log-path' and i + 1 < len(dbt_args_flat):
            cli_log_path = dbt_args_flat[i + 1]
            i += 2
            continue
        if tok.startswith('--log-path='):
            cli_log_path = tok.split('=', 1)[1]
            i += 1
            continue
        i += 1

    if cli_target_path:
        os.environ['DBT_TARGET_PATH'] = cli_target_path
        effective_target_dir = cli_target_path
        logger.info(f"Detected CLI --target-path, using {cli_target_path}")
    if cli_log_path:
        os.environ['DBT_LOG_PATH'] = cli_log_path
        effective_logs_dir = cli_log_path
        logger.info(f"Detected CLI --log-path, using {cli_log_path}")

    logger.info(f"Artifacts will be collected from target_dir={effective_target_dir}, logs_dir={effective_logs_dir}")

    def _resolve_dbt_artifacts_dir(project_dir: str, candidates: list[str]) -> str:
        for raw in candidates:
            p = Path(raw)
            resolved = p if p.is_absolute() else Path(project_dir) / p
            if not resolved.exists() or not resolved.is_dir():
                continue
            for name in ("manifest.json", "run_results.json", "catalog.json", "sources.json"):
                if (resolved / name).exists():
                    return str(resolved)
        return candidates[0]

    def _resolve_dbt_logs_dir(project_dir: str, candidates: list[str]) -> str:
        for raw in candidates:
            p = Path(raw)
            resolved = p if p.is_absolute() else Path(project_dir) / p
            if not resolved.exists() or not resolved.is_dir():
                continue
            if (resolved / "dbt.log").exists():
                return str(resolved)
        return candidates[0]

    # Don't create SparkSession before dbt runs - let dbt-spark create the first one
    # We'll create our session for logging after dbt completes
    
    try:
        # Validate dbt project files
        required_files = ['dbt_project.yml', 'profiles.yml']
        for file in required_files:
            if not Path(file).exists():
                logger.error(f"Required file not found: {file}")
                sys.exit(1)
        
        # Install dbt dependencies first
        if not install_dbt_dependencies(
            use_subprocess=args.use_subprocess, 
            dbt_command=args.dbt_command
        ):
            logger.error("Failed to install dbt dependencies")
            sys.exit(1)
        
        if args.use_subprocess:
            start_time = datetime.now(timezone.utc)
            all_success = True
            for idx, segment in enumerate(normalised_segments, start=1):
                logger.info(
                    "🚀 Running dbt command %d/%d: %s",
                    idx,
                    len(normalised_segments),
                    " ".join(segment),
                )
                success = run_dbt_subprocess(args.dbt_command, segment)
                if not success:
                    all_success = False
                    break
            end_time = datetime.now(timezone.utc)

            if all_success:
                try:
                    from utils.dbt_docs import DbtDocsGenerator

                    logger.info("📚 Generating dbt catalog.json via DbtDocsGenerator")
                    docs = DbtDocsGenerator(
                        dbt_command=args.dbt_command,
                        project_dir=dbt_project_dir,
                        target=selected_target,
                        target_dir=effective_target_dir,
                        profiles_dir=dbt_project_dir,
                    ).generate()
                    logger.info(
                        "Docs generation finished with return_code=%s, fallback_used=%s",
                        docs.get("return_code"),
                        docs.get("fallback_used"),
                    )
                except Exception as exc:
                    logger.warning("Docs generation failed: %s", exc)
            
            # Log to LakeHouse if enabled
            if args.log_to_lakehouse:
                logger.info("📊 Logging dbt execution to LakeHouse...")
                log_to_lakehouse(
                    target_dir=effective_target_dir,
                    job_log_table=args.job_log_table,
                    sql_log_table=args.sql_log_table,
                    source_system=args.source_system,
                    source_table=args.source_table,
                    iceberg_table=args.iceberg_table,
                    start_time=start_time,
                    end_time=end_time,
                    success=all_success,
                    logs_dir=effective_logs_dir,
                )
            
            # Upload artifacts BEFORE checking success - we want run_results.json 
            # in S3 even when tests fail so DataHub can read test results
            if args.upload_artifacts:
                if not args.s3_bucket:
                    logger.error("--s3-bucket is required when --upload-artifacts is set")
                    sys.exit(1)

                resolved_target_dir = _resolve_dbt_artifacts_dir(
                    dbt_project_dir,
                    [effective_target_dir, "target", "/tmp/dbt_target"],
                )
                resolved_logs_dir = _resolve_dbt_logs_dir(
                    dbt_project_dir,
                    [effective_logs_dir, "logs", "/tmp/dbt_logs"],
                )
                logger.info(
                    "Resolved artifact dirs for upload: target_dir=%s, logs_dir=%s",
                    resolved_target_dir,
                    resolved_logs_dir,
                )

                access_key = args.s3_access_key_id or os.environ.get('AWS_ACCESS_KEY_ID')
                secret_key = args.s3_secret_access_key or os.environ.get('AWS_SECRET_ACCESS_KEY')
                session_token = args.s3_session_token or os.environ.get('AWS_SESSION_TOKEN')
                endpoint_url = args.s3_endpoint_url or os.environ.get('AWS_ENDPOINT_URL')
                region = args.s3_region or os.environ.get('AWS_DEFAULT_REGION')

                uploaded = upload_dbt_artifacts(
                    bucket=args.s3_bucket,
                    prefix=args.s3_prefix or '',
                    project_dir=dbt_project_dir,
                    target_dir=resolved_target_dir,
                    logs_dir=resolved_logs_dir,
                    endpoint_url=endpoint_url,
                    region_name=region,
                    access_key=access_key,
                    secret_key=secret_key,
                    session_token=session_token,
                    verify_ssl=(not args.s3_no_verify_ssl),
                )
                if uploaded:
                    logger.info("✅ Uploaded dbt artifacts to S3")
                else:
                    logger.warning("⚠️ Failed to upload dbt artifacts to S3")
            
            # Now exit if tests failed
            if not all_success:
                logger.error("❌ dbt command failed - exiting with error code 1")
                sys.exit(1)
        else:
            # dbtRunner mode only supports a single command
            segment = normalised_segments[0]
            logger.info(f"🚀 Running dbt command: {' '.join(segment)}")

            from dbt.cli.main import dbtRunner, dbtRunnerResult
            dbt = dbtRunner()

            start_time = datetime.now(timezone.utc)
            res: dbtRunnerResult = dbt.invoke(segment)
            end_time = datetime.now(timezone.utc)
            
            for r in res.result:
                logger.info(f"{r.node.name}: {r.status}")
            
            # Log to LakeHouse if enabled
            if args.log_to_lakehouse:
                logger.info("📊 Logging dbt execution to LakeHouse...")
                log_to_lakehouse(
                    target_dir=effective_target_dir,
                    job_log_table=args.job_log_table,
                    sql_log_table=args.sql_log_table,
                    source_system=args.source_system,
                    source_table=args.source_table,
                    iceberg_table=args.iceberg_table,
                    start_time=start_time,
                    end_time=end_time,
                    success=res.success,
                    logs_dir=effective_logs_dir,
                )
            
            if res.success:
                logger.info("✅ dbt command completed successfully")
                try:
                    from utils.dbt_docs import DbtDocsGenerator

                    logger.info("📚 Generating dbt catalog.json via DbtDocsGenerator")
                    docs = DbtDocsGenerator(
                        dbt_command=args.dbt_command,
                        project_dir=dbt_project_dir,
                        target=selected_target,
                        target_dir=effective_target_dir,
                        profiles_dir=dbt_project_dir,
                    ).generate()
                    logger.info(
                        "Docs generation finished with return_code=%s, fallback_used=%s",
                        docs.get("return_code"),
                        docs.get("fallback_used"),
                    )
                except Exception as exc:
                    logger.warning("Docs generation failed: %s", exc)
                # After a successful run, optionally upload artifacts to S3
                if args.upload_artifacts:
                    if not args.s3_bucket:
                        logger.error("--s3-bucket is required when --upload-artifacts is set")
                        sys.exit(1)

                    resolved_target_dir = _resolve_dbt_artifacts_dir(
                        dbt_project_dir,
                        [effective_target_dir, "target", "/tmp/dbt_target"],
                    )
                    resolved_logs_dir = _resolve_dbt_logs_dir(
                        dbt_project_dir,
                        [effective_logs_dir, "logs", "/tmp/dbt_logs"],
                    )
                    logger.info(
                        "Resolved artifact dirs for upload: target_dir=%s, logs_dir=%s",
                        resolved_target_dir,
                        resolved_logs_dir,
                    )

                    access_key = args.s3_access_key_id or os.environ.get('AWS_ACCESS_KEY_ID')
                    secret_key = args.s3_secret_access_key or os.environ.get('AWS_SECRET_ACCESS_KEY')
                    session_token = args.s3_session_token or os.environ.get('AWS_SESSION_TOKEN')
                    endpoint_url = args.s3_endpoint_url or os.environ.get('AWS_ENDPOINT_URL')
                    region = args.s3_region or os.environ.get('AWS_DEFAULT_REGION')

                    uploaded = upload_dbt_artifacts(
                        bucket=args.s3_bucket,
                        prefix=args.s3_prefix or '',
                        project_dir=dbt_project_dir,
                        target_dir=resolved_target_dir,
                        logs_dir=resolved_logs_dir,
                        endpoint_url=endpoint_url,
                        region_name=region,
                        access_key=access_key,
                        secret_key=secret_key,
                        session_token=session_token,
                        verify_ssl=(not args.s3_no_verify_ssl),
                    )
                    if uploaded:
                        logger.info("✅ Uploaded dbt artifacts to S3")
                    else:
                        logger.error("❌ Failed to upload dbt artifacts to S3")
                        sys.exit(1)
            else:
                logger.error("❌ dbt command failed")
                if res.exception:
                    logger.error(f"Exception: {res.exception}")
                sys.exit(1)
            
    except Exception as e:
        logger.error(f"❌ Error running dbt: {str(e)}")
        sys.exit(1)
    finally:
        # Nothing to stop; let dbt-spark manage Spark lifecycle
        pass

if __name__ == "__main__":
    main()