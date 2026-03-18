import type { SidebarsConfig } from '@docusaurus/plugin-content-docs';

const sidebars: SidebarsConfig = {
  docsSidebar: [
    {
      type: 'doc',
      id: 'README',
      label: 'Trang Chủ',
    },
    {
      type: 'category',
      label: 'Tổng Quan',
      collapsed: false,
      link: {
        type: 'doc',
        id: 'overview/README',
      },
      items: [
        'overview/architecture',
        'overview/objectives',
        'overview/glossary',
      ],
    },
    {
      type: 'category',
      label: 'Thu Thập Dữ Liệu',
      collapsed: true,
      link: { type: 'doc', id: 'ingestion/README' },
      items: [],
    },
    {
      type: 'category',
      label: 'Lưu Trữ Dữ Liệu',
      collapsed: true,
      link: { type: 'doc', id: 'storage/README' },
      items: [],
    },
    {
      type: 'category',
      label: 'Xử Lý Dữ Liệu',
      collapsed: true,
      link: { type: 'doc', id: 'processing/README' },
      items: [],
    },
    {
      type: 'category',
      label: 'Điều Phối Luồng Dữ Liệu',
      collapsed: true,
      link: { type: 'doc', id: 'orchestration/README' },
      items: [],
    },
    {
      type: 'category',
      label: 'Mô Hình Dữ Liệu',
      collapsed: true,
      link: { type: 'doc', id: 'data-model/README' },
      items: [
        'data-model/naming-conventions',
        {
          type: 'category',
          label: 'Data Vault 2.0',
          items: [
            'data-model/data-vault/README',
            'data-model/data-vault/raw-vault',
            'data-model/data-vault/business-vault',
            'data-model/data-vault/information-mart',
          ],
        },
      ],
    },
    {
      type: 'category',
      label: 'Quản Trị Dữ Liệu',
      collapsed: true,
      link: { type: 'doc', id: 'governance/README' },
      items: [],
    },
    {
      type: 'category',
      label: 'Liên Kết Dữ Liệu',
      collapsed: true,
      link: { type: 'doc', id: 'federation/README' },
      items: [],
    },
    {
      type: 'category',
      label: 'Dịch Vụ AI',
      collapsed: true,
      link: { type: 'doc', id: 'ai-service/README' },
      items: [],
    },
    {
      type: 'category',
      label: 'Trực Quan Hóa Dữ Liệu',
      collapsed: true,
      link: { type: 'doc', id: 'visualization/README' },
      items: [],
    },
    {
      type: 'category',
      label: 'An Toàn Thông Tin',
      collapsed: true,
      link: { type: 'doc', id: 'security/README' },
      items: [],
    },
    {
      type: 'category',
      label: 'Quản Trị Hệ Thống',
      collapsed: true,
      link: { type: 'doc', id: 'system-management/README' },
      items: [],
    },
  ],

  // ============================================================
  // SERVICES CATALOG — 15-services/  (A → Z)
  // ============================================================
  servicesSidebar: [
    {
      type: 'doc',
      id: 'services/README',
      label: 'Danh sách Services',
    },
    // A ─────────────────────────────────────────────────────────
    {
      type: 'category',
      label: 'Apache Airflow',
      collapsed: true,
      link: { type: 'doc', id: 'services/apache-airflow/README' },
      items: [
        { type: 'doc', id: 'services/apache-airflow/installation', label: 'Cài đặt & Triển khai' },
        { type: 'doc', id: 'services/apache-airflow/configuration', label: 'Cấu hình' },
        { type: 'doc', id: 'services/apache-airflow/version-info', label: 'Thông tin Version' },
      ],
    },
    {
      type: 'category',
      label: 'Apache Iceberg',
      collapsed: true,
      link: { type: 'doc', id: 'services/apache-iceberg/README' },
      items: [
        { type: 'doc', id: 'services/apache-iceberg/installation', label: 'Cài đặt & Triển khai' },
        { type: 'doc', id: 'services/apache-iceberg/configuration', label: 'Cấu hình' },
        { type: 'doc', id: 'services/apache-iceberg/version-info', label: 'Thông tin Version' },
      ],
    },
    {
      type: 'category',
      label: 'Apache Kafka',
      collapsed: true,
      link: { type: 'doc', id: 'services/apache-kafka/README' },
      items: [
        { type: 'doc', id: 'services/apache-kafka/installation', label: 'Cài đặt & Triển khai' },
        { type: 'doc', id: 'services/apache-kafka/configuration', label: 'Cấu hình' },
        { type: 'doc', id: 'services/apache-kafka/version-info', label: 'Thông tin Version' },
      ],
    },
    {
      type: 'category',
      label: 'Apache NiFi',
      collapsed: true,
      link: { type: 'doc', id: 'services/apache-nifi/README' },
      items: [
        { type: 'doc', id: 'services/apache-nifi/installation', label: 'Cài đặt & Triển khai' },
        { type: 'doc', id: 'services/apache-nifi/configuration', label: 'Cấu hình' },
        { type: 'doc', id: 'services/apache-nifi/version-info', label: 'Thông tin Version' },
      ],
    },
    {
      type: 'category',
      label: 'Apache Ranger',
      collapsed: true,
      link: { type: 'doc', id: 'services/apache-ranger/README' },
      items: [
        { type: 'doc', id: 'services/apache-ranger/installation', label: 'Cài đặt & Triển khai' },
        { type: 'doc', id: 'services/apache-ranger/configuration', label: 'Cấu hình' },
        { type: 'doc', id: 'services/apache-ranger/version-info', label: 'Thông tin Version' },
      ],
    },
    {
      type: 'category',
      label: 'Apache Spark',
      collapsed: true,
      link: { type: 'doc', id: 'services/apache-spark/README' },
      items: [
        { type: 'doc', id: 'services/apache-spark/installation', label: 'Cài đặt & Triển khai' },
        { type: 'doc', id: 'services/apache-spark/configuration', label: 'Cấu hình' },
        { type: 'doc', id: 'services/apache-spark/version-info', label: 'Thông tin Version' },
      ],
    },
    {
      type: 'category',
      label: 'Apache Superset',
      collapsed: true,
      link: { type: 'doc', id: 'services/apache-superset/README' },
      items: [
        { type: 'doc', id: 'services/apache-superset/installation', label: 'Cài đặt & Triển khai' },
        { type: 'doc', id: 'services/apache-superset/configuration', label: 'Cấu hình' },
        { type: 'doc', id: 'services/apache-superset/version-info', label: 'Thông tin Version' },
      ],
    },
    // D ─────────────────────────────────────────────────────────
    {
      type: 'category',
      label: 'DataHub',
      collapsed: true,
      link: { type: 'doc', id: 'services/datahub/README' },
      items: [
        { type: 'doc', id: 'services/datahub/installation', label: 'Cài đặt & Triển khai' },
        { type: 'doc', id: 'services/datahub/configuration', label: 'Cấu hình' },
        { type: 'doc', id: 'services/datahub/version-info', label: 'Thông tin Version' },
      ],
    },
    {
      type: 'category',
      label: 'DBT',
      collapsed: true,
      link: { type: 'doc', id: 'services/dbt/README' },
      items: [
        { type: 'doc', id: 'services/dbt/installation', label: 'Cài đặt & Triển khai' },
        { type: 'doc', id: 'services/dbt/configuration', label: 'Cấu hình' },
        { type: 'doc', id: 'services/dbt/version-info', label: 'Thông tin Version' },
      ],
    },
    {
      type: 'category',
      label: 'Dify',
      collapsed: true,
      link: { type: 'doc', id: 'services/dify/README' },
      items: [
        { type: 'doc', id: 'services/dify/installation', label: 'Cài đặt & Triển khai' },
        { type: 'doc', id: 'services/dify/configuration', label: 'Cấu hình' },
        { type: 'doc', id: 'services/dify/version-info', label: 'Thông tin Version' },
      ],
    },
    {
      type: 'category',
      label: 'Dremio',
      collapsed: true,
      link: { type: 'doc', id: 'services/dremio/README' },
      items: [
        { type: 'doc', id: 'services/dremio/installation', label: 'Cài đặt & Triển khai' },
        { type: 'doc', id: 'services/dremio/configuration', label: 'Cấu hình' },
        { type: 'doc', id: 'services/dremio/version-info', label: 'Thông tin Version' },
      ],
    },
    // H ─────────────────────────────────────────────────────────
    {
      type: 'category',
      label: 'HashiCorp Vault',
      collapsed: true,
      link: { type: 'doc', id: 'services/hashicorp-vault/README' },
      items: [
        { type: 'doc', id: 'services/hashicorp-vault/installation', label: 'Cài đặt & Triển khai' },
        { type: 'doc', id: 'services/hashicorp-vault/configuration', label: 'Cấu hình' },
        { type: 'doc', id: 'services/hashicorp-vault/version-info', label: 'Thông tin Version' },
      ],
    },
    // L ─────────────────────────────────────────────────────────
    {
      type: 'category',
      label: 'Langfuse',
      collapsed: true,
      link: { type: 'doc', id: 'services/langfuse/README' },
      items: [
        { type: 'doc', id: 'services/langfuse/installation', label: 'Cài đặt & Triển khai' },
        { type: 'doc', id: 'services/langfuse/configuration', label: 'Cấu hình' },
        { type: 'doc', id: 'services/langfuse/version-info', label: 'Thông tin Version' },
      ],
    },
    // M ─────────────────────────────────────────────────────────
    {
      type: 'category',
      label: 'MinIO',
      collapsed: true,
      link: { type: 'doc', id: 'services/minio/README' },
      items: [
        { type: 'doc', id: 'services/minio/installation', label: 'Cài đặt & Triển khai' },
        { type: 'doc', id: 'services/minio/configuration', label: 'Cấu hình' },
        { type: 'doc', id: 'services/minio/version-info', label: 'Thông tin Version' },
      ],
    },
    // O ─────────────────────────────────────────────────────────
    {
      type: 'category',
      label: 'OpenObserve',
      collapsed: true,
      link: { type: 'doc', id: 'services/openobserve/README' },
      items: [
        { type: 'doc', id: 'services/openobserve/installation', label: 'Cài đặt & Triển khai' },
        { type: 'doc', id: 'services/openobserve/configuration', label: 'Cấu hình' },
        { type: 'doc', id: 'services/openobserve/version-info', label: 'Thông tin Version' },
      ],
    },
    // V ─────────────────────────────────────────────────────────
    {
      type: 'category',
      label: 'vLLM',
      collapsed: true,
      link: { type: 'doc', id: 'services/vllm/README' },
      items: [
        { type: 'doc', id: 'services/vllm/installation', label: 'Cài đặt & Triển khai' },
        { type: 'doc', id: 'services/vllm/configuration', label: 'Cấu hình' },
        { type: 'doc', id: 'services/vllm/version-info', label: 'Thông tin Version' },
      ],
    },
  ],
};

export default sidebars;
