# ktl_airflow_utils

This package is designed to be portable between Airflow instances.

## Configuration lookup

When this package needs configuration values, it uses `ktl_airflow_utils.airflow_vars.get_var(...)`:

1. Try **Airflow Variables** (`airflow.models.Variable.get(name)`).
2. Fallback to **process environment variables** (`os.environ[name]`).
3. Fallback to the provided default (if any).

This means the same setting can be provided either as an Airflow Variable or as an environment variable with the same name.

## Airflow Variables / Environment variables

### Maileroo (email notifications)
Used by: `ktl_airflow_utils.maileroo.MailerooClient` and `ktl_airflow_utils.taskgroups.notifications.create_maileroo_notification_group`.

- `MAILEROO_API_KEY`
  - Required to actually send emails.
- `SENDER_EMAIL`
  - Required to actually send emails.
  - Example: `no-reply@example.com`
- `DEFAULT_NOTIFICATION_EMAIL`
  - Optional default recipient used when the taskgroup caller does not provide a recipient.
  - Can be a comma-separated list.
- `AIRFLOW_BASE_URL`
  - Optional.
  - If set, emails include a link back to the DAG run page.
  - Example: `http://airflow-webserver:8080`

Notes:
- `MAILEROO_API_URL` can be overridden via `MailerooClient(config={"MAILEROO_API_URL": ...})`, but it is **not** currently read via Airflow Variables / environment variables.

### dbt artifacts storage
Used by: `ktl_airflow_utils.taskgroups.datahub_publish.create_publish_to_datahub_taskgroup`.

- `DBT_ARTIFACTS_BUCKET`
  - Bucket that contains dbt artifacts.
  - Default: `data`

The `prefix_value` you pass into `create_publish_to_datahub_taskgroup(prefix_value=...)` is treated as the prefix inside this bucket.

### DataHub publishing
Used by: `ktl_airflow_utils.taskgroups.datahub_publish.create_publish_to_datahub_taskgroup` and `ktl_airflow_utils.datahub.publishers.*`.

- `DATAHUB_GMS_HOST`
  - DataHub GMS base URL.
  - Example: `http://datahub-gms:8080`
  - If you provide port `9002` with no path (e.g. `http://host:9002`), the code will automatically append `/api/gms`.
- `DATAHUB_TOKEN`
  - Optional bearer token.
- `DATAHUB_ENV`
  - Environment name used in emitted URNs.
  - Default: `PROD`
- `DATAHUB_PLATFORM_INSTANCE`
  - Platform instance used for dbt and test-results publishing.
  - Default: `demo`
- `DATAHUB_ICEBERG_PLATFORM_INSTANCE`
  - Platform instance used for Iceberg catalog publishing.
  - Default: `LakeHouse`

Iceberg publishing options:
- `DATAHUB_INCLUDE_DATABASE_IN_NAME`
  - Boolean.
  - Default: `true`
  - When `true`, dataset names are emitted as `database.schema.table` (when database exists).
- `DATAHUB_EMIT_BOTH_NAME_VARIANTS`
  - Boolean.
  - Default: `false`
  - When `true`, emits both name variants (with-db and without-db) to support transitions.

### AWS / S3 credentials and endpoint
Used by: `ktl_airflow_utils.taskgroups.datahub_publish.create_publish_to_datahub_taskgroup` (passed through to `ktl_airflow_utils.datahub.publishers.*`).

- `AWS_ENDPOINT_URL`
  - Optional. Useful for S3-compatible storage (e.g., MinIO).
- `AWS_DEFAULT_REGION`
  - Optional.
- `AWS_ACCESS_KEY_ID`
  - Optional.
- `AWS_SECRET_ACCESS_KEY`
  - Optional.
- `AWS_SESSION_TOKEN`
  - Optional.

If these are not provided, `boto3` will fall back to its normal credential resolution chain.

## Expected artifacts in S3

The publishing code expects these objects under:

- `s3://$DBT_ARTIFACTS_BUCKET/$prefix_value/manifest.json`
- `s3://$DBT_ARTIFACTS_BUCKET/$prefix_value/run_results.json`
- `s3://$DBT_ARTIFACTS_BUCKET/$prefix_value/catalog.json`
