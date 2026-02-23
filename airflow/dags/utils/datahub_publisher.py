from __future__ import annotations

import tempfile
from pathlib import Path
from typing import Optional, Dict, Any


def build_dataset_urn(
    platform: str,
    platform_instance: str,
    schema: str,
    table: str,
    env: str,
    database: Optional[str] = None,
    include_database: bool = False,
) -> str:
    """
    Build a DataHub dataset URN for any platform.
    
    Args:
        platform: Platform name (e.g., "iceberg", "dbt").
        platform_instance: Instance name (e.g., "demo").
        schema: Schema name.
        table: Table name.
        env: Environment (e.g., "PROD").
        database: Optional database/catalog name.
        include_database: If True and database is provided, include it in the name.
    
    Returns:
        URN string like: urn:li:dataset:(urn:li:dataPlatform:{platform},{platform_instance}.{schema}.{table},{env})
    """
    if include_database and database:
        dataset_name = f"{platform_instance}.{database}.{schema}.{table}"
    else:
        dataset_name = f"{platform_instance}.{schema}.{table}"
    return f"urn:li:dataset:(urn:li:dataPlatform:{platform},{dataset_name},{env})"


def _publish_column_lineage_from_s3(
    s3_client,
    bucket: str,
    prefix: str,
    gms_host: str,
    token: Optional[str],
    iceberg_platform_instance: str = "demo",
    dbt_platform_instance: str = "demo",
    env: str = "PROD",
    emit_to_dbt_platform: bool = True,
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

        print("📊 Publishing column-level lineage (iceberg + dbt platforms)...")

        result = publish_column_lineage(
            gms_host=gms_host,
            token=token,
            manifest_path=str(manifest_path),
            run_results_path=str(run_results_path),
            iceberg_platform_instance=iceberg_platform_instance,
            dbt_platform_instance=dbt_platform_instance,
            env=env,
            emit_to_dbt_platform=emit_to_dbt_platform,
        )

        if result.get("status") == "ok":
            iceberg_count = result.get('processed_iceberg', result.get('processed', 0))
            dbt_count = result.get('processed_dbt', 0)
            print(f"✅ Published column lineage: {iceberg_count} iceberg tables, {dbt_count} dbt models")
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
    iceberg_platform_instance: str = "demo",
    dbt_platform_instance: str = "demo",
    skip_dbt_entities: bool = False,
    skip_column_lineage: bool = False,
    asset_tag_name: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Publish dbt metadata and column lineage to DataHub.
    
    Args:
        iceberg_platform_instance: Platform instance for Iceberg URNs (default: "demo").
        dbt_platform_instance: Platform instance for dbt URNs (default: "demo").
        skip_dbt_entities: If True, skip dbt source ingestion entirely
            and only publish iceberg-to-iceberg column lineage. This avoids
            creating dbt platform entities in DataHub.
        skip_column_lineage: If True, skip column lineage publishing.
            Default is False (publish lineage). Set to True for /test folders.
        asset_tag_name: If provided, automatically add this tag to all ingested
            datasets. The tag URN will be urn:li:tag:<tag_name_with_underscores>.
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
            iceberg_platform_instance=iceberg_platform_instance,
            dbt_platform_instance=dbt_platform_instance,
            env=env,
        )

        if column_lineage_result:
            print(f"📊 Column lineage result: {column_lineage_result}")

        return {
            "status": "ok" if column_lineage_result and column_lineage_result.get("status") == "ok" else "partial",
            "server": server,
            "base_uri": base_uri,
            "env": env,
            "iceberg_platform_instance": iceberg_platform_instance,
            "dbt_platform_instance": dbt_platform_instance,
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
        "target_platform_instance": iceberg_platform_instance,
        "env": env,
        "manifest_path": f"{base_uri}/manifest.json",
        "run_results_paths": [],
        "infer_dbt_schemas": True,
        "include_column_lineage": False,
        "include_database_name": False,  # Default to {platform_instance}.{schema}.{table}
        "enable_meta_mapping": False,
        "platform_instance": dbt_platform_instance,
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

    # Add transformer to automatically tag datasets
    if asset_tag_name:
        tag_urn = f"urn:li:tag:{asset_tag_name}"
        recipe["transformers"] = [
            {
                "type": "simple_add_dataset_tags",
                "config": {
                    "tag_urns": [tag_urn]
                }
            }
        ]
        print(f"🏷️ Will apply tag: {tag_urn}")

    pipeline = Pipeline.create(recipe)
    pipeline.run()
    pipeline.raise_from_status()

    # Publish column-level lineage using SQL parsing (skip for test folders)
    column_lineage_result = None
    if not skip_column_lineage:
        column_lineage_result = _publish_column_lineage_from_s3(
            s3_client=s3,
            bucket=bucket,
            prefix=prefix,
            gms_host=server,
            token=token,
            iceberg_platform_instance=iceberg_platform_instance,
            dbt_platform_instance=dbt_platform_instance,
            env=env,
            emit_to_dbt_platform=True,  # Ensure dbt lineage is emitted
        )
        if column_lineage_result:
            print(f"📊 Column lineage: {column_lineage_result}")
    else:
        print("ℹ️ Skipping column lineage (skip_column_lineage=True)")
        column_lineage_result = {"status": "skipped", "reason": "skip_column_lineage=True"}



    # Manually emit SubTypes for dbt models if manifest is available
    if not skip_dbt_entities:
        try:
            print("🔧 Manually updating dbt model SubTypes...")
            
            # Load manifest if not already loaded available
            manifest_to_process = None
            if 'manifest' in locals():
                manifest_to_process = locals()['manifest']
            else:
                # Try to load again
                manifest_key = f"{prefix.strip('/')}/manifest.json"
                if _exists_in_s3(s3, bucket, manifest_key):
                    obj = s3.get_object(Bucket=bucket, Key=manifest_key)
                    manifest_to_process = json.loads(obj['Body'].read())
            
            if manifest_to_process:
                nodes = manifest_to_process.get('nodes', {})
                dbt_subtypes_emitted = 0
                
                # Setup helper for ingestion
                def _headers_local() -> Dict[str, str]:
                    h = {"Content-Type": "application/json", "X-RestLi-Protocol-Version": "2.0.0"}
                    if token:
                        h["Authorization"] = f"Bearer {token}"
                    return h

                def _ingest_local(urn: str, aspect: str, payload: Dict) -> None:
                    u = f"{server}/aspects?action=ingestProposal"
                    prop = {
                        "proposal": {
                            "entityType": "dataset",
                            "entityUrn": urn,
                            "changeType": "UPSERT",
                            "aspectName": aspect,
                            "aspect": {"value": json.dumps(payload), "contentType": "application/json"}
                        }
                    }
                    try:
                        import requests
                        requests.post(u, headers=_headers_local(), json=prop, timeout=10)
                    except Exception:
                        pass

                for unique_id, node in nodes.items():
                    resource_type = node.get("resource_type")
                    if resource_type not in ["model", "seed", "snapshot", "source"]:
                        continue
                        
                    # Map resource type to subtype
                    subtype = "Model"
                    if resource_type == "seed":
                        subtype = "Seed"
                    elif resource_type == "snapshot":
                        subtype = "Snapshot"
                    elif resource_type == "source":
                        subtype = "Source"
                    
                    # Also include materialization if available for models
                    materialized = node.get("config", {}).get("materialized")
                    
                    subtypes_list = [subtype]
                    # if materialized and materialized not in ["table", "view", "incremental"]:
                    #    subtypes_list.append(materialized.replace("_", " ").title())

                    # Build URN
                    schema = node.get("schema")
                    name = node.get("alias") or node.get("name")
                    if not schema or not name:
                        continue
                        
                    urn = build_dataset_urn("dbt", dbt_platform_instance, schema, name, env)
                    
                    # Emit SubTypes
                    _ingest_local(urn, "subTypes", {"typeNames": subtypes_list})
                    dbt_subtypes_emitted += 1

                    # Emit Siblings (Link to Iceberg table)
                    iceberg_urn = build_dataset_urn("iceberg", iceberg_platform_instance, schema, name, env)
                    _ingest_local(urn, "siblings", {
                        "primary": True,
                        "siblings": [iceberg_urn]
                    })

                    # Emit datasetProperties (Friendly display name)
                    description = node.get("description", "")
                    _ingest_local(urn, "datasetProperties", {
                        "name": name,
                        "qualifiedName": f"{schema}.{name}",
                        "description": description if description else None,
                        "customProperties": {
                            "dbt_unique_id": unique_id,
                            "materialized": materialized or "unknown",
                        }
                    })
                
                print(f"✅ Updated SubTypes, Siblings, and Properties for {dbt_subtypes_emitted} dbt entities")
        except Exception as e:
            print(f"⚠️ Could not manually update dbt SubTypes: {e}")

    return {
        "status": "ok",
        "server": server,
        "base_uri": base_uri,
        "env": env,
        "iceberg_platform_instance": iceberg_platform_instance,
        "dbt_platform_instance": dbt_platform_instance,
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


def publish_test_results_to_datahub(
    gms_host: str,
    token: Optional[str],
    bucket: str,
    prefix: str,
    iceberg_platform_instance: str = "demo",
    dbt_platform_instance: str = "demo",
    env: str = "PROD",
    aws_endpoint_url: Optional[str] = None,
    aws_region: Optional[str] = None,
    aws_access_key_id: Optional[str] = None,
    aws_secret_access_key: Optional[str] = None,
    aws_session_token: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Parse run_results.json from S3 and push dbt test results to DataHub
    as Data Quality assertions.
    
    This creates:
    1. AssertionInfo aspects for each unique dbt test
    2. AssertionRunEvent timeseries aspects for each test execution
    
    Args:
        gms_host: DataHub GMS server URL
        token: DataHub access token (optional)
        bucket: S3 bucket containing dbt artifacts
        prefix: S3 prefix path to artifacts folder
        iceberg_platform_instance: Platform instance for Iceberg URNs (default: "demo")
        dbt_platform_instance: Platform instance for dbt URNs (default: "demo")
        env: DataHub environment (PROD, DEV, etc.)
        aws_*: AWS/S3 credentials and configuration
    
    Returns:
        Dict with status, counts of assertions created, and any errors
    """
    import json
    import hashlib
    from datetime import datetime
    from urllib.parse import urlparse
    
    try:
        import boto3
        import requests
    except ImportError as e:
        return {"status": "error", "error": f"Required packages not available: {e}"}
    
    # Normalize GMS server URL
    server = gms_host.rstrip("/")
    parsed = urlparse(server if "://" in server else f"http://{server}")
    if (parsed.port == 9002) and (parsed.path == "" or parsed.path == "/"):
        server = f"{server}/api/gms"
    
    # Setup S3 client
    s3_kwargs: Dict[str, Any] = {}
    if aws_endpoint_url:
        s3_kwargs["endpoint_url"] = aws_endpoint_url
    if aws_region:
        s3_kwargs["region_name"] = aws_region
    if aws_access_key_id and aws_secret_access_key:
        s3_kwargs["aws_access_key_id"] = aws_access_key_id
        s3_kwargs["aws_secret_access_key"] = aws_secret_access_key
        if aws_session_token:
            s3_kwargs["aws_session_token"] = aws_session_token
    
    s3 = boto3.client("s3", **s3_kwargs)
    
    # Download run_results.json
    prefix = prefix.strip("/")
    rr_key = f"{prefix}/run_results.json"
    
    try:
        print(f"📥 Downloading s3://{bucket}/{rr_key}")
        obj = s3.get_object(Bucket=bucket, Key=rr_key)
        run_results = json.loads(obj["Body"].read())
    except Exception as e:
        print(f"⚠️ Failed to download run_results.json: {e}")
        return {"status": "error", "error": str(e)}
    
    # Filter for test results only
    results = run_results.get("results", [])
    test_results = [r for r in results if r.get("unique_id", "").startswith("test.")]
    
    if not test_results:
        print("ℹ️ No test results found in run_results.json")
        return {"status": "ok", "assertions_created": 0, "message": "No tests found"}
    
    print(f"📊 Found {len(test_results)} test results to publish")
    
    # Also load manifest to get test -> dataset relationships and schemas
    manifest_key = f"{prefix}/manifest.json"
    model_refs: Dict[str, str] = {}
    model_schemas: Dict[str, str] = {}
    
    try:
        man_obj = s3.get_object(Bucket=bucket, Key=manifest_key)
        manifest = json.loads(man_obj["Body"].read())
        nodes = manifest.get("nodes", {})
        
        # First pass: map model names to schemas
        for node_id, node in nodes.items():
            if node_id.startswith("model."):
                name = node.get("name")
                schema = node.get("schema")
                if name and schema:
                    model_schemas[name] = schema

        # Second pass: map tests to models and extract descriptions
        test_descriptions: Dict[str, str] = {}
        for node_id, node in nodes.items():
            if node_id.startswith("test."):
                # Get description from manifest (dbt generates these)
                desc = node.get("description", "")
                # If no description, try to build from test metadata
                if not desc:
                    test_meta = node.get("test_metadata", {})
                    test_type = test_meta.get("name", "")  # e.g., "not_null", "unique"
                    kwargs = test_meta.get("kwargs", {})
                    column_name = kwargs.get("column_name", "")
                    
                    if test_type == "not_null" and column_name:
                        desc = f"Column {column_name} values are not null"
                    elif test_type == "unique" and column_name:
                        desc = f"Unique value proportion for column {column_name} is equal to 1"
                    elif test_type and column_name:
                        desc = f"{test_type.replace('_', ' ').title()} test for column {column_name}"
                
                if desc:
                    test_descriptions[node_id] = desc
                
                # Get refs (models this test is attached to)
                refs = node.get("refs", [])
                if refs:
                    # First ref is typically the main model being tested
                    first_ref = refs[0]
                    if isinstance(first_ref, dict):
                        model_refs[node_id] = first_ref.get("name", "")
                    elif isinstance(first_ref, list) and first_ref:
                        model_refs[node_id] = first_ref[-1]  # Last element is model name
                    else:
                        model_refs[node_id] = str(first_ref)
                # Fallback: try depends_on
                if node_id not in model_refs or not model_refs[node_id]:
                    deps = node.get("depends_on", {}).get("nodes", [])
                    for dep in deps:
                        if dep.startswith("model."):
                            model_name = dep.split(".")[-1]
                            model_refs[node_id] = model_name
                            break
    except Exception as e:
        print(f"⚠️ Could not load manifest.json for model refs: {e}")
    
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
            "aspect": {
                "value": json.dumps(aspect_obj),
                "contentType": "application/json",
            },
        }
        payload = {"proposal": proposal}
        try:
            resp = requests.post(url, headers=_headers(), json=payload, timeout=30)
            if not resp.ok:
                print(f"⚠️ Failed to ingest {aspect_name} for {entity_urn}: {resp.status_code} {resp.text}")
                return False
            return True
        except Exception as e:
            print(f"⚠️ Error ingesting {aspect_name}: {e}")
            return False

    def _generate_assertion_urn(test_unique_id: str) -> str:
        # Generate a stable URN based on test unique_id
        hash_val = hashlib.md5(test_unique_id.encode()).hexdigest()[:16]
        return f"urn:li:assertion:{hash_val}"
    
    
    assertions_created = 0
    
    assertions_created = 0
    run_events_created = 0
    errors = []
    
    for result in test_results:
        test_id = result.get("unique_id", "")
        # test_id format: test.project.test_type_model_column.hash
        # Example: test.ktl_dbt.not_null_mdm_corecif_cleansed_CIF_NO.abc123
        parts = test_id.split(".")
        if len(parts) >= 3:
            # Get the test definition part (e.g., not_null_mdm_corecif_cleansed_CIF_NO)
            test_def = parts[2] if len(parts) > 2 else parts[-1]
            test_name = test_def
        else:
            test_name = test_id.split(".")[-1] if "." in test_id else test_id
        
        # Create a human-readable display name
        display_name = test_name.replace("_", " ").title()
        
        # Use manifest description if available (more descriptive)
        final_description = test_descriptions.get(test_id, display_name)
        
        status = result.get("status", "").lower()
        message = result.get("message", "")
        failures = result.get("failures", 0)
        
        # Get timing info
        timing = result.get("timing", [])
        completed_at = None
        for t in timing:
            if t.get("name") == "execute" and t.get("completed_at"):
                completed_at = t.get("completed_at")
                break
        
        if not completed_at:
            completed_at = datetime.utcnow().isoformat() + "Z"
        
        assertion_urn = _generate_assertion_urn(test_id)
        
        # Create AssertionInfo aspect
        assertion_info = {
            "type": "DATASET",
            "customProperties": {
                "dbt_test_unique_id": test_id,
                "dbt_test_name": test_name,
            },
            "description": final_description,
            "source": {
                "type": "EXTERNAL",
                "sourceType": "dbt",
            },
            "datasetAssertion": {
                "scope": "DATASET_ROWS",
                "operator": "_NATIVE_",
                "nativeType": final_description,
            },
        }
        
        # Link assertion to dataset if we know the model
        model_name = model_refs.get(test_id)
        if model_name:
            # Use discovered schema or default to integration
            schema = model_schemas.get(model_name, "integration")
            # Use dbt platform URN for assertion (shows dbt logo in DataHub)
            dbt_dataset_urn = build_dataset_urn(
                platform="dbt",
                platform_instance=dbt_platform_instance,
                schema=schema,
                table=model_name,
                env=env,
            )
            assertion_info["datasetAssertion"]["dataset"] = dbt_dataset_urn
        
        if _ingest_mcp("assertion", assertion_urn, "assertionInfo", assertion_info):
            assertions_created += 1
            print(f"✅ Created assertion: {test_name}")
        
        # Create AssertionRunEvent
        assertion_result = "SUCCESS" if status == "pass" else "FAILURE"
        
        run_event = {
            "timestampMillis": int(datetime.fromisoformat(completed_at.replace("Z", "+00:00")).timestamp() * 1000),
            "assertionUrn": assertion_urn,
            "asserteeUrn": build_dataset_urn(
                platform="iceberg",
                platform_instance=iceberg_platform_instance,
                schema=schema,
                table=model_name,
                env=env,
            ) if model_name else None,
            "runId": run_results.get("metadata", {}).get("invocation_id", "unknown"),
            "status": "COMPLETE",
            "result": {
                "type": assertion_result,
                "nativeResults": {
                    "status": status,
                    "failures": str(failures),
                },
            },
        }
        
        # Add failure message if present
        if assertion_result == "FAILURE" and message:
            run_event["result"]["nativeResults"]["message"] = message[:1000]  # Truncate long messages
        
        # Remove None values
        run_event = {k: v for k, v in run_event.items() if v is not None}
        
        if _ingest_mcp("assertion", assertion_urn, "assertionRunEvent", run_event):
            run_events_created += 1
            status_emoji = "✅" if assertion_result == "SUCCESS" else "❌"
            print(f"{status_emoji} Published run event: {test_name} = {assertion_result}")
        
    summary = {
        "status": "ok",
        "server": server,
        "assertions_created": assertions_created,
        "run_events_created": run_events_created,
        "total_tests": len(test_results),
        "passed": sum(1 for r in test_results if r.get("status", "").lower() == "pass"),
        "failed": sum(1 for r in test_results if r.get("status", "").lower() != "pass"),
    }
    
    if errors:
        summary["errors"] = errors[:10]  # Limit error messages
    
    print(f"\n📊 Summary: {summary['passed']} passed, {summary['failed']} failed")
    print(f"✅ Published {assertions_created} assertions and {run_events_created} run events to DataHub")
    
    return summary


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
    asset_tag_name: Optional[str] = None,
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

    # Download run_results.json to filter nodes - only publish schemas for models that were run
    rr_key = f"{prefix.strip('/')}/run_results.json"
    run_node_ids = set()
    try:
        rr_obj = s3.get_object(Bucket=bucket, Key=rr_key)
        rr_data = json.loads(rr_obj["Body"].read())
        for res in rr_data.get("results", []):
            unique_id = res.get("unique_id")
            if unique_id and unique_id.startswith("model."):
                run_node_ids.add(unique_id)
        print(f"   Found {len(run_node_ids)} model(s) in run_results.json")
    except Exception as e:
        print(f"⚠️ Could not load run_results.json for filtering: {e}")
        # If run_results missing, process all nodes
        run_node_ids = None

    def _build_iceberg_dataset_urn(dataset_name: str) -> str:
        # Build URN with platform instance prefix
        full_name = f"{platform_instance}.{dataset_name}"
        return f"urn:li:dataset:(urn:li:dataPlatform:iceberg,{full_name},{env})"

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
    
    # Filter nodes if run_results was loaded
    if run_node_ids is not None:
        nodes = {k: v for k, v in nodes.items() if k in run_node_ids}
        print(f"📊 Iceberg publisher: filtered to {len(nodes)} of {total_nodes} nodes (based on run_results)")
    else:
        print(f"📊 Iceberg publisher: found {total_nodes} nodes in catalog.json (no filtering)")
    
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

        dataset_urns = [_build_iceberg_dataset_urn(n) for n in dataset_names]

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

            # Emit subTypes (Table)
            subtype_aspect = {
                "typeNames": ["Table"]
            }
            for du in dataset_urns:
                _ingest_mcp(du, "subTypes", subtype_aspect)

            # Emit globalTags if tag name is provided
            if asset_tag_name:
                tag_urn = f"urn:li:tag:{asset_tag_name}"
                tags_aspect = {
                    "tags": [{"tag": tag_urn}]
                }
                for du in dataset_urns:
                    _ingest_mcp(du, "globalTags", tags_aspect)
                    try:
                        print(f"🏷️ Applied tag {tag_urn} to {du}")
                    except Exception:
                        pass

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
