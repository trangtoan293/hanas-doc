import React from 'react';
import styles from './styles.module.css';

const dataSources = ['Core Banking', 'ERP / CRM', 'IoT & Logs'];
const dataProducts = ['BI & Analytics', 'AI Applications', 'Data APIs'];

export default function HeroSection(): React.JSX.Element {
  return (
    <section className={styles.hero}>
      <div className={styles.stage}>
        <div className={styles.gridBackdrop} aria-hidden="true" />
        <div className={styles.heroGlow} aria-hidden="true" />

        <div className="container">
          <div className={styles.heroInner}>
            <div className={styles.heroContent}>
            <div className={`${styles.productBadge} ${styles.animateIn} ${styles.delay1}`}>
              <span className={styles.badgeMark} aria-hidden="true" />
              Hanas Data &amp; AI Platform
            </div>
            <h1 className={`${styles.heroTitle} ${styles.animateIn} ${styles.delay2}`}>
              Dữ liệu sẵn sàng.
              <span className={styles.gradientText}> AI vận hành thật.</span>
            </h1>

            <p className={`${styles.heroSubtitle} ${styles.animateIn} ${styles.delay3}`}>
              Hanas hợp nhất dữ liệu, quản trị và AI trên một kiến trúc Lakehouse mở —
              giúp doanh nghiệp đi từ dữ liệu phân tán đến sản phẩm dữ liệu tin cậy,
              nhanh hơn và an toàn hơn.
            </p>

            <div className={`${styles.heroButtons} ${styles.animateIn} ${styles.delay4}`}>
              <a href="/overview" className={styles.ctaPrimary}>
                Khám phá nền tảng
                <span aria-hidden="true">↗</span>
              </a>
              <a href="/overview/architecture" className={styles.ctaSecondary}>
                Xem kiến trúc
                <span aria-hidden="true">→</span>
              </a>
            </div>

            <div className={`${styles.trustRow} ${styles.animateIn} ${styles.delay5}`}>
              <span>Open Lakehouse</span>
              <span>Cloud-native</span>
              <span>Enterprise-ready</span>
            </div>
            </div>

            <div className={`${styles.heroVisual} ${styles.animateIn} ${styles.delay4}`}>
              <div className={styles.controlPlane}>
              <div className={styles.panelHeader}>
                <div>
                  <span className={styles.panelEyebrow}>HANAS CONTROL PLANE</span>
                  <strong>Enterprise Data Flow</strong>
                </div>
                <span className={styles.liveStatus}>
                  <span aria-hidden="true" /> Live
                </span>
              </div>

              <div className={styles.pipeline} aria-label="Luồng dữ liệu từ hệ thống nguồn qua Hanas Lakehouse đến các sản phẩm dữ liệu">
                <div className={styles.pipelineColumn}>
                  <span className={styles.columnLabel}>Sources</span>
                  {dataSources.map((source, index) => (
                    <div key={source} className={styles.sourceNode}>
                      <span>{String(index + 1).padStart(2, '0')}</span>
                      {source}
                    </div>
                  ))}
                </div>

                <div className={styles.flowConnector} aria-hidden="true">
                  <i />
                  <i />
                  <i />
                </div>

                <div className={styles.lakehouseNode}>
                  <span className={styles.orbit} aria-hidden="true" />
                  <span className={styles.coreMark}>H</span>
                  <strong>Unified<br />Lakehouse</strong>
                  <small>Governed · Observable · AI-ready</small>
                </div>

                <div className={`${styles.flowConnector} ${styles.flowConnectorRight}`} aria-hidden="true">
                  <i />
                  <i />
                  <i />
                </div>

                <div className={styles.pipelineColumn}>
                  <span className={styles.columnLabel}>Data products</span>
                  {dataProducts.map((product) => (
                    <div key={product} className={styles.productNode}>
                      <span className={styles.nodePulse} aria-hidden="true" />
                      {product}
                    </div>
                  ))}
                </div>
              </div>

              <div className={styles.panelFooter}>
                <div>
                  <span>Pipeline health</span>
                  <strong>Operational</strong>
                </div>
                <div>
                  <span>Data quality</span>
                  <strong>Monitored</strong>
                </div>
                <div>
                  <span>AI services</span>
                  <strong>Connected</strong>
                </div>
              </div>
              </div>
            </div>
          </div>

          <div className={`${styles.techRail} ${styles.animateIn} ${styles.delay5}`}>
            <span className={styles.techRailLabel}>POWERED BY OPEN TECHNOLOGIES</span>
            <div className={styles.techList}>
              {['Kafka', 'Spark', 'Iceberg', 'Airflow', 'DataHub', 'Dremio', 'vLLM'].map((tech) => (
                <span key={tech}>{tech}</span>
              ))}
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
