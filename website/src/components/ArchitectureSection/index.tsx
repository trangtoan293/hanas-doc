import React from 'react';
import styles from './styles.module.css';

interface ArchitectureLayer {
  id: string;
  number: string;
  name: string;
  nameEn: string;
  technologies: string[];
  description: string;
}

const layers: ArchitectureLayer[] = [
  {
    id: 'l1',
    number: 'L1',
    name: 'Thu Thập',
    nameEn: 'Ingestion',
    technologies: ['NiFi', 'Kafka'],
    description: 'Thu thập dữ liệu từ mọi nguồn',
  },
  {
    id: 'l2',
    number: 'L2',
    name: 'Lưu Trữ',
    nameEn: 'Storage',
    technologies: ['MinIO', 'Iceberg'],
    description: 'Lưu trữ quy mô lớn, định dạng mở',
  },
  {
    id: 'l3',
    number: 'L3',
    name: 'Xử Lý',
    nameEn: 'Processing',
    technologies: ['Airflow', 'Spark'],
    description: 'Xử lý và transform dữ liệu',
  },
  {
    id: 'l4',
    number: 'L4',
    name: 'Mô Hình',
    nameEn: 'Data Modeling',
    technologies: ['dbt', 'Data Vault'],
    description: 'Mô hình hóa dữ liệu',
  },
  {
    id: 'l5',
    number: 'L5',
    name: 'Quản Trị',
    nameEn: 'Governance',
    technologies: ['DataHub'],
    description: 'Quản lý metadata và lineage',
  },
  {
    id: 'l6',
    number: 'L6',
    name: 'Liên Kết',
    nameEn: 'Federation',
    technologies: ['Dremio'],
    description: 'Truy vấn liên kết dữ liệu',
  },
  {
    id: 'l7',
    number: 'L7',
    name: 'Khai Thác',
    nameEn: 'Consumption',
    technologies: ['Dremio', 'Superset'],
    description: 'Cung cấp dữ liệu, semantic layer và dashboard',
  },
  {
    id: 'l8',
    number: 'L8',
    name: 'AI Service',
    nameEn: 'AI Service',
    technologies: ['Dify', 'vLLM', 'Langfuse'],
    description: 'Tích hợp AI/ML',
  },
];

const ArrowConnector: React.FC = () => (
  <div className={styles.arrowConnector}>
    <svg
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      className={styles.arrowIcon}
    >
      <path
        d="M12 5V19M12 19L5 12M12 19L19 12"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  </div>
);

const LayerCard: React.FC<ArchitectureLayer & { index: number }> = ({
  number,
  name,
  nameEn,
  technologies,
  description,
  index,
}) => (
  <div
    className={styles.layerCard}
    style={{ animationDelay: `${index * 0.1}s` }}
  >
    <div className={styles.accentBar} />
    <div className={styles.layerContent}>
      <div className={styles.layerBadge}>
        <span className={styles.layerNumber}>{number}</span>
      </div>
      <div className={styles.layerInfo}>
        <div className={styles.layerHeader}>
          <h3 className={styles.layerName}>{name}</h3>
          <span className={styles.layerNameEn}>{nameEn}</span>
        </div>
        <div className={styles.technologies}>
          {technologies.map((tech) => (
            <span key={tech} className={styles.techTag}>
              {tech}
            </span>
          ))}
        </div>
      </div>
      <p className={styles.layerDescription}>{description}</p>
    </div>
  </div>
);

const ArchitectureSection: React.FC = () => {
  return (
    <section className={styles.section}>
      <div className="container">
        <div className={styles.header}>
          <h2 className={styles.title}>Kiến Trúc Nền Tảng</h2>
          <p className={styles.subtitle}>
            Hanas Data Platform được thiết kế theo kiến trúc phân tầng rõ ràng,
            từ thu thập và quản trị dữ liệu đến khai thác và AI Service
          </p>
        </div>

        <div className={styles.diagram}>
          {layers.map((layer, index) => (
            <React.Fragment key={layer.id}>
              <LayerCard {...layer} index={index} />
              {index < layers.length - 1 && <ArrowConnector />}
            </React.Fragment>
          ))}
        </div>

        <div className={styles.footer}>
          <a
            href="/overview/architecture"
            className={styles.detailLink}
          >
            Xem kiến trúc chi tiết
            <svg
              width="20"
              height="20"
              viewBox="0 0 24 24"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
              className={styles.linkArrow}
            >
              <path
                d="M5 12H19M19 12L12 5M19 12L12 19"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
          </a>
        </div>
      </div>
    </section>
  );
};

export default ArchitectureSection;
