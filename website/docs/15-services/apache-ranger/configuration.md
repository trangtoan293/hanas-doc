# Apache Ranger — Cấu Hình

## 1. Cấu Hình Cơ Bản — Ranger Admin

### 1.1 ranger-admin-site.xml

File cấu hình chính cho Ranger Admin, chứa thông tin kết nối database, audit backend, và authentication.

```xml
<configuration>
  <!-- Database -->
  <property>
    <name>ranger.jpa.jdbc.driver</name>
    <value>org.postgresql.Driver</value>
  </property>
  <property>
    <name>ranger.jpa.jdbc.url</name>
    <value>jdbc:postgresql://ranger-db-postgresql.security.svc:5432/ranger</value>
  </property>
  <property>
    <name>ranger.jpa.jdbc.user</name>
    <value>ranger</value>
  </property>
  <property>
    <name>ranger.jpa.jdbc.password</name>
    <value>_secret_</value>
  </property>

  <!-- Admin Authentication -->
  <property>
    <name>ranger.authentication.method</name>
    <value>LDAP</value>  <!-- NONE | LDAP | ACTIVE_DIRECTORY | UNIX | PAM -->
  </property>

  <!-- Policy Cache -->
  <property>
    <name>ranger.service.http.port</name>
    <value>6080</value>
  </property>
  <property>
    <name>ranger.service.https.port</name>
    <value>6182</value>
  </property>
</configuration>
```

### 1.2 ranger-env.sh

```bash
# Java settings
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export RANGER_ADMIN_HEAP="-Xmx2g -Xms1g"

# Ranger Admin PID
export RANGER_PID_DIR_PATH=/var/run/ranger

# Log directory
export RANGER_ADMIN_LOG_DIR=/var/log/ranger/admin
```

---

## 2. Cấu Hình LDAP / Active Directory

### 2.1 Ranger Admin — LDAP Authentication

```xml
<!-- ranger-admin-site.xml - LDAP Authentication -->
<property>
  <name>ranger.ldap.url</name>
  <value>ldap://openldap.security.svc:389</value>
</property>
<property>
  <name>ranger.ldap.user.dnpattern</name>
  <value>uid={0},ou=users,dc=hanas,dc=local</value>
</property>
<property>
  <name>ranger.ldap.group.searchbase</name>
  <value>ou=groups,dc=hanas,dc=local</value>
</property>
<property>
  <name>ranger.ldap.group.searchfilter</name>
  <value>(member=uid={0},ou=users,dc=hanas,dc=local)</value>
</property>
<property>
  <name>ranger.ldap.group.roleattribute</name>
  <value>cn</value>
</property>
<property>
  <name>ranger.ldap.base.dn</name>
  <value>dc=hanas,dc=local</value>
</property>
<property>
  <name>ranger.ldap.bind.dn</name>
  <value>cn=admin,dc=hanas,dc=local</value>
</property>
<property>
  <name>ranger.ldap.bind.password</name>
  <value>_secret_</value>
</property>
<property>
  <name>ranger.ldap.referral</name>
  <value>follow</value>
</property>
```

### 2.2 Ranger Usersync — LDAP Synchronization

```bash
# usersync install.properties

POLICY_MGR_URL=http://ranger-admin.security.svc:6080
SYNC_SOURCE=ldap

# LDAP connection
SYNC_LDAP_URL=ldap://openldap.security.svc:389
SYNC_LDAP_BIND_DN=cn=admin,dc=hanas,dc=local
SYNC_LDAP_BIND_PASSWORD=_secret_

# User sync
SYNC_LDAP_USER_SEARCH_BASE=ou=users,dc=hanas,dc=local
SYNC_LDAP_USER_SEARCH_SCOPE=sub
SYNC_LDAP_USER_OBJECT_CLASS=inetOrgPerson
SYNC_LDAP_USER_SEARCH_FILTER=
SYNC_LDAP_USER_NAME_ATTRIBUTE=uid

# Group sync
SYNC_LDAP_GROUP_SEARCH_BASE=ou=groups,dc=hanas,dc=local
SYNC_LDAP_GROUP_SEARCH_SCOPE=sub
SYNC_LDAP_GROUP_OBJECT_CLASS=groupOfNames
SYNC_LDAP_GROUP_SEARCH_FILTER=
SYNC_LDAP_GROUP_NAME_ATTRIBUTE=cn
SYNC_LDAP_GROUP_MEMBER_ATTRIBUTE_NAME=member

# Sync interval (seconds)
SYNC_INTERVAL=360
```

---

## 3. Cấu Hình Plugin Cho Từng Service

### 3.1 Kafka Plugin

```properties
# ranger-kafka-security.xml (trong Kafka broker)
ranger.plugin.kafka.service.name=kafka_hanas
ranger.plugin.kafka.policy.rest.url=http://ranger-admin.security.svc:6080
ranger.plugin.kafka.policy.rest.ssl.config.file=/etc/ranger/kafka/conf/ranger-policymgr-ssl.xml
ranger.plugin.kafka.policy.cache.dir=/tmp/kafka/policycache
ranger.plugin.kafka.policy.pollIntervalMs=30000
ranger.plugin.kafka.policy.source.impl=org.apache.ranger.admin.client.RangerAdminRESTClient
```

**Ranger Service Config trong Admin UI:**

| Tham số | Giá trị | Mô tả |
|---------|---------|-------|
| `Service Name` | `kafka_hanas` | Tên service hiển thị trong Ranger |
| `Username` | `kafka_admin` | User kết nối Kafka |
| `Password` | `***` | Password |
| `Zookeeper Connect` | `zookeeper.data.svc:2181` | Zookeeper connection string |
| `Kafka Bootstrap` | `kafka-broker.data.svc:9092` | Broker address (KRaft mode) |

### 3.2 Hive Metastore Plugin

```properties
# ranger-hive-security.xml
ranger.plugin.hive.service.name=hive_hanas
ranger.plugin.hive.policy.rest.url=http://ranger-admin.security.svc:6080
ranger.plugin.hive.policy.cache.dir=/tmp/hive/policycache
ranger.plugin.hive.policy.pollIntervalMs=30000
ranger.plugin.hive.ambari.cluster.name=hanas
```

**Ranger Service Config trong Admin UI:**

| Tham số | Giá trị | Mô tả |
|---------|---------|-------|
| `Service Name` | `hive_hanas` | Tên service |
| `JDBC Driver` | `org.apache.hive.jdbc.HiveDriver` | JDBC driver class |
| `JDBC URL` | `jdbc:hive2://hive-metastore.data.svc:10000` | Hive Metastore JDBC URL |
| `Username` | `hive_admin` | User kết nối |

### 3.3 NiFi Plugin

```xml
<!-- ranger-nifi-security.xml -->
<configuration>
  <property>
    <name>ranger.plugin.nifi.service.name</name>
    <value>nifi_hanas</value>
  </property>
  <property>
    <name>ranger.plugin.nifi.policy.rest.url</name>
    <value>http://ranger-admin.security.svc:6080</value>
  </property>
  <property>
    <name>ranger.plugin.nifi.policy.cache.dir</name>
    <value>/tmp/nifi/policycache</value>
  </property>
  <property>
    <name>ranger.plugin.nifi.policy.pollIntervalMs</name>
    <value>30000</value>
  </property>
</configuration>
```

**Ranger Service Config trong Admin UI:**

| Tham số | Giá trị | Mô tả |
|---------|---------|-------|
| `Service Name` | `nifi_hanas` | Tên service |
| `NiFi URL` | `https://nifi.data.svc:8443/nifi-api/resources` | NiFi REST API |
| `Authentication Type` | `SSL` | SSL mutual auth |

### 3.4 Spark Plugin

```properties
# ranger-spark-security.xml
ranger.plugin.spark.service.name=spark_hanas
ranger.plugin.spark.policy.rest.url=http://ranger-admin.security.svc:6080
ranger.plugin.spark.policy.cache.dir=/tmp/spark/policycache
ranger.plugin.spark.policy.pollIntervalMs=30000
```

### 3.5 Dremio — Ranger Authorization

```yaml
# dremio.conf hoặc Helm values
services.coordinator.web.auth.type: "ranger"

# Ranger integration
ranger:
  service-name: "dremio_hanas"
  host-url: "http://ranger-admin.security.svc:6080"
  admin-username: "admin"
  admin-password: "_secret_"
```

---

## 4. Cấu Hình Audit Backend

### 4.1 Elasticsearch (Khuyến nghị)

```xml
<!-- ranger-admin-site.xml -->
<property>
  <name>ranger.audit.store</name>
  <value>elasticsearch</value>
</property>
<property>
  <name>ranger.audit.elasticsearch.urls</name>
  <value>http://elasticsearch.observability.svc:9200</value>
</property>
<property>
  <name>ranger.audit.elasticsearch.index</name>
  <value>ranger_audits</value>
</property>
<property>
  <name>ranger.audit.elasticsearch.user</name>
  <value>ranger_audit</value>
</property>
<property>
  <name>ranger.audit.elasticsearch.password</name>
  <value>_secret_</value>
</property>
```

### 4.2 Solr (Thay thế)

```xml
<property>
  <name>ranger.audit.store</name>
  <value>solr</value>
</property>
<property>
  <name>ranger.audit.solr.urls</name>
  <value>http://solr.observability.svc:8983/solr/ranger_audits</value>
</property>
<property>
  <name>ranger.audit.solr.zookeepers</name>
  <value>zookeeper.data.svc:2181/solr</value>
</property>
```

### 4.3 Database (Backup)

```xml
<property>
  <name>ranger.audit.store</name>
  <value>db</value>
</property>
<!-- Sử dụng cùng PostgreSQL database -->
```

---

## 5. Cấu Hình KMS (Key Management Service)

```xml
<!-- kms-site.xml -->
<configuration>
  <property>
    <name>ranger.kms.service.name</name>
    <value>kms_hanas</value>
  </property>
  <property>
    <name>ranger.kms.policy.rest.url</name>
    <value>http://ranger-admin.security.svc:6080</value>
  </property>

  <!-- KMS Database (tách riêng khỏi Ranger Admin DB) -->
  <property>
    <name>ranger.ks.jpa.jdbc.url</name>
    <value>jdbc:postgresql://ranger-db-postgresql.security.svc:5432/rangerkms</value>
  </property>
  <property>
    <name>ranger.ks.jpa.jdbc.user</name>
    <value>rangerkms</value>
  </property>
  <property>
    <name>ranger.ks.jpa.jdbc.password</name>
    <value>_secret_</value>
  </property>

  <!-- Master Key -->
  <property>
    <name>ranger.kms.master.key.password</name>
    <value>_secret_</value>
  </property>
</configuration>
```

> **Ghi chú**: Trong Hanas Platform, HashiCorp Vault cũng được sử dụng cho secrets management. KMS và Vault có thể bổ sung cho nhau — Vault quản lý application secrets, KMS quản lý data encryption keys.

---

## 6. Bảng Tham Số Quan Trọng

### 6.1 Ranger Admin

| Tham số | Mặc định | Mô tả |
|---------|---------|-------|
| `ranger.service.http.port` | `6080` | HTTP port cho Ranger Admin |
| `ranger.service.https.port` | `6182` | HTTPS port (khi SSL enabled) |
| `ranger.authentication.method` | `NONE` | `NONE` / `LDAP` / `ACTIVE_DIRECTORY` / `UNIX` / `PAM` |
| `ranger.admin.cookie.name` | `RANGERADMINSESSIONID` | Session cookie name |
| `ranger.service.https.attrib.ssl.enabled` | `false` | Enable SSL cho Admin UI |
| `ranger.jpa.jdbc.maxPoolSize` | `40` | DB connection pool max size |
| `ranger.admin.password.history.count` | `4` | Số password cũ không được tái sử dụng |

### 6.2 Plugin Common

| Tham số | Mặc định | Mô tả |
|---------|---------|-------|
| `ranger.plugin.*.policy.pollIntervalMs` | `30000` | Khoảng thời gian plugin pull policies (30s) |
| `ranger.plugin.*.policy.cache.dir` | `/tmp/*/policycache` | Thư mục cache local cho policies |
| `ranger.plugin.*.policy.rest.url` | — | URL Ranger Admin API |
| `ranger.plugin.*.policy.rest.ssl.config.file` | — | File cấu hình SSL cho plugin → Admin |

### 6.3 Usersync

| Tham số | Mặc định | Mô tả |
|---------|---------|-------|
| `SYNC_INTERVAL` | `360` | Đồng bộ LDAP mỗi 6 phút |
| `SYNC_LDAP_SEARCH_SCOPE` | `sub` | `base` / `one` / `sub` |
| `SYNC_LDAP_USER_NAME_ATTRIBUTE` | `uid` | Attribute chứa username |
| `SYNC_LDAP_GROUP_NAME_ATTRIBUTE` | `cn` | Attribute chứa group name |
| `SYNC_LDAP_DELTASYNC` | `true` | Chỉ sync thay đổi (delta mode) |
