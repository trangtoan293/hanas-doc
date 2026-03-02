import React from 'react';
import styles from './styles.module.css';

interface TechItem {
  id: string;
  name: string;
  displayName: string;
  hasIcon: boolean;
  iconUrl?: string;
  bgColor?: string;
}

const technologies: TechItem[] = [
  {
    id: 'nifi',
    name: 'Apache NiFi',
    displayName: 'NiFi',
    hasIcon: false,
    bgColor: '#728E9B',
  },
  {
    id: 'kafka',
    name: 'Apache Kafka',
    displayName: 'Kafka',
    hasIcon: true,
    iconUrl: 'https://cdn.simpleicons.org/apachekafka',
  },
  {
    id: 'spark',
    name: 'Apache Spark',
    displayName: 'Spark',
    hasIcon: true,
    iconUrl: 'https://cdn.simpleicons.org/apachespark',
  },
  {
    id: 'airflow',
    name: 'Apache Airflow',
    displayName: 'Airflow',
    hasIcon: true,
    iconUrl: 'https://cdn.simpleicons.org/apacheairflow',
  },
  {
    id: 'minio',
    name: 'MinIO',
    displayName: 'MinIO',
    hasIcon: false,
    bgColor: '#C72E49',
  },
  {
    id: 'iceberg',
    name: 'Apache Iceberg',
    displayName: 'Iceberg',
    hasIcon: true,
    iconUrl: 'https://cdn.simpleicons.org/apacheiceberg',
  },
  {
    id: 'dbt',
    name: 'dbt',
    displayName: 'dbt',
    hasIcon: true,
    iconUrl: 'https://cdn.simpleicons.org/dbt',
  },
  {
    id: 'datahub',
    name: 'DataHub',
    displayName: 'DataHub',
    hasIcon: false,
    bgColor: '#1890FF',
  },
  {
    id: 'dremio',
    name: 'Dremio',
    displayName: 'Dremio',
    hasIcon: false,
    bgColor: '#1E90FF',
  },
  {
    id: 'kubernetes',
    name: 'Kubernetes',
    displayName: 'K8s',
    hasIcon: true,
    iconUrl: 'https://cdn.simpleicons.org/kubernetes',
  },
  {
    id: 'openobserve',
    name: 'OpenObserve',
    displayName: 'OpenObserve',
    hasIcon: false,
    bgColor: '#6347FF',
  },
  {
    id: 'dify',
    name: 'Dify',
    displayName: 'Dify',
    hasIcon: false,
    bgColor: '#1C64F2',
  },
  {
    id: 'vllm',
    name: 'vLLM',
    displayName: 'vLLM',
    hasIcon: false,
    bgColor: '#2D3748',
  },
];

const TechLogo: React.FC<{ tech: TechItem }> = ({ tech }) => {
  if (tech.hasIcon && tech.iconUrl) {
    return (
      <img
        src={tech.iconUrl}
        alt={tech.name}
        className={styles.logo}
        loading="lazy"
      />
    );
  }

  // Fallback: styled text badge
  return (
    <div
      className={styles.fallbackLogo}
      style={{ backgroundColor: tech.bgColor }}
    >
      <span>{tech.displayName}</span>
    </div>
  );
};

const TechStackSection: React.FC = () => {
  return (
    <section className={styles.section}>
      <div className="container">
        <div className={styles.header}>
          <h2 className={styles.title}>Công Nghệ Được Sử Dụng</h2>
          <p className={styles.subtitle}>
            Nền tảng Hanas tích hợp các công nghệ hàng đầu trong hệ sinh thái Data Lakehouse
          </p>
        </div>
        <div className={styles.grid}>
          {technologies.map((tech) => (
            <div key={tech.id} className={styles.techItem} title={tech.name}>
              <TechLogo tech={tech} />
              <span className={styles.techName}>{tech.name}</span>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};

export default TechStackSection;
