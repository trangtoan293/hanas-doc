# dbt Project - Simple Data Transformation

Dự án dbt tách biệt cho việc transformation data sử dụng Apache Spark và Apache Iceberg.

## 📁 Cấu trúc dự án

```
dbt-project/
├── README.md          # Tài liệu dự án
├── dbt_project.yml    # Cấu hình dbt project
├── profiles.yml       # Cấu hình connection profiles
├── models/            # dbt models
│   ├── staging/       # Staging models (views)
│   ├── marts/         # Mart models (tables)
│   └── sources.yml    # Source definitions
├── tests/             # dbt tests
│   └── schema.yml     # Test definitions
└── seeds/             # Seed data
    └── sample_orders.csv
```

## 🎯 Mục đích

Repository này chứa toàn bộ dbt project code, tách biệt với infrastructure code để:

- **Faster Development**: Không cần rebuild Docker image khi thay đổi models
- **Team Collaboration**: Data engineers có thể làm việc độc lập
- **Version Control**: Proper versioning cho dbt transformations
- **Environment Separation**: Dev/prod branches khác nhau

## 🚀 Local Development

### Prerequisites
- Python 3.8+
- dbt-spark installed
- Apache Spark (nếu test local)

### Setup
```bash
# Install dependencies
pip install dbt-spark

# Configure profiles
export DBT_PROFILES_DIR=$(pwd)

# Test connection
dbt debug

# Run models
dbt run --target dev
```

## 📊 Models

### Staging Models
- `stg_orders`: Staging layer cho orders data

### Marts Models  
- `dim_orders`: Dimensional model cho orders với business logic

## 🔧 Profiles Configuration

Project sử dụng Spark session method với:
- **Dev environment**: `integration_demo` schema
- **Prod environment**: `analytics_prod` schema

## 🧪 Testing

```bash
# Run tests
dbt test

# Test specific model
dbt test --select stg_orders
```

## 📝 Deployment

Repository này được deploy qua:
1. **Git-sync init container** trong Kubernetes
2. **SparkOperator** với external code injection
3. **ConfigMap** cho environment-specific configs

Xem repository `dbt-spark-k8s` cho infrastructure code.