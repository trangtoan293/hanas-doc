from __future__ import annotations

import hashlib
import json
from datetime import datetime
from typing import Any, Dict, Optional
from urllib.parse import urlparse


def _normalize_gms_host(gms_host: str) -> str:
    server = (gms_host or "").rstrip("/")
    parsed = urlparse(server if "://" in server else f"http://{server}")
    if (parsed.port == 9002) and (parsed.path == "" or parsed.path == "/"):
        server = f"{server}/api/gms"
    return server


def _make_s3_client(
    *,
    aws_endpoint_url: Optional[str] = None,
    aws_region: Optional[str] = None,
    aws_access_key_id: Optional[str] = None,
    aws_secret_access_key: Optional[str] = None,
    aws_session_token: Optional[str] = None,
    verify: Any = True,
):
    try:
        import boto3  # type: ignore
    except Exception:
        return None

    kwargs: Dict[str, Any] = {"verify": verify}
    if aws_endpoint_url:
        kwargs["endpoint_url"] = aws_endpoint_url
    if aws_region:
        kwargs["region_name"] = aws_region
    if aws_access_key_id and aws_secret_access_key:
        kwargs["aws_access_key_id"] = aws_access_key_id
        kwargs["aws_secret_access_key"] = aws_secret_access_key
        if aws_session_token:
            kwargs["aws_session_token"] = aws_session_token

    return boto3.client("s3", **kwargs)


def publish_dbt_to_datahub(
    *,
    gms_host: str,
    token: Optional[str],
    bucket: str,
    prefix: str,
    aws_endpoint_url: Optional[str] = None,
    aws_region: Optional[str] = None,
    aws_access_key_id: Optional[str] = None,
    aws_secret_access_key: Optional[str] = None,
    aws_session_token: Optional[str] = None,
    env: str = "PROD",
    target_platform_instance: str = "demo",
) -> Dict[str, Any]:
    server = _normalize_gms_host(gms_host)
    base_uri = f"s3://{bucket}/{prefix.strip('/')}"

    try:
        from datahub.ingestion.run.pipeline import Pipeline  # type: ignore
    except Exception as e:
        raise RuntimeError(
            "acryl-datahub is required. Install with: uv pip install 'acryl-datahub[datahub-rest,dbt]'"
        ) from e

    source_config: Dict[str, Any] = {
        "target_platform": "iceberg",
        "target_platform_instance": target_platform_instance,
        "env": env,
        "manifest_path": f"{base_uri}/manifest.json",
        "run_results_paths": [f"{base_uri}/run_results.json"],
        "infer_dbt_schemas": True,
        "include_column_lineage": False,
        "include_database_name": True,
    }

    if any([aws_endpoint_url, aws_region, aws_access_key_id, aws_secret_access_key, aws_session_token]):
        source_config["aws_connection"] = {
            "aws_endpoint_url": aws_endpoint_url,
            "aws_region": aws_region,
            "aws_access_key_id": aws_access_key_id,
            "aws_secret_access_key": aws_secret_access_key,
            "aws_session_token": aws_session_token,
        }

    recipe = {
        "source": {"type": "dbt", "config": source_config},
        "sink": {
            "type": "datahub-rest",
            "config": {"server": server, **({"token": token} if token else {})},
        },
    }

    pipeline = Pipeline.create(recipe)
    pipeline.run()
    pipeline.raise_from_status()

    return {
        "status": "ok",
        "server": server,
        "base_uri": base_uri,
        "env": env,
        "platform_instance": target_platform_instance,
    }


def publish_iceberg_from_catalog(
    *,
    gms_host: str,
    token: Optional[str],
    bucket: str,
    prefix: str,
    env: str = "PROD",
    platform_instance: str = "LakeHouse",
    include_database_in_name: bool = True,
    emit_both_name_variants: bool = False,
    aws_endpoint_url: Optional[str] = None,
    aws_region: Optional[str] = None,
    aws_access_key_id: Optional[str] = None,
    aws_secret_access_key: Optional[str] = None,
    aws_session_token: Optional[str] = None,
) -> Dict[str, Any]:
    try:
        import requests  # type: ignore
    except Exception as e:
        raise RuntimeError("requests is required") from e

    server = _normalize_gms_host(gms_host)

    s3 = _make_s3_client(
        aws_endpoint_url=aws_endpoint_url,
        aws_region=aws_region,
        aws_access_key_id=aws_access_key_id,
        aws_secret_access_key=aws_secret_access_key,
        aws_session_token=aws_session_token,
    )
    if s3 is None:
        raise RuntimeError("boto3 is required")

    key = f"{prefix.strip('/')}/catalog.json"
    obj = s3.get_object(Bucket=bucket, Key=key)
    catalog = json.loads(obj["Body"].read())

    def _headers() -> Dict[str, str]:
        h = {"Content-Type": "application/json", "X-RestLi-Protocol-Version": "2.0.0"}
        if token:
            h["Authorization"] = f"Bearer {token}"
        return h

    def _ingest_mcp(entity_urn: str, aspect_name: str, aspect_obj: Dict[str, Any]) -> None:
        url = f"{server}/aspects?action=ingestProposal"
        proposal = {
            "entityType": "dataset",
            "entityUrn": entity_urn,
            "changeType": "UPSERT",
            "aspectName": aspect_name,
            "aspect": {"value": json.dumps(aspect_obj), "contentType": "application/json"},
        }
        resp = requests.post(url, headers=_headers(), json={"proposal": proposal}, timeout=30)
        if not resp.ok:
            raise RuntimeError(f"Failed to ingest {aspect_name} for {entity_urn}: {resp.status_code} {resp.text}")

    def _build_dataset_urn(dataset_name: str) -> str:
        return f"urn:li:dataset:(urn:li:dataPlatform:iceberg,{dataset_name},{env})"

    nodes: Dict[str, Any] = catalog.get("nodes") or {}
    emitted = 0

    for _, node in nodes.items():
        meta = node.get("metadata") or {}
        database = (meta.get("database") or node.get("database") or "").strip()
        schema = (meta.get("schema") or node.get("schema") or "").strip()
        name = (meta.get("alias") or meta.get("name") or node.get("alias") or node.get("name") or "").strip()
        if not name or not schema:
            continue

        name_with_db = f"{database}.{schema}.{name}" if database else f"{schema}.{name}"
        name_no_db = f"{schema}.{name}"
        primary_name = name_with_db if include_database_in_name else name_no_db

        dataset_names = [primary_name]
        if emit_both_name_variants:
            alt = name_no_db if include_database_in_name else name_with_db
            if alt not in dataset_names:
                dataset_names.append(alt)

        dataset_urns = [_build_dataset_urn(n) for n in dataset_names]

        cols = node.get("columns") or {}
        if not cols:
            continue

        fields = []
        for col_name, col_meta in cols.items():
            native = ""
            if isinstance(col_meta, dict):
                native = col_meta.get("type") or col_meta.get("data_type") or ""
            fields.append(
                {
                    "fieldPath": col_name,
                    "type": {"type": {"com.linkedin.schema.StringType": {}}},
                    "nullable": True,
                    "nativeDataType": native,
                }
            )

        schema_aspect = {
            "schemaName": primary_name,
            "platform": "urn:li:dataPlatform:iceberg",
            "version": 0,
            "hash": "",
            "platformSchema": {"com.linkedin.schema.OtherSchema": {"rawSchema": ""}},
            "fields": fields,
        }

        for du in dataset_urns:
            _ingest_mcp(du, "schemaMetadata", schema_aspect)

        if platform_instance:
            dpi_aspect = {
                "platform": "urn:li:dataPlatform:iceberg",
                "instance": f"urn:li:dataPlatformInstance:(urn:li:dataPlatform:iceberg,{platform_instance})",
            }
            for du in dataset_urns:
                _ingest_mcp(du, "dataPlatformInstance", dpi_aspect)

        emitted += 1

    return {
        "status": "ok",
        "server": server,
        "base_uri": f"s3://{bucket}/{prefix.strip('/')}" ,
        "datasets_emitted": emitted,
        "platform": "iceberg",
        "platform_instance": platform_instance,
    }


def publish_test_results_to_datahub(
    *,
    gms_host: str,
    token: Optional[str],
    bucket: str,
    prefix: str,
    platform: str = "iceberg",
    platform_instance: str = "demo",
    env: str = "PROD",
    aws_endpoint_url: Optional[str] = None,
    aws_region: Optional[str] = None,
    aws_access_key_id: Optional[str] = None,
    aws_secret_access_key: Optional[str] = None,
    aws_session_token: Optional[str] = None,
) -> Dict[str, Any]:
    try:
        import requests  # type: ignore
    except Exception as e:
        raise RuntimeError("requests is required") from e

    server = _normalize_gms_host(gms_host)

    s3 = _make_s3_client(
        aws_endpoint_url=aws_endpoint_url,
        aws_region=aws_region,
        aws_access_key_id=aws_access_key_id,
        aws_secret_access_key=aws_secret_access_key,
        aws_session_token=aws_session_token,
    )
    if s3 is None:
        raise RuntimeError("boto3 is required")

    prefix = prefix.strip("/")
    rr_key = f"{prefix}/run_results.json"
    obj = s3.get_object(Bucket=bucket, Key=rr_key)
    run_results = json.loads(obj["Body"].read())

    results = run_results.get("results", [])
    test_results = [r for r in results if str(r.get("unique_id", "")).startswith("test.")]

    if not test_results:
        return {"status": "ok", "total_tests": 0, "passed": 0, "failed": 0}

    def _assertion_urn(test_unique_id: str) -> str:
        digest = hashlib.md5(test_unique_id.encode("utf-8")).hexdigest()[:16]
        return f"urn:li:assertion:{digest}"

    def _headers() -> Dict[str, str]:
        h = {"Content-Type": "application/json", "X-RestLi-Protocol-Version": "2.0.0"}
        if token:
            h["Authorization"] = f"Bearer {token}"
        return h

    def _ingest_mcp(entity_type: str, entity_urn: str, aspect_name: str, aspect_obj: Dict[str, Any]) -> bool:
        url = f"{server}/aspects?action=ingestProposal"
        proposal = {
            "entityType": entity_type,
            "entityUrn": entity_urn,
            "changeType": "UPSERT",
            "aspectName": aspect_name,
            "aspect": {"value": json.dumps(aspect_obj), "contentType": "application/json"},
        }
        resp = requests.post(url, headers=_headers(), json={"proposal": proposal}, timeout=30)
        return bool(resp.ok)

    created = 0
    events = 0

    for r in test_results:
        test_id = str(r.get("unique_id", ""))
        test_name = test_id.split(".")[-1] if "." in test_id else test_id
        status = str(r.get("status", "")).lower()

        assertion_urn = _assertion_urn(test_id)

        assertion_info = {
            "type": "DATASET",
            "customProperties": {"dbt_test_unique_id": test_id, "dbt_test_name": test_name},
            "description": f"dbt test: {test_name}",
            "datasetAssertion": {"scope": "DATASET_ROWS", "operator": "CUSTOM"},
        }

        if _ingest_mcp("assertion", assertion_urn, "assertionInfo", assertion_info):
            created += 1

        assertion_result = "SUCCESS" if status == "pass" else "FAILURE"

        run_event = {
            "timestampMillis": int(datetime.utcnow().timestamp() * 1000),
            "assertionUrn": assertion_urn,
            "runId": run_results.get("metadata", {}).get("invocation_id", "unknown"),
            "status": "COMPLETE",
            "result": {"type": assertion_result, "nativeResults": {"status": status}},
        }

        if _ingest_mcp("assertion", assertion_urn, "assertionRunEvent", run_event):
            events += 1

    return {
        "status": "ok",
        "server": server,
        "assertions_created": created,
        "run_events_created": events,
        "total_tests": len(test_results),
        "passed": sum(1 for r in test_results if str(r.get("status", "")).lower() == "pass"),
        "failed": sum(1 for r in test_results if str(r.get("status", "")).lower() != "pass"),
    }
