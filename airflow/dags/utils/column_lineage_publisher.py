"""
Column-Level Lineage Publisher for DataHub.

Extracts column-level lineage from dbt compiled SQL and publishes to DataHub
with support for multiple platforms (iceberg and dbt).
"""

from __future__ import annotations

import json
import logging
import re
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

from urllib.parse import urlparse

# Import shared URN builder from datahub_publisher
try:
    from utils.datahub_publisher import build_dataset_urn
except ImportError:
    from datahub_publisher import build_dataset_urn

logger = logging.getLogger(__name__)


class ColumnLineagePublisher:
    """Publishes column-level lineage from dbt artifacts to DataHub."""

    def __init__(
        self,
        gms_host: str,
        token: Optional[str] = None,
        iceberg_platform_instance: str = "demo",
        dbt_platform_instance: str = "demo",
        env: str = "PROD",
        uppercase_columns: bool = True,
        emit_to_dbt_platform: bool = True,
    ):
        """
        Initialize the ColumnLineagePublisher.
        
        Args:
            gms_host: DataHub GMS server URL
            token: DataHub API token (optional)
            iceberg_platform_instance: Platform instance for Iceberg URNs (default: 'demo')
            dbt_platform_instance: Platform instance for dbt URNs (default: 'demo') 
            env: Environment (default: PROD)
            uppercase_columns: Whether to uppercase column names for field URNs
            emit_to_dbt_platform: If True, also emit lineage for dbt platform entities
        """
        self.gms_host = self._normalize_gms_host(gms_host)
        self.token = token
        self.iceberg_platform_instance = iceberg_platform_instance
        self.dbt_platform_instance = dbt_platform_instance
        self.env = env
        self.uppercase_columns = uppercase_columns
        self.emit_to_dbt_platform = emit_to_dbt_platform

    @staticmethod
    def _normalize_gms_host(gms_host: str) -> str:
        server = gms_host.rstrip("/")
        parsed = urlparse(server if "://" in server else f"http://{server}")
        if parsed.port == 9002 and (parsed.path == "" or parsed.path == "/"):
            server = f"{server}/api/gms"
        return server



    def _build_field_urn(self, dataset_urn: str, column: str) -> str:
        """Build a DataHub schema field URN."""
        if self.uppercase_columns:
            column = column.upper()
        return f"urn:li:schemaField:({dataset_urn},{column})"

    def _normalize_upstream_urn(self, urn: str) -> str:
        """
        Normalize upstream URN to ensure it has the correct iceberg_platform_instance prefix.
        
        The SQL parser sometimes generates URNs without the platform_instance,
        e.g., 'urn:li:dataset:(urn:li:dataPlatform:iceberg,mdm.table,PROD)'
        but we need 'urn:li:dataset:(urn:li:dataPlatform:iceberg,demo.mdm.table,PROD)'
        """
        pattern = r"urn:li:dataset:\(urn:li:dataPlatform:iceberg,([^,]+),([^)]+)\)"
        match = re.match(pattern, urn)
        if not match:
            return urn
        
        dataset_name = match.group(1)
        env = match.group(2)
        
        # If dataset_name already starts with iceberg_platform_instance, return as-is
        if dataset_name.startswith(f"{self.iceberg_platform_instance}."):
            return urn
        
        # Add iceberg_platform_instance prefix
        normalized_name = f"{self.iceberg_platform_instance}.{dataset_name}"
        return f"urn:li:dataset:(urn:li:dataPlatform:iceberg,{normalized_name},{env})"

    def _convert_iceberg_urn_to_dbt_urn(self, iceberg_urn: str) -> str:
        """
        Convert an iceberg URN to dbt URN by:
        1. Changing platform from 'iceberg' to 'dbt'
        2. Replacing iceberg_platform_instance prefix with dbt_platform_instance prefix
        
        Example:
        - Input: urn:li:dataset:(urn:li:dataPlatform:iceberg,demo_iceberg.integration.hub_gl,PROD)
        - Output: urn:li:dataset:(urn:li:dataPlatform:dbt,demo_dbt.integration.hub_gl,PROD)
        """
        pattern = r"urn:li:dataset:\(urn:li:dataPlatform:iceberg,([^,]+),([^)]+)\)"
        match = re.match(pattern, iceberg_urn)
        if not match:
            return iceberg_urn.replace("dataPlatform:iceberg,", "dataPlatform:dbt,")
        
        dataset_name = match.group(1)
        env = match.group(2)
        
        # Remove iceberg_platform_instance prefix and add dbt_platform_instance prefix
        iceberg_prefix = f"{self.iceberg_platform_instance}."
        if dataset_name.startswith(iceberg_prefix):
            dataset_name = dataset_name[len(iceberg_prefix):]
        
        # Add dbt_platform_instance prefix
        dbt_dataset_name = f"{self.dbt_platform_instance}.{dataset_name}"
        return f"urn:li:dataset:(urn:li:dataPlatform:dbt,{dbt_dataset_name},{env})"

    def _read_dbt_artifacts(
        self, manifest_path: str, run_results_path: str
    ) -> tuple[Dict[str, Any], Dict[str, str]]:
        """Read dbt manifest and run_results, return nodes and compiled SQL map."""
        manifest = {}
        run_results = {}

        manifest_file = Path(manifest_path)
        if manifest_file.exists():
            with manifest_file.open("r", encoding="utf-8") as f:
                manifest = json.load(f)

        run_results_file = Path(run_results_path)
        if run_results_file.exists():
            with run_results_file.open("r", encoding="utf-8") as f:
                run_results = json.load(f)

        nodes = manifest.get("nodes", {}) or {}

        compiled_sql_map: Dict[str, str] = {}
        run_node_ids = set()
        
        # Extract compiled SQL and node IDs from run_results
        for result in run_results.get("results", []):
            unique_id = result.get("unique_id")
            if not unique_id:
                continue
            run_node_ids.add(unique_id)
            sql = result.get("compiled_code") or result.get("compiled_sql")
            if sql:
                compiled_sql_map[unique_id] = sql

        # Filter nodes to only those that were actually run (in run_results)
        # This prevents overwriting lineage for unrelated models
        filtered_nodes = {
            unique_id: node 
            for unique_id, node in nodes.items() 
            if unique_id in run_node_ids and unique_id.startswith("model.")
        }

        return filtered_nodes, compiled_sql_map

    def _parse_sql_lineage(
        self,
        sql: str,
        default_db: Optional[str],
        default_schema: Optional[str],
    ) -> Optional[Any]:
        """Parse SQL to extract column-level lineage using DataHub's SQL parser."""
        try:
            from datahub.sql_parsing.sqlglot_lineage import (
                create_lineage_sql_parsed_result,
            )
        except ImportError as e:
            logger.error(
                "DataHub SQL parsing not available. "
                "Install with: uv pip install 'acryl-datahub[sql-parsing]': %s",
                e,
            )
            return None

        try:
            result = create_lineage_sql_parsed_result(
                query=sql,
                graph=None,
                platform="iceberg",
                platform_instance=self.iceberg_platform_instance,
                env=self.env,
                default_db=default_db,
                default_schema=default_schema,
                override_dialect="spark",
            )
            return result
        except Exception as e:
            logger.warning("SQL parsing failed for model: %s", e)
            return None

    def _extract_lineage_from_result(
        self,
        result: Any,
        downstream_urn: str,
        table_name: str,
    ) -> tuple[List[Dict[str, Any]], Dict[str, bool]]:
        """Extract fine-grained lineage entries from SQL parse result."""
        fine_grained_lineages: List[Dict[str, Any]] = []
        upstream_tables: Dict[str, bool] = {}

        column_lineage = getattr(result, "column_lineage", None)
        if not column_lineage:
            return fine_grained_lineages, upstream_tables

        for cl in column_lineage:
            try:
                downstream = getattr(cl, "downstream", None)
                if not downstream:
                    continue
                downstream_col = getattr(downstream, "column", None)
                if not downstream_col:
                    continue

                upstreams = getattr(cl, "upstreams", []) or []
                upstream_field_urns: List[str] = []

                for up in upstreams:
                    up_table = getattr(up, "table", None)
                    up_col = getattr(up, "column", None)
                    if not up_table or not up_col:
                        continue

                    up_urn_str = str(up_table)

                    # Only include iceberg platform URNs
                    if "dataPlatform:iceberg" not in up_urn_str:
                        logger.debug(
                            "Skipping non-iceberg upstream: %s", up_urn_str
                        )
                        continue

                    # Normalize URN to ensure platform_instance prefix
                    original_urn = up_urn_str
                    up_urn_str = self._normalize_upstream_urn(up_urn_str)
                    if original_urn != up_urn_str:
                        logger.debug("Normalized URN: %s -> %s", original_urn, up_urn_str)

                    # Skip self-referencing lineage (check after normalization)
                    if up_urn_str == downstream_urn:
                        continue

                    upstream_tables[up_urn_str] = True
                    upstream_field_urns.append(
                        self._build_field_urn(up_urn_str, str(up_col))
                    )

                if not upstream_field_urns:
                    continue

                logic = getattr(cl, "logic", None)
                is_direct_copy = False
                if logic:
                    is_direct_copy = getattr(logic, "is_direct_copy", False)

                downstream_field_urn = self._build_field_urn(
                    downstream_urn, str(downstream_col)
                )

                fine_grained_lineages.append(
                    {
                        "upstreamType": "FIELD_SET",
                        "upstreams": upstream_field_urns,
                        "downstreamType": "FIELD",
                        "downstreams": [downstream_field_urn],
                        "confidenceScore": 1.0 if is_direct_copy else 0.9,
                    }
                )

            except Exception as e:
                logger.debug("Error processing column lineage entry: %s", e)
                continue

        return fine_grained_lineages, upstream_tables

    def _delete_existing_lineage(self, downstream_urn: str) -> bool:
        """Delete existing upstreamLineage aspect from DataHub using soft delete."""
        try:
            import requests
            
            headers = {"Content-Type": "application/json"}
            if self.token:
                headers["Authorization"] = f"Bearer {self.token}"
            
            url = f"{self.gms_host}/entities?action=delete"
            payload = {
                "urn": downstream_urn,
                "aspectName": "upstreamLineage",
            }
            response = requests.post(url, headers=headers, json=payload, timeout=30)
            
            if response.status_code in (200, 204, 404):
                logger.debug("Deleted existing lineage for %s", downstream_urn)
                return True
            else:
                logger.debug(
                    "Delete lineage returned %s for %s, will overwrite",
                    response.status_code, downstream_urn
                )
                return False
        except Exception as e:
            logger.debug("Could not delete existing lineage for %s: %s", downstream_urn, e)
            return False

    def _emit_lineage(
        self,
        downstream_urn: str,
        upstream_tables: Dict[str, bool],
        fine_grained_lineages: List[Dict[str, Any]],
        clear_existing: bool = False,
    ) -> bool:
        """Emit lineage to DataHub using REST emitter."""
        try:
            from datahub.emitter.mcp import MetadataChangeProposalWrapper
            from datahub.emitter.rest_emitter import DatahubRestEmitter
            from datahub.metadata.schema_classes import (
                ChangeTypeClass,
                DatasetLineageTypeClass,
                FineGrainedLineageClass,
                FineGrainedLineageDownstreamTypeClass,
                FineGrainedLineageUpstreamTypeClass,
                UpstreamClass,
                UpstreamLineageClass,
            )
        except ImportError as e:
            logger.error(
                "DataHub emitter not available. "
                "Install with: uv pip install 'acryl-datahub[datahub-rest]': %s",
                e,
            )
            return False

        if clear_existing:
            self._delete_existing_lineage(downstream_urn)

        upstreams = [
            UpstreamClass(dataset=up_urn, type=DatasetLineageTypeClass.TRANSFORMED)
            for up_urn in upstream_tables.keys()
        ]

        fgl_classes = []
        for fgl in fine_grained_lineages:
            fgl_classes.append(
                FineGrainedLineageClass(
                    upstreamType=FineGrainedLineageUpstreamTypeClass.FIELD_SET,
                    upstreams=fgl["upstreams"],
                    downstreamType=FineGrainedLineageDownstreamTypeClass.FIELD,
                    downstreams=fgl["downstreams"],
                    confidenceScore=fgl.get("confidenceScore", 0.9),
                )
            )

        upstream_lineage = UpstreamLineageClass(
            upstreams=upstreams,
            fineGrainedLineages=fgl_classes,
        )

        mcp = MetadataChangeProposalWrapper(
            entityUrn=downstream_urn,
            aspect=upstream_lineage,
            changeType=ChangeTypeClass.UPSERT,
        )

        try:
            emitter = DatahubRestEmitter(self.gms_host, token=self.token)
            emitter.emit_mcp(mcp)
            emitter.flush()
            return True
        except Exception as e:
            logger.error("Failed to emit lineage for %s: %s", downstream_urn, e)
            return False

    def _convert_lineage_to_dbt_platform(
        self,
        iceberg_upstream_tables: Dict[str, bool],
        iceberg_fine_grained_lineages: List[Dict[str, Any]],
        iceberg_downstream_urn: str,
    ) -> Tuple[str, Dict[str, bool], List[Dict[str, Any]]]:
        """
        Convert iceberg-to-iceberg lineage to dbt-to-dbt lineage.
        
        Returns:
            A tuple of (dbt_downstream_urn, dbt_upstream_tables, dbt_fine_grained_lineages)
        """
        # Convert downstream URN
        dbt_downstream_urn = self._convert_iceberg_urn_to_dbt_urn(iceberg_downstream_urn)
        
        # Convert upstream table URNs
        dbt_upstream_tables: Dict[str, bool] = {}
        urn_mapping: Dict[str, str] = {}  # iceberg_urn -> dbt_urn
        
        for iceberg_urn in iceberg_upstream_tables.keys():
            dbt_urn = self._convert_iceberg_urn_to_dbt_urn(iceberg_urn)
            dbt_upstream_tables[dbt_urn] = True
            urn_mapping[iceberg_urn] = dbt_urn
        
        # Convert fine-grained lineages (column-level)
        dbt_fine_grained_lineages: List[Dict[str, Any]] = []
        
        for fgl in iceberg_fine_grained_lineages:
            # Convert upstream field URNs
            new_upstreams = []
            for up_field_urn in fgl.get("upstreams", []):
                # Extract dataset URN from field URN: urn:li:schemaField:(DATASET_URN,COLUMN)
                # Note: Dataset URNs contain commas, so we split by the LAST comma
                if up_field_urn.startswith("urn:li:schemaField:(") and up_field_urn.endswith(")"):
                    # Remove prefix "urn:li:schemaField:(" and suffix ")"
                    content = up_field_urn[20:-1]
                    last_comma_idx = content.rfind(",")
                    
                    if last_comma_idx != -1:
                        iceberg_dataset_urn = content[:last_comma_idx]
                        column = content[last_comma_idx + 1:]
                        dbt_dataset_urn = self._convert_iceberg_urn_to_dbt_urn(iceberg_dataset_urn)
                        new_upstreams.append(f"urn:li:schemaField:({dbt_dataset_urn},{column})")
                    else:
                        # Fallback if format is unexpected
                        new_upstreams.append(up_field_urn)
                else:
                    new_upstreams.append(up_field_urn)
            
            # Convert downstream field URNs
            new_downstreams = []
            for down_field_urn in fgl.get("downstreams", []):
                if down_field_urn.startswith("urn:li:schemaField:(") and down_field_urn.endswith(")"):
                    content = down_field_urn[20:-1]
                    last_comma_idx = content.rfind(",")
                    
                    if last_comma_idx != -1:
                        iceberg_dataset_urn = content[:last_comma_idx]
                        column = content[last_comma_idx + 1:]
                        dbt_dataset_urn = self._convert_iceberg_urn_to_dbt_urn(iceberg_dataset_urn)
                        new_downstreams.append(f"urn:li:schemaField:({dbt_dataset_urn},{column})")
                    else:
                        new_downstreams.append(down_field_urn)
                else:
                    new_downstreams.append(down_field_urn)
            
            dbt_fine_grained_lineages.append({
                "upstreamType": fgl.get("upstreamType", "FIELD_SET"),
                "upstreams": new_upstreams,
                "downstreamType": fgl.get("downstreamType", "FIELD"),
                "downstreams": new_downstreams,
                "confidenceScore": fgl.get("confidenceScore", 0.9),
            })
        
        return dbt_downstream_urn, dbt_upstream_tables, dbt_fine_grained_lineages

    def publish_from_dbt_artifacts(
        self,
        manifest_path: str,
        run_results_path: str,
        clear_existing: bool = True,
    ) -> Dict[str, Any]:
        """
        Publish column-level lineage from dbt artifacts to DataHub.

        Parses compiled SQL from dbt manifest/run_results and extracts
        column-level lineage, emitting it for both iceberg and dbt platforms.
        
        Args:
            clear_existing: If True (default), delete existing lineage before
                emitting new lineage. This ensures a full refresh instead of merge.
        """
        self._clear_existing = clear_existing
        nodes, compiled_sql_map = self._read_dbt_artifacts(
            manifest_path, run_results_path
        )

        if not nodes:
            logger.warning("No nodes found in manifest")
            return {"status": "error", "reason": "no_nodes"}

        processed_iceberg = 0
        processed_dbt = 0
        errors = 0
        skipped = 0

        for unique_id, node in nodes.items():
            resource_type = (node.get("resource_type") or "").lower()
            if resource_type not in {"model", "snapshot"}:
                continue

            database = (node.get("database") or "").strip()
            schema = (node.get("schema") or "").strip()
            name = (node.get("alias") or node.get("name") or "").strip()

            if not name or not schema:
                skipped += 1
                continue

            sql = (
                compiled_sql_map.get(unique_id)
                or node.get("compiled_code")
                or node.get("compiled_sql")
                or ""
            )

            if not sql.strip():
                skipped += 1
                logger.warning("No compiled SQL for %s (This node might not have been run or compiled)", name)
                continue

            # Build iceberg URN (primary platform)
            iceberg_downstream_urn = build_dataset_urn(
                platform="iceberg",
                platform_instance=self.iceberg_platform_instance,
                schema=schema,
                table=name,
                env=self.env,
            )

            logger.info("Processing model: %s (database=%s, schema=%s)", name, database, schema)
            
            result = self._parse_sql_lineage(sql, database or None, schema or None)
            if not result:
                skipped += 1
                logger.warning("SQL parsing returned no result for %s", name)
                continue

            # Debug: log what upstream tables the parser found
            in_tables = getattr(result, "in_tables", None) or []
            if in_tables:
                logger.info("  SQL parser found %d upstream tables:", len(in_tables))
                for t in in_tables[:5]:
                    logger.info("    - %s", t)

            fine_grained_lineages, upstream_tables = self._extract_lineage_from_result(
                result, iceberg_downstream_urn, name
            )

            if not fine_grained_lineages:
                skipped += 1
                logger.warning("No column lineage found for %s (Parser returned empty lineage)", name)
                continue

            # Emit lineage for ICEBERG platform
            if self._emit_lineage(
                iceberg_downstream_urn,
                upstream_tables,
                fine_grained_lineages,
                self._clear_existing
            ):
                processed_iceberg += 1
                logger.info(
                    "✅ [Iceberg] Published column lineage for %s (%d columns, %d upstream tables)",
                    name,
                    len(fine_grained_lineages),
                    len(upstream_tables),
                )
            else:
                errors += 1

            # Emit lineage for DBT platform (if enabled)
            if self.emit_to_dbt_platform:
                dbt_urn, dbt_upstreams, dbt_lineages = self._convert_lineage_to_dbt_platform(
                    upstream_tables, fine_grained_lineages, iceberg_downstream_urn
                )
                
                if self._emit_lineage(
                    dbt_urn,
                    dbt_upstreams,
                    dbt_lineages,
                    self._clear_existing
                ):
                    processed_dbt += 1
                    logger.info(
                        "✅ [dbt] Published column lineage for %s (%d columns, %d upstream tables)",
                        name,
                        len(dbt_lineages),
                        len(dbt_upstreams),
                    )
                else:
                    errors += 1

        return {
            "status": "ok" if errors == 0 else "partial",
            "processed_iceberg": processed_iceberg,
            "processed_dbt": processed_dbt,
            "processed": processed_iceberg,  # Backward compatibility
            "errors": errors,
            "skipped": skipped,
            "server": self.gms_host,
            "emit_to_dbt_platform": self.emit_to_dbt_platform,
        }


def publish_column_lineage(
    gms_host: str,
    token: Optional[str],
    manifest_path: str,
    run_results_path: str,
    iceberg_platform_instance: str = "demo",
    dbt_platform_instance: str = "demo",
    env: str = "PROD",
    clear_existing: bool = True,
    emit_to_dbt_platform: bool = True,
) -> Dict[str, Any]:
    """
    Convenience function to publish column-level lineage from dbt artifacts.

    Args:
        gms_host: DataHub GMS host URL
        token: DataHub API token (optional)
        manifest_path: Path to dbt manifest.json
        run_results_path: Path to dbt run_results.json
        iceberg_platform_instance: Platform instance for Iceberg URNs (default: demo)
        dbt_platform_instance: Platform instance for dbt URNs (default: demo)
        env: Environment (default: PROD)
        clear_existing: If True (default), delete existing lineage before
            emitting. This ensures full refresh instead of merge.
        emit_to_dbt_platform: If True (default), also emit lineage to dbt platform
            to ensure Combined View in DataHub shows correct lineage.

    Returns:
        Dict with status, processed count, errors, etc.
    """
    publisher = ColumnLineagePublisher(
        gms_host=gms_host,
        token=token,
        iceberg_platform_instance=iceberg_platform_instance,
        dbt_platform_instance=dbt_platform_instance,
        env=env,
        emit_to_dbt_platform=emit_to_dbt_platform,
    )
    return publisher.publish_from_dbt_artifacts(
        manifest_path, run_results_path, clear_existing=clear_existing
    )


def main():
    import argparse
    import sys

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    )

    parser = argparse.ArgumentParser(
        description="Publish column-level lineage from dbt artifacts to DataHub"
    )
    parser.add_argument(
        "--manifest", required=True, help="Path to dbt manifest.json"
    )
    parser.add_argument(
        "--run-results", required=True, help="Path to dbt run_results.json"
    )
    parser.add_argument(
        "--gms-host", required=True, help="DataHub GMS host URL"
    )
    parser.add_argument("--token", help="DataHub API token")
    parser.add_argument(
        "--iceberg-platform-instance", default="demo", help="Iceberg platform instance (default: demo)"
    )
    parser.add_argument(
        "--dbt-platform-instance", default="demo", help="dbt platform instance (default: demo)"
    )
    parser.add_argument(
        "--env", default="PROD", help="Environment (default: PROD)"
    )
    parser.add_argument(
        "--no-dbt-platform",
        action="store_true",
        help="Disable emitting lineage to dbt platform (only emit to iceberg)"
    )

    args = parser.parse_args()

    result = publish_column_lineage(
        gms_host=args.gms_host,
        token=args.token,
        manifest_path=args.manifest,
        run_results_path=args.run_results,
        iceberg_platform_instance=args.iceberg_platform_instance,
        dbt_platform_instance=args.dbt_platform_instance,
        env=args.env,
        emit_to_dbt_platform=not args.no_dbt_platform,
    )

    print(f"Result: {json.dumps(result, indent=2)}")
    sys.exit(0 if result.get("status") == "ok" else 1)


if __name__ == "__main__":
    main()
