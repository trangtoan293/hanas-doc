"""
DataHub BI Lineage Emission DAG

This DAG emits lineage metadata to DataHub:
1. Dremio view → Iceberg table lineage (table + column level)
2. Superset dataset → Dremio view lineage (column level)

Prerequisites:
- Dremio and Superset must be ingested via DataHub UI first
- This DAG only creates lineage relationships, not metadata

Manual trigger recommended after each DataHub UI ingestion.
"""

from datetime import timedelta
import pendulum
from airflow import DAG
from airflow.operators.python import PythonVirtualenvOperator
import logging

logger = logging.getLogger(__name__)

default_args = {
    "owner": "data-engineering",
    "depends_on_past": False,
    "start_date": pendulum.datetime(2024, 1, 1, tz="UTC"),
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
}


def emit_dremio_lineage(datahub_gms_host, datahub_token, dremio_schema_pattern_allow, source_to_iceberg_platform_instance, dremio_hostname, dremio_port, dremio_user, dremio_password, dremio_platform_urn_prefix="dremio"):
    """
    Parse Dremio view SQL and emit upstream lineage to Iceberg tables.
    
    This function:
    1. Queries DataHub for recently ingested Dremio datasets
    2. Parses view SQL to extract source.* table references based on mapping
    3. Maps source.schema.table -> platform_instance.schema.table for Iceberg platform
    4. Emits upstream lineage relationships with column-level mappings
    """
    import requests
    import re
    import logging
    import json
    import sys
    
    logging.basicConfig(stream=sys.stdout, level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    logger = logging.getLogger(__name__)
    
    # Parse source mapping
    try:
        source_mapping = json.loads(source_to_iceberg_platform_instance) if source_to_iceberg_platform_instance else {}
    except json.JSONDecodeError:
        logger.warning(f"Invalid JSON for source_to_iceberg_platform_instance: {source_to_iceberg_platform_instance}")
        source_mapping = {"LakeHouse": "demo"}
    
    logger.info(f"Source to Iceberg platform instance mapping: {source_mapping}")
    
    # Dremio API configuration
    dremio_host_clean = dremio_hostname.replace("http://", "").replace("https://", "").rstrip("/")
    dremio_base_url = f"http://{dremio_host_clean}:{dremio_port}"
    dremio_token = None
    
    def _get_dremio_token():
        nonlocal dremio_token
        url = f"{dremio_base_url}/apiv2/login"
        try:
            resp = requests.post(url, json={"userName": dremio_user, "password": dremio_password}, timeout=10)
            if resp.status_code == 200:
                dremio_token = resp.json().get("token")
                logger.info("Successfully authenticated with Dremio")
                return True
            else:
                logger.error(f"Dremio authentication failed: {resp.status_code}")
                return False
        except Exception as e:
            logger.error(f"Dremio authentication error: {e}")
            return False
    
    def _get_view_sql_from_dremio(space: str, view_name: str) -> str:
        if not dremio_token:
            return ""
        path_url = f"{space}/{view_name}"
        url = f"{dremio_base_url}/api/v3/catalog/by-path/{path_url}"
        headers = {"Authorization": f"_dremio{dremio_token}"}
        try:
            resp = requests.get(url, headers=headers, timeout=10)
            if resp.status_code == 200:
                return resp.json().get("sql", "")
            return ""
        except Exception as e:
            logger.error(f"Error querying Dremio API: {e}")
            return ""
    
    def _headers():
        h = {"Content-Type": "application/json", "X-RestLi-Protocol-Version": "2.0.0"}
        if datahub_token:
            h["Authorization"] = f"Bearer {datahub_token}"
        return h
    
    def _build_iceberg_urn(source_name: str, schema: str, table: str, env: str = "PROD") -> str:
        platform_instance = source_mapping.get(source_name, source_name.lower())
        return f"urn:li:dataset:(urn:li:dataPlatform:iceberg,{platform_instance}.{schema.lower()}.{table.strip('\"').lower()},{env})"
    
    def _build_dremio_urn(space: str, view_name: str, env: str = "PROD") -> str:
        return f"urn:li:dataset:(urn:li:dataPlatform:dremio,{dremio_platform_urn_prefix}.{space.lower()}.{view_name.strip('\"').lower()},{env})"
    
    def _parse_source_references(sql: str) -> list:
        all_refs = []
        for source_name in source_mapping.keys():
            pattern = rf'{source_name}\.(\w+)\.\"?(\w+)\"?'
            matches = re.findall(pattern, sql, re.IGNORECASE)
            for schema, table in matches:
                all_refs.append((source_name, schema, table))
        return all_refs
    
    def _parse_dremio_view_references(sql: str) -> list:
        known_dremio_spaces = {'DATA_MART', 'MDM', 'ETLADMIN', 'LANDING', 'STAGING', 'RAW_VAULT'}
        pattern = r'(?<!\.)(?<!\w)\b(\w+)\.\"?(\w+)\"?'
        matches = re.findall(pattern, sql, re.IGNORECASE)
        
        mapped_sources = set(s.upper() for s in source_mapping.keys())
        system_schemas = {'SYS', 'INFORMATION_SCHEMA', '$SCRATCH'}
        
        filtered = []
        for space, view in matches:
            space_upper = space.upper()
            if space_upper in mapped_sources or space_upper in system_schemas:
                continue
            if space_upper in known_dremio_spaces or len(space) >= 4:
                filtered.append((space, view))
        return filtered
    
    def _get_dremio_datasets():
        search_url = f"{datahub_gms_host}/entities?action=search"
        query = {
            "input": "*",
            "entity": "dataset",
            "start": 0,
            "count": 1000,
            "filter": {"or": [{"and": [{"field": "platform", "value": "urn:li:dataPlatform:dremio"}]}]}
        }
        try:
            resp = requests.post(search_url, headers=_headers(), json=query, timeout=60)
            if resp.status_code == 200:
                return resp.json().get("value", {}).get("entities", [])
            return []
        except Exception as e:
            logger.error(f"Error searching datasets: {e}")
            return []
    
    def _get_schema_via_graphql(urn: str) -> dict:
        url = f"{datahub_gms_host}/api/graphql"
        query = """query getDataset($urn: String!) { dataset(urn: $urn) { schemaMetadata { fields { fieldPath nativeDataType } } } }"""
        try:
            resp = requests.post(url, headers=_headers(), json={"query": query, "variables": {"urn": urn}}, timeout=30)
            if resp.status_code == 200:
                data = resp.json()
                if "errors" not in data:
                    dataset = data.get("data", {}).get("dataset")
                    if dataset:
                        return dataset.get("schemaMetadata") or {}
            return {}
        except Exception as e:
            logger.error(f"GraphQL error: {e}")
            return {}
    
    def _get_dremio_schema(space: str, view_name: str) -> list:
        if not dremio_token:
            return []
        path_url = f"{space}/{view_name}"
        url = f"{dremio_base_url}/api/v3/catalog/by-path/{path_url}"
        headers = {"Authorization": f"_dremio{dremio_token}"}
        try:
            resp = requests.get(url, headers=headers, timeout=10)
            if resp.status_code == 200:
                data = resp.json()
                fields = data.get("fields", [])
                return [f.get("name") for f in fields if f.get("name")]
            return []
        except Exception as e:
            logger.error(f"Error getting schema: {e}")
            return []
    
    def _get_datahub_schema(urn: str) -> list:
        """Get schema fields from DataHub. Returns list of (normalized_name, original_fieldPath)."""
        schema = _get_schema_via_graphql(urn)
        if not schema:
            return []
        
        results = []
        for f in schema.get("fields", []):
            field_path = f.get("fieldPath", "")
            if not field_path:
                continue
            
            # Extract actual column name from complex fieldPath
            # Format: [version=2.0].[type=struct].[type=string].COLUMN_NAME
            # or just: COLUMN_NAME
            parts = field_path.split(".")
            # Find the last part that doesn't start with [ (that's the actual column name)
            actual_name = None
            for part in reversed(parts):
                if not part.startswith("["):
                    actual_name = part
                    break
            
            if actual_name:
                results.append((actual_name, field_path))
        
        return results
    
    def _build_column_mappings(downstream_urn: str, downstream_cols: list, upstream_urns_with_cols: dict) -> list:
        """Build column mappings. downstream_cols is list of names, upstream is list of (name, fieldPath) tuples."""
        column_mappings = []
        # Normalize downstream cols for matching
        downstream_cols_lower = {c.lower(): c for c in downstream_cols}
        
        for upstream_urn, upstream_cols in upstream_urns_with_cols.items():
            # upstream_cols is list of (normalized_name, original_fieldPath)
            # Build map: lowercase_name -> simple_col_name (for URN)
            upstream_cols_map = {}
            for name, field_path in upstream_cols:
                # Extract simple name from fieldPath (last segment)
                simple_name = field_path.split(".")[-1]  # e.g., "RULE_CODE"
                upstream_cols_map[name.lower()] = simple_name
            
            # Find common columns
            common = set(downstream_cols_lower.keys()) & set(upstream_cols_map.keys())
            
            for col_lower in common:
                downstream_col = downstream_cols_lower[col_lower]
                upstream_simple_name = upstream_cols_map[col_lower]
                
                # Use UPPERCASE for schemaField URN (match DataHub stored format)
                column_mappings.append({
                    "upstreamType": "FIELD_SET",
                    "upstreams": [f"urn:li:schemaField:({upstream_urn},{upstream_simple_name})"],
                    "downstreamType": "FIELD_SET",
                    "downstreams": [f"urn:li:schemaField:({downstream_urn},{downstream_col.upper()})"],
                    "transformOperation": "IDENTITY",
                    "confidenceScore": 1.0
                })
        return column_mappings
    
    def _emit_upstream_lineage(downstream_urn: str, upstream_urns: list, column_mappings: list = None) -> bool:
        url = f"{datahub_gms_host}/aspects?action=ingestProposal"
        upstreams = [{"auditStamp": {"time": 0, "actor": "urn:li:corpuser:datahub"}, "dataset": u, "type": "TRANSFORMED"} for u in upstream_urns]
        aspect_value = {"upstreams": upstreams}
        if column_mappings:
            aspect_value["fineGrainedLineages"] = column_mappings
        
        proposal = {
            "entityType": "dataset",
            "entityUrn": downstream_urn,
            "changeType": "UPSERT",
            "aspectName": "upstreamLineage",
            "aspect": {"value": json.dumps(aspect_value), "contentType": "application/json"}
        }
        try:
            resp = requests.post(url, headers=_headers(), json={"proposal": proposal}, timeout=30)
            return resp.status_code == 200
        except Exception as e:
            logger.error(f"Error emitting lineage: {e}")
            return False
    
    # Main logic
    logger.info("Starting Dremio lineage emission...")
    
    if not _get_dremio_token():
        logger.error("Failed to authenticate with Dremio")
        return
    
    # Parse schema patterns
    if dremio_schema_pattern_allow and dremio_schema_pattern_allow.strip():
        schema_allow_patterns = [p.strip() for p in dremio_schema_pattern_allow.split(",") if p.strip()]
    else:
        schema_allow_patterns = ["^DATA_MART.*", "^MDM.*", "^ETLADMIN.*"]
    
    datasets = _get_dremio_datasets()
    logger.info(f"Found {len(datasets)} Dremio datasets")
    
    success_count = 0
    for ds in datasets:
        urn = ds.get("entity", "")
        dremio_prefix_lower = dremio_platform_urn_prefix.lower()
        if not urn or f"{dremio_prefix_lower}." not in urn.lower():
            continue
        
        # Parse URN to get space and view name
        try:
            dataset_part = urn.split(",")[1]
            parts = dataset_part.split(".")
            if len(parts) < 3:
                continue
            space = parts[1]
            view_name = parts[2]
        except:
            continue
        
        # Check if matches allow patterns
        import re as re_mod
        if not any(re_mod.match(p, space, re_mod.IGNORECASE) for p in schema_allow_patterns):
            continue
        
        view_sql = _get_view_sql_from_dremio(space, view_name)
        if not view_sql:
            continue
        
        logger.info(f"Processing: {urn}")
        upstream_urns = []
        
        # Parse source -> Iceberg refs
        for source_name, schema, table in _parse_source_references(view_sql):
            iceberg_urn = _build_iceberg_urn(source_name, schema, table)
            upstream_urns.append(iceberg_urn)
        
        # Parse Dremio view refs
        for ref_space, ref_view in _parse_dremio_view_references(view_sql):
            dremio_urn = _build_dremio_urn(ref_space, ref_view)
            upstream_urns.append(dremio_urn)
        
        if upstream_urns:
            # Build column mappings
            column_mappings = []
            try:
                downstream_cols = _get_dremio_schema(space, view_name)
                if downstream_cols:
                    upstream_urns_with_cols = {}
                    for u_urn in upstream_urns:
                        u_cols = _get_datahub_schema(u_urn)
                        if u_cols:
                            upstream_urns_with_cols[u_urn] = u_cols
                    if upstream_urns_with_cols:
                        column_mappings = _build_column_mappings(urn, downstream_cols, upstream_urns_with_cols)
            except Exception as e:
                logger.warning(f"Column mapping failed: {e}")
            
            if _emit_upstream_lineage(urn, upstream_urns, column_mappings):
                success_count += 1
                logger.info(f"  ✅ {len(upstream_urns)} upstreams, {len(column_mappings)} columns")
    
    logger.info(f"Dremio lineage completed. Success: {success_count}/{len(datasets)}")


def emit_superset_dataset_lineage(datahub_gms_host, datahub_token, 
                                   superset_host, superset_user, superset_password,
                                   dremio_platform_urn_prefix="dremio", superset_dataset_urn_prefix="dataset"):
    """
    Create column-level lineage from Superset datasets to their source Dremio views.
    
    For Virtual Datasets (no matching Dremio view), parse SQL from Superset to find sources.
    
    Args:
        datahub_gms_host: DataHub GMS URL
        datahub_token: DataHub API token
        superset_host: Superset API URL
        superset_user: Superset username
        superset_password: Superset password
        dremio_platform_urn_prefix: URN prefix for Dremio views (default: "dremio")
        superset_dataset_urn_prefix: URN prefix for Superset datasets (default: "dataset")
    """
    import requests
    import json
    import logging
    import sys
    
    # Configure logging for Airflow output
    logging.basicConfig(stream=sys.stdout, level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    logger = logging.getLogger(__name__)
    
    logger.info(f"Starting Superset dataset lineage emission...")
    logger.info(f"DataHub GMS: {datahub_gms_host}")
    logger.info(f"Dremio platform URN prefix: {dremio_platform_urn_prefix}")
    logger.info(f"Superset dataset URN prefix: {superset_dataset_urn_prefix}")
    
    # Build prefix list for searching Superset datasets
    # Use the superset_dataset_urn_prefix as the primary search pattern
    superset_prefix_list = [superset_dataset_urn_prefix, superset_dataset_urn_prefix.lower(), superset_dataset_urn_prefix.upper()]
    superset_prefix_list = list(set(superset_prefix_list))  # Remove duplicates
    
    logger.info(f"Searching for Superset datasets with prefixes: {superset_prefix_list}")
    
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {datahub_token}" if datahub_token else "",
        "X-RestLi-Protocol-Version": "2.0.0"
    }
    gql_headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {datahub_token}" if datahub_token else ""
    }
    
    # Superset API session (for Virtual Dataset SQL parsing)
    superset_session = None
    superset_access_token = None
    
    def init_superset_session():
        """Initialize Superset API session with login."""
        nonlocal superset_session, superset_access_token
        if superset_session is not None:
            return True
        
        if not superset_host or not superset_user or not superset_password:
            logger.warning("Superset credentials not provided - Virtual Dataset SQL parsing disabled")
            return False
        
        try:
            superset_session = requests.Session()
            
            # Get CSRF token (optional, some Superset configs require it)
            try:
                csrf_resp = superset_session.get(f"{superset_host}/api/v1/security/csrf_token/", timeout=10)
                csrf_token = csrf_resp.json().get("result") if csrf_resp.status_code == 200 else None
            except:
                csrf_token = None
            
            # Login
            login_headers = {"Content-Type": "application/json"}
            if csrf_token:
                login_headers["X-CSRFToken"] = csrf_token
            
            login_resp = superset_session.post(
                f"{superset_host}/api/v1/security/login",
                headers=login_headers,
                json={"username": superset_user, "password": superset_password, "provider": "db", "refresh": True},
                timeout=15
            )
            
            if login_resp.status_code == 200:
                superset_access_token = login_resp.json().get("access_token")
                logger.info("Superset API login successful")
                return True
            else:
                logger.warning(f"Superset login failed: {login_resp.status_code}")
                superset_session = None
                return False
        except Exception as e:
            logger.warning(f"Superset connection error: {e}")
            superset_session = None
            return False
    
    def get_virtual_dataset_sql(dataset_name):
        """Get SQL from Superset Virtual Dataset."""
        import re as re_mod
        
        if not init_superset_session() or not superset_access_token:
            return None
        
        try:
            auth_headers = {"Authorization": f"Bearer {superset_access_token}", "Content-Type": "application/json"}
            
            # List datasets to find our target
            datasets_resp = superset_session.get(f"{superset_host}/api/v1/dataset/", headers=auth_headers, timeout=30)
            if datasets_resp.status_code != 200:
                return None
            
            datasets = datasets_resp.json().get("result", [])
            
            # Find by name (last part of dataset_name, e.g., "mdm_flow" from "dataset.MDM.mdm_flow")
            table_name = dataset_name.split(".")[-1].lower()
            target_id = None
            
            for ds in datasets:
                if ds.get("table_name", "").lower() == table_name:
                    target_id = ds.get("id")
                    break
            
            if not target_id:
                logger.debug(f"Dataset '{table_name}' not found in Superset")
                return None
            
            # Get dataset detail with SQL
            detail_resp = superset_session.get(f"{superset_host}/api/v1/dataset/{target_id}", headers=auth_headers, timeout=30)
            if detail_resp.status_code == 200:
                sql = detail_resp.json().get("result", {}).get("sql", "")
                if sql:
                    logger.info(f"  Found Virtual Dataset SQL for {dataset_name}")
                    return sql
            return None
        except Exception as e:
            logger.warning(f"Error fetching Superset dataset: {e}")
            return None
    
    def parse_sql_for_tables(sql):
        """Parse SQL to extract table references. Returns list of (schema, table) tuples.
        
        Handles both formats:
        - schema.table → returns (schema, table)
        - source.schema.table → returns (schema, table) - strips source prefix
        """
        import re as re_mod
        if not sql:
            return []
        
        # Find all table references after FROM or JOIN
        # Match patterns like: FROM schema.table or FROM source.schema.table
        # Use two separate patterns to handle both cases correctly
        
        # Pattern for 3-part names: source.schema.table
        pattern_3part = r'(?:FROM|JOIN)\s+(\w+)\.(\w+)\.(\w+)'
        matches_3part = re_mod.findall(pattern_3part, sql, re_mod.IGNORECASE)
        
        # Pattern for 2-part names: schema.table  
        pattern_2part = r'(?:FROM|JOIN)\s+(\w+)\.(\w+)(?!\.\w)'
        matches_2part = re_mod.findall(pattern_2part, sql, re_mod.IGNORECASE)
        
        unique_tables = []
        seen = set()
        
        # Process 3-part matches: (source, schema, table) -> use (schema, table)
        for source, schema, table in matches_3part:
            key = (schema.lower(), table.lower())
            if key not in seen:
                seen.add(key)
                unique_tables.append(key)
                logger.info(f"    Parsed 3-part table: {source}.{schema}.{table} -> ({schema}, {table})")
        
        # Process 2-part matches: (schema, table) - only if not already seen from 3-part
        for schema, table in matches_2part:
            key = (schema.lower(), table.lower())
            if key not in seen:
                seen.add(key)
                unique_tables.append(key)
                logger.info(f"    Parsed 2-part table: {schema}.{table} -> ({schema}, {table})")
        
        return unique_tables
    
    def emit_virtual_dataset_lineage(superset_urn, sql):
        """Emit lineage from Superset Virtual Dataset to source tables from SQL, including column-level lineage."""
        import re as re_mod
        
        tables = parse_sql_for_tables(sql)
        if not tables:
            return False
        
        # Build upstream URNs - schema is already without platform prefix
        upstream_urns = []
        for schema, table in tables:
            # Build URN: {prefix}.{schema}.{table}
            dremio_urn = f"urn:li:dataset:(urn:li:dataPlatform:dremio,{dremio_platform_urn_prefix}.{schema}.{table},PROD)"
            upstream_urns.append((dremio_urn, schema, table))
            logger.info(f"  -> Upstream from SQL: {dremio_urn}")
        
        # Parse SQL to extract column mappings
        # Pattern to find SELECT expressions: expression AS alias
        column_mappings = []
        
        # Extract SELECT clause
        select_match = re_mod.search(r'SELECT\s+(.*?)(?:\s+FROM)', sql, re_mod.IGNORECASE | re_mod.DOTALL)
        if select_match:
            select_clause = select_match.group(1)
            
            # Split by top-level commas (not inside parentheses)
            # Simple approach: split by comma followed by space and identifier pattern
            expressions = []
            depth = 0
            current = ""
            for char in select_clause:
                if char == '(':
                    depth += 1
                elif char == ')':
                    depth -= 1
                elif char == ',' and depth == 0:
                    expressions.append(current.strip())
                    current = ""
                    continue
                current += char
            if current.strip():
                expressions.append(current.strip())
            
            for expr in expressions:
                # Extract alias: "expression AS alias" or just "column"
                as_match = re_mod.search(r'\s+AS\s+(\w+)\s*$', expr, re_mod.IGNORECASE)
                if as_match:
                    alias = as_match.group(1).upper()
                    expression = expr[:as_match.start()].strip()
                else:
                    # Column name is the expression itself
                    alias = expr.strip().upper()
                    expression = expr.strip()
                
                # Extract column references from expression
                # Pattern: word that looks like column (not function, not literal)
                # Exclude SQL keywords and functions
                sql_keywords = {'CASE', 'WHEN', 'THEN', 'ELSE', 'END', 'AND', 'OR', 'NOT', 'IN', 'IS', 'NULL', 
                               'COUNT', 'SUM', 'AVG', 'MAX', 'MIN', 'DISTINCT', 'AS', 'SELECT', 'FROM'}
                
                # Find all potential column references: table.column or just column
                col_refs = re_mod.findall(r'(?:(\w+)\.)?(\w+)', expression)
                source_columns = set()
                
                for table_ref, col in col_refs:
                    col_upper = col.upper()
                    # Skip if it's a keyword, function, number, or literal
                    if col_upper in sql_keywords:
                        continue
                    if col.isdigit():
                        continue
                    if re_mod.match(r'^[0-9\'"]+', col):
                        continue
                    # Skip if it looks like a string literal marker
                    if col_upper in {'CORE_CIF', 'INVALID', 'VALID', 'DUPLICATE', 'NON', 'MERGE', 'GOLDEN'}:
                        continue
                    source_columns.add(col_upper)
                
                if source_columns:
                    column_mappings.append((alias, list(source_columns)))
                    logger.info(f"    Column mapping: {alias} <- {list(source_columns)}")
        
        # Build fineGrainedLineages
        fine_grained = []
        if column_mappings and upstream_urns:
            main_upstream_urn = upstream_urns[0][0]  # Use first upstream
            
            for output_col, input_cols in column_mappings:
                downstream_field = f"urn:li:schemaField:({superset_urn},{output_col})"
                upstream_fields = [f"urn:li:schemaField:({main_upstream_urn},{col})" for col in input_cols]
                
                fine_grained.append({
                    "upstreamType": "FIELD_SET",
                    "upstreams": upstream_fields,
                    "downstreamType": "FIELD",
                    "downstreams": [downstream_field],
                    "transformOperation": "TRANSFORM"
                })
        
        aspect_value = {
            "upstreams": [
                {"auditStamp": {"time": 0, "actor": "urn:li:corpuser:datahub"}, "dataset": urn, "type": "TRANSFORMED"}
                for urn, _, _ in upstream_urns
            ]
        }
        
        if fine_grained:
            aspect_value["fineGrainedLineages"] = fine_grained
            logger.info(f"  -> {len(fine_grained)} column mappings created")
        
        proposal = {
            "entityType": "dataset",
            "entityUrn": superset_urn,
            "changeType": "UPSERT",
            "aspectName": "upstreamLineage",
            "aspect": {"value": json.dumps(aspect_value), "contentType": "application/json"}
        }
        
        try:
            resp = requests.post(f"{datahub_gms_host}/aspects?action=ingestProposal", headers=headers, json={"proposal": proposal}, timeout=30)
            return resp.status_code == 200
        except Exception as e:
            logger.error(f"Emit error: {e}")
            return False
    
    def graphql_query(query, variables=None):
        url = f"{datahub_gms_host}/api/graphql"
        payload = {"query": query}
        if variables:
            payload["variables"] = variables
        try:
            resp = requests.post(url, headers=gql_headers, json=payload, timeout=30)
            if resp.status_code == 200:
                return resp.json()
            logger.warning(f"GraphQL failed: {resp.status_code} - {resp.text[:200]}")
            return {}
        except Exception as e:
            logger.error(f"GraphQL error: {e}")
            return {}
    
    def get_superset_datasets():
        """Find Superset datasets by searching with specific prefix.SPACE patterns."""
        # Known Dremio spaces
        dremio_spaces = ["DATA_MART", "MDM", "ETLADMIN", "LANDING", "STAGING", "RAW_VAULT"]
        
        # Build search patterns: prefix.SPACE*
        search_patterns = []
        for prefix in superset_prefix_list:
            for space in dremio_spaces:
                search_patterns.append(f"{prefix}.{space}")
        
        logger.info(f"Searching with {len(search_patterns)} patterns...")
        
        all_results = []
        for pattern in search_patterns:
            query = f'''
            query {{
                search(input: {{type: DATASET, query: "{pattern}*", start: 0, count: 200}}) {{
                    searchResults {{
                        entity {{
                            urn
                            ... on Dataset {{ name platform {{ name }} }}
                        }}
                    }}
                }}
            }}
            '''
            data = graphql_query(query)
            for r in data.get("data", {}).get("search", {}).get("searchResults", []):
                entity = r.get("entity", {})
                urn = entity.get("urn", "")
                platform = entity.get("platform", {}).get("name", "")
                
                if platform == "dremio" and urn:
                    # Extract dataset path from URN
                    # Format: urn:li:dataset:(urn:li:dataPlatform:dremio,dataset.DATA_MART.table,PROD)
                    try:
                        dataset_path = urn.split(",")[1]  # dataset.DATA_MART.table
                        path_lower = dataset_path.lower()
                        
                        # IMPORTANT: Skip real Dremio views (path starts with dremio_platform_urn_prefix)
                        # These are handled by emit_dremio_lineage task - processing them here would OVERWRITE their lineage!
                        if path_lower.startswith(f"{dremio_platform_urn_prefix.lower()}."):
                            continue
                        
                        is_superset = any(path_lower.startswith(f"{p.lower()}.") for p in superset_prefix_list)
                        if is_superset:
                            all_results.append({"urn": urn, "name": dataset_path})
                            logger.info(f"  Found: {dataset_path}")
                    except (IndexError, AttributeError):
                        pass
        
        # Remove duplicates by URN
        seen = set()
        unique_results = []
        for r in all_results:
            if r["urn"] not in seen:
                seen.add(r["urn"])
                unique_results.append(r)
        
        return unique_results

    
    def find_dremio_view(superset_ds_name):
        """Find matching Dremio view (not Superset dataset) with schema."""
        parts = superset_ds_name.split(".")
        if len(parts) < 2:
            logger.warning(f"Invalid Superset dataset name: {superset_ds_name}")
            return None
        table_name = parts[-1]
        
        logger.info(f"  Looking for Dremio view matching: {table_name}")
        
        query = f'''
        query {{
            search(input: {{type: DATASET, query: "{table_name}", start: 0, count: 20}}) {{
                searchResults {{
                    entity {{
                        urn
                        ... on Dataset {{
                            name platform {{ name }}
                            schemaMetadata {{ fields {{ fieldPath }} }}
                        }}
                    }}
                }}
            }}
        }}
        '''
        data = graphql_query(query)
        if not data or "data" not in data or data.get("data") is None:
            logger.warning(f"    GraphQL search failed for: {table_name}")
            return None
        
        search_results = data.get("data", {}).get("search", {})
        if search_results is None:
            return None
        
        for r in search_results.get("searchResults", []):
            entity = r.get("entity", {})
            urn = entity.get("urn", "")
            platform = entity.get("platform", {}).get("name", "")
            schema = entity.get("schemaMetadata")
            name = entity.get("name", "")
            
            # Skip Superset datasets - check URN path, not name!
            # Superset datasets have URN like: ...dremio,dataset.MDM.xxx,PROD
            # Dremio views have URN like: ...dremio,dremio.mdm.xxx,PROD
            # We want Dremio views (URN contains 'dremio.space.') NOT Superset datasets (URN contains 'dataset.SPACE.')
            urn_path = urn.split(",")[1] if "," in urn else ""
            is_superset_dataset = urn_path.lower().startswith(f"{superset_dataset_urn_prefix.lower()}.")
            
            # IMPORTANT: Require exact name match (case-insensitive) to avoid selecting wrong views
            # e.g., searching "mdm_flow" should not match "MDM_GOLDEN_RECORDS"
            name_matches = name.lower() == table_name.lower()
            
            if platform == "dremio" and schema and not is_superset_dataset and name_matches:
                logger.info(f"    Found exact Dremio view: {name} ({len(schema.get('fields', []))} fields)")
                return {"urn": urn, "name": name, "fields": [f["fieldPath"] for f in schema.get("fields", [])]}
        
        logger.warning(f"    No Dremio view found for: {table_name}")
        return None
    
    def emit_lineage(downstream_urn, upstream_urn, columns):
        if not columns:
            return False
        fine_grained = [{
            "upstreamType": "FIELD_SET",
            "upstreams": [f"urn:li:schemaField:({upstream_urn},{col})"],
            "downstreamType": "FIELD_SET",
            "downstreams": [f"urn:li:schemaField:({downstream_urn},{col})"],
            "transformOperation": "IDENTITY",
            "confidenceScore": 1.0
        } for col in columns]
        
        aspect_value = {
            "upstreams": [{"auditStamp": {"time": 0, "actor": "urn:li:corpuser:datahub"}, "dataset": upstream_urn, "type": "TRANSFORMED"}],
            "fineGrainedLineages": fine_grained
        }
        
        url = f"{datahub_gms_host}/aspects?action=ingestProposal"
        proposal = {
            "entityType": "dataset",
            "entityUrn": downstream_urn,
            "changeType": "UPSERT",
            "aspectName": "upstreamLineage",
            "aspect": {"value": json.dumps(aspect_value), "contentType": "application/json"}
        }
        try:
            resp = requests.post(url, headers=headers, json={"proposal": proposal}, timeout=30)
            if resp.status_code != 200:
                logger.error(f"Emit failed: {resp.status_code} - {resp.text[:100]}")
            return resp.status_code == 200
        except Exception as e:
            logger.error(f"Emit error: {e}")
            return False
    
    # Main logic - already logged at start
    superset_datasets = get_superset_datasets()
    logger.info(f"Total Superset datasets found: {len(superset_datasets)}")
    
    if not superset_datasets:
        logger.warning("No Superset datasets found! Check if Superset ingestion has been run.")
        return
    
    success_count = 0
    virtual_count = 0
    for ds in superset_datasets:
        # Step 1: Check if this is a Virtual Dataset (has SQL) from Superset
        sql = get_virtual_dataset_sql(ds["name"])
        
        if sql:
            # Virtual Dataset: Parse SQL to find upstream tables
            logger.info(f"🔷 {ds['name']} is a Virtual Dataset")
            if emit_virtual_dataset_lineage(ds["urn"], sql):
                virtual_count += 1
                logger.info(f"✅ {ds['name']} -> (Virtual Dataset lineage from SQL)")
        else:
            # Physical Dataset: Find matching Dremio view by exact name
            logger.info(f"🔶 {ds['name']} is a Physical Dataset")
            dremio_view = find_dremio_view(ds["name"])
            
            if dremio_view:
                if emit_lineage(ds["urn"], dremio_view["urn"], dremio_view["fields"]):
                    success_count += 1
                    logger.info(f"✅ {ds['name']} -> {dremio_view['name']} ({len(dremio_view['fields'])} cols)")
            else:
                logger.debug(f"⏭️ Skip {ds['name']}: No matching Dremio view found")
    
    logger.info(f"Superset lineage completed. Physical: {success_count}, Virtual: {virtual_count}")


with DAG(
    dag_id="datahub_emit_bi_lineage",
    default_args=default_args,
    description="Emit lineage from Dremio views to Iceberg tables and Superset datasets to Dremio views",
    schedule_interval=None,  # Manual trigger only
    catchup=False,
    tags=["datahub", "lineage", "dremio", "superset"],
    params={
        # Dremio schema patterns to filter (regex, comma-separated)
        "dremio_schema_pattern_allow": "^DATA_MART.*,^MDM.*,^ETLADMIN.*",
        # Source to Iceberg platform instance mapping (JSON: {"LakeHouse": "demo"})
        "source_to_iceberg_platform_instance": '{"LakeHouse": "demo"}',
        # Platform prefix for Dremio views in DataHub URNs (e.g., dremio.data_mart.view)
        "dremio_platform_urn_prefix": "dremio",
        # Platform prefix for Superset datasets in DataHub URNs (e.g., dataset.DATA_MART.table)
        "superset_dataset_urn_prefix": "dataset",
    }
) as dag:

    t1_dremio_lineage = PythonVirtualenvOperator(
        task_id="emit_dremio_lineage",
        python_callable=emit_dremio_lineage,
        requirements=["requests"],
        system_site_packages=False,
        op_kwargs={
            "datahub_gms_host": "{{ var.value.get('DATAHUB_GMS_HOST', 'http://192.168.1.173:8080') }}",
            "datahub_token": "{{ var.value.get('DATAHUB_TOKEN', '') }}",
            "dremio_schema_pattern_allow": "{{ params.dremio_schema_pattern_allow }}",
            "source_to_iceberg_platform_instance": "{{ params.source_to_iceberg_platform_instance }}",
            "dremio_hostname": "{{ var.value.get('dremio_host', '192.168.1.193') }}",
            "dremio_port": "{{ var.value.get('dremio_port', '9047') }}",
            "dremio_user": "{{ var.value.get('dremio_username', 'vaultadmin') }}",
            "dremio_password": "{{ var.value.get('dremio_password', 'vaultadmin1A') }}",
            "dremio_platform_urn_prefix": "{{ params.dremio_platform_urn_prefix }}",
        }
    )

    t2_superset_lineage = PythonVirtualenvOperator(
        task_id="emit_superset_dataset_lineage",
        python_callable=emit_superset_dataset_lineage,
        requirements=["requests"],
        system_site_packages=False,
        op_kwargs={
            "datahub_gms_host": "{{ var.value.get('DATAHUB_GMS_HOST', 'http://192.168.1.173:8080') }}",
            "datahub_token": "{{ var.value.get('DATAHUB_TOKEN', '') }}",
            "superset_host": "{{ var.value.get('superset_host', 'http://my-superset.superset.svc:8088') }}",
            "superset_user": "{{ var.value.get('superset_username', 'vaultadmin') }}",
            "superset_password": "{{ var.value.get('superset_password', 'vaultadmin1A') }}",
            "dremio_platform_urn_prefix": "{{ params.dremio_platform_urn_prefix }}",
            "superset_dataset_urn_prefix": "{{ params.superset_dataset_urn_prefix }}",
        }
    )

    # Flow: emit_dremio_lineage -> emit_superset_dataset_lineage
    t1_dremio_lineage >> t2_superset_lineage
