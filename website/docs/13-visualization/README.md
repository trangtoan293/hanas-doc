# Lớp Trực Quan Hóa Dữ Liệu (Data Visualization)

## Tổng Quan

Lớp trực quan hóa dữ liệu là lớp tiêu thụ cuối cùng trong kiến trúc Hanas Data Platform, nơi dữ liệu được chuyển đổi thành biểu đồ, dashboard và báo cáo phục vụ ra quyết định. Lớp này kết nối trực tiếp với **Dremio** (Layer 6 — Liên Kết Dữ Liệu) qua giao thức hiệu năng cao Apache Arrow Flight, cho phép truy vấn và trực quan hóa dữ liệu real-time mà không cần di chuyển hay sao chép dữ liệu.

```mermaid
flowchart LR
    subgraph L6["Lớp 6: Liên Kết"]
        Dremio[Dremio]
    end

    subgraph L7["Lớp Visualization / Consumption"]
        Superset[Apache Superset]
    end

    subgraph Users["Người Dùng"]
        BA[Business Analyst]
        DS[Data Scientist]
        Exec[Lãnh đạo]
        App[Ứng dụng Embedded]
    end

    Dremio -->|Arrow Flight / JDBC| Superset
    Superset --> BA
    Superset --> DS
    Superset --> Exec
    Superset -->|Embedded SDK| App

    style L6 fill:#e0f7fa,stroke:#00838f
    style L7 fill:#e8eaf6,stroke:#3f51b5,stroke-width:3px
    style Users fill:#f3e5f5,stroke:#7b1fa2
```

## Services

- [Apache Superset](apache-superset/README.md) — BI Platform, Dashboard, SQL Lab, Alerts & Reports
