import React from 'react';
import styles from './styles.module.css';

interface FeatureCard {
  id: string;
  title: string;
  description: string;
  icon: React.ReactNode;
  link: string;
}

// Inline SVG icons - 32x32 with currentColor for theme compatibility
const icons = {
  // Thu Thập Dữ Liệu: Database/flow icon (data pipeline)
  collection: (
    <svg width="32" height="32" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M12 2C6.48 2 2 3.79 2 6V18C2 20.21 6.48 22 12 22C17.52 22 22 20.21 22 18V6C22 3.79 17.52 2 12 2Z" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
      <path d="M2 6C2 8.21 6.48 10 12 10C17.52 10 22 8.21 22 6" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
      <path d="M2 12C2 14.21 6.48 16 12 16C17.52 16 22 14.21 22 12" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  ),
  // Lưu Trữ Dữ Liệu: Layers/storage icon
  storage: (
    <svg width="32" height="32" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M12 2L2 7L12 12L22 7L12 2Z" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
      <path d="M2 17L12 22L22 17" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
      <path d="M2 12L12 17L22 12" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  ),
  // Xử Lý Dữ Liệu: Gear/process icon
  processing: (
    <svg width="32" height="32" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <circle cx="12" cy="12" r="3" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
      <path d="M19.4 15C19.2669 15.3016 19.2272 15.6362 19.286 15.9606C19.3448 16.285 19.4995 16.5843 19.73 16.82L19.79 16.88C19.976 17.0657 20.1235 17.2863 20.2241 17.5291C20.3248 17.7719 20.3766 18.0322 20.3766 18.295C20.3766 18.5578 20.3248 18.8181 20.2241 19.0609C20.1235 19.3037 19.976 19.5243 19.79 19.71C19.6043 19.896 19.3837 20.0435 19.1409 20.1441C18.8981 20.2448 18.6378 20.2966 18.375 20.2966C18.1122 20.2966 17.8519 20.2448 17.6091 20.1441C17.3663 20.0435 17.1457 19.896 16.96 19.71L16.9 19.65C16.6643 19.4195 16.365 19.2648 16.0406 19.206C15.7162 19.1472 15.3816 19.1869 15.08 19.32C14.7842 19.4465 14.532 19.6573 14.3553 19.9255C14.1786 20.1937 14.0856 20.5072 14.09 20.827V21C14.09 21.5304 13.8793 22.0391 13.5042 22.4142C13.1291 22.7893 12.6204 23 12.09 23C11.5596 23 11.0509 22.7893 10.6758 22.4142C10.3007 22.0391 10.09 21.5304 10.09 21V20.91C10.0944 20.5902 10.0014 20.2767 9.8247 20.0085C9.648 19.7403 9.3958 19.5295 9.1 19.403C8.79838 19.2699 8.46381 19.2302 8.13941 19.289C7.81501 19.3478 7.51571 19.5025 7.28 19.733L7.22 19.793C7.03428 19.979 6.81368 20.1265 6.57088 20.2271C6.32808 20.3278 6.06783 20.3796 5.805 20.3796C5.54217 20.3796 5.28192 20.3278 5.03912 20.2271C4.79632 20.1265 4.57572 19.979 4.39 19.793C4.20401 19.6073 4.0565 19.3867 3.95588 19.1439C3.85526 18.9011 3.80343 18.6408 3.80343 18.378C3.80343 18.1152 3.85526 17.8549 3.95588 17.6121C4.0565 17.3693 4.20401 17.1487 4.39 16.963L4.45 16.903C4.68054 16.6673 4.83519 16.368 4.89399 16.0436C4.95279 15.7192 4.91312 15.3846 4.78 15.083C4.65347 14.7872 4.44267 14.535 4.17446 14.3583C3.90625 14.1816 3.59279 14.0886 3.273 14.093H3.1C2.56957 14.093 2.06086 13.8823 1.68579 13.5072C1.31071 13.1321 1.1 12.6234 1.1 12.093C1.1 11.5626 1.31071 11.0539 1.68579 10.6788C2.06086 10.3037 2.56957 10.093 3.1 10.093H3.19C3.50979 10.0974 3.82325 10.0044 4.09146 9.8277C4.35967 9.65101 4.57047 9.39881 4.697 9.103C4.83012 8.80138 4.86979 8.46681 4.81099 8.14241C4.75219 7.81801 4.59754 7.51871 4.367 7.283L4.307 7.223C4.12101 7.03728 3.9735 6.81668 3.87288 6.57388C3.77226 6.33108 3.72043 6.07083 3.72043 5.808C3.72043 5.54517 3.77226 5.28492 3.87288 5.04212C3.9735 4.79932 4.12101 4.57872 4.307 4.393C4.49272 4.20701 4.71332 4.0595 4.95612 3.95888C5.19892 3.85826 5.45917 3.80643 5.722 3.80643C5.98483 3.80643 6.24508 3.85826 6.48788 3.95888C6.73068 4.0595 6.95128 4.20701 7.137 4.393L7.197 4.453C7.43271 4.68354 7.73201 4.83819 8.05641 4.89699C8.38081 4.95579 8.71538 4.91612 9.017 4.783H9.1C9.3958 4.65647 9.648 4.44567 9.8247 4.17746C10.0014 3.90925 10.0944 3.59579 10.09 3.276V3.1C10.09 2.56957 10.3007 2.06086 10.6758 1.68579C11.0509 1.31071 11.5596 1.1 12.09 1.1C12.6204 1.1 13.1291 1.31071 13.5042 1.68579C13.8793 2.06086 14.09 2.56957 14.09 3.1V3.19C14.0856 3.50979 14.1786 3.82325 14.3553 4.09146C14.532 4.35967 14.7842 4.57047 15.08 4.697C15.3816 4.83012 15.7162 4.86979 16.0406 4.81099C16.365 4.75219 16.6643 4.59754 16.9 4.367L16.96 4.307C17.1457 4.12101 17.3663 3.9735 17.6091 3.87288C17.8519 3.77226 18.1122 3.72043 18.375 3.72043C18.6378 3.72043 18.8981 3.77226 19.1409 3.87288C19.3837 3.9735 19.6043 4.12101 19.79 4.307C19.976 4.49272 20.1235 4.71332 20.2241 4.95612C20.3248 5.19892 20.3766 5.45917 20.3766 5.722C20.3766 5.98483 20.3248 6.24508 20.2241 6.48788C20.1235 6.73068 19.976 6.95128 19.79 7.137L19.73 7.197C19.4995 7.43271 19.3448 7.73201 19.286 8.05641C19.2272 8.38081 19.2669 8.71538 19.4 9.017V9.1C19.5265 9.3958 19.7373 9.648 20.0055 9.8247C20.2737 10.0014 20.5872 10.0944 20.907 10.09H21C21.5304 10.09 22.0391 10.3007 22.4142 10.6758C22.7893 11.0509 23 11.5596 23 12.09C23 12.6204 22.7893 13.1291 22.4142 13.5042C22.0391 13.8793 21.5304 14.09 21 14.09H20.91C20.5902 14.0944 20.2767 14.1874 20.0085 14.3641C19.7403 14.5408 19.5295 14.793 19.403 15.088L19.4 15Z" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  ),
  // Mô Hình Dữ Liệu: Cube/structure icon
  modeling: (
    <svg width="32" height="32" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M21 16.5C21 16.88 20.79 17.21 20.47 17.38L12.57 21.82C12.41 21.94 12.21 22 12 22C11.79 22 11.59 21.94 11.43 21.82L3.53 17.38C3.21 17.21 3 16.88 3 16.5V7.5C3 7.12 3.21 6.79 3.53 6.62L11.43 2.18C11.59 2.06 11.79 2 12 2C12.21 2 12.41 2.06 12.57 2.18L20.47 6.62C20.79 6.79 21 7.12 21 7.5V16.5Z" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
      <path d="M12 12L21 7.5" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
      <path d="M12 12V22" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
      <path d="M12 12L3 7.5" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
      <path d="M17 4.5L7 10" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  ),
  // Quản Trị Dữ Liệu: Shield/governance icon
  governance: (
    <svg width="32" height="32" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M12 22C12 22 20 18 20 12V5L12 2L4 5V12C4 18 12 22 12 22Z" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
      <path d="M9 12L11 14L15 10" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  ),
  // Truy Vấn Dữ Liệu: Search/query icon
  query: (
    <svg width="32" height="32" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <circle cx="11" cy="11" r="8" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
      <path d="M21 21L16.65 16.65" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
      <path d="M8 11H14" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  ),
  // Dịch Vụ AI: Sparkle/brain icon
  ai: (
    <svg width="32" height="32" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M12 2L14.4 9.6L22 12L14.4 14.4L12 22L9.6 14.4L2 12L9.6 9.6L12 2Z" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
      <path d="M19 5L20 3L22 4L21 6L19 5Z" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
      <path d="M4 19L5 17L7 18L6 20L4 19Z" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  ),
};

const features: FeatureCard[] = [
  {
    id: 'collection',
    title: 'Thu Thập Dữ Liệu',
    description: 'Thu thập dữ liệu từ mọi nguồn với NiFi và Kafka',
    icon: icons.collection,
    link: '/ingestion',
  },
  {
    id: 'storage',
    title: 'Lưu Trữ Dữ Liệu',
    description: 'Lưu trữ quy mô lớn với MinIO và Apache Iceberg',
    icon: icons.storage,
    link: '/storage',
  },
  {
    id: 'processing',
    title: 'Xử Lý Dữ Liệu',
    description: 'Xử lý và transform dữ liệu với Spark và Airflow',
    icon: icons.processing,
    link: '/processing',
  },
  {
    id: 'modeling',
    title: 'Mô Hình Dữ Liệu',
    description: 'Xây dựng mô hình với dbt và Data Vault',
    icon: icons.modeling,
    link: '/data-model',
  },
  {
    id: 'governance',
    title: 'Quản Trị Dữ Liệu',
    description: 'Quản lý metadata và bảo mật với DataHub',
    icon: icons.governance,
    link: '/governance',
  },
  {
    id: 'query',
    title: 'Truy Vấn Dữ Liệu',
    description: 'Truy vấn federated với Dremio SQL Engine',
    icon: icons.query,
    link: '/federation',
  },
  {
    id: 'ai',
    title: 'Dịch Vụ AI',
    description: 'Tích hợp AI với Dify, vLLM và Langfuse cho các tác vụ thông minh',
    icon: icons.ai,
    link: '/ai-service',
  },
];

const FeatureCardComponent: React.FC<FeatureCard> = ({ title, description, icon, link }) => (
  <div className={styles.card}>
    <div className={styles.iconWrapper}>
      {icon}
    </div>
    <h3 className={styles.cardTitle}>{title}</h3>
    <p className={styles.cardDescription}>{description}</p>
    <a href={link} className={styles.link}>
      Tìm hiểu thêm
      <svg className={styles.linkArrow} width="16" height="16" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
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
