import React from 'react';
import styles from './styles.module.css';

interface Capability {
  number: string;
  title: string;
  description: string;
  technologies: string[];
  link: string;
}

const capabilities: Capability[] = [
  {
    number: '01',
    title: 'Ingestion & Streaming',
    description: 'Kết nối dữ liệu batch và real-time từ hệ thống lõi, ứng dụng, thiết bị và dịch vụ bên ngoài.',
    technologies: ['NiFi', 'Kafka', 'Debezium'],
    link: '/ingestion',
  },
  {
    number: '02',
    title: 'Open Lakehouse',
    description: 'Xây dựng lớp lưu trữ thống nhất, linh hoạt và không khóa chặt dữ liệu vào một nhà cung cấp.',
    technologies: ['MinIO', 'Iceberg', 'Polaris'],
    link: '/storage',
  },
  {
    number: '03',
    title: 'Processing & Modeling',
    description: 'Điều phối, xử lý và chuẩn hóa dữ liệu thành các mô hình có ngữ nghĩa, sẵn sàng cho phân tích.',
    technologies: ['Spark', 'Airflow', 'dbt'],
    link: '/processing',
  },
  {
    number: '04',
    title: 'Governance & Security',
    description: 'Quản lý metadata, lineage, phân quyền và chính sách bảo mật từ một lớp kiểm soát tập trung.',
    technologies: ['DataHub', 'Ranger', 'Vault'],
    link: '/governance',
  },
  {
    number: '05',
    title: 'Data Access & BI',
    description: 'Cung cấp dữ liệu hiệu năng cao cho SQL, semantic layer, dashboard, API và ứng dụng nghiệp vụ.',
    technologies: ['Dremio', 'Superset'],
    link: '/federation',
  },
  {
    number: '06',
    title: 'Enterprise AI Services',
    description: 'Đưa GenAI vào doanh nghiệp với LLM tự quản, workflow thông minh và khả năng đánh giá, giám sát đầy đủ.',
    technologies: ['Dify', 'vLLM', 'Langfuse'],
    link: '/ai-service',
  },
];

function CapabilityCard({number, title, description, technologies, link}: Capability): React.JSX.Element {
  return (
    <article className={styles.card}>
      <div className={styles.cardTopline}>
        <span className={styles.cardNumber}>{number}</span>
        <span className={styles.cardSignal} aria-hidden="true" />
      </div>
      <h3>{title}</h3>
      <p>{description}</p>
      <div className={styles.cardFooter}>
        <div className={styles.technologies}>
          {technologies.map((technology) => (
            <span key={technology}>{technology}</span>
          ))}
        </div>
        <a href={link} aria-label={`Tìm hiểu ${title}`}>
          <span aria-hidden="true">↗</span>
        </a>
      </div>
    </article>
  );
}

export default function PlatformGrid(): React.JSX.Element {
  return (
    <section className={styles.section} id="capabilities">
      <div className="container">
        <div className={styles.header}>
          <div>
            <span className={styles.eyebrow}>Năng lực nền tảng</span>
            <h2>Một nền tảng. Toàn bộ vòng đời dữ liệu.</h2>
          </div>
          <p>
            Hanas kết nối các năng lực data engineering, analytics, governance và AI thành
            một hệ sinh thái đồng nhất — từ hạ tầng đến trải nghiệm người dùng cuối.
          </p>
        </div>

        <div className={styles.grid}>
          {capabilities.map((capability) => (
            <CapabilityCard key={capability.number} {...capability} />
          ))}
        </div>
      </div>
    </section>
  );
}
