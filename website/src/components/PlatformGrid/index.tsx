import React from 'react';
import styles from './styles.module.css';

interface FeatureCard {
  id: string;
  title: string;
  description: string;
  icon: React.ReactNode;
  link: string;
}

const features: FeatureCard[] = [
  {
    id: 'collection',
    title: 'Thu Thập Dữ Liệu',
    description: 'Thu thập dữ liệu từ mọi nguồn với NiFi và Kafka',
    icon: (
      <svg width="40" height="40" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M12 2C6.48 2 2 6.48 2 12C2 17.52 6.48 22 12 22C17.52 22 22 17.52 22 12C22 6.48 17.52 2 12 2ZM12 20C7.59 20 4 16.41 4 12C4 7.59 7.59 4 12 4C16.41 4 20 7.59 20 12C20 16.41 16.41 20 12 20Z" fill="#29B5E8" />
        <path d="M12 6C8.69 6 6 8.69 6 12C6 15.31 8.69 18 12 18C15.31 18 18 15.31 18 12C18 8.69 15.31 6 12 6ZM12 16C9.79 16 8 14.21 8 12C8 9.79 9.79 8 12 8C14.21 8 16 9.79 16 12C16 14.21 14.21 16 12 16Z" fill="#29B5E8" />
        <circle cx="12" cy="12" r="2" fill="#FF9F36" />
      </svg>
    ),
    link: '/ingestion',
  },
  {
    id: 'storage',
    title: 'Lưu Trữ Dữ Liệu',
    description: 'Lưu trữ quy mô lớn với MinIO và Apache Iceberg',
    icon: (
      <svg width="40" height="40" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <rect x="3" y="4" width="18" height="4" rx="1" fill="#29B5E8" />
        <rect x="3" y="10" width="18" height="4" rx="1" fill="#4DC3ED" />
        <rect x="3" y="16" width="18" height="4" rx="1" fill="#71D1F2" />
        <rect x="5" y="6" width="4" height="1" fill="#FF9F36" />
        <rect x="5" y="12" width="4" height="1" fill="#FF9F36" />
        <rect x="5" y="18" width="4" height="1" fill="#FF9F36" />
      </svg>
    ),
    link: '/storage',
  },
  {
    id: 'processing',
    title: 'Xử Lý Dữ Liệu',
    description: 'Xử lý và transform dữ liệu với Spark và Airflow',
    icon: (
      <svg width="40" height="40" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M12 2L2 7L12 12L22 7L12 2Z" fill="#29B5E8" />
        <path d="M2 17L12 22L22 17" stroke="#4DC3ED" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
        <path d="M2 12L12 17L22 12" stroke="#71D1F2" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
        <circle cx="12" cy="7" r="2" fill="#FF9F36" />
      </svg>
    ),
    link: '/processing',
  },
  {
    id: 'modeling',
    title: 'Mô Hình Dữ Liệu',
    description: 'Xây dựng mô hình với dbt và Data Vault',
    icon: (
      <svg width="40" height="40" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M12 2L3 7V17L12 22L21 17V7L12 2Z" stroke="#29B5E8" strokeWidth="2" strokeLinejoin="round" />
        <path d="M12 12L21 7" stroke="#4DC3ED" strokeWidth="2" />
        <path d="M12 12V22" stroke="#4DC3ED" strokeWidth="2" />
        <path d="M12 12L3 7" stroke="#4DC3ED" strokeWidth="2" />
        <circle cx="12" cy="12" r="3" fill="#FF9F36" />
      </svg>
    ),
    link: '/data-model',
  },
  {
    id: 'governance',
    title: 'Quản Trị Dữ Liệu',
    description: 'Quản lý metadata và bảo mật với DataHub',
    icon: (
      <svg width="40" height="40" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <circle cx="12" cy="12" r="10" stroke="#29B5E8" strokeWidth="2" />
        <path d="M12 6V12L16 14" stroke="#4DC3ED" strokeWidth="2" strokeLinecap="round" />
        <path d="M12 2C12 2 8 4 8 8C8 12 12 10 12 10C12 10 16 12 16 8C16 4 12 2 12 2Z" fill="#FF9F36" />
      </svg>
    ),
    link: '/governance',
  },
  {
    id: 'query',
    title: 'Truy Vấn Dữ Liệu',
    description: 'Truy vấn federated với Dremio SQL Engine',
    icon: (
      <svg width="40" height="40" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <rect x="4" y="4" width="16" height="16" rx="2" stroke="#29B5E8" strokeWidth="2" />
        <path d="M4 8H20" stroke="#4DC3ED" strokeWidth="2" />
        <path d="M8 4V8" stroke="#4DC3ED" strokeWidth="2" />
        <path d="M8 12H16" stroke="#71D1F2" strokeWidth="2" />
        <path d="M8 16H13" stroke="#71D1F2" strokeWidth="2" />
        <circle cx="17" cy="16" r="2" fill="#FF9F36" />
      </svg>
    ),
    link: '/federation',
  },
  {
    id: 'ai',
    title: 'Dịch Vụ AI',
    description: 'Tích hợp AI với Dify, vLLM và Langfuse cho các tác vụ thông minh',
    icon: (
      <svg width="40" height="40" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M12 2L4 6V12C4 16.4183 7.58172 20 12 22C16.4183 20 20 16.4183 20 12V6L12 2Z" stroke="#29B5E8" strokeWidth="2" strokeLinejoin="round"/>
        <path d="M12 6V14" stroke="#4DC3ED" strokeWidth="2" strokeLinecap="round"/>
        <path d="M9 11L12 14L15 11" stroke="#71D1F2" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
        <circle cx="12" cy="16" r="2" fill="#FF9F36"/>
        <path d="M8 8H10" stroke="#FF9F36" strokeWidth="2" strokeLinecap="round"/>
        <path d="M14 8H16" stroke="#FF9F36" strokeWidth="2" strokeLinecap="round"/>
      </svg>
    ),
    link: '/ai-service',
  },
];

const FeatureCardComponent: React.FC<FeatureCard> = ({ title, description, icon, link }) => (
  <div className={`feature-card ${styles.card}`}>
    <div className={styles.iconWrapper}>{icon}</div>
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
