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
    description: 'Đưa dữ liệu từ mọi hệ thống về một nơi, theo lô hoặc ngay khi phát sinh — không còn chờ batch đêm.',
    technologies: ['NiFi', 'Kafka', 'Debezium'],
    link: '/ingestion',
  },
  {
    number: '02',
    title: 'Open Lakehouse',
    description: 'Dữ liệu nằm ở định dạng mở và thuộc về doanh nghiệp — đổi công cụ xử lý mà không phải chuyển kho.',
    technologies: ['MinIO', 'Iceberg', 'Polaris'],
    link: '/storage',
  },
  {
    number: '03',
    title: 'Processing & Modeling',
    description: 'Mỗi phòng ban đọc ra cùng một con số, vì cùng lấy từ một mô hình dữ liệu đã được chuẩn hóa.',
    technologies: ['Spark', 'Airflow', 'dbt'],
    link: '/processing',
  },
  {
    number: '04',
    title: 'Governance & Security',
    description: 'Biết rõ dữ liệu đến từ đâu, ai được xem, ai đã dùng — trả lời được mọi câu hỏi của kiểm toán.',
    technologies: ['DataHub', 'Ranger', 'Vault'],
    link: '/governance',
  },
  {
    number: '05',
    title: 'Data Access & BI',
    description: 'Đội nghiệp vụ tự lấy được dữ liệu cần, qua dashboard hay API, không phải mở ticket chờ IT.',
    technologies: ['Dremio', 'Superset'],
    link: '/federation',
  },
  {
    number: '06',
    title: 'Enterprise AI Services',
    description: 'Chạy AI trên dữ liệu nội bộ, trong hạ tầng của doanh nghiệp — đo được cả chất lượng lẫn chi phí.',
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
            Sáu lớp năng lực, từ lúc dữ liệu đi vào đến khi ra quyết định. Tất cả chạy
            trên cùng một nền tảng, cùng một cách quản trị.
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
