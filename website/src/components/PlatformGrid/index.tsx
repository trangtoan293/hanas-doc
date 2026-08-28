import React from 'react';
import styles from './styles.module.css';

interface Capability {
  number: string;
  title: string;
  description: string;
  technologies: string[];
  video: string;
  poster: string;
  link: string;
}

const capabilities: Capability[] = [
  {
    number: '01',
    title: 'Ingestion & Streaming',
    description: 'Đưa dữ liệu từ mọi hệ thống về một nơi, theo lô hoặc ngay khi phát sinh — không còn chờ batch đêm.',
    technologies: ['NiFi', 'Kafka', 'Debezium'],
    video: '/video/data-pipeline.mp4',
    poster: '/img/landing/use-case-operations.webp',
    link: '/ingestion',
  },
  {
    number: '02',
    title: 'Open Lakehouse',
    description: 'Dữ liệu nằm ở định dạng mở và thuộc về doanh nghiệp — đổi công cụ xử lý mà không phải chuyển kho.',
    technologies: ['MinIO', 'Iceberg', 'Polaris'],
    video: '/video/data-sample.mp4',
    poster: '/img/landing/use-case-analytics.webp',
    link: '/storage',
  },
  {
    number: '03',
    title: 'Processing & Modeling',
    description: 'Mỗi phòng ban đọc ra cùng một con số, vì cùng lấy từ một mô hình dữ liệu đã được chuẩn hóa.',
    technologies: ['Spark', 'Airflow', 'dbt'],
    video: '/video/processing-data.mp4',
    poster: '/img/landing/use-case-operations.webp',
    link: '/processing',
  },
  {
    number: '04',
    title: 'Governance & Security',
    description: 'Biết rõ dữ liệu đến từ đâu, ai được xem, ai đã dùng — trả lời được mọi câu hỏi của kiểm toán.',
    technologies: ['DataHub', 'Ranger', 'Vault'],
    video: '/video/Governance & Security.mp4',
    poster: '/img/landing/use-case-financial.webp',
    link: '/governance',
  },
  {
    number: '05',
    title: 'Data Access & BI',
    description: 'Đội nghiệp vụ tự lấy được dữ liệu cần, qua dashboard hay API, không phải mở ticket chờ IT.',
    technologies: ['Dremio', 'Superset'],
    video: '/video/Data Access & BI.mp4',
    poster: '/img/landing/use-case-analytics.webp',
    link: '/federation',
  },
  {
    number: '06',
    title: 'Enterprise AI Services',
    description: 'Chạy AI trên dữ liệu nội bộ, trong hạ tầng của doanh nghiệp — đo được cả chất lượng lẫn chi phí.',
    technologies: ['Dify', 'vLLM', 'Langfuse'],
    video: '/video/Enterprise AI Services.mp4',
    poster: '/img/landing/use-case-ai.webp',
    link: '/ai-service',
  },
];

function CapabilityCard({title, description, technologies, video, poster, link}: Capability): React.JSX.Element {
  return (
    <a href={link} className={styles.card} aria-label={`Tìm hiểu ${title}`}>
      <div className={styles.cardMedia} aria-hidden="true">
        <video
          autoPlay
          muted
          loop
          playsInline
          preload="metadata"
          poster={poster}
          aria-hidden="true"
        >
          <source src={video} type="video/mp4" />
        </video>
      </div>
      <div className={styles.cardContent}>
        <h3>{title}</h3>
        <p>{description}</p>
        <div className={styles.cardFooter}>
          <div className={styles.technologies}>
            {technologies.map((technology) => (
              <span key={technology}>{technology}</span>
            ))}
          </div>
        </div>
      </div>
    </a>
  );
}

export default function PlatformGrid(): React.JSX.Element {
  return (
    <section className={styles.section} id="capabilities">
      <div className="container">
        <div className={styles.header}>
          <div>
            <span className={styles.eyebrow}>Năng lực nền tảng</span>
            <h2>
              Một nền tảng
              <br className="landingDesktopBreak" />{' '}
              Toàn bộ vòng đời dữ liệu
            </h2>
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
