import React from 'react';
import styles from './styles.module.css';

const principles = [
  {
    number: '01',
    title: 'Mở theo thiết kế',
    description: 'Open-source, open table format và API-first giúp doanh nghiệp kiểm soát dữ liệu lẫn lộ trình công nghệ.',
  },
  {
    number: '02',
    title: 'Bảo mật xuyên suốt',
    description: 'Policy, identity, secret và audit được thiết kế thành năng lực nền tảng, không phải lớp bổ sung về sau.',
  },
  {
    number: '03',
    title: 'Sẵn sàng mở rộng',
    description: 'Kiến trúc cloud-native hỗ trợ mở rộng từng lớp độc lập theo khối lượng dữ liệu và workload thực tế.',
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
  return (
    <section className={styles.section} id="architecture">
      <div className="container">
        <div className={styles.intro}>
          <div>
            <span className={styles.eyebrow}>Enterprise reference architecture</span>
            <h2>Kiến trúc mở cho dữ liệu và AI ở quy mô doanh nghiệp.</h2>
          </div>
          <div className={styles.introCopy}>
            <p>
              Hanas tổ chức toàn bộ platform thành các lớp độc lập nhưng liên kết chặt chẽ:
              nguồn dữ liệu, ingestion, transformation, data store, governance, consumption và AI services.
            </p>
            <a href="/overview/architecture">
              Đọc tài liệu kiến trúc <span aria-hidden="true">↗</span>
            </a>
          </div>
        </div>

        <a
          href="/img/solution-architect.png"
          target="_blank"
          rel="noreferrer"
          className={styles.architectureFrame}
          aria-label="Mở sơ đồ kiến trúc Hanas Data & AI Platform ở kích thước đầy đủ"
        >
          <div className={styles.frameHeader}>
            <span>HANAS / SOLUTION BLUEPRINT</span>
            <span>EXPAND ↗</span>
          </div>
          <div className={styles.imageViewport}>
            <img
              src="/img/solution-architect.png"
              alt="Sơ đồ kiến trúc giải pháp Hanas Data & AI Platform"
              loading="lazy"
            />
          </div>
        </a>

        <div
          className={styles.mobileArchitecture}
          aria-label="Kiến trúc Hanas theo luồng dọc từ nguồn dữ liệu đến sản phẩm dữ liệu và AI"
        >
          <div className={styles.mobileFrameHeader}>
            <span>HANAS / PLATFORM FLOW</span>
            <span>05 LAYERS</span>
          </div>
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
          <a href="/img/solution-architect.png" target="_blank" rel="noreferrer">
            Xem blueprint đầy đủ <span aria-hidden="true">↗</span>
          </a>
        </div>

        <div className={styles.principles}>
          {principles.map((principle) => (
            <article key={principle.number}>
              <span>{principle.number}</span>
              <div>
                <h3>{principle.title}</h3>
                <p>{principle.description}</p>
              </div>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}
