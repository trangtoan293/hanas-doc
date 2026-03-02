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
      link: {
        type: 'doc',
        id: 'ingestion/README',
      },
      items: [
        {
          type: 'category',
          label: 'Apache NiFi',
          items: [
            'ingestion/apache-nifi/README',
            'ingestion/apache-nifi/installation',
            'ingestion/apache-nifi/configuration',
            'ingestion/apache-nifi/user-guide',
            'ingestion/apache-nifi/best-practices',
            'ingestion/apache-nifi/version-info',
          ],
        },
        {
          type: 'category',
          label: 'Apache Kafka',
          items: [
            'ingestion/apache-kafka/README',
            'ingestion/apache-kafka/installation',
            'ingestion/apache-kafka/configuration',
            'ingestion/apache-kafka/user-guide',
            'ingestion/apache-kafka/best-practices',
            'ingestion/apache-kafka/version-info',
          ],
        },
      ],
    },
    {
      type: 'category',
      label: 'Lưu Trữ Dữ Liệu',
      collapsed: true,
      link: {
        type: 'doc',
        id: 'storage/README',
      },
      items: [
        {
          type: 'category',
          label: 'MinIO',
          items: [
            'storage/minio/README',
            'storage/minio/installation',
            'storage/minio/configuration',
            'storage/minio/user-guide',
            'storage/minio/best-practices',
            'storage/minio/version-info',
          ],
        },
        {
          type: 'category',
          label: 'Apache Iceberg',
          items: [
            'storage/apache-iceberg/README',
            'storage/apache-iceberg/installation',
            'storage/apache-iceberg/configuration',
            'storage/apache-iceberg/user-guide',
            'storage/apache-iceberg/best-practices',
            'storage/apache-iceberg/version-info',
          ],
        },
      ],
    },
    {
      type: 'category',
      label: 'Xử Lý Dữ Liệu',
      collapsed: true,
      link: {
        type: 'doc',
        id: 'processing/README',
      },
      items: [
        {
          type: 'category',
          label: 'Apache Airflow',
          items: [
            'processing/apache-airflow/README',
            'processing/apache-airflow/installation',
            'processing/apache-airflow/configuration',
            'processing/apache-airflow/user-guide',
            'processing/apache-airflow/best-practices',
            'processing/apache-airflow/version-info',
          ],
        },
        {
          type: 'category',
          label: 'Apache Spark',
          items: [
            'processing/apache-spark/README',
            'processing/apache-spark/installation',
            'processing/apache-spark/configuration',
            'processing/apache-spark/user-guide',
            'processing/apache-spark/best-practices',
            'processing/apache-spark/version-info',
          ],
        },
      ],
    },
    {
      type: 'category',
      label: 'Mô Hình Dữ Liệu',
      collapsed: true,
      link: {
        type: 'doc',
        id: 'data-model/README',
      },
      items: [
        'data-model/naming-conventions',
        {
          type: 'category',
          label: 'dbt',
          items: [
            'data-model/dbt/README',
            'data-model/dbt/installation',
            'data-model/dbt/configuration',
            'data-model/dbt/user-guide',
            'data-model/dbt/best-practices',
            'data-model/dbt/version-info',
          ],
        },
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
      link: {
        type: 'doc',
        id: 'governance/README',
      },
      items: [
        {
          type: 'category',
          label: 'DataHub',
          items: [
            'governance/datahub/README',
            'governance/datahub/installation',
            'governance/datahub/configuration',
            'governance/datahub/user-guide',
            'governance/datahub/best-practices',
            'governance/datahub/version-info',
          ],
        },
      ],
    },
    {
      type: 'category',
      label: 'Liên Kết Dữ Liệu',
      collapsed: true,
      link: {
        type: 'doc',
        id: 'federation/README',
      },
      items: [
        {
          type: 'category',
          label: 'Dremio',
          items: [
            'federation/dremio/README',
            'federation/dremio/installation',
            'federation/dremio/configuration',
            'federation/dremio/user-guide',
            'federation/dremio/best-practices',
            'federation/dremio/version-info',
          ],
        },
      ],
    },
    {
      type: 'category',
      label: 'Quản Trị Hệ Thống',
      collapsed: true,
      link: {
        type: 'doc',
        id: 'system-management/README',
      },
      items: [
        {
          type: 'category',
          label: 'OpenObserve',
          items: [
            'system-management/openobserve/README',
            'system-management/openobserve/installation',
            'system-management/openobserve/configuration',
            'system-management/openobserve/user-guide',
            'system-management/openobserve/best-practices',
            'system-management/openobserve/version-info',
          ],
        },
      ],
    },
    {
      type: 'category',
      label: 'Hạ Tầng',
      collapsed: true,
      link: {
        type: 'doc',
        id: 'infrastructure/README',
      },
      items: [
        'infrastructure/deployment-diagram',
        {
          type: 'category',
          label: 'Kubernetes',
          items: [
            'infrastructure/kubernetes/README',
            'infrastructure/kubernetes/cluster-setup',
            'infrastructure/kubernetes/best-practices',
          ],
        },
        {
          type: 'category',
          label: 'DC-DR',
          items: [
            'infrastructure/dc-dr/README',
            'infrastructure/dc-dr/minio-replication',
            'infrastructure/dc-dr/velero-backup',
            'infrastructure/dc-dr/recovery-workflow',
          ],
        },
      ],
    },
    {
      type: 'category',
      label: 'An Toàn Thông Tin',
      collapsed: true,
      link: {
        type: 'doc',
        id: 'security/README',
      },
      items: [
        'security/authentication',
        'security/authorization',
        {
          type: 'category',
          label: 'Apache Ranger',
          items: [
            'security/apache-ranger/README',
            'security/apache-ranger/installation',
            'security/apache-ranger/configuration',
            'security/apache-ranger/user-guide',
          ],
        },
        {
          type: 'category',
          label: 'HashiCorp Vault',
          items: [
            'security/hashicorp-vault/README',
            'security/hashicorp-vault/installation',
            'security/hashicorp-vault/configuration',
            'security/hashicorp-vault/user-guide',
          ],
        },
      ],
    },

    {
      type: 'category',
      label: 'AI Service',
      collapsed: true,
      link: {
        type: 'doc',
        id: 'ai-service/README',
      },
      items: [
        {
          type: 'category',
          label: 'Dify',
          items: [
            'ai-service/dify/README',
            'ai-service/dify/installation',
            'ai-service/dify/configuration',
            'ai-service/dify/user-guide',
            'ai-service/dify/best-practices',
            'ai-service/dify/version-info',
          ],
        },
        {
          type: 'category',
          label: 'vLLM',
          items: [
            'ai-service/vllm/README',
            'ai-service/vllm/installation',
            'ai-service/vllm/configuration',
            'ai-service/vllm/user-guide',
            'ai-service/vllm/best-practices',
            'ai-service/vllm/version-info',
          ],
        },
        {
          type: 'category',
          label: 'Langfuse',
          items: [
            'ai-service/langfuse/README',
            'ai-service/langfuse/installation',
            'ai-service/langfuse/configuration',
            'ai-service/langfuse/user-guide',
            'ai-service/langfuse/best-practices',
            'ai-service/langfuse/version-info',
          ],
        },
      ],
    },

  ],
};

export default sidebars;
