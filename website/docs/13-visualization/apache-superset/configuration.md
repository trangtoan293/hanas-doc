# Apache Superset - Cấu Hình

## Kết Nối Dremio (Data Source Chính)

### Cấu Hình Kết Nối Arrow Flight

Apache Superset kết nối với Dremio qua connector `sqlalchemy_dremio`, sử dụng giao thức **Apache Arrow Flight** cho hiệu năng truyền dữ liệu tối ưu.

#### Cài Đặt Driver

```bash
# Trong Superset container hoặc virtual environment
pip install sqlalchemy-dremio
```

> Trên Kubernetes, driver được cài tự động qua `init.initscript` trong Helm values.

#### SQLAlchemy URI

**Username/Password Authentication:**

```
dremio+flight://<DREMIO_USER>:<DREMIO_PASS>@<DREMIO_HOST>:32010/dremio
```

**Personal Access Token (PAT):**

```
dremio+flight://<DREMIO_USER>:<PAT>@<DREMIO_HOST>:32010/dremio?UseEncryption=false
```

**Ví dụ cho Hanas Platform (Kubernetes internal):**

```
dremio+flight://hanas_bi:P%40ssw0rd@dremio-client.dremio.svc.cluster.local:32010/dremio
```

> **Cảnh báo:** Mật khẩu chứa ký tự đặc biệt phải được URL-encoded (ví dụ: `@` → `%40`, `#` → `%23`).

#### Cấu Hình Qua UI

1. Login Superset → **Settings** → **Database Connections**
2. Click **+ Database** → chọn **Other**
3. Nhập **Display Name**: `Dremio Hanas`
4. Nhập **SQLAlchemy URI**: `dremio+flight://...`
5. Tab **Advanced** → **Security**:
   - Allow DML (nếu cần INSERT/UPDATE)
   - Allow this database to be explored
   - Expose database in SQL Lab
6. Click **Test Connection** → **Connect**

#### Cấu Hình Qua CLI

```bash
superset set-database-uri \
  --database_name "Dremio Hanas" \
  --uri "dremio+flight://hanas_bi:<PASSWORD>@dremio-client.dremio.svc:32010/dremio"
```

---

## superset_config.py (Cấu Hình Toàn Diện)

File `superset_config.py` là file cấu hình chính của Superset. Trên Kubernetes, nội dung này được đặt trong `configOverrides` của Helm values.

```python
# superset_config.py - Cấu hình cho Hanas Data Platform

import os
from typing import Optional
from cachelib.redis import RedisCache
from celery.schedules import crontab

# ============================================================
# 1. FLASK APP CONFIGURATION
# ============================================================
SECRET_KEY = os.environ.get('SUPERSET_SECRET_KEY', 'CHANGE-ME-IN-PRODUCTION')

# Metadata Database (PostgreSQL)
SQLALCHEMY_DATABASE_URI = os.environ.get(
    'DATABASE_URL',
    'postgresql://superset:superset@superset-postgresql:5432/superset'
)
SQLALCHEMY_TRACK_MODIFICATIONS = False
SQLALCHEMY_POOL_SIZE = 10
SQLALCHEMY_POOL_TIMEOUT = 300
SQLALCHEMY_MAX_OVERFLOW = 10

# ============================================================
# 2. CACHE CONFIGURATION (Redis)
# ============================================================
REDIS_URL = os.environ.get('REDIS_URL', 'redis://superset-redis-master:6379')

# Application Cache
CACHE_CONFIG = {
    'CACHE_TYPE': 'RedisCache',
    'CACHE_DEFAULT_TIMEOUT': 86400,     # 24 hours
    'CACHE_KEY_PREFIX': 'superset_',
    'CACHE_REDIS_URL': f'{REDIS_URL}/0',
}

# Data Cache (query results)
DATA_CACHE_CONFIG = {
    'CACHE_TYPE': 'RedisCache',
    'CACHE_DEFAULT_TIMEOUT': 86400,     # 24 hours
    'CACHE_KEY_PREFIX': 'superset_data_',
    'CACHE_REDIS_URL': f'{REDIS_URL}/1',
}

# Filter State Cache
FILTER_STATE_CACHE_CONFIG = {
    'CACHE_TYPE': 'RedisCache',
    'CACHE_DEFAULT_TIMEOUT': 86400,
    'CACHE_KEY_PREFIX': 'superset_filter_',
    'CACHE_REDIS_URL': f'{REDIS_URL}/2',
}

# Explore Form Data Cache
EXPLORE_FORM_DATA_CACHE_CONFIG = {
    'CACHE_TYPE': 'RedisCache',
    'CACHE_DEFAULT_TIMEOUT': 86400,
    'CACHE_KEY_PREFIX': 'superset_explore_',
    'CACHE_REDIS_URL': f'{REDIS_URL}/3',
}

# ============================================================
# 3. CELERY CONFIGURATION (Async Queries & Reports)
# ============================================================
class CeleryConfig:
    broker_url = f'{REDIS_URL}/4'
    result_backend = f'{REDIS_URL}/5'
    imports = (
        'superset.sql_lab',
        'superset.tasks',
        'superset.tasks.thumbnails',
    )

    # Task routing
    task_routes = {
        'sql_lab.get_sql_results': {'queue': 'sql_lab'},
        'email_reports.send': {'queue': 'email'},
    }

    # Scheduled tasks
    beat_schedule = {
        'reports.scheduler': {
            'task': 'reports.scheduler',
            'schedule': crontab(minute='*/1'),  # Check every minute
        },
        'reports.prune_log': {
            'task': 'reports.prune_log',
            'schedule': crontab(minute=0, hour=0),  # Daily at midnight
        },
        'cache-warmup': {
            'task': 'cache-warmup',
            'schedule': crontab(minute='0', hour='6'),  # 6 AM daily
            'kwargs': {
                'strategy_name': 'top_n_dashboards',
                'top_n': 10,
            },
        },
    }

    # Task concurrency
    worker_prefetch_multiplier = 1
    task_acks_late = True
    task_annotations = {
        'sql_lab.get_sql_results': {'rate_limit': '100/s'},
        'email_reports.send': {'rate_limit': '10/s'},
    }

CELERY_CONFIG = CeleryConfig

# ============================================================
# 4. FEATURE FLAGS
# ============================================================
FEATURE_FLAGS = {
    # Dashboard Features
    'DASHBOARD_NATIVE_FILTERS': True,
    'DASHBOARD_CROSS_FILTERS': True,
    'DASHBOARD_RBAC': True,

    # Embedded Superset
    'EMBEDDED_SUPERSET': True,

    # Alerts & Reports
    'ALERT_REPORTS': True,

    # SQL Lab
    'ENABLE_TEMPLATE_PROCESSING': True,

    # Thumbnails
    'THUMBNAILS': True,

    # Security
    'ENABLE_JAVASCRIPT_CONTROLS': False,  # Tắt vì lý do bảo mật
}

# ============================================================
# 5. SECURITY CONFIGURATION
# ============================================================

# Row Level Security
ROW_LEVEL_SECURITY_ENABLED = True

# Proxy fix (cho Ingress / Load Balancer)
ENABLE_PROXY_FIX = True

# CSRF Protection
WTF_CSRF_ENABLED = True
WTF_CSRF_TIME_LIMIT = None

# CORS (nếu cần cross-origin access)
ENABLE_CORS = True
CORS_OPTIONS = {
    'supports_credentials': True,
    'allow_headers': ['*'],
    'resources': ['*'],
    'origins': [
        'https://superset.hanas.local',
        'https://app.hanas.vn',
    ],
}

# Session Configuration (Server-side via Redis)
from redis import Redis
SESSION_SERVER_SIDE = True
SESSION_TYPE = 'redis'
SESSION_REDIS = Redis(
    host=os.environ.get('REDIS_HOST', 'superset-redis-master'),
    port=int(os.environ.get('REDIS_PORT', 6379)),
    db=6,
)
SESSION_USE_SIGNER = True

# ============================================================
# 6. SQL LAB CONFIGURATION
# ============================================================
SQLLAB_TIMEOUT = 300                # 5 minutes per query
SQLLAB_ASYNC_TIME_LIMIT_SEC = 3600  # 1 hour for async queries
SQL_MAX_ROW = 100000                # Max rows returned
SQLLAB_SAVE_WARNING_MESSAGE = None

# ============================================================
# 7. DASHBOARD CONFIGURATION
# ============================================================
DASHBOARD_AUTO_REFRESH_MODE = 'fetch'
DASHBOARD_AUTO_REFRESH_INTERVALS = [
    [0, "Don't refresh"],
    [10, '10 seconds'],
    [30, '30 seconds'],
    [60, '1 minute'],
    [300, '5 minutes'],
    [1800, '30 minutes'],
    [3600, '1 hour'],
]

# ============================================================
# 8. ALERTS & REPORTS
# ============================================================
ALERT_REPORTS_NOTIFICATION_DRY_RUN = False

# Email
SMTP_HOST = os.environ.get('SMTP_HOST', 'smtp.hanas.vn')
SMTP_PORT = int(os.environ.get('SMTP_PORT', 587))
SMTP_STARTTLS = True
SMTP_USER = os.environ.get('SMTP_USER', 'superset@hanas.vn')
SMTP_PASSWORD = os.environ.get('SMTP_PASSWORD', '')
SMTP_MAIL_FROM = 'superset@hanas.vn'

# Slack (Optional)
SLACK_API_TOKEN = os.environ.get('SLACK_API_TOKEN', '')

# Screenshot rendering (dùng Selenium/Chromium headless)
WEBDRIVER_BASEURL = 'http://superset:8088/'
WEBDRIVER_BASEURL_USER_FRIENDLY = 'https://superset.hanas.local/'
```

---

## Role-Based Access Control (RBAC)

### Built-in Roles

Superset cung cấp 5 roles mặc định:

| Role | Quyền | Use Case |
|---|---|---|
| **Admin** | Toàn quyền: quản lý users, databases, security | System administrators |
| **Alpha** | Tạo/sửa tất cả datasources, charts, dashboards | Data engineers, analysts |
| **Gamma** | Chỉ xem datasources/charts được cấp quyền | Business users, viewers |
| **sql_lab** | Truy cập SQL Lab (thường kết hợp với Gamma) | Analysts cần chạy SQL |
| **Public** | Xem nội dung public (không cần login) | Anonymous access |

### Custom Roles Cho Hanas Platform

| Custom Role | Base Role | Thêm quyền | Dành cho |
|---|---|---|---|
| `hanas_admin` | Admin | — | Platform administrators |
| `hanas_analyst` | Alpha + sql_lab | — | Data analysts |
| `hanas_viewer` | Gamma | Dashboard access cụ thể | Business users |
| `hanas_embedded` | Public | Xem embedded dashboards | External applications |

### Cấu Hình Roles Qua UI

1. **Settings** → **List Roles**
2. Click **+ (Add)** → đặt tên role
3. Chọn permissions từ danh sách (ví dụ: `can read on Chart`, `can write on Dashboard`)
4. **Save**

### Cấu Hình Roles Qua CLI

```bash
# Tạo role
superset fab create-role -n hanas_viewer

# Gán user vào role
superset fab add-role-user -r hanas_viewer -u <username>
```

---

## Row Level Security (RLS)

Row Level Security cho phép giới hạn dữ liệu visible theo user/role. Đây là lớp bảo mật bổ sung bên cạnh RLS của Dremio/Ranger.

### Bật RLS

```python
# superset_config.py
ROW_LEVEL_SECURITY_ENABLED = True
```

### Tạo RLS Rule Qua UI

1. **Settings** → **Row Level Security**
2. Click **+ (Add)**
3. Cấu hình:
   - **Filter Type**: Regular (filter data) hoặc Base (mở rộng filter)
   - **Tables**: Chọn dataset(s) áp dụng
   - **Roles**: Chọn role(s) bị ảnh hưởng
   - **Clause**: Điều kiện SQL filter

**Ví dụ:**
```
-- Chỉ cho phép xem dữ liệu chi nhánh Hà Nội
branch_code = 'HN'

-- Chỉ cho phép xem dữ liệu tháng hiện tại
date_column >= DATE_TRUNC('MONTH', CURRENT_DATE)
```

---

## Embedded Dashboards

### Bật Feature Flag

```python
# superset_config.py
FEATURE_FLAGS = {
    'EMBEDDED_SUPERSET': True,
}

# CORS cho domain embed
CORS_OPTIONS = {
    'supports_credentials': True,
    'origins': ['https://app.hanas.vn'],
}

# Guest Token settings
GUEST_ROLE_NAME = 'Public'
GUEST_TOKEN_JWT_SECRET = os.environ.get('GUEST_TOKEN_SECRET', SECRET_KEY)
GUEST_TOKEN_JWT_EXP = 300  # 5 minutes
```

### Tạo Guest Token

```bash
# POST /api/v1/security/guest_token/
curl -X POST http://superset:8088/api/v1/security/guest_token/ \
  -H "Authorization: Bearer <ADMIN_ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "username": "guest_user",
      "first_name": "Guest",
      "last_name": "User"
    },
    "resources": [
      {"type": "dashboard", "id": "<DASHBOARD_UUID>"}
    ],
    "rls": [
      {"clause": "branch_code = '\''HN'\''"}
    ]
  }'
```

### Nhúng Vào Ứng Dụng

```html
<!-- Install SDK -->
<script src="https://unpkg.com/@superset-ui/embedded-sdk"></script>

<div id="superset-dashboard"></div>

<script>
  supersetEmbeddedSdk.embedDashboard({
    id: "<DASHBOARD_UUID>",
    supersetDomain: "https://superset.hanas.local",
    mountPoint: document.getElementById("superset-dashboard"),
    fetchGuestToken: () =>
      fetch("/api/guest-token") // Backend endpoint tạo guest token
        .then((res) => res.json())
        .then((data) => data.token),
    dashboardUiConfig: {
      hideTitle: true,
      hideChartControls: false,
      hideTab: false,
    },
  });
</script>
```

---

## OAuth Authentication (Optional)

### Google OAuth

```python
# superset_config.py
from flask_appbuilder.security.manager import AUTH_OAUTH

AUTH_TYPE = AUTH_OAUTH
ENABLE_PROXY_FIX = True

OAUTH_PROVIDERS = [
    {
        'name': 'google',
        'icon': 'fa-google',
        'token_key': 'access_token',
        'remote_app': {
            'client_id': os.environ.get('GOOGLE_CLIENT_ID'),
            'client_secret': os.environ.get('GOOGLE_CLIENT_SECRET'),
            'api_base_url': 'https://www.googleapis.com/oauth2/v2/',
            'client_kwargs': {'scope': 'email profile'},
            'access_token_url': 'https://accounts.google.com/o/oauth2/token',
            'authorize_url': 'https://accounts.google.com/o/oauth2/auth',
            'authorize_params': {'hd': 'hanas.vn'},
        },
    }
]

AUTH_USER_REGISTRATION = True
AUTH_USER_REGISTRATION_ROLE = 'Gamma'
```

### Helm Values Cho OAuth

```yaml
# superset-values.yaml
extraEnv:
  - name: AUTH_DOMAIN
    value: "hanas.vn"

extraSecretEnv:
  GOOGLE_CLIENT_ID:
    valueFrom:
      secretKeyRef:
        name: superset-oauth
        key: client-id
  GOOGLE_CLIENT_SECRET:
    valueFrom:
      secretKeyRef:
        name: superset-oauth
        key: client-secret
```

---

## Tích Hợp Với HashiCorp Vault

Credentials nhạy cảm (SECRET_KEY, database passwords, OAuth secrets) nên được lưu trong HashiCorp Vault:

```yaml
# Kubernetes - sử dụng Vault Agent Injector
spec:
  template:
    metadata:
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "superset"
        vault.hashicorp.com/agent-inject-secret-config: "secret/data/superset/config"
        vault.hashicorp.com/agent-inject-template-config: |
          {{- with secret "secret/data/superset/config" -}}
          export SUPERSET_SECRET_KEY="{{ .Data.data.secret_key }}"
          export DREMIO_PASSWORD="{{ .Data.data.dremio_password }}"
          export SMTP_PASSWORD="{{ .Data.data.smtp_password }}"
          {{- end }}
```

> Chi tiết cấu hình Vault → xem [HashiCorp Vault Documentation](../../09-security/hashicorp-vault/README.md)
