import React from 'react';
import styles from './styles.module.css';

interface FeatureCard {
  id: string;
  title: string;
  description: string;
  iconSrc: string;
  link: string;
}

const features: FeatureCard[] = [
  {
    id: 'collection',
    title: 'Thu Thập Dữ Liệu',
    description: 'Thu thập dữ liệu từ mọi nguồn với NiFi và Kafka',
    iconSrc: '/img/card-icon/data-ingestion.png',
    link: '/ingestion',
  },
  {
    id: 'storage',
    title: 'Lưu Trữ Dữ Liệu',
    description: 'Lưu trữ quy mô lớn với MinIO và Apache Iceberg',
    iconSrc: '/img/card-icon/data-storage.png',
    link: '/storage',
  },
  {
    id: 'processing',
    title: 'Xử Lý Dữ Liệu',
    description: 'Xử lý và transform dữ liệu với Spark và Airflow',
    iconSrc: '/img/card-icon/data-processing.png',
    link: '/processing',
  },
  {
    id: 'modeling',
    title: 'Mô Hình Dữ Liệu',
    description: 'Xây dựng mô hình với dbt và Data Vault',
    iconSrc: '/img/card-icon/data-model.png',
    link: '/data-model',
  },
  {
    id: 'governance',
    title: 'Quản Trị Dữ Liệu',
    description: 'Quản lý metadata và bảo mật với DataHub',
    iconSrc: '/img/card-icon/data-governance.png',
    link: '/governance',
  },
  {
    id: 'query',
    title: 'Truy Vấn Dữ Liệu',
    description: 'Truy vấn federated với Dremio SQL Engine',
    iconSrc: '/img/card-icon/Data-analytics.png',
    link: '/federation',
  },
  {
    id: 'ai',
    title: 'Dịch Vụ AI',
    description: 'Tích hợp AI với Dify, vLLM và Langfuse cho các tác vụ thông minh',
    iconSrc: '/img/card-icon/genAI.png',
    link: '/ai-service',
  },
];

const FeatureCardComponent: React.FC<FeatureCard> = ({ title, description, iconSrc, link }) => (
  <div className={`feature-card ${styles.card}`}>
    <div className={styles.iconWrapper}>
      <img src={iconSrc} alt={title} className={styles.cardIcon} />
    </div>
    <h3 className={styles.cardTitle}>{title}</h3>
    <p className={styles.cardDescription}>{description}</p>
    <a href={link} className="button--link">
      Tìm hiểu thêm
      <svg className="link-arrow" width="16" height="16" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M5 12H19M19 12L12 5M19 12L12 19" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
      </svg>
    </a>
  </div>
);

const PlatformGrid: React.FC = () => {
  return (
    <section className={styles.section}>
      <div className="container">
        <div className={styles.header}>
          <h2 className={styles.title}>Đơn giản hóa kiến trúc dữ liệu</h2>
          <p className={styles.subtitle}>
            Nền tảng Hanas cung cấp giải pháp toàn diện cho mọi nhu cầu xử lý dữ liệu
          </p>
        </div>
        <div className={styles.grid}>
          {features.map((feature) => (
            <FeatureCardComponent key={feature.id} {...feature} />
          ))}
        </div>
      </div>
    </section>
  );
};

export default PlatformGrid;
