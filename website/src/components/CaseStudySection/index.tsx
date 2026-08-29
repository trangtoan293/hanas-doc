import React from 'react';
import useLazyVideo from '@site/src/hooks/useLazyVideo';
import styles from './styles.module.css';

const principles = [
  {
    title: 'Không bị khóa công nghệ',
    description: 'Định dạng mở và API tiêu chuẩn cho phép thay storage, compute hoặc công cụ xử lý theo nhu cầu.',
  },
  {
    title: 'Quản trị ngay từ đầu',
    description: 'Phân quyền, metadata, lineage và audit đi cùng dữ liệu xuyên suốt, không phải bổ sung sau khi vận hành.',
  },
  {
    title: 'Mở rộng theo tải thực tế',
    description: 'Từng lớp mở rộng độc lập theo khối lượng dữ liệu và workload, không phải nâng cấp toàn bộ hệ thống.',
  },
];

const architectureLayers = [
  {number: '01', title: 'Nguồn dữ liệu', detail: 'Core systems · SaaS · IoT'},
  {number: '02', title: 'Ingestion & Streaming', detail: 'NiFi · Kafka · CDC'},
  {number: '03', title: 'Open Lakehouse', detail: 'MinIO · Iceberg · Polaris'},
  {number: '04', title: 'Processing & Modeling', detail: 'Spark · Airflow · dbt'},
  {number: '05', title: 'Data Products & AI', detail: 'Dremio · BI · Dify · vLLM'},
];

export default function CaseStudySection(): React.JSX.Element {
  const videoRef = useLazyVideo();
  return (
    <section className={styles.section} id="architecture">
      <video
        className={styles.sectionVideo}
        ref={videoRef}
        muted
        loop
        playsInline
        preload="none"
        poster="/img/poster/computer.webp"
        aria-hidden="true"
      >
        <source src="/video/computer.mp4" type="video/mp4" />
      </video>
      <div className={styles.sectionVideoOverlay} aria-hidden="true" />

      <div className={`container ${styles.content}`}>
        <div className={styles.intro}>
          <div>
            <span className={styles.eyebrow}>Kiến trúc tham chiếu doanh nghiệp</span>
            <h2>
              Một kiến trúc mở
              <br className="landingDesktopBreak" />{' '}
              Từ dữ liệu đến AI
            </h2>
          </div>
          <div className={styles.introCopy}>
            <p>
              Doanh nghiệp thay đổi từng lớp công nghệ mà không phải xây lại toàn bộ nền tảng.
              Dữ liệu vẫn đi liền mạch từ hệ thống nguồn đến BI và AI.
            </p>
          </div>
        </div>

        <a
          href="/overview/architecture"
          className={styles.architectureVisual}
          aria-label="Mở trang kiến trúc Hanas Data & AI Platform"
        >
          <img
            src="/img/solution-architect.png"
            alt="Sơ đồ kiến trúc giải pháp Hanas Data & AI Platform"
            loading="lazy"
          />
        </a>

        <div
          className={styles.mobileArchitecture}
          aria-label="Kiến trúc Hanas theo luồng dọc từ nguồn dữ liệu đến sản phẩm dữ liệu và AI"
        >
          <div className={styles.mobileLayers}>
            {architectureLayers.map((layer) => (
              <article key={layer.number}>
                <span>{layer.number}</span>
                <div>
                  <strong>{layer.title}</strong>
                  <small>{layer.detail}</small>
                </div>
              </article>
            ))}
          </div>
          <div className={styles.supportingLayers}>
            <span>Governance</span>
            <span>Security</span>
            <span>Observability</span>
          </div>
        </div>

        <div className={styles.principles}>
          {principles.map((principle) => (
            <article key={principle.title}>
              <h3>{principle.title}</h3>
              <p>{principle.description}</p>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}
