"""DataHub utility functions for URN building, API calls, and lineage emission.

This module provides reusable utilities for interacting with DataHub:
- URN builders for various platforms (Iceberg, dbt, Dremio, Superset)
- API helpers for REST and GraphQL calls
- Lineage emission helpers
- S3 client factory
"""
from __future__ import annotations

import json
from typing import Any, Dict, List, Optional
from urllib.parse import urlparse


# =============================================================================
# URN Builders
# =============================================================================

def build_dataset_urn(
    platform: str,
    name: str,
    env: str = "PROD",
) -> str:
    """
    Build a DataHub dataset URN.
    
    Args:
        platform: Platform name (e.g., "iceberg", "dbt", "dremio").
        name: Full dataset name (e.g., "demo.schema.table").
        env: Environment (default: "PROD").
    
    Returns:
        URN string: urn:li:dataset:(urn:li:dataPlatform:{platform},{name},{env})
    """
    return f"urn:li:dataset:(urn:li:dataPlatform:{platform},{name},{env})"


def build_iceberg_urn(
    platform_instance: str,
    schema: str,
    table: str,
    env: str = "PROD",
    database: Optional[str] = None,
    include_database: bool = False,
) -> str:
    """
    Build an Iceberg dataset URN.
    
    Args:
        platform_instance: Instance name (e.g., "demo", "LakeHouse").
        schema: Schema name.
        table: Table name.
        env: Environment (default: "PROD").
        database: Optional database/catalog name.
        include_database: If True and database provided, include it in name.
    
    Returns:
        URN for Iceberg dataset.
    """
    if include_database and database:
        name = f"{platform_instance}.{database}.{schema}.{table}"
    else:
        name = f"{platform_instance}.{schema}.{table}"
    return build_dataset_urn("iceberg", name, env)


def build_dremio_urn(
    platform_prefix: str,
    space: str,
    view_name: str,
    env: str = "PROD",
) -> str:
    """
    Build a Dremio view URN.
    
    Args:
        platform_prefix: URN prefix for Dremio (e.g., "dremio").
        space: Dremio space name (e.g., "DATA_MART").
        view_name: View name.
        env: Environment (default: "PROD").
    
    Returns:
        URN for Dremio view.
    """
    name = f"{platform_prefix}.{space.lower()}.{view_name.strip('\"').lower()}"
    return build_dataset_urn("dremio", name, env)


def build_schema_field_urn(dataset_urn: str, field_name: str) -> str:
    """
    Build a schema field URN.
    
    Args:
        dataset_urn: The dataset URN.
        field_name: Field/column name.
    
    Returns:
        URN for schema field.
    """
    return f"urn:li:schemaField:({dataset_urn},{field_name})"


def build_assertion_urn(unique_id: str) -> str:
    """
    Build an assertion URN from a unique identifier.
    
    Args:
        unique_id: Unique identifier (e.g., dbt test unique_id).
    
    Returns:
        URN for assertion.
    """
    import hashlib
    digest = hashlib.md5(unique_id.encode("utf-8")).hexdigest()[:16]
    return f"urn:li:assertion:{digest}"


def build_tag_urn(tag_name: str) -> str:
    """
    Build a tag URN.
    
    Args:
        tag_name: Tag name (spaces will be replaced with underscores).
    
    Returns:
        URN for tag.
    """
    safe_name = tag_name.replace(" ", "_")
    return f"urn:li:tag:{safe_name}"


# =============================================================================
# GMS Host Normalization
# =============================================================================

def normalize_gms_host(gms_host: str) -> str:
    """
    Normalize DataHub GMS host URL.
    
    Handles cases where port 9002 needs /api/gms suffix.
    
    Args:
        gms_host: Raw GMS host URL.
    
    Returns:
        Normalized GMS URL.
    """
    server = (gms_host or "").rstrip("/")
    parsed = urlparse(server if "://" in server else f"http://{server}")
    if (parsed.port == 9002) and (parsed.path == "" or parsed.path == "/"):
        server = f"{server}/api/gms"
    return server


# =============================================================================
# API Helpers
# =============================================================================

def make_datahub_headers(token: Optional[str] = None) -> Dict[str, str]:
    """
    Build headers for DataHub REST API calls.
    
    Args:
        token: Optional Bearer token.
    
    Returns:
        Headers dict.
    """
    headers = {
        "Content-Type": "application/json",
        "X-RestLi-Protocol-Version": "2.0.0",
    }
    if token:
        headers["Authorization"] = f"Bearer {token}"
    return headers


def make_graphql_headers(token: Optional[str] = None) -> Dict[str, str]:
    """
    Build headers for DataHub GraphQL API calls.
    
    Args:
        token: Optional Bearer token.
    
    Returns:
        Headers dict.
    """
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    return headers


def graphql_query(
    gms_host: str,
    query: str,
    variables: Optional[Dict[str, Any]] = None,
    token: Optional[str] = None,
    timeout: int = 30,
) -> Dict[str, Any]:
    """
    Execute a GraphQL query against DataHub.
    
    Args:
        gms_host: DataHub GMS host URL.
        query: GraphQL query string.
        variables: Optional query variables.
        token: Optional Bearer token.
        timeout: Request timeout in seconds.
    
    Returns:
        Response JSON or empty dict on error.
    """
    try:
        import requests
    except ImportError:
        return {"error": "requests not available"}

    url = f"{normalize_gms_host(gms_host)}/api/graphql"
    payload: Dict[str, Any] = {"query": query}
    if variables:
        payload["variables"] = variables

    try:
        resp = requests.post(
            url,
            headers=make_graphql_headers(token),
            json=payload,
            timeout=timeout,
        )
        if resp.status_code == 200:
            return resp.json()
        return {"error": f"HTTP {resp.status_code}"}
    except Exception as e:
        return {"error": str(e)}


def ingest_mcp(
    gms_host: str,
    entity_type: str,
    entity_urn: str,
    aspect_name: str,
    aspect_value: Dict[str, Any],
    token: Optional[str] = None,
    timeout: int = 30,
) -> bool:
    """
    Ingest a Metadata Change Proposal (MCP) to DataHub.
    
    Args:
        gms_host: DataHub GMS host URL.
        entity_type: Entity type (e.g., "dataset", "assertion").
        entity_urn: Entity URN.
        aspect_name: Aspect name (e.g., "upstreamLineage", "schemaMetadata").
        aspect_value: Aspect value as dict.
        token: Optional Bearer token.
        timeout: Request timeout in seconds.
    
    Returns:
        True if successful, False otherwise.
    """
    try:
        import requests
    except ImportError:
        return False

    url = f"{normalize_gms_host(gms_host)}/aspects?action=ingestProposal"
    proposal = {
        "entityType": entity_type,
        "entityUrn": entity_urn,
        "changeType": "UPSERT",
        "aspectName": aspect_name,
        "aspect": {
            "value": json.dumps(aspect_value),
            "contentType": "application/json",
        },
    }

    try:
        resp = requests.post(
            url,
            headers=make_datahub_headers(token),
            json={"proposal": proposal},
            timeout=timeout,
        )
        return resp.status_code == 200
    except Exception:
        return False


# =============================================================================
# Lineage Helpers
# =============================================================================

def emit_upstream_lineage(
    gms_host: str,
    downstream_urn: str,
    upstream_urns: List[str],
    token: Optional[str] = None,
    column_mappings: Optional[List[Dict[str, Any]]] = None,
    timeout: int = 30,
) -> bool:
    """
    Emit upstream lineage for a dataset.
    
    Args:
        gms_host: DataHub GMS host URL.
        downstream_urn: Downstream dataset URN.
        upstream_urns: List of upstream dataset URNs.
        token: Optional Bearer token.
        column_mappings: Optional fine-grained column lineage mappings.
        timeout: Request timeout in seconds.
    
    Returns:
        True if successful, False otherwise.
    """
    upstreams = [
        {
            "auditStamp": {"time": 0, "actor": "urn:li:corpuser:datahub"},
            "dataset": urn,
            "type": "TRANSFORMED",
        }
        for urn in upstream_urns
    ]

    aspect_value: Dict[str, Any] = {"upstreams": upstreams}
    if column_mappings:
        aspect_value["fineGrainedLineages"] = column_mappings

    return ingest_mcp(
        gms_host=gms_host,
        entity_type="dataset",
        entity_urn=downstream_urn,
        aspect_name="upstreamLineage",
        aspect_value=aspect_value,
        token=token,
        timeout=timeout,
    )


def build_column_lineage_mapping(
    upstream_urn: str,
    upstream_column: str,
    downstream_urn: str,
    downstream_column: str,
    transform_operation: str = "IDENTITY",
    confidence_score: float = 1.0,
) -> Dict[str, Any]:
    """
    Build a single column lineage mapping entry.
    
    Args:
        upstream_urn: Upstream dataset URN.
        upstream_column: Upstream column name.
        downstream_urn: Downstream dataset URN.
        downstream_column: Downstream column name.
        transform_operation: Transformation type (default: "IDENTITY").
        confidence_score: Confidence score (default: 1.0).
    
    Returns:
        Column mapping dict for fineGrainedLineages.
    """
    return {
        "upstreamType": "FIELD_SET",
        "upstreams": [build_schema_field_urn(upstream_urn, upstream_column)],
        "downstreamType": "FIELD_SET",
        "downstreams": [build_schema_field_urn(downstream_urn, downstream_column)],
        "transformOperation": transform_operation,
        "confidenceScore": confidence_score,
    }


# =============================================================================
# S3 Client Factory
# =============================================================================

def make_s3_client(
    endpoint_url: Optional[str] = None,
    region: Optional[str] = None,
    access_key_id: Optional[str] = None,
    secret_access_key: Optional[str] = None,
    session_token: Optional[str] = None,
    verify: bool = True,
):
    """
    Create a boto3 S3 client with optional configuration.
    
    Args:
        endpoint_url: Optional S3 endpoint URL (for MinIO, etc.).
        region: Optional AWS region.
        access_key_id: Optional AWS access key ID.
        secret_access_key: Optional AWS secret access key.
        session_token: Optional AWS session token.
        verify: SSL verification (default: True).
    
    Returns:
        boto3 S3 client or None if boto3 not available.
    """
    try:
        import boto3
    except ImportError:
        return None

    kwargs: Dict[str, Any] = {"verify": verify}
    if endpoint_url:
        kwargs["endpoint_url"] = endpoint_url
    if region:
        kwargs["region_name"] = region
    if access_key_id and secret_access_key:
        kwargs["aws_access_key_id"] = access_key_id
        kwargs["aws_secret_access_key"] = secret_access_key
        if session_token:
            kwargs["aws_session_token"] = session_token

    return boto3.client("s3", **kwargs)


# =============================================================================
# Schema Helpers
# =============================================================================

def get_schema_fields_graphql(
    gms_host: str,
    dataset_urn: str,
    token: Optional[str] = None,
) -> List[Dict[str, str]]:
    """
    Get schema fields for a dataset via GraphQL.
    
    Args:
        gms_host: DataHub GMS host URL.
        dataset_urn: Dataset URN.
        token: Optional Bearer token.
    
    Returns:
        List of field dicts with 'fieldPath' and 'nativeDataType'.
    """
    query = """
    query getDataset($urn: String!) {
        dataset(urn: $urn) {
            schemaMetadata {
                fields {
                    fieldPath
                    nativeDataType
                }
            }
        }
    }
    """
    result = graphql_query(gms_host, query, {"urn": dataset_urn}, token)

    if "error" in result:
        return []

    dataset = result.get("data", {}).get("dataset")
    if not dataset:
        return []

    schema = dataset.get("schemaMetadata") or {}
    return schema.get("fields", [])


def extract_column_name(field_path: str) -> str:
    """
    Extract actual column name from DataHub fieldPath.
    
    DataHub fieldPath can be complex like:
    [version=2.0].[type=struct].[type=string].COLUMN_NAME
    
    Args:
        field_path: Raw fieldPath from DataHub.
    
    Returns:
        Extracted column name.
    """
    parts = field_path.split(".")
    for part in reversed(parts):
        if not part.startswith("["):
            return part
    return field_path
