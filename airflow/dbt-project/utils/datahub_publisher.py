from __future__ import annotations

import tempfile
from pathlib import Path
from typing import Optional, Dict, Any


def _publish_column_lineage_from_s3(
    s3_client,
    bucket: str,
    prefix: str,
    gms_host: str,
    token: Optional[str],
    platform: str = "iceberg",
    platform_instance: str = "demo",
    env: str = "PROD",
) -> Optional[Dict[str, Any]]:
    """Publish column-level lineage from dbt artifacts stored in S3."""
    if s3_client is None:
        return None

    prefix = prefix.strip("/")
    manifest_key = f"{prefix}/manifest.json"
    run_results_key = f"{prefix}/run_results.json"

    try:
        s3_client.head_object(Bucket=bucket, Key=manifest_key)
        s3_client.head_object(Bucket=bucket, Key=run_results_key)
    except Exception:
        print("⚠ Cannot publish column lineage: manifest.json or run_results.json not found")
        return None

    try:
        from utils.column_lineage_publisher import publish_column_lineage
    except ImportError:
        try:
            from column_lineage_publisher import publish_column_lineage
        except ImportError:
            print("⚠ Cannot import column_lineage_publisher")
            return None

    with tempfile.TemporaryDirectory() as tmpdir:
        tmp_path = Path(tmpdir)
        manifest_path = tmp_path / "manifest.json"
        run_results_path = tmp_path / "run_results.json"

        try:
            s3_client.download_file(bucket, manifest_key, str(manifest_path))
            s3_client.download_file(bucket, run_results_key, str(run_results_path))
        except Exception as e:
            print(f"⚠ Failed to download artifacts for column lineage: {e}")
            return None

        print("📊 Publishing column-level lineage (iceberg-to-iceberg)...")

        result = publish_column_lineage(
            gms_host=gms_host,
            token=token,
            manifest_path=str(manifest_path),
            run_results_path=str(run_results_path),
            platform=platform,
            platform_instance=platform_instance,
            env=env,
        )

        if result.get("status") == "ok":
            print(f"✅ Published column lineage: {result.get('processed', 0)} tables")
        else:
            print(f"⚠ Column lineage publish result: {result}")

        return result


def publish_dbt_to_datahub(
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
    skip_dbt_entities: bool = False,
) -> Dict[str, Any]:
    """
    Publish dbt metadata and column lineage to DataHub.
    
    Args:
        skip_dbt_entities: If True, skip dbt source ingestion entirely
            and only publish iceberg-to-iceberg column lineage. This avoids
            creating dbt platform entities in DataHub.
    """
    base_uri = f"s3://{bucket}/{prefix.strip('/')}"

    from urllib.parse import urlparse
    server = gms_host.rstrip("/")
    parsed = urlparse(server if "://" in server else f"http://{server}")
    if (parsed.port == 9002) and (parsed.path == "" or parsed.path == "/"):
        server = f"{server}/api/gms"

    def _s3_client():
        try:
            import boto3
            client_kwargs: Dict[str, Any] = {}
            if aws_endpoint_url:
                client_kwargs["endpoint_url"] = aws_endpoint_url
            if aws_region:
                client_kwargs["region_name"] = aws_region
            if aws_access_key_id and aws_secret_access_key:
                client_kwargs["aws_access_key_id"] = aws_access_key_id
                client_kwargs["aws_secret_access_key"] = aws_secret_access_key
                if aws_session_token:
                    client_kwargs["aws_session_token"] = aws_session_token
            return boto3.client("s3", **client_kwargs)
        except Exception:
            return None

    s3 = _s3_client()

    if skip_dbt_entities:
        print("⏭️  Skipping dbt source ingestion (skip_dbt_entities=True)")
        print("📊 Publishing iceberg-to-iceberg column lineage only...")

        column_lineage_result = _publish_column_lineage_from_s3(
            s3_client=s3,
            bucket=bucket,
            prefix=prefix,
            gms_host=server,
            token=token,
            platform="iceberg",
            platform_instance=target_platform_instance,
            env=env,
        )

        if column_lineage_result:
            print(f"📊 Column lineage result: {column_lineage_result}")

        return {
            "status": "ok" if column_lineage_result and column_lineage_result.get("status") == "ok" else "partial",
            "server": server,
            "base_uri": base_uri,
            "env": env,
            "platform_instance": target_platform_instance,
            "column_lineage": column_lineage_result,
            "dbt_ingestion": "skipped",
        }

    try:
        from datahub.ingestion.run.pipeline import Pipeline
    except Exception as e:
        raise RuntimeError(
            "acryl-datahub is required. Install with: uv pip install 'acryl-datahub[datahub-rest]'"
        ) from e

    source_config: Dict[str, Any] = {
        "target_platform": "iceberg",
        "target_platform_instance": target_platform_instance,
        "env": env,
        "manifest_path": f"{base_uri}/manifest.json",
        "run_results_paths": [],
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

    def _exists_in_s3(client, b: str, key: str) -> bool:
        if client is None:
            return False
        try:
            client.head_object(Bucket=b, Key=key)
            return True
        except Exception:
            return False

    rr_key = f"{prefix.strip('/')}/run_results.json"
    if _exists_in_s3(s3, bucket, rr_key):
        source_config["run_results_paths"] = [f"{base_uri}/run_results.json"]
        print(f"✓ Found run_results.json")
    
    cat_key = f"{prefix.strip('/')}/catalog.json"
    if _exists_in_s3(s3, bucket, cat_key):
        try:
            import json
            obj = s3.get_object(Bucket=bucket, Key=cat_key)
            catalog = json.loads(obj['Body'].read())
            node_count = len(catalog.get('nodes', {}))
            if node_count > 0:
                patched = False
                nodes = catalog.get('nodes') or {}
                for _, node in nodes.items():
                    cols = node.get('columns') or {}
                    if not isinstance(cols, dict):
                        continue
                    dirty = False
                    new_cols = {}
                    for col_name, meta in cols.items():
                        if any(ch in str(col_name) for ch in (" ", "\t", "\n", "(", ")", "=", ";")):
                            dirty = True
                            continue
                        if not isinstance(meta, dict):
                            meta = {"type": str(meta) if meta is not None else ""}
                            dirty = True
                        if meta.get("name") != col_name:
                            meta["name"] = col_name
                            dirty = True
                        if "description" not in meta and "comment" in meta:
                            meta["description"] = meta.pop("comment")
                            dirty = True
                        new_cols[col_name] = meta
                    if new_cols:
                        i = 1
                        for k in new_cols.keys():
                            if new_cols[k].get("index") != i:
                                new_cols[k]["index"] = i
                                dirty = True
                            i += 1
                    if dirty:
                        node["columns"] = new_cols
                        patched = True

                if patched:
                    patched_key = f"{prefix.strip('/')}/catalog.patched.json"
                    s3.put_object(Bucket=bucket, Key=patched_key, Body=json.dumps(catalog).encode("utf-8"))
                    source_config["catalog_path"] = f"{base_uri}/catalog.patched.json"
                    print(f"✓ Using catalog.patched.json with {node_count} nodes (sanitized columns)")
                else:
                    source_config["catalog_path"] = f"{base_uri}/catalog.json"
                    print(f"✓ Using catalog.json with {node_count} nodes")
            else:
                print("⚠ catalog.json is empty (0 nodes), skipping - will use manifest schemas instead")
        except Exception as e:
            print(f"⚠ Could not validate catalog.json: {e}, skipping")
    else:
        print("⚠ catalog.json not found in S3")
    
    # Check manifest for schema info
    manifest_key = f"{prefix.strip('/')}/manifest.json"
    if _exists_in_s3(s3, bucket, manifest_key):
        try:
            import json
            obj = s3.get_object(Bucket=bucket, Key=manifest_key)
            manifest = json.loads(obj['Body'].read())
            nodes = manifest.get('nodes', {})
            total_nodes = len(nodes)
            nodes_with_columns = sum(1 for n in nodes.values() if n.get('columns'))
            print(f"📊 manifest.json: {total_nodes} nodes, {nodes_with_columns} with column definitions")
            
            if nodes_with_columns == 0:
                print("⚠️  WARNING: manifest.json has NO column definitions!")
                print("   Add schema yml files or dbt will have no schema info to ingest")
            elif nodes_with_columns < total_nodes:
                print(f"⚠️  {total_nodes - nodes_with_columns} nodes missing column definitions in manifest")
        except Exception as e:
            print(f"Could not analyze manifest.json: {e}")
    
    src_key = f"{prefix.strip('/')}/sources.json"
    if _exists_in_s3(s3, bucket, src_key):
        source_config["sources_path"] = f"{base_uri}/sources.json"
        print(f"✓ Found sources.json")

    recipe = {
        "source": {
            "type": "dbt",
            "config": source_config,
        },
        "sink": {
            "type": "datahub-rest",
            "config": {
                "server": server,
                **({"token": token} if token else {}),
            },
        },
    }

    pipeline = Pipeline.create(recipe)
    pipeline.run()
    pipeline.raise_from_status()

    # Publish column-level lineage using SQL parsing
    column_lineage_result = _publish_column_lineage_from_s3(
        s3_client=s3,
        bucket=bucket,
        prefix=prefix,
        gms_host=server,
        token=token,
        platform="iceberg",
        platform_instance=target_platform_instance,
        env=env,
    )
    if column_lineage_result:
        print(f"📊 Column lineage: {column_lineage_result}")

    return {
        "status": "ok",
        "server": server,
        "base_uri": base_uri,
        "env": env,
        "platform_instance": target_platform_instance,
        "column_lineage": column_lineage_result,
    }


def publish_iceberg_catalog_to_datahub(
    gms_host: str,
    token: Optional[str],
    env: str,
    catalog_type: str,
    catalog_name: str,
    uri: Optional[str] = None,
    warehouse: Optional[str] = None,
    s3_endpoint: Optional[str] = None,
    s3_region: Optional[str] = None,
    s3_access_key_id: Optional[str] = None,
    s3_secret_access_key: Optional[str] = None,
    s3_session_token: Optional[str] = None,
    s3_path_style_access: Optional[bool] = None,
    s3_ssl_enabled: Optional[bool] = None,
) -> Dict[str, Any]:
    try:
        from datahub.ingestion.run.pipeline import Pipeline  # type: ignore
    except Exception as e:  # pragma: no cover
        raise RuntimeError(
            "acryl-datahub is required. Install with: uv pip install 'acryl-datahub[datahub-rest]'"
        ) from e

    from urllib.parse import urlparse
    server = gms_host.rstrip("/")
    parsed = urlparse(server if "://" in server else f"http://{server}")
    if (parsed.port == 9002) and (parsed.path == "" or parsed.path == "/"):
        server = f"{server}/api/gms"

    cat_cfg: Dict[str, Any] = {"type": catalog_type}
    if uri:
        cat_cfg["uri"] = uri
    if warehouse:
        cat_cfg["warehouse"] = warehouse
    # Pass through s3.* options supported by pyiceberg
    if s3_endpoint:
        cat_cfg["s3.endpoint"] = s3_endpoint
    if s3_region:
        cat_cfg["s3.region"] = s3_region
    if s3_access_key_id:
        cat_cfg["s3.access-key-id"] = s3_access_key_id
    if s3_secret_access_key:
        cat_cfg["s3.secret-access-key"] = s3_secret_access_key
    if s3_session_token:
        cat_cfg["s3.session-token"] = s3_session_token
    if s3_path_style_access is not None:
        cat_cfg["s3.path-style-access"] = s3_path_style_access
    if s3_ssl_enabled is not None:
        cat_cfg["s3.ssl.enabled"] = s3_ssl_enabled

    recipe = {
        "source": {
            "type": "iceberg",
            "config": {
                "env": env,
                "catalog": {catalog_name: cat_cfg},
            },
        },
        "sink": {
            "type": "datahub-rest",
            "config": {
                "server": server,
                **({"token": token} if token else {}),
            },
        },
    }

    pipeline = Pipeline.create(recipe)
    pipeline.run()
    pipeline.raise_from_status()

    return {
        "status": "ok",
        "server": server,
        "env": env,
        "catalog_type": catalog_type,
        "catalog_name": catalog_name,
    }


def publish_iceberg_from_catalog(
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
    from urllib.parse import urlparse
    import json
    try:
        import boto3  # type: ignore
    except Exception as e:  # pragma: no cover
        raise RuntimeError("boto3 required to read catalog.json from S3") from e
    try:
        import requests  # type: ignore
    except Exception as e:  # pragma: no cover
        raise RuntimeError("requests is required to call DataHub REST API") from e

    server = gms_host.rstrip("/")
    parsed = urlparse(server if "://" in server else f"http://{server}")
    if (parsed.port == 9002) and (parsed.path == "" or parsed.path == "/"):
        server = f"{server}/api/gms"

    s3_client_kwargs: Dict[str, Any] = {}
    if aws_endpoint_url:
        s3_client_kwargs["endpoint_url"] = aws_endpoint_url
    if aws_region:
        s3_client_kwargs["region_name"] = aws_region
    if aws_access_key_id and aws_secret_access_key:
        s3_client_kwargs["aws_access_key_id"] = aws_access_key_id
        s3_client_kwargs["aws_secret_access_key"] = aws_secret_access_key
        if aws_session_token:
            s3_client_kwargs["aws_session_token"] = aws_session_token

    s3 = boto3.client("s3", **s3_client_kwargs)
    key = f"{prefix.strip('/')}/catalog.json"
    obj = s3.get_object(Bucket=bucket, Key=key)
    catalog = json.loads(obj["Body"].read())

    def _build_dataset_urn(dataset_name: str) -> str:
        return f"urn:li:dataset:(urn:li:dataPlatform:iceberg,{dataset_name},{env})"

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
            "aspect": {
                "value": json.dumps(aspect_obj),
                "contentType": "application/json",
            },
        }
        payload = {"proposal": proposal}
        resp = requests.post(url, headers=_headers(), json=payload, timeout=30)
        if not resp.ok:
            raise RuntimeError(f"Failed to ingest {aspect_name} for {entity_urn}: {resp.status_code} {resp.text}")

    def _schema_type(col_type: Optional[str]) -> Dict[str, Any]:
        t = (col_type or "").lower()
        variant = "StringType"
        if any(x in t for x in ["int", "decimal", "double", "float", "number"]):
            variant = "NumberType"
        elif any(x in t for x in ["bool"]):
            variant = "BooleanType"
        elif any(x in t for x in ["date", "timestamp"]):
            variant = "TimeType" if "time" in t or "timestamp" in t else "DateType"
        return {"type": {f"com.linkedin.schema.{variant}": {}}}

    nodes: Dict[str, Any] = catalog.get("nodes") or {}
    total_nodes = len(nodes)
    print(f"📊 Iceberg publisher: found {total_nodes} nodes in catalog.json")
    
    if total_nodes == 0:
        print("⚠️  No nodes in catalog.json - cannot emit Iceberg schemas!")
        print("   This happens because dbt-spark can't introspect Iceberg tables from HMS.")
        print("   Schemas will come from dbt source (manifest) instead, under 'iceberg' platform.")
        return {"status": "skipped", "reason": "empty_catalog", "emitted": 0}
    
    emitted = 0
    for node_id, node in nodes.items():
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
            print(f"⚠️  Skipping {name} - no columns in catalog")
            continue
            
        fields = []
        for col_name, col_meta in cols.items():
            native = col_meta.get("type") or col_meta.get("data_type") or ""
            desc = col_meta.get("description")
            fields.append(
                {
                    "fieldPath": col_name,
                    "type": _schema_type(native),
                    "nullable": True,
                    "nativeDataType": native,
                    **({"description": desc} if desc else {}),
                }
            )

        if fields:
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
                try:
                    print(f"DataHub REST: emitted schema for {du} with {len(fields)} fields")
                except Exception:
                    pass
            emitted += 1

            if platform_instance:
                dpi_aspect = {
                    "platform": "urn:li:dataPlatform:iceberg",
                    "instance": f"urn:li:dataPlatformInstance:(urn:li:dataPlatform:iceberg,{platform_instance})",
                }
                for du in dataset_urns:
                    _ingest_mcp(du, "dataPlatformInstance", dpi_aspect)

    print(f"\n✅ Iceberg publisher: emitted {emitted} datasets to DataHub")
    if emitted == 0:
        print("⚠️  WARNING: No datasets were emitted because catalog.json has no column data")
    
    return {
        "status": "ok",
        "server": server,
        "base_uri": f"s3://{bucket}/{prefix.strip('/')}",
        "datasets_emitted": emitted,
        "platform": "iceberg",
        "platform_instance": platform_instance,
    }
