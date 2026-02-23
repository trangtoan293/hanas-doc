# Backdate ETL Pipeline

This directory contains the Airflow DAG and supporting files for the backdate data flow ETL pipeline.

## Directory Structure

```
backdate/
├── config/
│   └── backdate_config.yaml      # Configuration file with dates and Dremio settings
├── sql/
│   ├── create_backdate_table.sql # SQL to create gl_poc_backdate table
│   ├── FACT_PL_DETAIL_BACKDATE.sql  # Profit & Loss view SQL
│   ├── FACT_DP_DETAIL_BACKDATE.sql  # Deposits view SQL
│   └── FACT_LN_DETAIL_BACKDATE.sql  # Loans view SQL
├── utils/
│   ├── dremio_client.py          # Dremio API client
│   └── execute_sql.py            # Spark SQL executor script
└── k8s/
    └── backdate-spark-job.yaml   # Spark Kubernetes job configuration
```

## Configuration

Edit `config/backdate_config.yaml` to adjust:
- **Date range**: `start_date` and `end_date` for backdate processing
- **Dremio settings**: API URL, credentials, and space name
- **Spark settings**: Resource allocation for driver and executors

## Usage

### Trigger the DAG

```bash
# Using Airflow CLI
airflow dags trigger backdate_etl_pipeline

# With custom dates
airflow dags trigger backdate_etl_pipeline \
  --conf '{"start_date": "2025-02-10", "end_date": "2025-02-15"}'
```

### Monitor Progress

1. **Airflow UI**: Check task status and logs
2. **Dremio UI**: Verify views at http://dremio.hanas.local/
3. **Kubernetes**: Monitor Spark jobs
   ```bash
   kubectl get sparkapplication -n spark-jobs
   kubectl describe sparkapplication backdate-table-creation-<id> -n spark-jobs
   ```

## Pipeline Steps

1. **Create Backdate Table** (Spark Job)
   - Drops existing `landing.gl_poc_backdate` table
   - Creates new Iceberg table with aggregated data
   - Date range from config is applied

2. **Create Dremio Views** (Python Task)
   - Authenticates with Dremio API
   - Creates/updates 3 views in DATA_MART space:
     - `FACT_PL_DETAIL_BACKDATE`
     - `FACT_DP_DETAIL_BACKDATE`
     - `FACT_LN_DETAIL_BACKDATE`

3. **Create Reflections** (Python Task)
   - Creates raw reflections for all views
   - Strategy: minimize refresh time
   - Displays all columns

## Prerequisites

- Kubernetes cluster with Spark Operator
- Hive Metastore accessible at `hive-metastore.hive-metastore.svc:9083`
- Dremio accessible at `http://10.10.101.54:9047`
- S3/MinIO storage configured
- Airflow connection `k8s_conn_id` configured

## Troubleshooting

### DAG Import Errors
```bash
python /path/to/backdate_etl_dag.py
```

### Dremio API Issues
- Check credentials in `config/backdate_config.yaml`
- Verify Dremio is accessible
- Check task logs for API error responses

### Spark Job Failures
```bash
kubectl logs -n spark-jobs backdate-table-creation-<id>-driver
```

## Development

To modify the pipeline:
1. Update SQL files in `sql/` directory
2. Adjust config in `config/backdate_config.yaml`
3. Test DAG syntax: `python backdate_etl_dag.py`
4. Deploy and trigger in Airflow
